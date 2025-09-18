// lib/services/google_drive_backup_service.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:shared_preferences/shared_preferences.dart';

import '../blocs/prayer_bloc.dart';
import '../blocs/prayer_event.dart';
import '../providers/devocional_provider.dart';
import '../services/spiritual_stats_service.dart';
import 'compression_service.dart';
import 'connectivity_service.dart';
import 'google_drive_auth_service.dart';

/// Service for managing Google Drive backup functionality
/// Integrates with real Google Drive API for cloud storage
class GoogleDriveBackupService {
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

  // Backup file names
  static const String _backupFileName = 'devocional_backup.json';
  static const String _backupFolderName = 'Devocional Backup';

  final GoogleDriveAuthService _authService;
  final ConnectivityService _connectivityService;
  final SpiritualStatsService _statsService;

  GoogleDriveBackupService({
    required GoogleDriveAuthService authService,
    required ConnectivityService connectivityService,
    required SpiritualStatsService statsService,
  })  : _authService = authService,
        _connectivityService = connectivityService,
        _statsService = statsService;

  /// Check if Google Drive backup is enabled
  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupEnabledKey) ?? false;
  }

  /// Enable/disable automatic Google Drive backup
  Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupEnabledKey, enabled);
    debugPrint('Google Drive auto-backup ${enabled ? "enabled" : "disabled"}');
  }

  /// Get backup frequency
  Future<String> getBackupFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backupFrequencyKey) ??
        frequencyDaily; // Default to Daily (2:00 AM) as requested
  }

  /// Set backup frequency
  Future<void> setBackupFrequency(String frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupFrequencyKey, frequency);
    debugPrint('Google Drive backup frequency set to: $frequency');
  }

  /// Check if WiFi-only backup is enabled
  Future<bool> isWifiOnlyEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wifiOnlyKey) ??
        true; // Default to WiFi-only for data saving
  }

  /// Enable/disable WiFi-only backup
  Future<void> setWifiOnlyEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wifiOnlyKey, enabled);
    debugPrint(
        'Google Drive WiFi-only backup ${enabled ? "enabled" : "disabled"}');
  }

  /// Check if data compression is enabled
  Future<bool> isCompressionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_compressDataKey) ??
        true; // Default to enabled for smaller backups
  }

  /// Enable/disable data compression
  Future<void> setCompressionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compressDataKey, enabled);
    debugPrint('Google Drive compression ${enabled ? "enabled" : "disabled"}');
  }

  /// Get backup options (what to include in backup)
  Future<Map<String, bool>> getBackupOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final optionsJson = prefs.getString(_backupOptionsKey);

    if (optionsJson != null) {
      final Map<String, dynamic> decoded = json.decode(optionsJson);
      return decoded.map((key, value) => MapEntry(key, value as bool));
    }

    // Default options - all enabled
    return {
      'spiritual_stats': true,
      'favorite_devotionals': true,
      'saved_prayers': true,
    };
  }

  /// Set backup options
  Future<void> setBackupOptions(Map<String, bool> options) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupOptionsKey, json.encode(options));
    debugPrint('Google Drive backup options updated: $options');
  }

  /// Get last backup timestamp
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

  /// Calculate next backup time based on frequency
  Future<DateTime?> getNextBackupTime() async {
    final lastBackup = await getLastBackupTime();
    final frequency = await getBackupFrequency();

    // Handle deactivated and manual frequencies
    if (frequency == frequencyDeactivated || frequency == frequencyManual) {
      return null;
    }

    if (lastBackup == null || !await isAutoBackupEnabled()) {
      return null;
    }

    switch (frequency) {
      case frequencyDaily:
        final now = DateTime.now();
        final today2AM = DateTime(now.year, now.month, now.day, 2, 0);

        if (now.isBefore(today2AM)) {
          // Si aún no son las 2:00 AM de hoy, el próximo es HOY a las 2:00 AM
          return today2AM;
        } else {
          // Si ya pasaron las 2:00 AM, el próximo es MAÑANA a las 2:00 AM
          final tomorrow = now.add(const Duration(days: 1));
          return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 2, 0);
        }
    }
    return null;
  }

  /// Get estimated backup size in bytes
  Future<int> getEstimatedBackupSize(DevocionalProvider? provider) async {
    int totalSize = 0;
    final options = await getBackupOptions();

    // Spiritual stats (~5 KB)
    if (options['spiritual_stats'] == true) {
      totalSize += 5 * 1024; // 5 KB
    }

    // Favorite devotionals
    if (options['favorite_devotionals'] == true && provider != null) {
      final favoritesCount = provider.favoriteDevocionales.length;
      totalSize += favoritesCount * 2 * 1024; // ~2 KB per devotional
    }

    // Saved prayers (~15 KB default)
    if (options['saved_prayers'] == true) {
      totalSize += 15 * 1024; // 15 KB
    }

    return totalSize;
  }

  /// Get storage usage info from Google Drive API
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final driveApi = await _authService.getDriveApi();
      if (driveApi == null) {
        throw Exception('Not authenticated with Google Drive');
      }

      final about = await driveApi.about.get($fields: 'storageQuota');
      final storageQuota = about.storageQuota;

      if (storageQuota != null) {
        final usedBytes = int.tryParse(storageQuota.usage ?? '0') ?? 0;
        final totalBytes = int.tryParse(storageQuota.limit ?? '0') ?? 0;

        final usedGB = usedBytes / (1024 * 1024 * 1024);
        final totalGB = totalBytes / (1024 * 1024 * 1024);
        final percentage =
            totalBytes > 0 ? (usedBytes / totalBytes) * 100 : 0.0;

        debugPrint(
            'Google Drive storage: ${usedGB.toStringAsFixed(2)} GB / ${totalGB.toStringAsFixed(2)} GB');

        return {
          'used_gb': double.parse(usedGB.toStringAsFixed(2)),
          'total_gb': double.parse(totalGB.toStringAsFixed(2)),
          'percentage': double.parse(percentage.toStringAsFixed(1)),
          'used_bytes': usedBytes,
          'total_bytes': totalBytes,
        };
      }

      // Fallback if storage quota is not available
      return {
        'used_gb': 0.0,
        'total_gb': 15.0, // Free Google account default
        'percentage': 0.0,
        'used_bytes': 0,
        'total_bytes': 15 * 1024 * 1024 * 1024, // 15 GB
      };
    } catch (e) {
      debugPrint('Error getting Google Drive storage info: $e');
      // Return default values on error
      return {
        'used_gb': 0.0,
        'total_gb': 15.0,
        'percentage': 0.0,
        'used_bytes': 0,
        'total_bytes': 15 * 1024 * 1024 * 1024,
        'error': e.toString(),
      };
    }
  }

  /// Create backup to Google Drive
  Future<bool> createBackup(DevocionalProvider? provider) async {
    try {
      debugPrint('Creating Google Drive backup...');

      // Check authentication
      if (!await _authService.isSignedIn()) {
        throw Exception('Not signed in to Google Drive');
      }

      // Check connectivity if WiFi-only is enabled
      final wifiOnlyEnabled = await isWifiOnlyEnabled();
      if (!await _connectivityService
          .shouldProceedWithBackup(wifiOnlyEnabled)) {
        throw Exception('Network connectivity requirements not met');
      }

      final driveApi = await _authService.getDriveApi();
      if (driveApi == null) {
        throw Exception('Could not get Google Drive API client');
      }

      // Prepare backup data
      final backupData = await _prepareBackupData(provider);

      // Convert to bytes
      Uint8List fileBytes;
      final compressionEnabled = await isCompressionEnabled();
      if (compressionEnabled) {
        fileBytes = CompressionService.compressJson(backupData);
        debugPrint(
            'Backup compressed: ${json.encode(backupData).length} -> ${fileBytes.length} bytes');
      } else {
        fileBytes = Uint8List.fromList(utf8.encode(json.encode(backupData)));
        debugPrint('Backup uncompressed: ${fileBytes.length} bytes');
      }

      // Get or create backup folder
      final folderId = await _getOrCreateBackupFolder(driveApi);

      // Check if backup file already exists
      final existingFile = await _findBackupFile(driveApi, folderId);

      if (existingFile != null) {
        // Update existing file - NO parents field
        debugPrint('Updating existing backup file: ${existingFile.id}');
        final updateFile = drive.File()
          ..name = _backupFileName
          ..description =
              'Devocional backup updated on ${DateTime.now().toIso8601String()}'
          ..mimeType = 'application/json';
        // Importante: NO incluir parents field en updates

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

        await driveApi.files.create(
          createFile,
          uploadMedia: media,
        );
      }

      await _setLastBackupTime(DateTime.now());
      debugPrint('Google Drive backup created successfully');
      return true;
    } catch (e) {
      debugPrint('Error creating Google Drive backup: $e');
      return false;
    }
  }

  /// Prepare backup data
  Future<Map<String, dynamic>> _prepareBackupData(
      DevocionalProvider? provider) async {
    final options = await getBackupOptions();
    final backupData = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      'app_version': '1.0.45', // TODO: Get from package info
      'compression_enabled': await isCompressionEnabled(),
    };

    // Include spiritual stats if enabled
    if (options['spiritual_stats'] == true) {
      try {
        final stats = await _statsService.getAllStats();
        debugPrint('🔍 BACKUP STATS: ${json.encode(stats)}');
        backupData['spiritual_stats'] = stats;
        debugPrint('Included spiritual stats in backup');
      } catch (e) {
        debugPrint('Error getting spiritual stats: $e');
        backupData['spiritual_stats'] = {};
      }
    }

    // Include favorite devotionals if enabled
    if (options['favorite_devotionals'] == true && provider != null) {
      try {
        backupData['favorite_devotionals'] =
            provider.favoriteDevocionales.map((dev) => dev.toJson()).toList();
        debugPrint(
            'Included ${provider.favoriteDevocionales.length} favorite devotionals in backup');
      } catch (e) {
        debugPrint('Error getting favorite devotionals: $e');
        backupData['favorite_devotionals'] = [];
      }
    }

    // Include saved prayers if enabled
    if (options['saved_prayers'] == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final prayersJson = prefs.getString('prayers') ?? '[]';
        final prayersList = json.decode(prayersJson) as List<dynamic>;
        backupData['saved_prayers'] = prayersList;
        debugPrint('Included ${prayersList.length} saved prayers in backup');
      } catch (e) {
        debugPrint('Error getting saved prayers: $e');
        backupData['saved_prayers'] = [];
      }
    }

    return backupData;
  }

  /// Restore from Google Drive backup
  Future<bool> restoreBackup() async {
    try {
      debugPrint('Restoring from Google Drive backup...');

      // Check authentication
      if (!await _authService.isSignedIn()) {
        throw Exception('Not signed in to Google Drive');
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
      debugPrint('Downloaded backup file: ${fileBytes.length} bytes');

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

      debugPrint('Google Drive backup restored successfully');
      return true;
    } catch (e) {
      debugPrint('Error restoring from Google Drive backup: $e');
      return false;
    }
  }

  /// Check if backup should be created automatically
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
          "name='$_backupFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final fileList = await driveApi.files.list(q: query);

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final folderId = fileList.files!.first.id!;
        await _setBackupFolderId(folderId);
        debugPrint('Found existing backup folder: $folderId');
        return folderId;
      }

      // Create new backup folder
      final folder = drive.File()
        ..name = _backupFolderName
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
      drive.DriveApi driveApi, String folderId) async {
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
      // Restore spiritual stats
      if (data.containsKey('spiritual_stats')) {
        try {
          final stats = data['spiritual_stats'] as Map<String, dynamic>;
          await _statsService.restoreStats(stats);
          debugPrint('Restored spiritual stats from backup');
        } catch (e) {
          debugPrint('Error restoring spiritual stats: $e');
        }
      }

      // Restore favorite devotionals
      if (data.containsKey('favorite_devotionals')) {
        try {
          final favorites = data['favorite_devotionals'] as List<dynamic>;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('favorites', json.encode(favorites));
          debugPrint(
              'Restored ${favorites.length} favorite devotionals from backup');
        } catch (e) {
          debugPrint('Error restoring favorite devotionals: $e');
        }
      }

      // Restore saved prayers
      if (data.containsKey('saved_prayers')) {
        try {
          final prayers = data['saved_prayers'] as List<dynamic>;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('prayers', json.encode(prayers));
          debugPrint('Restored ${prayers.length} saved prayers from backup');
        } catch (e) {
          debugPrint('Error restoring saved prayers: $e');
        }
      }

      debugPrint('Backup data restoration completed');
    } catch (e) {
      debugPrint('Error restoring backup data: $e');
      rethrow;
    }
  }

  /// Check if user is authenticated with Google Drive
  Future<bool> isAuthenticated() async {
    return await _authService.isSignedIn();
  }

  /// Sign in to Google Drive
  Future<bool?> signIn() async {
    // Era: Future<bool> signIn() async {
    return await _authService.signIn(); // El metodo ya queda simple
  }

  /// Sign out from Google Drive
  Future<void> signOut() async {
    await _authService.signOut();
    // Clear backup folder cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backupFolderIdKey);
  }

  /// Get current user email
  Future<String?> getUserEmail() async {
    return await _authService.getUserEmail();
  }

  /// Check for existing backups on Google Drive when user signs in
  Future<Map<String, dynamic>?> checkForExistingBackup() async {
    try {
      final driveApi = await _authService.getDriveApi();
      if (driveApi == null) {
        return null;
      }

      // Search for existing backup folder
      final folderQuery =
          "name='$_backupFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
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
  Future<bool> restoreExistingBackup(
    String fileId, {
    DevocionalProvider? devocionalProvider,
    PrayerBloc? prayerBloc,
  }) async {
    try {
      final driveApi = await _authService.getDriveApi();
      if (driveApi == null) {
        return false;
      }

      // Download the backup file
      final media = await driveApi.files.get(fileId,
          downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

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
      // Notify providers if available (add this section)
      if (devocionalProvider != null) {
        await devocionalProvider.reloadFavoritesFromStorage();
        debugPrint('✅ DevocionalProvider notified and reloaded');
      }

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
