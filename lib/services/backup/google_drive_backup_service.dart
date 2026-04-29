// lib/services/google_drive_backup_service.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../blocs/prayer_bloc.dart';
import '../../blocs/prayer_event.dart';
import '../../models/spiritual_stats_model.dart';
import '../../providers/devocional_provider.dart';
import '../i_spiritual_stats_service.dart';
import 'compression_service.dart';
import '../i_connectivity_service.dart';
import 'i_google_drive_auth_service.dart';
import 'i_google_drive_backup_service.dart';
import '../i_localization_service.dart';
import 'package:devocional_nuevo/utils/constants/backup_keys_constants.dart';


/// Service for managing Google Drive backup functionality
/// Integrates with real Google Drive API for cloud storage
class GoogleDriveBackupService implements IGoogleDriveBackupService {
  static const String _lastBackupTimeKey = 'last_google_drive_backup_time';
  static const String _autoBackupEnabledKey =
      'google_drive_auto_backup_enabled';
  static const String _backupFrequencyKey = 'google_drive_backup_frequency';
  static const String _wifiOnlyKey = 'google_drive_wifi_only';
  static const String _compressDataKey = 'google_drive_compress_data';
  static const String _backupOptionsKey = 'google_drive_backup_options';
  static const String _backupFolderIdKey = 'google_drive_backup_folder_id';

  // Backup frequency options
  static const String frequencyDaily = 'daily';
  static const String frequencyManual = 'manual';
  static const String frequencyDeactivated = 'deactivated';

  // file name is derived from localization at runtime

  String get _backupFileName =>
      '${_localizationService.translate("backup.automatic_backups").toLowerCase().replaceAll(" ", "_")}.json';

  final IGoogleDriveAuthService _authService;
  final IConnectivityService _connectivityService;
  final ISpiritualStatsService _statsService;
  final ILocalizationService _localizationService;

  GoogleDriveBackupService({
    required IGoogleDriveAuthService authService,
    required IConnectivityService connectivityService,
    required ISpiritualStatsService statsService,
    required ILocalizationService localizationService,
  })  : _authService = authService,
        _connectivityService = connectivityService,
        _statsService = statsService,
        _localizationService = localizationService;

  /// Check if Google Drive backup is enabled
  @override
  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupEnabledKey) ?? false;
  }

  /// Enable/disable automatic Google Drive backup
  @override
  Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupEnabledKey, enabled);
    debugPrint('Google Drive auto-backup ${enabled ? "enabled" : "disabled"}');
  }

  /// Get backup frequency
  @override
  Future<String> getBackupFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backupFrequencyKey) ??
        frequencyDaily; // Default to Daily (2:00 AM) as requested
  }

  /// Set backup frequency
  @override
  Future<void> setBackupFrequency(String frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupFrequencyKey, frequency);
    debugPrint('Google Drive backup frequency set to: $frequency');
  }

  /// Check if WiFi-only backup is enabled
  @override
  Future<bool> isWifiOnlyEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wifiOnlyKey) ??
        true; // Default to WiFi-only for data saving
  }

  /// Enable/disable WiFi-only backup
  @override
  Future<void> setWifiOnlyEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wifiOnlyKey, enabled);
    debugPrint(
      'Google Drive WiFi-only backup ${enabled ? "enabled" : "disabled"}',
    );
  }

  /// Check if data compression is enabled
  @override
  Future<bool> isCompressionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_compressDataKey) ??
        true; // Default to enabled for smaller backups
  }

  /// Enable/disable data compression
  @override
  Future<void> setCompressionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compressDataKey, enabled);
    debugPrint('Google Drive compression ${enabled ? "enabled" : "disabled"}');
  }

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
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastBackupTimeKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Set last backup timestamp
  Future<void> _setLastBackupTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBackupTimeKey, time.millisecondsSinceEpoch);
  }

  /// Calculate next backup time - Always today for startup approach
  @override
  Future<DateTime?> getNextBackupTime() async {
    final frequency = await getBackupFrequency();

    if (frequency == frequencyDeactivated || frequency == frequencyManual) {
      return null;
    }

    if (!await isAutoBackupEnabled()) {
      return null;
    }

    // Always return today since backup is checked at app startup
    return DateTime.now();
  }

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
          '[BACKUP] Downloaded remote backup: ${fileBytes.length} bytes');

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
    final patchedStats =
        mergedStats.copyWith(favoritesCount: mergedFavs.length);

    // --- Prayers merge (union by id) ---
    final mergedPrayers = {
      for (final p in [
        ...(local[BackupKeys.savedPrayers] as List<dynamic>?) ?? [],
        ...(remote[BackupKeys.savedPrayers] as List<dynamic>?) ?? [],
      ].whereType<Map<String, dynamic>>())
        if (p.containsKey('id')) p['id'].toString(): p,
    }.values.toList();

    // --- Thanksgivings merge (union by id) ---
    final mergedThanksgivings = {
      for (final p in [
        ...(local[BackupKeys.savedThanksgivings] as List<dynamic>?) ?? [],
        ...(remote[BackupKeys.savedThanksgivings] as List<dynamic>?) ?? [],
      ].whereType<Map<String, dynamic>>())
        if (p.containsKey('id')) p['id'].toString(): p,
    }.values.toList();

    // --- Testimonies merge (union by id) ---
    final mergedTestimonies = {
      for (final p in [
        ...(local[BackupKeys.testimonies] as List<dynamic>?) ?? [],
        ...(remote[BackupKeys.testimonies] as List<dynamic>?) ?? [],
      ].whereType<Map<String, dynamic>>())
        if (p.containsKey('id')) p['id'].toString(): p,
    }.values.toList();

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
            '[BACKUP] No valid remote backup found, uploading local only');
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

      // Step 5: Sync merged result back to local so UI reflects true merged state
      if (remotePayload != null && _validateBackupData(remotePayload)) {
        try {
          await _statsService.restoreStats(finalPayload);
          debugPrint('[BACKUP] Local state synced to merged result');
        } catch (e) {
          debugPrint(
            '[BACKUP] Warning: could not sync merged state locally: $e',
          );
          // non-fatal — Drive is correct, local will catch up on next restore
        }
      }

      await _setLastBackupTime(DateTime.now());
      debugPrint('✅ Merged backup uploaded — local IDs: '
          '${(localPayload[BackupKeys.spiritualStats] as Map<String, dynamic>?)?['readDevocionalIds']?.length ?? 0}, '
          'remote IDs: '
          '${(remotePayload?[BackupKeys.spiritualStats] as Map<String, dynamic>?)?['readDevocionalIds']?.length ?? 0}, '
          'merged IDs: '
          '${(finalPayload[BackupKeys.spiritualStats] as Map<String, dynamic>?)?['readDevocionalIds']?.length ?? 0}');
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
        backupData[BackupKeys.spiritualStats] = stats;

        // Extract nested stats map for clear logging
        final innerStats =
            (stats['stats'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final readDevocionalIds =
            (innerStats['readDevocionalIds'] as List<dynamic>?)?.length ?? 0;
        debugPrint('[BACKUP] Included spiritual stats:');
        debugPrint(
            '[BACKUP]   - Total devotionals read: ${innerStats['totalDevocionalesRead'] ?? 0}');
        debugPrint('[BACKUP]   - Completed devotional IDs: $readDevocionalIds');
        debugPrint(
            '[BACKUP]   - Current streak: ${innerStats['currentStreak'] ?? 0}');
        debugPrint(
            '[BACKUP]   - Longest streak: ${innerStats['longestStreak'] ?? 0}');
        debugPrint(
            '[BACKUP]   - Favorites count: ${innerStats['favoritesCount'] ?? 0}');
      } catch (e) {
        debugPrint('[BACKUP] ❌ Error getting spiritual stats: $e');
        backupData[BackupKeys.spiritualStats] = {};
      }
    }

    // Include favorite devotionals if enabled
    if (options[BackupKeys.favoriteDevotionals] == true && provider != null) {
      try {
        backupData[BackupKeys.favoriteDevotionals] =
            provider.favoriteIds.toList();
        debugPrint(
          '[BACKUP] Included ${provider.favoriteIds.length} favorite devotionals',
        );
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
          if (key.startsWith('discovery_progress_')) {
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
          '[BACKUP] Included ${markedVerses.length} marked bible verses');
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

  /// Restore from Google Drive backup
  @override
  Future<bool> restoreBackup({Future<void> Function()? onRestored}) async {
    try {
      debugPrint('[RESTORE] Restoring from Google Drive backup...');

      // Check authentication
      if (!await _authService.isSignedIn()) {
        final signedIn = await _authService.signIn();
        if (signedIn != true) {
          throw Exception('backup.error_auth_failed');
        }
      }

      final driveApi = await _authService.getDriveApi();
      if (driveApi == null) {
        throw Exception('Could not get Google Drive API client');
      }

      // Get backup folder
      final folderId = await _getBackupFolderId();
      if (folderId == null) {
        throw Exception('Backup folder not found');
      }

      // Find backup file
      final backupFile = await _findBackupFile(driveApi, folderId);
      if (backupFile == null) {
        throw Exception('Backup file not found');
      }

      // Download backup file
      final media = await driveApi.files.get(
        backupFile.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      if (media is! drive.Media) {
        throw Exception('Failed to download backup file');
      }

      // Read file content
      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      final fileBytes = Uint8List.fromList(bytes);
      debugPrint('[RESTORE] Downloaded backup file: ${fileBytes.length} bytes');

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
          throw Exception('Could not parse backup file: $e');
        }
      }

      // Validate backup data
      if (!_validateBackupData(backupData)) {
        throw Exception('Invalid backup data format');
      }

      // Restore data
      await _restoreBackupData(backupData);

      // Invoke callback to reload in-memory state if provided
      if (onRestored != null) {
        await onRestored();
        debugPrint(
            '[RESTORE] ✅ In-memory state reloaded via onRestored callback');
      }

      debugPrint('[RESTORE] ✅ Google Drive backup restored successfully');
      return true;
    } catch (e) {
      debugPrint('[RESTORE] ❌ Error restoring from Google Drive backup: $e');
      return false;
    }
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

          // Extract and log read devotional IDs count
          final readDevocionalIds =
              (stats['readDevocionalIds'] as List<dynamic>?)?.length ?? 0;
          debugPrint('[RESTORE] ✅ Restored spiritual stats');
          debugPrint(
              '[RESTORE]   - Total devotionals read: ${stats['totalDevocionalesRead'] ?? 0}');
          debugPrint(
              '[RESTORE]   - Completed devotional IDs: $readDevocionalIds (${stats['readDevocionalIds']?.toString() ?? '[]'})');
          debugPrint(
              '[RESTORE]   - Current streak: ${stats['currentStreak'] ?? 0}');
          debugPrint(
              '[RESTORE]   - Longest streak: ${stats['longestStreak'] ?? 0}');
          debugPrint(
              '[RESTORE]   - Favorites count: ${stats['favoritesCount'] ?? 0}');

          // (removed: downstream verify of SharedPreferences write —
          //  restoreStats() throws on failure; key internals belong to SpiritualStatsService)
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
          debugPrint(
            '[RESTORE] ✅ Restored ${testimonies.length} testimonies',
          );
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
                entry.key.startsWith('discovery_progress_')) {
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
                '[RESTORE] ✅ Restored preferred bible version: $version');
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
              prefs.getStringList('bible_marked_verses') ?? []);
          final mergedVerses = {...localVerses, ...backupVerses};
          await prefs.setStringList(
              'bible_marked_verses', mergedVerses.toList());
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
      await _setLastBackupTime(DateTime.now());

      debugPrint('Existing backup restored successfully');
      return true;
    } catch (e) {
      debugPrint('Error restoring existing backup: $e');
      return false;
    }
  }
}
