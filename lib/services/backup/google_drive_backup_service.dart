// lib/services/google_drive_backup_service.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'i_backup_settings_service.dart';

import '../../blocs/prayer_bloc.dart';
import '../../blocs/prayer_event.dart';
import '../../models/backup_content_summary.dart';
import '../../models/spiritual_stats_model.dart';
import '../../providers/devocional_provider.dart';
import '../i_spiritual_stats_service.dart';
import 'compression_service.dart';
import '../i_connectivity_service.dart';
import 'i_google_drive_auth_service.dart';
import 'i_google_drive_backup_service.dart';
import '../discovery_progress_tracker.dart';
import '../i_localization_service.dart';
import 'package:devocional_nuevo/utils/constants/backup_keys_constants.dart';

/// Service for managing Google Drive backup functionality
/// Integrates with real Google Drive API for cloud storage
class GoogleDriveBackupService implements IGoogleDriveBackupService {
  static const String _backupOptionsKey = 'google_drive_backup_options';
  static const String _backupFolderIdKey = 'google_drive_backup_folder_id';

  // file name is derived from localization at runtime

  String get _backupFileName =>
      '${_localizationService.translate("backup.automatic_backups").toLowerCase().replaceAll(" ", "_")}.json';

  final IGoogleDriveAuthService _authService;
  final IConnectivityService _connectivityService;
  final ISpiritualStatsService _statsService;
  final ILocalizationService _localizationService;
  final IBackupSettingsService _settingsService;

  GoogleDriveBackupService({
    required IGoogleDriveAuthService authService,
    required IConnectivityService connectivityService,
    required ISpiritualStatsService statsService,
    required ILocalizationService localizationService,
    required IBackupSettingsService settingsService,
  })  : _authService = authService,
        _connectivityService = connectivityService,
        _statsService = statsService,
        _localizationService = localizationService,
        _settingsService = settingsService;

  /// Check if Google Drive backup is enabled
  @override
  Future<bool> isAutoBackupEnabled() => _settingsService.isAutoBackupEnabled();

  /// Enable/disable automatic Google Drive backup
  @override
  Future<void> setAutoBackupEnabled(bool enabled) =>
      _settingsService.setAutoBackupEnabled(enabled);

  /// Get backup frequency
  @override
  Future<String> getBackupFrequency() => _settingsService.getBackupFrequency();

  /// Set backup frequency
  @override
  Future<void> setBackupFrequency(String frequency) =>
      _settingsService.setBackupFrequency(frequency);

  /// Check if WiFi-only backup is enabled
  @override
  Future<bool> isWifiOnlyEnabled() => _settingsService.isWifiOnlyEnabled();

  /// Enable/disable WiFi-only backup
  @override
  Future<void> setWifiOnlyEnabled(bool enabled) =>
      _settingsService.setWifiOnlyEnabled(enabled);

  /// Check if data compression is enabled
  @override
  Future<bool> isCompressionEnabled() =>
      _settingsService.isCompressionEnabled();

  /// Enable/disable data compression
  @override
  Future<void> setCompressionEnabled(bool enabled) =>
      _settingsService.setCompressionEnabled(enabled);

  /// Get backup options (what to include in backup)
  @override
  Future<Map<String, bool>> getBackupOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final optionsJson = prefs.getString(_backupOptionsKey);

    if (optionsJson != null) {
      final Map<String, dynamic> decoded = json.decode(optionsJson);
      return decoded.map((key, value) => MapEntry(key, value as bool));
    }

    // Default options - all enabled
    return {
      BackupKeys.spiritualStats: true,
      BackupKeys.favoriteDevotionals: true,
      BackupKeys.savedPrayers: true,
      BackupKeys.savedThanksgivings: true,
      BackupKeys.completedEncounters: true,
      BackupKeys.discoveryProgress: true,
      BackupKeys.discoveryFavorites: true,
      BackupKeys.testimonies: true,
      BackupKeys.preferredBibleVersion: true,
      BackupKeys.markedBibleVerses: true,
    };
  }

  /// Set backup options
  @override
  Future<void> setBackupOptions(Map<String, bool> options) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupOptionsKey, json.encode(options));
    debugPrint('Google Drive backup options updated: $options');
  }

  /// Get last backup timestamp
  @override
  Future<DateTime?> getLastBackupTime() => _settingsService.getLastBackupTime();

  /// Calculate next backup time (delegated to settings service)
  @override
  Future<DateTime?> getNextBackupTime() => _settingsService.getNextBackupTime();

  /// Get estimated backup size in bytes
  @override
  Future<int> getEstimatedBackupSize(DevocionalProvider? provider) async {
    int totalSize = 0;
    final options = await getBackupOptions();

    // Spiritual stats (~5 KB)
    if (options[BackupKeys.spiritualStats] == true) {
      totalSize += 5 * 1024; // 5 KB
    }

    // Favorite devotionals
    if (options[BackupKeys.favoriteDevotionals] == true && provider != null) {
      final favoritesCount = provider.favoriteDevocionales.length;
      totalSize += favoritesCount * 2 * 1024; // ~2 KB per devotional
    }

    // Saved prayers (~15 KB default)
    if (options[BackupKeys.savedPrayers] == true) {
      totalSize += 15 * 1024; // 15 KB
    }

    // Saved thanksgivings (~15 KB default)
    if (options[BackupKeys.savedThanksgivings] == true) {
      totalSize += 15 * 1024; // 15 KB
    }

    // Testimonies (~10 KB default)
    if (options[BackupKeys.testimonies] == true) {
      totalSize += 10 * 1024; // 10 KB
    }

    return totalSize;
  }

  /// Returns a [BackupContentSummary] reflecting item counts in SharedPreferences.
  ///
  /// Reads the same keys used by [_prepareBackupData], so the counts match
  /// exactly what will be included in the next backup.
  @override
  Future<BackupContentSummary> getBackupContentSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Prayers
      int prayersCount = 0;
      final prayersJson = prefs.getString('prayers');
      if (prayersJson != null) {
        prayersCount = (json.decode(prayersJson) as List<dynamic>).length;
      }

      // Thanksgivings
      int thanksgivingsCount = 0;
      final thanksgivingsJson = prefs.getString('thanksgivings');
      if (thanksgivingsJson != null) {
        thanksgivingsCount =
            (json.decode(thanksgivingsJson) as List<dynamic>).length;
      }

      // Testimonies
      int testimoniesCount = 0;
      final testimoniesJson = prefs.getString('testimonies');
      if (testimoniesJson != null) {
        testimoniesCount =
            (json.decode(testimoniesJson) as List<dynamic>).length;
      }

      // Favourite devotionals (stored as JSON array under 'favorite_ids')
      int favoritesCount = 0;
      final favoritesJson = prefs.getString('favorite_ids');
      if (favoritesJson != null) {
        favoritesCount = (json.decode(favoritesJson) as List<dynamic>).length;
      }

      // Completed encounters
      final encountersCount =
          (prefs.getStringList('encounter_completed_ids') ?? []).length;

      // Discovery study progress entries
      final discoveryCount = prefs
          .getKeys()
          .where(
            (k) => k.startsWith(DiscoveryProgressTracker.progressKeyPrefix),
          )
          .length;

      // Marked Bible verses
      final versesCount =
          (prefs.getStringList('bible_marked_verses') ?? []).length;

      // Read devotionals (from spiritualStats blob)
      int readDevocionalesCount = 0;
      int answeredPrayersCount = 0;
      final statsJson = prefs.getString('spiritual_stats');
      if (statsJson != null) {
        final statsMap = json.decode(statsJson) as Map<String, dynamic>?;
        readDevocionalesCount =
            (statsMap?['readDevocionalIds'] as List<dynamic>?)?.length ?? 0;
        answeredPrayersCount = statsMap?['answeredPrayersCount'] ?? 0;
      }

      debugPrint(
        '[BACKUP] ContentSummary — prayers:$prayersCount '
        'thanks:$thanksgivingsCount testimonies:$testimoniesCount '
        'favorites:$favoritesCount encounters:$encountersCount '
        'discovery:$discoveryCount verses:$versesCount '
        'readDevocionales:$readDevocionalesCount '
        'answeredPrayers:$answeredPrayersCount',
      );

      return BackupContentSummary(
        prayersCount: prayersCount,
        thanksgivingsCount: thanksgivingsCount,
        testimoniesCount: testimoniesCount,
        favoritesCount: favoritesCount,
        encountersCount: encountersCount,
        discoveryCount: discoveryCount,
        versesCount: versesCount,
        readDevocionalesCount: readDevocionalesCount,
        answeredPrayersCount: answeredPrayersCount,
      );
    } catch (e) {
      debugPrint('[BACKUP] Error getting content summary: $e');
      return const BackupContentSummary(
        prayersCount: 0,
        thanksgivingsCount: 0,
        testimoniesCount: 0,
        favoritesCount: 0,
        encountersCount: 0,
        discoveryCount: 0,
        versesCount: 0,
        answeredPrayersCount: 0,
      );
    }
  }

  /// Download the current Drive backup file as a raw map.
  /// Returns null if no backup file exists yet.
  /// Returns null on all error paths — never throws.
  Future<Map<String, dynamic>?> _downloadCurrentDriveBackup() async {
    try {
      debugPrint('[BACKUP] Fetching existing Drive backup for merge...');

      final driveApi = await _authService.getDriveApi();
      if (driveApi == null) {
        debugPrint('[BACKUP] Could not get Drive API — no remote to fetch');
        return null;
      }

      // Get backup folder
      final folderId = await _getBackupFolderId();
      if (folderId == null) {
        debugPrint('[BACKUP] No backup folder found on Drive yet');
        return null;
      }

      // Find backup file
      final backupFile = await _findBackupFile(driveApi, folderId);
      if (backupFile == null) {
        debugPrint('[BACKUP] No backup file found on Drive yet');
        return null;
      }

      // Download backup file
      final media = await driveApi.files.get(
        backupFile.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      if (media is! drive.Media) {
        debugPrint('[BACKUP] Failed to download backup file: expected Media');
        return null;
      }

      // Read file content
      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      final fileBytes = Uint8List.fromList(bytes);
      debugPrint(
        '[BACKUP] Downloaded remote backup: ${fileBytes.length} bytes',
      );

      // Parse backup data
      Map<String, dynamic>? backupData;

      // Try to decompress first
      backupData = CompressionService.decompressJson(fileBytes);
      if (backupData == null) {
        // Try as uncompressed JSON
        try {
          final jsonString = utf8.decode(fileBytes);
          backupData = json.decode(jsonString) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('[BACKUP] Could not parse remote backup: $e');
          return null;
        }
      }

      return backupData;
    } catch (e) {
      debugPrint('[BACKUP] Error downloading current Drive backup: $e');
      return null; // Non-fatal — caller will use local-only
    }
  }

  /// Helper method to parse DateTime from JSON string
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        debugPrint('[BACKUP] Error parsing date: $value. Error: $e');
        return null;
      }
    }
    return null;
  }

  /// Merge local and remote backup payloads.
  /// Returns final merged payload ready for upload.
  Map<String, dynamic> _mergePayloads(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    debugPrint('[BACKUP] Merging local and remote backups...');

    // --- Stats merge ---
    final localStats = SpiritualStats.fromJson(
      local[BackupKeys.spiritualStats] as Map<String, dynamic>? ?? {},
    );
    final remoteStats = SpiritualStats.fromJson(
      remote[BackupKeys.spiritualStats] as Map<String, dynamic>? ?? {},
    );
    final mergedStats = SpiritualStats.merge(localStats, remoteStats);

    // Log merge details
    debugPrint(
      '[BACKUP] Stats merge: local=${localStats.readDevocionalIds.length} IDs, '
      'remote=${remoteStats.readDevocionalIds.length} IDs, '
      'merged=${mergedStats.readDevocionalIds.length} IDs',
    );

    // --- Read dates merge (union, sorted) ---
    final localDates = (local['read_dates'] as List<dynamic>?)
            ?.map((d) => d.toString())
            .toSet() ??
        {};
    final remoteDates = (remote['read_dates'] as List<dynamic>?)
            ?.map((d) => d.toString())
            .toSet() ??
        {};
    final mergedDates = {...localDates, ...remoteDates}.toList()..sort();

    // --- Favorites merge (union by ID string) ---
    final localFavs = (local[BackupKeys.favoriteDevotionals] as List<dynamic>?)
            ?.map((f) => f.toString())
            .toSet() ??
        {};
    final remoteFavs =
        (remote[BackupKeys.favoriteDevotionals] as List<dynamic>?)
                ?.map((f) => f.toString())
                .toSet() ??
            {};
    final mergedFavs = {...localFavs, ...remoteFavs}.toList();

    // Patch favoritesCount to reflect actual merged favorites length
    final patchedStats = mergedStats.copyWith(
      favoritesCount: mergedFavs.length,
    );

    // --- Prayers merge (union by id, keeping newer version based on lastModifiedDate) ---
    final prayersById = <String, Map<String, dynamic>>{};
    for (final p in [
      ...(remote[BackupKeys.savedPrayers] as List<dynamic>?) ?? [],
      ...(local[BackupKeys.savedPrayers] as List<dynamic>?) ?? [],
    ].whereType<Map<String, dynamic>>()) {
      if (p.containsKey('id')) {
        final id = p['id'].toString();
        final existing = prayersById[id];
        if (existing == null) {
          prayersById[id] = p;
        } else {
          // Compare lastModifiedDate and keep newer version
          final existingDate = _parseDateTime(existing['lastModifiedDate']);
          final currentDate = _parseDateTime(p['lastModifiedDate']);
          if (currentDate != null &&
              (existingDate == null || currentDate.isAfter(existingDate))) {
            prayersById[id] = p;
          }
        }
      }
    }
    final mergedPrayers = prayersById.values.toList();

    // --- Thanksgivings merge (union by id, keeping newer version based on lastModifiedDate) ---
    final thanksgivingsById = <String, Map<String, dynamic>>{};
    for (final p in [
      ...(remote[BackupKeys.savedThanksgivings] as List<dynamic>?) ?? [],
      ...(local[BackupKeys.savedThanksgivings] as List<dynamic>?) ?? [],
    ].whereType<Map<String, dynamic>>()) {
      if (p.containsKey('id')) {
        final id = p['id'].toString();
        final existing = thanksgivingsById[id];
        if (existing == null) {
          thanksgivingsById[id] = p;
        } else {
          // Compare lastModifiedDate and keep newer version
          final existingDate = _parseDateTime(existing['lastModifiedDate']);
          final currentDate = _parseDateTime(p['lastModifiedDate']);
          if (currentDate != null &&
              (existingDate == null || currentDate.isAfter(existingDate))) {
            thanksgivingsById[id] = p;
          }
        }
      }
    }
    final mergedThanksgivings = thanksgivingsById.values.toList();

    // --- Testimonies merge (union by id, keeping newer version based on lastModifiedDate) ---
    final testimoniesById = <String, Map<String, dynamic>>{};
    for (final p in [
      ...(remote[BackupKeys.testimonies] as List<dynamic>?) ?? [],
      ...(local[BackupKeys.testimonies] as List<dynamic>?) ?? [],
    ].whereType<Map<String, dynamic>>()) {
      if (p.containsKey('id')) {
        final id = p['id'].toString();
        final existing = testimoniesById[id];
        if (existing == null) {
          testimoniesById[id] = p;
        } else {
          // Compare lastModifiedDate and keep newer version
          final existingDate = _parseDateTime(existing['lastModifiedDate']);
          final currentDate = _parseDateTime(p['lastModifiedDate']);
          if (currentDate != null &&
              (existingDate == null || currentDate.isAfter(existingDate))) {
            testimoniesById[id] = p;
          }
        }
      }
    }
    final mergedTestimonies = testimoniesById.values.toList();

    // --- Completed encounters merge (union) ---
    final localEncounters =
        (local[BackupKeys.completedEncounters] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toSet() ??
            {};
    final remoteEncounters =
        (remote[BackupKeys.completedEncounters] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toSet() ??
            {};
    final mergedEncounters = {...localEncounters, ...remoteEncounters}.toList();

    // --- Discovery progress merge (newer values win by key) ---
    final mergedProgress = <String, dynamic>{
      ...?remote[BackupKeys.discoveryProgress] as Map<String, dynamic>?,
      ...?local[BackupKeys.discoveryProgress] as Map<String, dynamic>?,
    };

    // --- Discovery favorites merge (union) ---
    final mergedDiscoveryFavs = <String, dynamic>{
      ...?remote[BackupKeys.discoveryFavorites] as Map<String, dynamic>?,
      ...?local[BackupKeys.discoveryFavorites] as Map<String, dynamic>?,
    };

    // Build final merged payload
    return {
      ...local, // preserve all other keys (metadata, timestamps, etc.)
      BackupKeys.spiritualStats: patchedStats.toJson(),
      'read_dates': mergedDates,
      BackupKeys.favoriteDevotionals: mergedFavs,
      BackupKeys.savedPrayers: mergedPrayers,
      BackupKeys.savedThanksgivings: mergedThanksgivings,
      BackupKeys.completedEncounters: mergedEncounters,
      BackupKeys.discoveryProgress: mergedProgress,
      BackupKeys.discoveryFavorites: mergedDiscoveryFavs,
      BackupKeys.testimonies: mergedTestimonies,
      'backup_timestamp': DateTime.now().toIso8601String(),
      'merge_source': 'multi_device',
    };
  }

  /// Create backup to Google Drive
  @override
  Future<bool> createBackup(DevocionalProvider? provider) async {
    try {
      debugPrint('Creating Google Drive backup...');
      debugPrint('Google Drive backup file name: $_backupFileName');
      // Check authentication
      if (!await _authService.isSignedIn()) {
        final signedIn = await _authService.signIn();
        if (signedIn != true) {
          throw Exception('backup.error_auth_failed');
        }
      }

      // Check connectivity if WiFi-only is enabled
      final wifiOnlyEnabled = await isWifiOnlyEnabled();
      if (!await _connectivityService.shouldProceedWithBackup(
        wifiOnlyEnabled,
      )) {
        throw Exception('Network connectivity requirements not met');
      }

      final driveApi = await _authService.getDriveApi();
      if (driveApi == null) {
        throw Exception('Could not get Google Drive API client');
      }

      // Step 1: Build local backup payload
      final localPayload = await _prepareBackupData(provider);

      // Step 2: Attempt to download existing Drive backup for merge
      Map<String, dynamic>? remotePayload;
      try {
        remotePayload = await _downloadCurrentDriveBackup();
      } catch (e) {
        debugPrint(
          '[BACKUP] Could not fetch remote for merge, proceeding with local only: $e',
        );
      }

      // Step 3: Determine final payload (merged or local only)
      final Map<String, dynamic> finalPayload;
      if (remotePayload != null && _validateBackupData(remotePayload)) {
        finalPayload = _mergePayloads(localPayload, remotePayload);
        debugPrint('[BACKUP] Merged local + remote backup payloads');
      } else {
        finalPayload = localPayload;
        debugPrint(
          '[BACKUP] No valid remote backup found, uploading local only',
        );
      }

      // Convert to bytes
      Uint8List fileBytes;
      final compressionEnabled = await isCompressionEnabled();
      if (compressionEnabled) {
        fileBytes = CompressionService.compressJson(finalPayload);
        debugPrint(
          'Backup compressed: ${json.encode(finalPayload).length} -> ${fileBytes.length} bytes',
        );
      } else {
        fileBytes = Uint8List.fromList(utf8.encode(json.encode(finalPayload)));
        debugPrint('Backup uncompressed: ${fileBytes.length} bytes');
      }

      // Get or create backup folder
      final folderId = await _getOrCreateBackupFolder(driveApi);

      // Check if backup file already exists
      final existingFile = await _findBackupFile(driveApi, folderId);

      // Step 4: Upload merged result to Drive
      if (existingFile != null) {
        // Update existing file - NO parents field
        debugPrint('Updating existing backup file: ${existingFile.id}');
        final updateFile = drive.File()
          ..name = _backupFileName
          ..description =
              'Devocional backup updated on ${DateTime.now().toIso8601String()}'
          ..mimeType = 'application/json';

        final media = drive.Media(
          Stream.fromIterable([fileBytes]),
          fileBytes.length,
        );

        await driveApi.files.update(
          updateFile,
          existingFile.id!,
          uploadMedia: media,
        );
      } else {
        // Create new file - SÍ parents field
        debugPrint('Creating new backup file');
        final createFile = drive.File()
          ..name = _backupFileName
          ..parents = [folderId] // Solo en creación
          ..description =
              'Devocional backup created on ${DateTime.now().toIso8601String()}'
          ..mimeType = 'application/json';

        final media = drive.Media(
          Stream.fromIterable([fileBytes]),
          fileBytes.length,
        );

        await driveApi.files.create(createFile, uploadMedia: media);
      }

      await _settingsService.setLastBackupTime(DateTime.now());
      debugPrint(
        '✅ Merged backup uploaded — local IDs: '
        '${(localPayload[BackupKeys.spiritualStats] as Map<String, dynamic>?)?['readDevocionalIds']?.length ?? 0}, '
        'remote IDs: '
        '${(remotePayload?[BackupKeys.spiritualStats] as Map<String, dynamic>?)?['readDevocionalIds']?.length ?? 0}, '
        'merged IDs: '
        '${(finalPayload[BackupKeys.spiritualStats] as Map<String, dynamic>?)?['readDevocionalIds']?.length ?? 0}',
      );
      return true;
    } catch (e) {
      debugPrint('Error creating Google Drive backup: $e');
      return false;
    }
  }

  /// Prepare backup data
  Future<Map<String, dynamic>> _prepareBackupData(
    DevocionalProvider? provider,
  ) async {
    final options = await getBackupOptions();
    final packageInfo = await PackageInfo.fromPlatform();
    final backupData = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      'app_version': packageInfo.version, // Now gets real app version
      'compression_enabled': await isCompressionEnabled(),
      'language': _localizationService.currentLocale.languageCode,
    };

    // Add logs for each section included in the backup
    debugPrint('[BACKUP] Creating backupData...');
    debugPrint('[BACKUP] timestamp: ${backupData['timestamp']}');
    debugPrint('[BACKUP] version: ${backupData['version']}');
    debugPrint('[BACKUP] app_version: ${backupData['app_version']}');
    debugPrint(
      '[BACKUP] compression_enabled: ${backupData['compression_enabled']}',
    );

    // Include spiritual stats if enabled
    if (options[BackupKeys.spiritualStats] == true) {
      try {
        final stats = await _statsService.getAllStats();
        debugPrint('[BACKUP] 🔍 SPIRITUAL STATS: ${json.encode(stats)}');
        final innerStats =
            (stats['stats'] as Map<String, dynamic>?) ?? <String, dynamic>{};

        backupData[BackupKeys.spiritualStats] = innerStats;
        final readDevocionalIds =
            (innerStats['readDevocionalIds'] as List<dynamic>?)?.length ?? 0;
        debugPrint('[BACKUP] Included spiritual stats:');
        debugPrint(
          '[BACKUP]   - Total devotionals read: ${innerStats['totalDevocionalesRead'] ?? 0}',
        );
        debugPrint('[BACKUP]   - Completed devotional IDs: $readDevocionalIds');
        debugPrint(
          '[BACKUP]   - Current streak: ${innerStats['currentStreak'] ?? 0}',
        );
        debugPrint(
          '[BACKUP]   - Longest streak: ${innerStats['longestStreak'] ?? 0}',
        );
        debugPrint(
          '[BACKUP]   - Favorites count: ${innerStats['favoritesCount'] ?? 0}',
        );
        debugPrint(
          '[BACKUP]   - Answered prayers count: ${innerStats['answeredPrayersCount'] ?? 0}',
        );
      } catch (e) {
        debugPrint('[BACKUP] ❌ Error getting spiritual stats: $e');
        backupData[BackupKeys.spiritualStats] = {};
      }
    }

    // Include favorite devotionals if enabled
    if (options[BackupKeys.favoriteDevotionals] == true && provider != null) {
      try {
        var ids = provider.favoriteIds.toList();
        if (ids.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final raw = prefs.getString('favorite_ids');
          if (raw != null) {
            ids = (json.decode(raw) as List<dynamic>).cast<String>();
            debugPrint(
              '[BACKUP] ⚠️ Provider empty — fallback to prefs: ${ids.length} favorites',
            );
          }
        }
        backupData[BackupKeys.favoriteDevotionals] = ids;
        debugPrint('[BACKUP] Included ${ids.length} favorite devotionals');
      } catch (e) {
        debugPrint('[BACKUP] ❌ Error getting favorite devotionals: $e');
        backupData[BackupKeys.favoriteDevotionals] = [];
      }
    }

    // Include saved prayers if enabled
    if (options[BackupKeys.savedPrayers] == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final prayersJson = prefs.getString('prayers') ?? '[]';
        final prayersList = json.decode(prayersJson) as List<dynamic>;
        backupData[BackupKeys.savedPrayers] = prayersList;
        debugPrint('[BACKUP] Included ${prayersList.length} saved prayers');
      } catch (e) {
        debugPrint('[BACKUP] ❌ Error getting saved prayers: $e');
        backupData[BackupKeys.savedPrayers] = [];
      }
    }

    // Include saved thanksgivings if enabled
    if (options[BackupKeys.savedThanksgivings] == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final thanksgivingsJson = prefs.getString('thanksgivings') ?? '[]';
        final thanksgivingsList =
            json.decode(thanksgivingsJson) as List<dynamic>;
        backupData[BackupKeys.savedThanksgivings] = thanksgivingsList;
        debugPrint(
          '[BACKUP] Included ${thanksgivingsList.length} saved thanksgivings',
        );
      } catch (e) {
        debugPrint('[BACKUP] ❌ Error getting saved thanksgivings: $e');
        backupData[BackupKeys.savedThanksgivings] = [];
      }
    }

    // Include testimonies if enabled
    if (options[BackupKeys.testimonies] == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final testimoniesJson = prefs.getString('testimonies') ?? '[]';
        final testimoniesList = json.decode(testimoniesJson) as List<dynamic>;
        backupData[BackupKeys.testimonies] = testimoniesList;
        debugPrint('[BACKUP] Included ${testimoniesList.length} testimonies');
      } catch (e) {
        debugPrint('[BACKUP] ❌ Error getting testimonies: $e');
        backupData[BackupKeys.testimonies] = [];
      }
    }

    // Include completed encounters if enabled
    if (options[BackupKeys.completedEncounters] == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final completedIds =
            prefs.getStringList('encounter_completed_ids') ?? [];
        backupData[BackupKeys.completedEncounters] = completedIds;
        debugPrint(
          '[BACKUP] Included ${completedIds.length} completed encounters: $completedIds',
        );
      } catch (e) {
        debugPrint('[BACKUP] Error getting completed encounters: $e');
        backupData[BackupKeys.completedEncounters] = [];
      }
    }

    // Include discovery progress if enabled (all keys with prefix)
    if (options[BackupKeys.discoveryProgress] == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final allKeys = prefs.getKeys();
        final discoveryProgressData = <String, dynamic>{};
        for (final key in allKeys) {
          if (key.startsWith(DiscoveryProgressTracker.progressKeyPrefix)) {
            final value = prefs.getString(key);
            if (value != null) {
              discoveryProgressData[key] = value;
            }
          }
        }
        backupData[BackupKeys.discoveryProgress] = discoveryProgressData;
        debugPrint(
          '[BACKUP] Included ${discoveryProgressData.length} discovery progress entries: ${discoveryProgressData.keys.toList()}',
        );
      } catch (e) {
        debugPrint('[BACKUP] Error getting discovery progress: $e');
        backupData[BackupKeys.discoveryProgress] = <String, dynamic>{};
      }
    }

    // Include discovery favorites if enabled (all keys with prefix)
    if (options[BackupKeys.discoveryFavorites] == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final allKeys = prefs.getKeys();
        final discoveryFavoritesData = <String, dynamic>{};
        for (final key in allKeys) {
          if (key.startsWith('discovery_favorite_ids_')) {
            final value = prefs.getString(key);
            if (value != null) {
              discoveryFavoritesData[key] = value;
            }
          }
        }
        backupData[BackupKeys.discoveryFavorites] = discoveryFavoritesData;
        debugPrint(
          '[BACKUP] Included ${discoveryFavoritesData.length} discovery favorites entries: ${discoveryFavoritesData.keys.toList()}',
        );
      } catch (e) {
        debugPrint('[BACKUP] Error getting discovery favorites: $e');
        backupData[BackupKeys.discoveryFavorites] = <String, dynamic>{};
      }
    }

    // Include preferred bible version
    try {
      final prefs = await SharedPreferences.getInstance();
      final version = prefs.getString('selectedVersion') ?? '';
      backupData[BackupKeys.preferredBibleVersion] = version;
      debugPrint('[BACKUP] Included preferred bible version: $version');
    } catch (e) {
      debugPrint('[BACKUP] ❌ Error getting preferred bible version: $e');
      backupData[BackupKeys.preferredBibleVersion] = '';
    }

    // Include marked bible verses
    try {
      final prefs = await SharedPreferences.getInstance();
      final markedVerses = prefs.getStringList('bible_marked_verses') ?? [];
      backupData[BackupKeys.markedBibleVerses] = markedVerses;
      debugPrint(
        '[BACKUP] Included ${markedVerses.length} marked bible verses',
      );
    } catch (e) {
      debugPrint('[BACKUP] ❌ Error getting marked bible verses: $e');
      backupData[BackupKeys.markedBibleVerses] = [];
    }

    // Full backup summary log
    debugPrint('[BACKUP] ══════════════════════════════════');
    debugPrint('[BACKUP] FULL BACKUP PAYLOAD SUMMARY:');
    debugPrint('[BACKUP]   timestamp: ${backupData['timestamp']}');
    debugPrint('[BACKUP]   version: ${backupData['version']}');
    debugPrint('[BACKUP]   app_version: ${backupData['app_version']}');
    debugPrint('[BACKUP]   keys included: ${backupData.keys.toList()}');
    for (final key in [
      BackupKeys.spiritualStats,
      BackupKeys.favoriteDevotionals,
      BackupKeys.savedPrayers,
      BackupKeys.savedThanksgivings,
      BackupKeys.completedEncounters,
      BackupKeys.discoveryProgress,
      BackupKeys.discoveryFavorites,
      BackupKeys.testimonies,
    ]) {
      final value = backupData[key];
      if (value is List) {
        debugPrint('[BACKUP]   $key: ${value.length} items');
      } else if (value is Map) {
        debugPrint('[BACKUP]   $key: ${value.length} entries');
      } else {
        debugPrint('[BACKUP]   $key: $value');
      }
    }
    debugPrint('[BACKUP] ══════════════════════════════════');

    return backupData;
  }

  /// Check if backup should be created automatically
  @override
  Future<bool> shouldCreateAutoBackup() async {
    if (!await isAutoBackupEnabled()) {
      return false;
    }

    final lastBackup = await getLastBackupTime();
    if (lastBackup == null) {
      return true; // No backup exists yet
    }

    final nextBackup = await getNextBackupTime();
    if (nextBackup == null) {
      return false;
    }

    final remaining = nextBackup.difference(DateTime.now());
    debugPrint('[BACKUP] ⏱ Next backup in: ${remaining.inMinutes} minutes');
    return DateTime.now().isAfter(nextBackup);
  }

  /// Validate favorites data integrity
  Future<bool> validateFavoritesData(List<dynamic> favoritesData) async {
    try {
      for (final item in favoritesData) {
        if (item is! Map<String, dynamic>) {
          debugPrint('Invalid favorite item format: not a map');
          return false;
        }

        final favoriteMap = item;
        if (!favoriteMap.containsKey('id') ||
            !favoriteMap.containsKey('title')) {
          debugPrint('Invalid favorite item: missing required fields');
          return false;
        }

        if (favoriteMap['id'] is! String || favoriteMap['title'] is! String) {
          debugPrint('Invalid favorite item: invalid field types');
          return false;
        }
      }

      debugPrint('Favorites data validation passed');
      return true;
    } catch (e) {
      debugPrint('Error validating favorites data: $e');
      return false;
    }
  }

  /// Get or create backup folder in Google Drive
  Future<String> _getOrCreateBackupFolder(drive.DriveApi driveApi) async {
    try {
      final folderName = _localizationService.translate('app.title');
      // Check if we have cached folder ID
      final cachedFolderId = await _getBackupFolderId();
      if (cachedFolderId != null) {
        // Verify folder still exists
        try {
          await driveApi.files.get(cachedFolderId);
          return cachedFolderId;
        } catch (e) {
          debugPrint('Cached folder not found, creating new one');
        }
      }

      // Search for existing backup folder
      final query =
          "name='$folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final fileList = await driveApi.files.list(q: query);

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final folderId = fileList.files!.first.id!;
        await _setBackupFolderId(folderId);
        debugPrint('Found existing backup folder: $folderId');
        return folderId;
      }

      // Create new backup folder
      final folder = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..description = 'Devocional app backup folder';

      final createdFolder = await driveApi.files.create(folder);
      final folderId = createdFolder.id!;
      await _setBackupFolderId(folderId);
      debugPrint('Created new backup folder: $folderId');
      return folderId;
    } catch (e) {
      debugPrint('Error creating backup folder: $e');
      rethrow;
    }
  }

  /// Find backup file in the specified folder
  Future<drive.File?> _findBackupFile(
    drive.DriveApi driveApi,
    String folderId,
  ) async {
    try {
      final query =
          "name='$_backupFileName' and '$folderId' in parents and trashed=false";
      final fileList = await driveApi.files.list(q: query);

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error finding backup file: $e');
      return null;
    }
  }

  /// Get backup folder ID from preferences
  Future<String?> _getBackupFolderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backupFolderIdKey);
  }

  /// Set backup folder ID in preferences
  Future<void> _setBackupFolderId(String folderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupFolderIdKey, folderId);
  }

  /// Validate backup data structure
  bool _validateBackupData(Map<String, dynamic> data) {
    try {
      // Check required fields
      if (!data.containsKey('timestamp') || !data.containsKey('version')) {
        debugPrint('Backup data missing required fields');
        return false;
      }

      // Validate timestamp
      try {
        DateTime.parse(data['timestamp'] as String);
      } catch (e) {
        debugPrint('Invalid timestamp in backup data');
        return false;
      }

      // Check version compatibility
      final version = data['version'] as String;
      if (version != '1.0') {
        debugPrint('Incompatible backup version: $version');
        // For now, only support version 1.0
        // In the future, add migration logic here
        return false;
      }

      debugPrint('Backup data validation passed');
      return true;
    } catch (e) {
      debugPrint('Error validating backup data: $e');
      return false;
    }
  }

  /// Restore backup data to local storage
  Future<void> _restoreBackupData(Map<String, dynamic> data) async {
    try {
      debugPrint('[RESTORE] ══════════════════════════════════');
      debugPrint('[RESTORE] Starting backup data restoration...');
      debugPrint('[RESTORE] Keys in backup: ${data.keys.toList()}');

      // Restore spiritual stats
      if (data.containsKey(BackupKeys.spiritualStats)) {
        try {
          final stats = data[BackupKeys.spiritualStats] as Map<String, dynamic>;
          await _statsService.restoreStats(stats);
          debugPrint('[RESTORE] ✅ Restored spiritual stats');
        } catch (e) {
          debugPrint('[RESTORE] ❌ Error restoring spiritual stats: $e');
        }
      }

      // Restore favorite devotionals
      if (data.containsKey(BackupKeys.favoriteDevotionals)) {
        try {
          final favorites =
              data[BackupKeys.favoriteDevotionals] as List<dynamic>;
          final prefs = await SharedPreferences.getInstance();
          final isNewFormat = favorites.isEmpty || favorites.first is String;
          if (isNewFormat) {
            final ids = favorites.cast<String>().toList();
            debugPrint('[RESTORE] 🔍 Writing favorite IDs to prefs: $ids');
            await prefs.setString('favorite_ids', json.encode(ids));
            debugPrint(
              '[RESTORE] ✅ Restored ${ids.length} favorite devotionals',
            );
          } else {
            // Legacy: full JSON objects — existing migration path handles it
            await prefs.setString('favorites', json.encode(favorites));
            debugPrint(
              '[RESTORE] ✅ Restored ${favorites.length} favorite devotionals (legacy format)',
            );
          }
        } catch (e) {
          debugPrint('[RESTORE] ❌ Error restoring favorite devotionals: $e');
        }
      }

      // Restore saved prayers
      if (data.containsKey(BackupKeys.savedPrayers)) {
        try {
          final prayers = data[BackupKeys.savedPrayers] as List<dynamic>;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('prayers', json.encode(prayers));
          debugPrint('[RESTORE] ✅ Restored ${prayers.length} saved prayers');
        } catch (e) {
          debugPrint('[RESTORE] ❌ Error restoring saved prayers: $e');
        }
      }

      // Restore saved thanksgivings
      if (data.containsKey(BackupKeys.savedThanksgivings)) {
        try {
          final thanksgivings =
              data[BackupKeys.savedThanksgivings] as List<dynamic>;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('thanksgivings', json.encode(thanksgivings));
          debugPrint(
            '[RESTORE] ✅ Restored ${thanksgivings.length} saved thanksgivings',
          );
        } catch (e) {
          debugPrint('[RESTORE] ❌ Error restoring saved thanksgivings: $e');
        }
      }

      // Restore testimonies
      if (data.containsKey(BackupKeys.testimonies)) {
        try {
          final testimonies = data[BackupKeys.testimonies] as List<dynamic>;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('testimonies', json.encode(testimonies));
          debugPrint('[RESTORE] ✅ Restored ${testimonies.length} testimonies');
        } catch (e) {
          debugPrint('[RESTORE] ❌ Error restoring testimonies: $e');
        }
      }

      // Restore completed encounter IDs
      if (data.containsKey(BackupKeys.completedEncounters)) {
        try {
          final completedIds =
              (data[BackupKeys.completedEncounters] as List<dynamic>)
                  .map((e) => e as String)
                  .toList();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('encounter_completed_ids', completedIds);
          debugPrint(
            '[RESTORE] ✅ Restored ${completedIds.length} completed encounters: $completedIds',
          );
        } catch (e) {
          debugPrint('[RESTORE] ❌ Error restoring completed encounters: $e');
        }
      }

      // Restore discovery progress (all study progress entries)
      if (data.containsKey(BackupKeys.discoveryProgress)) {
        try {
          final progressData =
              data[BackupKeys.discoveryProgress] as Map<String, dynamic>;
          final prefs = await SharedPreferences.getInstance();
          for (final entry in progressData.entries) {
            if (entry.value is String &&
                entry.key.startsWith(
                  DiscoveryProgressTracker.progressKeyPrefix,
                )) {
              await prefs.setString(entry.key, entry.value as String);
            }
          }
          debugPrint(
            '[RESTORE] ✅ Restored ${progressData.length} discovery progress entries: ${progressData.keys.toList()}',
          );
        } catch (e) {
          debugPrint('[RESTORE] ❌ Error restoring discovery progress: $e');
        }
      }

      // Restore discovery favorites (per-language favorite study IDs)
      if (data.containsKey(BackupKeys.discoveryFavorites)) {
        try {
          final favoritesData =
              data[BackupKeys.discoveryFavorites] as Map<String, dynamic>;
          final prefs = await SharedPreferences.getInstance();
          for (final entry in favoritesData.entries) {
            if (entry.value is String &&
                entry.key.startsWith('discovery_favorite_ids_')) {
              await prefs.setString(entry.key, entry.value as String);
            }
          }
          debugPrint(
            '[RESTORE] ✅ Restored ${favoritesData.length} discovery favorites entries: ${favoritesData.keys.toList()}',
          );
        } catch (e) {
          debugPrint('[RESTORE] ❌ Error restoring discovery favorites: $e');
        }
      }

      // Restore preferred bible version
      if (data.containsKey(BackupKeys.preferredBibleVersion)) {
        try {
          final version = data[BackupKeys.preferredBibleVersion] as String;
          if (version.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('selectedVersion', version);
            debugPrint(
              '[RESTORE] ✅ Restored preferred bible version: $version',
            );
          }
        } catch (e) {
          debugPrint('[RESTORE] ❌ Error restoring preferred bible version: $e');
        }
      }

      // Restore marked bible verses (union merge — preserve local marks)
      if (data.containsKey(BackupKeys.markedBibleVerses)) {
        try {
          final backupVerses =
              (data[BackupKeys.markedBibleVerses] as List<dynamic>)
                  .map((e) => e as String)
                  .toSet();
          final prefs = await SharedPreferences.getInstance();
          final localVerses = Set<String>.from(
            prefs.getStringList('bible_marked_verses') ?? [],
          );
          final mergedVerses = {...localVerses, ...backupVerses};
          await prefs.setStringList(
            'bible_marked_verses',
            mergedVerses.toList(),
          );
          debugPrint(
            '[RESTORE] ✅ Restored ${mergedVerses.length} marked bible verses '
            '(local: ${localVerses.length}, backup: ${backupVerses.length})',
          );
        } catch (e) {
          debugPrint('[RESTORE] ❌ Error restoring marked bible verses: $e');
        }
      }

      debugPrint('[RESTORE] ══════════════════════════════════');
      debugPrint('[RESTORE] Backup data restoration completed successfully');
    } catch (e) {
      debugPrint('[RESTORE] ❌ Fatal error restoring backup data: $e');
      rethrow;
    }
  }

  /// Check if user is authenticated with Google Drive
  @override
  Future<bool> isAuthenticated() async {
    return await _authService.isSignedIn();
  }

  /// Sign in to Google Drive
  @override
  Future<bool?> signIn() async {
    // Era: Future<bool> signIn() async {
    return await _authService.signIn(); // El metodo ya queda simple
  }

  /// Sign out from Google Drive
  @override
  Future<void> signOut() async {
    await _authService.signOut();
    // Clear backup folder cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backupFolderIdKey);
  }

  /// Get current user email
  @override
  Future<String?> getUserEmail() async {
    return await _authService.getUserEmail();
  }

  /// Check for existing backups on Google Drive when user signs in
  @override
  Future<Map<String, dynamic>?> checkForExistingBackup() async {
    try {
      final driveApi = await _authService.getDriveApi();
      if (driveApi == null) {
        return null;
      }

      final folderName = _localizationService.translate('app.title');

      // Search for existing backup folder
      final folderQuery =
          "name='$folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final folderResults = await driveApi.files.list(q: folderQuery);

      if (folderResults.files == null || folderResults.files!.isEmpty) {
        return null; // No backup folder found
      }

      final folderId = folderResults.files!.first.id!;

      // Search for backup file in the folder
      final fileQuery =
          "name='$_backupFileName' and parents in '$folderId' and trashed=false";
      final fileResults = await driveApi.files.list(q: fileQuery);

      if (fileResults.files == null || fileResults.files!.isEmpty) {
        return null; // No backup file found
      }

      final backupFile = fileResults.files!.first;

      // Get backup file metadata
      return {
        'found': true,
        'fileName': backupFile.name,
        'modifiedTime': backupFile.modifiedTime?.toIso8601String(),
        'size': backupFile.size,
        'fileId': backupFile.id,
        'folderId': folderId,
      };
    } catch (e) {
      debugPrint('Error checking for existing backup: $e');
      return null;
    }
  }

  /// Restore backup from existing file on Google Drive
  @override
  Future<bool> restoreExistingBackup(
    String fileId, {
    PrayerBloc? prayerBloc,
  }) async {
    try {
      final driveApi = await _authService.getDriveApi();
      if (driveApi == null) {
        return false;
      }

      // Download the backup file
      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final backupData = <int>[];
      await for (final chunk in media.stream) {
        backupData.addAll(chunk);
      }

      final fileBytes = Uint8List.fromList(backupData);
      debugPrint('Downloaded existing backup file: ${fileBytes.length} bytes');

      // Parse backup data (same logic as restoreBackup)
      Map<String, dynamic>? backupJson;

      // Try to decompress first
      backupJson = CompressionService.decompressJson(fileBytes);
      if (backupJson == null) {
        // Try as uncompressed JSON
        try {
          final jsonString = utf8.decode(fileBytes);
          backupJson = json.decode(jsonString) as Map<String, dynamic>;
          debugPrint('Backup file is uncompressed JSON');
        } catch (e) {
          throw Exception('Could not parse backup file: $e');
        }
      } else {
        debugPrint('Backup file was compressed, decompressed successfully');
      }

      // Validate backup data
      if (!_validateBackupData(backupJson)) {
        throw Exception('Invalid backup data format');
      }

      // Restore the backup data using existing restore method
      await _restoreBackupData(backupJson);
      // Provider reload is the caller's responsibility — BackupBloc handles it
      // via the onRestored callback pattern. Do NOT call provider methods here.

      if (prayerBloc != null) {
        prayerBloc.add(RefreshPrayers());
        debugPrint('✅ PrayerBloc notified to refresh');
      }

      // Update last backup time
      await _settingsService.setLastBackupTime(DateTime.now());

      debugPrint('Existing backup restored successfully');
      return true;
    } catch (e) {
      debugPrint('Error restoring existing backup: $e');
      return false;
    }
  }
}
