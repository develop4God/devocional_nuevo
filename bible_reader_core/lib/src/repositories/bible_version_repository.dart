import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;

import '../exceptions/bible_version_exceptions.dart';
import '../interfaces/bible_version_storage.dart';
import '../interfaces/http_client.dart';
import '../models/bible_version_model.dart';

/// Configuration for download retry behavior.
class RetryConfig {
  /// Maximum number of retry attempts.
  final int maxRetries;

  /// Initial delay between retries (doubles with each attempt).
  final Duration initialDelay;

  /// Maximum delay between retries.
  final Duration maxDelay;

  /// Creates a retry configuration.
  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(seconds: 30),
  });

  /// Calculates delay for given attempt (exponential backoff).
  /// Uses bounded calculation to prevent overflow for large attempt values.
  Duration delayForAttempt(int attempt) {
    // Limit exponent to prevent overflow (max ~17 hours with default 2s initial delay)
    final boundedAttempt = attempt.clamp(0, 20);
    final multiplier = 1 << boundedAttempt; // 2^attempt, capped at 2^20
    final delay = initialDelay * multiplier;
    return delay > maxDelay ? maxDelay : delay;
  }
}

/// Priority levels for download queue.
enum DownloadPriority {
  /// Normal priority (default).
  normal,

  /// High priority - moves to front of queue.
  high,
}

/// Repository for managing Bible version downloads and storage.
///
/// This is a framework-agnostic class that can be used with any state management
/// solution (BLoC, Riverpod, Provider, etc.). It uses constructor-based
/// dependency injection for all external dependencies.
///
/// Features:
/// - Download queuing with priority support (max 2 concurrent)
/// - Exponential backoff retry on failure (3 retries by default)
/// - Pre-download storage space validation
/// - SQLite database integrity verification
///
/// Usage example:
/// ```dart
/// final repo = BibleVersionRepository(
///   httpClient: httpClientAdapter,
///   storage: storageAdapter,
///   metadataUrl: 'https://raw.githubusercontent.com/...',
/// );
///
/// // Fetch available versions
/// final versions = await repo.fetchAvailableVersions();
///
/// // Download a version with high priority
/// repo.downloadProgress('es-RVR1960').listen((progress) {
///   print('Progress: ${progress * 100}%');
/// });
/// await repo.downloadVersion('es-RVR1960', priority: DownloadPriority.high);
/// ```
class BibleVersionRepository {
  /// HTTP client for network operations.
  final HttpClient httpClient;

  /// Storage interface for file operations.
  final BibleVersionStorage storage;

  /// URL to fetch the metadata.json catalog.
  final String metadataUrl;

  /// Configuration for download retries.
  final RetryConfig retryConfig;

  /// Maximum concurrent downloads allowed.
  final int maxConcurrentDownloads;

  /// Buffer size multiplier for storage space (2x file size).
  static const int _storageBufferMultiplier = 2;

  /// Cached metadata for available versions.
  List<BibleVersionMetadata>? _cachedMetadata;

  /// Set of currently downloaded version IDs.
  final Set<String> _downloadedVersions = {};

  /// Map of version ID to download progress stream controllers.
  final Map<String, StreamController<double>> _progressControllers = {};

  /// Queue for managing pending downloads.
  final List<_QueuedDownload> _downloadQueue = [];

  /// Number of currently active downloads.
  int _activeDownloads = 0;

  /// Stream controller for queue position updates.
  final _queuePositionController = StreamController<Map<String, int>>.broadcast();

  /// Creates a Bible version repository.
  ///
  /// [httpClient] - HTTP client implementation for network operations.
  /// [storage] - Storage implementation for file operations.
  /// [metadataUrl] - URL to fetch the versions catalog (metadata.json).
  /// [retryConfig] - Configuration for download retry behavior.
  /// [maxConcurrentDownloads] - Maximum number of simultaneous downloads (default: 2).
  BibleVersionRepository({
    required this.httpClient,
    required this.storage,
    this.metadataUrl =
        'https://raw.githubusercontent.com/develop4God/bible_versions/main/metadata.json',
    this.retryConfig = const RetryConfig(),
    this.maxConcurrentDownloads = 2,
  });

  /// Initializes the repository by loading the list of downloaded versions.
  ///
  /// Call this once when the app starts or when you need to refresh the state.
  Future<void> initialize() async {
    final downloaded = await storage.getDownloadedVersions();
    _downloadedVersions.clear();
    _downloadedVersions.addAll(downloaded);
  }

  /// Returns a stream of download progress for the specified version.
  ///
  /// Progress is a value between 0.0 and 1.0.
  /// The stream completes when the download finishes or fails.
  Stream<double> downloadProgress(String versionId) {
    _progressControllers[versionId]?.close();
    _progressControllers[versionId] = StreamController<double>.broadcast();
    return _progressControllers[versionId]!.stream;
  }

  /// Fetches the list of available Bible versions from the remote catalog.
  ///
  /// Returns a list of [BibleVersionMetadata] with information about each version.
  /// Throws [NetworkException] if the fetch fails.
  /// Throws [MetadataParsingException] if the JSON is malformed.
  Future<List<BibleVersionMetadata>> fetchAvailableVersions() async {
    if (_cachedMetadata != null) {
      return _cachedMetadata!;
    }

    try {
      final response = await httpClient.get(metadataUrl);

      if (!response.isSuccess) {
        throw NetworkException(
          'Failed to fetch metadata',
          statusCode: response.statusCode,
        );
      }

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) {
        throw const MetadataParsingException('Invalid metadata format');
      }

      final versionsJson = json['versions'];
      if (versionsJson is! List) {
        throw const MetadataParsingException('Missing or invalid versions array');
      }

      _cachedMetadata = versionsJson
          .map((v) => BibleVersionMetadata.fromJson(v as Map<String, dynamic>))
          .toList();

      return _cachedMetadata!;
    } on BibleVersionException {
      rethrow;
    } on FormatException catch (e) {
      throw MetadataParsingException('Invalid JSON format', e);
    } catch (e) {
      throw NetworkException('Failed to fetch versions: $e', cause: e);
    }
  }

  /// Downloads a Bible version to local storage.
  ///
  /// Progress can be monitored via [downloadProgress].
  /// Downloads are queued - max [maxConcurrentDownloads] run simultaneously.
  /// Implements exponential backoff retry on transient failures.
  ///
  /// [priority] - Download priority (high moves to front of queue).
  ///
  /// Throws [InsufficientStorageException] if there isn't enough space.
  /// Throws [NetworkException] if the download fails after all retries.
  /// Throws [DatabaseCorruptedException] if validation fails.
  /// Throws [VersionNotFoundException] if the version doesn't exist.
  /// Throws [MaxRetriesExceededException] if download fails after max retries.
  Future<void> downloadVersion(
    String versionId, {
    DownloadPriority priority = DownloadPriority.normal,
  }) async {
    // Check if already in queue or downloading
    if (_downloadQueue.any((q) => q.versionId == versionId)) {
      return; // Already queued
    }

    // Add to queue with priority
    final queuedDownload = _QueuedDownload(versionId: versionId, priority: priority);
    
    if (priority == DownloadPriority.high) {
      _downloadQueue.insert(0, queuedDownload);
    } else {
      _downloadQueue.add(queuedDownload);
    }
    
    _updateQueuePositions();
    _processQueue();

    // Wait for this download to complete
    await queuedDownload.completer.future;
  }

  /// Returns the current queue position for a version (0 if not queued).
  int getQueuePosition(String versionId) {
    final index = _downloadQueue.indexWhere((q) => q.versionId == versionId);
    return index >= 0 ? index + 1 : 0;
  }

  /// Stream of queue position updates as downloads progress.
  Stream<Map<String, int>> get queuePositionUpdates => _queuePositionController.stream;

  /// Calculates the required storage space for a version.
  Future<int> calculateRequiredSpace(String versionId) async {
    final versions = await fetchAvailableVersions();
    final metadata = versions.where((v) => v.id == versionId).firstOrNull;
    if (metadata == null) return 0;
    return metadata.uncompressedSizeBytes * _storageBufferMultiplier;
  }

  void _updateQueuePositions() {
    final positions = <String, int>{};
    for (var i = 0; i < _downloadQueue.length; i++) {
      positions[_downloadQueue[i].versionId] = i + 1;
    }
    _queuePositionController.add(positions);
  }

  void _processQueue() {
    while (_activeDownloads < maxConcurrentDownloads && _downloadQueue.isNotEmpty) {
      final download = _downloadQueue.first;
      if (download.isProcessing) break;
      
      download.isProcessing = true;
      _activeDownloads++;
      _updateQueuePositions();
      
      _performDownloadWithRetry(download).then((_) {
        _downloadQueue.remove(download);
        _activeDownloads--;
        download.completer.complete();
        _updateQueuePositions();
        _processQueue();
      }).catchError((error) {
        _downloadQueue.remove(download);
        _activeDownloads--;
        download.completer.completeError(error);
        _updateQueuePositions();
        _processQueue();
      });
    }
  }

  Future<void> _performDownloadWithRetry(_QueuedDownload download) async {
    final versionId = download.versionId;
    int attempt = 0;
    Object? lastError;

    while (attempt <= retryConfig.maxRetries) {
      try {
        await _performDownload(versionId);
        return; // Success
      } on NetworkException catch (e) {
        lastError = e;
        attempt++;
        if (attempt <= retryConfig.maxRetries) {
          final delay = retryConfig.delayForAttempt(attempt - 1);
          await Future.delayed(delay);
        }
      } on InsufficientStorageException {
        rethrow; // Don't retry storage issues
      } on DatabaseCorruptedException {
        rethrow; // Don't retry corruption
      } on VersionNotFoundException {
        rethrow; // Don't retry not found
      } catch (e) {
        lastError = e;
        attempt++;
        if (attempt <= retryConfig.maxRetries) {
          final delay = retryConfig.delayForAttempt(attempt - 1);
          await Future.delayed(delay);
        }
      }
    }

    throw MaxRetriesExceededException(
      versionId: versionId,
      attempts: retryConfig.maxRetries,
      cause: lastError,
    );
  }

  Future<void> _performDownload(String versionId) async {
    final controller = _progressControllers[versionId];
    String? partialPath;

    try {
      // Get version metadata
      final versions = await fetchAvailableVersions();
      final metadata = versions.where((v) => v.id == versionId).firstOrNull;
      
      if (metadata == null) {
        throw VersionNotFoundException(versionId);
      }

      // Validate metadata
      final validationErrors = metadata.validate();
      if (validationErrors.isNotEmpty) {
        throw MetadataValidationException(validationErrors);
      }

      // Check storage space (require 2x uncompressed size as buffer)
      final availableSpace = await storage.getAvailableSpace();
      final requiredSpace = metadata.uncompressedSizeBytes * _storageBufferMultiplier;
      
      if (availableSpace > 0 && availableSpace < requiredSpace) {
        throw InsufficientStorageException(
          availableBytes: availableSpace,
          requiredBytes: requiredSpace,
        );
      }

      // Prepare paths
      final biblesDir = await storage.getBiblesDirectory();
      final versionDir = '$biblesDir/$versionId';
      final dbPath = '$versionDir/bible.db';
      partialPath = '$dbPath.partial';

      // Create version directory
      await storage.createDirectory(versionDir);

      // Emit initial progress
      controller?.add(0.0);

      // Download the file
      final downloadedBytes = <int>[];
      
      await for (final progress in httpClient.downloadStream(metadata.downloadUrl)) {
        downloadedBytes.addAll(progress.data);
        controller?.add(progress.progress);
      }

      if (downloadedBytes.isEmpty) {
        throw NetworkException('Download produced no data');
      }

      // Write partial file
      await storage.writeFile(partialPath, downloadedBytes);

      // Decompress if needed (gzip)
      List<int> decompressedBytes;
      try {
        decompressedBytes = gzip.decode(downloadedBytes);
      } catch (e) {
        throw DecompressionException(versionId, e);
      }

      // Validate the database (basic check: SQLite header)
      if (!_isValidSqliteDatabase(decompressedBytes)) {
        throw DatabaseCorruptedException.forVersion(versionId);
      }

      // Write final file
      await storage.writeFile(dbPath, decompressedBytes);

      // Remove partial file
      await storage.deleteFile(partialPath);
      partialPath = null;

      // Update downloaded versions
      _downloadedVersions.add(versionId);
      await storage.saveDownloadedVersions(_downloadedVersions.toList());

      // Emit completion
      controller?.add(1.0);
    } catch (e) {
      // Clean up partial file on failure
      if (partialPath != null) {
        await storage.deleteFile(partialPath);
      }

      // Remove from downloaded set
      _downloadedVersions.remove(versionId);

      rethrow;
    } finally {
      controller?.close();
      _progressControllers.remove(versionId);
    }
  }

  /// Validates that the bytes represent a valid SQLite database.
  bool _isValidSqliteDatabase(List<int> bytes) {
    // SQLite database files start with "SQLite format 3\0"
    const sqliteHeader = [0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, 
                          0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00];
    
    if (bytes.length < sqliteHeader.length) {
      return false;
    }
    
    for (int i = 0; i < sqliteHeader.length; i++) {
      if (bytes[i] != sqliteHeader[i]) {
        return false;
      }
    }
    
    return true;
  }

  /// Deletes a downloaded Bible version.
  ///
  /// Removes all files associated with the version and updates the downloaded list.
  /// Does nothing if the version is not downloaded.
  Future<void> deleteVersion(String versionId) async {
    final biblesDir = await storage.getBiblesDirectory();
    final versionDir = '$biblesDir/$versionId';

    // Delete the version directory
    await storage.deleteDirectory(versionDir);

    // Update downloaded versions
    _downloadedVersions.remove(versionId);
    await storage.saveDownloadedVersions(_downloadedVersions.toList());
  }

  /// Returns the list of downloaded version IDs.
  Future<List<String>> getDownloadedVersionIds() async {
    if (_downloadedVersions.isEmpty) {
      final downloaded = await storage.getDownloadedVersions();
      _downloadedVersions.addAll(downloaded);
    }
    return _downloadedVersions.toList();
  }

  /// Checks if a version is downloaded.
  bool isVersionDownloaded(String versionId) {
    return _downloadedVersions.contains(versionId);
  }

  /// Gets the database path for a downloaded version.
  ///
  /// Returns null if the version is not downloaded.
  Future<String?> getVersionDatabasePath(String versionId) async {
    if (!isVersionDownloaded(versionId)) {
      return null;
    }

    final biblesDir = await storage.getBiblesDirectory();
    final dbPath = '$biblesDir/$versionId/bible.db';

    if (await storage.fileExists(dbPath)) {
      return dbPath;
    }

    return null;
  }

  /// Clears the cached metadata, forcing a refresh on the next fetch.
  void clearMetadataCache() {
    _cachedMetadata = null;
  }

  /// Disposes of resources used by the repository.
  void dispose() {
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
    _queuePositionController.close();
  }
}

/// Internal class for managing queued downloads.
class _QueuedDownload {
  final String versionId;
  final DownloadPriority priority;
  final Completer<void> completer = Completer<void>();
  bool isProcessing = false;

  _QueuedDownload({
    required this.versionId,
    required this.priority,
  });
}
