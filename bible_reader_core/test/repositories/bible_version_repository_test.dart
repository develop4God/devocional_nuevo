import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock HTTP client for testing.
class MockHttpClient implements HttpClient {
  final Map<String, MockHttpResponse> _responses = {};
  final Map<String, MockDownloadStream> _downloadStreams = {};
  bool _downloadStarted = false;

  void givenMetadataResponse(List<Map<String, dynamic>> versions) {
    _responses['metadata.json'] = MockHttpResponse(
      statusCode: 200,
      body: jsonEncode({
        'schemaVersion': '1.0',
        'lastUpdated': '2025-12-03T00:00:00Z',
        'versions': versions,
      }),
    );
  }

  void givenGetResponse(String urlPattern, {required int statusCode, String body = ''}) {
    _responses[urlPattern] = MockHttpResponse(statusCode: statusCode, body: body);
  }

  void givenDownloadStream(String versionId, List<int> data) {
    _downloadStreams[versionId] = MockDownloadStream(
      data: data,
      total: data.length,
    );
  }

  void givenDownloadStreamFailsAt(String versionId, List<int> data, int failAtPercent) {
    _downloadStreams[versionId] = MockDownloadStream(
      data: data,
      total: data.length,
      failAtPercent: failAtPercent,
    );
  }

  void givenDownloadTakes(String versionId, List<int> data, Duration duration) {
    _downloadStreams[versionId] = MockDownloadStream(
      data: data,
      total: data.length,
      delayBetweenChunks: duration ~/ 10,
    );
  }

  void givenDownloadProducesCorruptedFile(String versionId) {
    // Produce a file that doesn't have SQLite header
    _downloadStreams[versionId] = MockDownloadStream(
      data: gzip.encode([0, 1, 2, 3, 4, 5]),
      total: 6,
    );
  }

  void givenDownloadResponse(String versionId, List<int> data) {
    _downloadStreams[versionId] = MockDownloadStream(
      data: data,
      total: data.length,
    );
  }

  void givenDownloadResponseWithDelay(String versionId, Duration delay) {
    // Create a valid gzip compressed SQLite-like response
    _downloadStreams[versionId] = MockDownloadStream(
      data: gzip.encode([0x53, 0x51, 0x4C, 0x69, 0x74, 0x65]),
      total: 6,
      delayBetweenChunks: delay,
    );
  }

  void givenGetThrows(String urlPattern, Exception exception) {
    _exceptions[urlPattern] = exception;
  }

  final Map<String, Exception> _exceptions = {};

  Future<void> verifyNoDownloadStarted() async {
    expect(_downloadStarted, isFalse, reason: 'Download should not have started');
  }

  @override
  Future<HttpResponse> get(String url) async {
    for (final pattern in _exceptions.keys) {
      if (url.contains(pattern)) {
        throw _exceptions[pattern]!;
      }
    }
    for (final pattern in _responses.keys) {
      if (url.contains(pattern)) {
        final response = _responses[pattern]!;
        return HttpResponse(
          statusCode: response.statusCode,
          body: response.body,
          headers: const {},
        );
      }
    }
    return const HttpResponse(statusCode: 404, body: '', headers: {});
  }

  @override
  Stream<HttpDownloadProgress> downloadStream(String url) async* {
    _downloadStarted = true;
    
    for (final pattern in _downloadStreams.keys) {
      if (url.contains(pattern)) {
        yield* _downloadStreams[pattern]!.stream();
        return;
      }
    }
    
    throw NetworkException('Download URL not found: $url');
  }
}

class MockHttpResponse {
  final int statusCode;
  final String body;

  MockHttpResponse({required this.statusCode, required this.body});
}

class MockDownloadStream {
  final List<int> data;
  final int total;
  final int? failAtPercent;
  final Duration? delayBetweenChunks;

  MockDownloadStream({
    required this.data,
    required this.total,
    this.failAtPercent,
    this.delayBetweenChunks,
  });

  Stream<HttpDownloadProgress> stream() async* {
    const chunkSize = 1024;
    int downloaded = 0;

    for (var i = 0; i < data.length; i += chunkSize) {
      if (delayBetweenChunks != null) {
        await Future.delayed(delayBetweenChunks!);
      }

      final end = (i + chunkSize > data.length) ? data.length : i + chunkSize;
      final chunk = data.sublist(i, end);
      downloaded += chunk.length;

      // Check if we should fail at this point
      if (failAtPercent != null) {
        final progress = (downloaded / total) * 100;
        if (progress >= failAtPercent!) {
          throw const NetworkException('Network error during download');
        }
      }

      yield HttpDownloadProgress(
        downloaded: downloaded,
        total: total,
        data: chunk,
      );
    }
  }
}

/// Mock storage for testing.
class MockBibleVersionStorage implements BibleVersionStorage {
  final Map<String, List<int>> _files = {};
  final Set<String> _directories = {};
  List<String> _downloadedVersions = [];
  int _availableSpace = 1024 * 1024 * 1024; // 1GB default
  final List<String> _deletedFiles = [];
  final List<String> _deletedDirectories = [];

  void givenDownloadedVersions(List<String> versions) {
    _downloadedVersions = List.from(versions);
  }

  void givenAvailableSpace(int bytes) {
    _availableSpace = bytes;
  }

  Future<void> verifyFileDeleted(String pathContains) async {
    final found = _deletedFiles.any((f) => f.contains(pathContains));
    expect(found, isTrue, reason: 'Expected file containing "$pathContains" to be deleted');
  }

  Future<void> verifyDirectoryDeleted(String pathContains) async {
    final found = _deletedDirectories.any((d) => d.contains(pathContains));
    expect(found, isTrue, reason: 'Expected directory containing "$pathContains" to be deleted');
  }

  @override
  Future<String> getBiblesDirectory() async => '/mock/bibles';

  @override
  Future<void> saveDownloadedVersions(List<String> versionIds) async {
    _downloadedVersions = List.from(versionIds);
  }

  @override
  Future<List<String>> getDownloadedVersions() async {
    return List.from(_downloadedVersions);
  }

  @override
  Future<void> writeFile(String path, List<int> bytes) async {
    _files[path] = bytes;
  }

  @override
  Future<List<int>> readFile(String path) async {
    if (!_files.containsKey(path)) {
      throw Exception('File not found: $path');
    }
    return _files[path]!;
  }

  @override
  Future<void> deleteFile(String path) async {
    _files.remove(path);
    _deletedFiles.add(path);
  }

  @override
  Future<bool> fileExists(String path) async {
    return _files.containsKey(path);
  }

  @override
  Future<int> getAvailableSpace() async => _availableSpace;

  @override
  Future<void> deleteDirectory(String path) async {
    _directories.remove(path);
    _deletedDirectories.add(path);
    // Also remove files in the directory
    _files.removeWhere((key, _) => key.startsWith(path));
  }

  @override
  Future<bool> directoryExists(String path) async {
    return _directories.contains(path);
  }

  @override
  Future<void> createDirectory(String path) async {
    _directories.add(path);
  }

  @override
  Future<List<String>> listFiles(String directoryPath) async {
    return _files.keys
        .where((path) => path.startsWith(directoryPath))
        .map((path) => path.split('/').last)
        .toList();
  }
}

/// Creates a valid SQLite database bytes (just the header for testing).
List<int> createValidSqliteDatabase() {
  // SQLite header: "SQLite format 3\0"
  final header = [0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, 
                  0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00];
  // Add some padding to make it look like a real database
  final padding = List.filled(1024, 0);
  return [...header, ...padding];
}

/// Creates test metadata for a Bible version.
Map<String, dynamic> createVersionMetadata({
  required String id,
  required String name,
  required String language,
  required String languageName,
  int sizeBytes = 1024 * 1024,
  int uncompressedSizeBytes = 2 * 1024 * 1024,
}) {
  return {
    'id': id,
    'name': name,
    'language': language,
    'languageName': languageName,
    'filename': '$id.SQLite3',
    'downloadUrl': 'https://raw.githubusercontent.com/test/$id.SQLite3.gz',
    'rawUrl': 'https://raw.githubusercontent.com/test/$id.SQLite3',
    'sizeBytes': sizeBytes,
    'uncompressedSizeBytes': uncompressedSizeBytes,
    'version': '1.0.0',
    'description': 'Test version $name',
    'license': 'Public Domain',
  };
}

void main() {
  late MockHttpClient mockHttp;
  late MockBibleVersionStorage mockStorage;
  late BibleVersionRepository repo;

  setUp(() {
    mockHttp = MockHttpClient();
    mockStorage = MockBibleVersionStorage();
    repo = BibleVersionRepository(
      httpClient: mockHttp,
      storage: mockStorage,
      metadataUrl: 'https://test.com/metadata.json',
      // Use no retries for faster tests
      retryConfig: const RetryConfig(
        maxRetries: 0,
        initialDelay: Duration.zero,
      ),
    );
  });

  group('User Scenario Tests', () {
    test('Scenario 1: Fresh install - User browses available versions', () async {
      // Given: Fresh install, no downloaded versions
      mockStorage.givenDownloadedVersions([]);
      mockHttp.givenMetadataResponse([
        createVersionMetadata(id: 'es-RVR1960', name: 'Reina Valera 1960', language: 'es', languageName: 'Español'),
        createVersionMetadata(id: 'es-NVI', name: 'Nueva Versión Internacional', language: 'es', languageName: 'Español'),
        createVersionMetadata(id: 'en-KJV', name: 'King James Version', language: 'en', languageName: 'English'),
        createVersionMetadata(id: 'en-NIV', name: 'New International Version', language: 'en', languageName: 'English'),
        createVersionMetadata(id: 'pt-ARC', name: 'Almeida Revista e Corrigida', language: 'pt', languageName: 'Português'),
        createVersionMetadata(id: 'pt-NVI', name: 'Nova Versão Internacional', language: 'pt', languageName: 'Português'),
        createVersionMetadata(id: 'fr-LSG1910', name: 'Louis Segond 1910', language: 'fr', languageName: 'Français'),
        createVersionMetadata(id: 'ja-SK2003', name: '新改訳2003', language: 'ja', languageName: '日本語'),
        createVersionMetadata(id: 'ja-JCB', name: '口語訳', language: 'ja', languageName: '日本語'),
      ]);

      // When: User opens version manager
      final versions = await repo.fetchAvailableVersions();

      // Then: Sees all 9 versions with metadata
      expect(versions, hasLength(9));
      expect(versions.first.name, 'Reina Valera 1960');
      expect(versions.first.language, 'es');
      expect(versions.first.languageName, 'Español');
    });

    test('Scenario 2: User downloads first version, sees progress', () async {
      // Given: Version not downloaded
      mockStorage.givenDownloadedVersions([]);
      mockHttp.givenMetadataResponse([
        createVersionMetadata(id: 'es-RVR1960', name: 'Reina Valera 1960', language: 'es', languageName: 'Español'),
      ]);
      
      // Prepare valid database bytes
      final validDb = createValidSqliteDatabase();
      final compressedDb = gzip.encode(validDb);
      mockHttp.givenDownloadStream('es-RVR1960', compressedDb);

      await repo.initialize();
      expect(repo.isVersionDownloaded('es-RVR1960'), false);

      // When: User taps download button
      final progressValues = <double>[];
      repo.downloadProgress('es-RVR1960').listen(progressValues.add);
      await repo.downloadVersion('es-RVR1960');

      // Then: Progress updates from 0% to 100%
      expect(progressValues, isNotEmpty);
      expect(progressValues.first, 0.0);
      expect(progressValues.last, 1.0);
      expect(repo.isVersionDownloaded('es-RVR1960'), true);

      // And: Can get database path
      final path = await repo.getVersionDatabasePath('es-RVR1960');
      expect(path, endsWith('bibles/es-RVR1960/bible.db'));
    });

    test('Scenario 3: Network fails mid-download, version not marked downloaded', () async {
      // Given: Download starts but fails at 50%
      mockStorage.givenDownloadedVersions([]);
      mockHttp.givenMetadataResponse([
        createVersionMetadata(id: 'en-KJV', name: 'King James Version', language: 'en', languageName: 'English'),
      ]);
      
      final validDb = createValidSqliteDatabase();
      final compressedDb = gzip.encode(validDb);
      mockHttp.givenDownloadStreamFailsAt('en-KJV', compressedDb, 50);

      await repo.initialize();

      // When: Network drops at 50% - with 0 retries configured, it throws MaxRetriesExceededException
      expect(
        () => repo.downloadVersion('en-KJV'),
        throwsA(anyOf(
          isA<NetworkException>(),
          isA<MaxRetriesExceededException>(),
        )),
      );

      // Then: Version not marked downloaded (no partial data remains)
      // Note: We collect data in memory during download, so no partial file is written
      // until download completes. This is intentional - we verify clean state on failure.
      expect(repo.isVersionDownloaded('en-KJV'), false);
    });

    test('Scenario 5: User deletes unused version to free space', () async {
      // Given: User has versions downloaded
      final validDb = createValidSqliteDatabase();
      final compressedDb = gzip.encode(validDb);
      
      mockStorage.givenDownloadedVersions([]);
      mockHttp.givenMetadataResponse([
        createVersionMetadata(id: 'es-RVR1960', name: 'Reina Valera 1960', language: 'es', languageName: 'Español'),
        createVersionMetadata(id: 'en-KJV', name: 'King James Version', language: 'en', languageName: 'English'),
        createVersionMetadata(id: 'fr-LSG', name: 'Louis Segond', language: 'fr', languageName: 'Français'),
      ]);
      mockHttp.givenDownloadStream('es-RVR1960', compressedDb);
      mockHttp.givenDownloadStream('en-KJV', compressedDb);
      mockHttp.givenDownloadStream('fr-LSG', compressedDb);

      await repo.initialize();
      
      await repo.downloadVersion('es-RVR1960');
      await repo.downloadVersion('en-KJV');
      await repo.downloadVersion('fr-LSG');

      var downloaded = await repo.getDownloadedVersionIds();
      expect(downloaded, hasLength(3));

      // When: User deletes French version
      await repo.deleteVersion('fr-LSG');

      // Then: Only 2 versions remain
      downloaded = await repo.getDownloadedVersionIds();
      expect(downloaded, hasLength(2));
      expect(downloaded, isNot(contains('fr-LSG')));
      await mockStorage.verifyDirectoryDeleted('fr-LSG');
    });

    test('Scenario 6: Corrupted download validation fails', () async {
      // Given: Download completes but file corrupted
      mockStorage.givenDownloadedVersions([]);
      mockHttp.givenMetadataResponse([
        createVersionMetadata(id: 'ja-COLLOQUIAL', name: 'Japanese Colloquial', language: 'ja', languageName: '日本語'),
      ]);
      mockHttp.givenDownloadProducesCorruptedFile('ja-COLLOQUIAL');

      await repo.initialize();

      // When: User downloads version
      expect(
        () => repo.downloadVersion('ja-COLLOQUIAL'),
        throwsA(isA<DatabaseCorruptedException>()),
      );

      // Then: Invalid file removed, not marked as downloaded
      expect(repo.isVersionDownloaded('ja-COLLOQUIAL'), false);
    });

    test('Scenario 7: Insufficient storage space', () async {
      // Given: Device has only 1MB free, version needs 2MB
      mockStorage.givenDownloadedVersions([]);
      mockStorage.givenAvailableSpace(1 * 1024 * 1024);
      mockHttp.givenMetadataResponse([
        createVersionMetadata(
          id: 'es-RVR1960',
          name: 'Reina Valera 1960',
          language: 'es',
          languageName: 'Español',
          uncompressedSizeBytes: 10 * 1024 * 1024,
        ),
      ]);

      await repo.initialize();

      // When: User attempts download
      expect(
        () => repo.downloadVersion('es-RVR1960'),
        throwsA(isA<InsufficientStorageException>()),
      );

      // Then: No download attempted
      await mockHttp.verifyNoDownloadStarted();
    });

    test('Scenario 9: App restart - downloaded versions persist', () async {
      // Given: User downloaded 2 versions
      final validDb = createValidSqliteDatabase();
      final compressedDb = gzip.encode(validDb);
      
      mockStorage.givenDownloadedVersions([]);
      mockHttp.givenMetadataResponse([
        createVersionMetadata(id: 'es-RVR1960', name: 'Reina Valera 1960', language: 'es', languageName: 'Español'),
        createVersionMetadata(id: 'pt-ARC', name: 'Almeida Revista e Corrigida', language: 'pt', languageName: 'Português'),
      ]);
      mockHttp.givenDownloadStream('es-RVR1960', compressedDb);
      mockHttp.givenDownloadStream('pt-ARC', compressedDb);

      await repo.initialize();
      await repo.downloadVersion('es-RVR1960');
      await repo.downloadVersion('pt-ARC');

      // When: App closes and reopens (simulate with new repository instance)
      final newRepo = BibleVersionRepository(
        httpClient: mockHttp,
        storage: mockStorage, // Same persisted storage
        metadataUrl: 'https://test.com/metadata.json',
      );
      await newRepo.initialize();

      // Then: Downloaded versions still listed
      final downloaded = await newRepo.getDownloadedVersionIds();
      expect(downloaded, containsAll(['es-RVR1960', 'pt-ARC']));
    });
  });

  group('Edge Case Tests', () {
    test('Malformed metadata JSON returns graceful error', () async {
      // Given: Malformed JSON
      mockHttp.givenGetResponse('metadata.json', statusCode: 200, body: 'not valid json');

      // When/Then: Graceful error
      expect(
        () => repo.fetchAvailableVersions(),
        throwsA(isA<MetadataParsingException>()),
      );
    });

    test('GitHub repo unavailable (404) throws NetworkException', () async {
      // Given: 404 response
      mockHttp.givenGetResponse('metadata.json', statusCode: 404, body: 'Not Found');

      // When/Then: Network exception
      expect(
        () => repo.fetchAvailableVersions(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('Version not found throws VersionNotFoundException', () async {
      // Given: No versions available
      mockStorage.givenDownloadedVersions([]);
      mockHttp.givenMetadataResponse([]);

      await repo.initialize();

      // When/Then: Version not found
      expect(
        () => repo.downloadVersion('nonexistent-version'),
        throwsA(isA<VersionNotFoundException>()),
      );
    });

    test('getVersionDatabasePath returns null for non-downloaded version', () async {
      mockStorage.givenDownloadedVersions([]);
      await repo.initialize();

      final path = await repo.getVersionDatabasePath('es-RVR1960');
      expect(path, isNull);
    });

    test('clearMetadataCache forces refresh', () async {
      mockStorage.givenDownloadedVersions([]);
      mockHttp.givenMetadataResponse([
        createVersionMetadata(id: 'es-RVR1960', name: 'Reina Valera 1960', language: 'es', languageName: 'Español'),
      ]);

      // First fetch
      var versions = await repo.fetchAvailableVersions();
      expect(versions, hasLength(1));

      // Update response
      mockHttp.givenMetadataResponse([
        createVersionMetadata(id: 'es-RVR1960', name: 'Reina Valera 1960', language: 'es', languageName: 'Español'),
        createVersionMetadata(id: 'en-KJV', name: 'King James Version', language: 'en', languageName: 'English'),
      ]);

      // Second fetch without clear - should use cache
      versions = await repo.fetchAvailableVersions();
      expect(versions, hasLength(1));

      // Clear cache and fetch again
      repo.clearMetadataCache();
      versions = await repo.fetchAvailableVersions();
      expect(versions, hasLength(2));
    });

    test('Download corrupted response is detected', () async {
      // Given: Download returns invalid data (not a SQLite database)
      mockStorage.givenDownloadedVersions([]);
      mockStorage.givenAvailableSpace(100 * 1024 * 1024); // 100MB
      mockHttp.givenMetadataResponse([
        createVersionMetadata(
          id: 'es-RVR1960',
          name: 'Reina Valera 1960',
          language: 'es',
          languageName: 'Español',
          sizeBytes: 1000,
          uncompressedSizeBytes: 1000,
        ),
      ]);
      // Valid gzip data that decompresses to invalid SQLite content
      mockHttp.givenDownloadProducesCorruptedFile('es-RVR1960');

      await repo.initialize();

      // When/Then: Throws DatabaseCorruptedException
      expect(
        () => repo.downloadVersion('es-RVR1960'),
        throwsA(isA<DatabaseCorruptedException>()),
      );
    });

    test('Metadata fetch timeout throws NetworkException', () async {
      // Given: Network timeout
      mockHttp.givenGetThrows('metadata.json', NetworkException('Connection timeout'));

      // When/Then: Network exception
      expect(
        () => repo.fetchAvailableVersions(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('Download fills disk space throws InsufficientStorageException', () async {
      // Given: Not enough space for download (need 2x buffer)
      mockStorage.givenDownloadedVersions([]);
      mockStorage.givenAvailableSpace(10 * 1024); // Only 10KB available
      mockHttp.givenMetadataResponse([
        createVersionMetadata(
          id: 'es-RVR1960',
          name: 'Reina Valera 1960',
          language: 'es',
          languageName: 'Español',
          sizeBytes: 100 * 1024, // 100KB compressed
          uncompressedSizeBytes: 200 * 1024, // 200KB uncompressed
        ),
      ]);

      await repo.initialize();

      // When/Then: Throws InsufficientStorageException
      expect(
        () => repo.downloadVersion('es-RVR1960'),
        throwsA(isA<InsufficientStorageException>()),
      );
    });

    test('Delete version while downloading cancels download', () async {
      // Given: Download in progress
      mockStorage.givenDownloadedVersions([]);
      mockStorage.givenAvailableSpace(100 * 1024 * 1024);
      mockHttp.givenMetadataResponse([
        createVersionMetadata(
          id: 'es-RVR1960',
          name: 'Reina Valera 1960',
          language: 'es',
          languageName: 'Español',
          sizeBytes: 1000,
          uncompressedSizeBytes: 2000,
        ),
      ]);
      mockHttp.givenDownloadResponseWithDelay('es-RVR1960', Duration(seconds: 5));

      await repo.initialize();

      // Start download (don't await)
      final downloadFuture = repo.downloadVersion('es-RVR1960');

      // Delete while downloading
      await Future.delayed(Duration(milliseconds: 100));
      await repo.deleteVersion('es-RVR1960');

      // Verify version is not downloaded
      expect(repo.isVersionDownloaded('es-RVR1960'), isFalse);

      // Clean up the future
      try {
        await downloadFuture;
      } catch (_) {
        // Expected to fail or complete without the version
      }
    });
  });

  group('Model Tests', () {
    test('BibleVersionMetadata equality works correctly', () {
      final v1 = BibleVersionMetadata.fromJson(
        createVersionMetadata(id: 'es-RVR1960', name: 'RVR1960', language: 'es', languageName: 'Español'),
      );
      final v2 = BibleVersionMetadata.fromJson(
        createVersionMetadata(id: 'es-RVR1960', name: 'RVR1960', language: 'es', languageName: 'Español'),
      );
      final v3 = BibleVersionMetadata.fromJson(
        createVersionMetadata(id: 'en-KJV', name: 'KJV', language: 'en', languageName: 'English'),
      );

      expect(v1, equals(v2));
      expect(v1, isNot(equals(v3)));
      expect(v1.hashCode, equals(v2.hashCode));
    });

    test('BibleVersionMetadata.copyWith works correctly', () {
      final original = BibleVersionMetadata.fromJson(
        createVersionMetadata(id: 'es-RVR1960', name: 'RVR1960', language: 'es', languageName: 'Español'),
      );

      final copy = original.copyWith(name: 'Updated Name');

      expect(copy.id, equals(original.id));
      expect(copy.name, equals('Updated Name'));
      expect(copy.language, equals(original.language));
    });

    test('BibleVersionWithState.copyWith works correctly', () {
      final metadata = BibleVersionMetadata.fromJson(
        createVersionMetadata(id: 'es-RVR1960', name: 'RVR1960', language: 'es', languageName: 'Español'),
      );

      final original = BibleVersionWithState(
        metadata: metadata,
        state: DownloadState.notDownloaded,
      );

      final copy = original.copyWith(state: DownloadState.downloading, progress: 0.5);

      expect(copy.metadata, equals(original.metadata));
      expect(copy.state, equals(DownloadState.downloading));
      expect(copy.progress, equals(0.5));
    });

    test('BibleVersionWithState.copyWith clearError works correctly', () {
      final metadata = BibleVersionMetadata.fromJson(
        createVersionMetadata(id: 'es-RVR1960', name: 'RVR1960', language: 'es', languageName: 'Español'),
      );

      final withError = BibleVersionWithState(
        metadata: metadata,
        state: DownloadState.failed,
        errorCode: BibleVersionErrorCode.network,
      );

      // Without clearError, error code is preserved
      final copy1 = withError.copyWith(state: DownloadState.downloading);
      expect(copy1.errorCode, equals(BibleVersionErrorCode.network));

      // With clearError, error code is cleared
      final copy2 = withError.copyWith(state: DownloadState.downloading, clearError: true);
      expect(copy2.errorCode, isNull);

      // With new error code, it's updated
      final copy3 = withError.copyWith(errorCode: BibleVersionErrorCode.storage);
      expect(copy3.errorCode, equals(BibleVersionErrorCode.storage));
    });
  });

  group('Exception Tests', () {
    test('NetworkException has correct properties', () {
      const e = NetworkException('Test error', statusCode: 404);
      expect(e.message, contains('Test error'));
      expect(e.statusCode, equals(404));
      expect(e.toString(), contains('404'));
    });

    test('InsufficientStorageException has correct properties', () {
      const e = InsufficientStorageException(
        availableBytes: 1000,
        requiredBytes: 2000,
      );
      expect(e.availableBytes, equals(1000));
      expect(e.requiredBytes, equals(2000));
      expect(e.message, contains('1000'));
      expect(e.message, contains('2000'));
    });

    test('DatabaseCorruptedException has correct properties', () {
      const e = DatabaseCorruptedException.forVersion('test-version');
      expect(e.versionId, equals('test-version'));
      expect(e.message, contains('test-version'));
    });

    test('DatabaseCorruptedException with message has correct properties', () {
      const e = DatabaseCorruptedException('Test corruption error');
      expect(e.versionId, isNull);
      expect(e.message, equals('Test corruption error'));
    });

    test('DatabaseSchemaException has correct properties', () {
      const e = DatabaseSchemaException(
        'Schema mismatch',
        expectedVersion: 2,
        actualVersion: 1,
      );
      expect(e.expectedVersion, equals(2));
      expect(e.actualVersion, equals(1));
      expect(e.message, equals('Schema mismatch'));
    });
  });
}
