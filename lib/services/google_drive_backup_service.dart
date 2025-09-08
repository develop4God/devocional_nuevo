// lib/services/google_drive_backup_service.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/devocional_provider.dart';

/// Service for managing Google Drive backup functionality
/// Integrates with existing SpiritualStatsService for data consistency
class GoogleDriveBackupService {
  static const String _lastBackupTimeKey = 'last_google_drive_backup_time';
  static const String _autoBackupEnabledKey = 'google_drive_auto_backup_enabled';
  static const String _backupFrequencyKey = 'google_drive_backup_frequency';
  static const String _wifiOnlyKey = 'google_drive_wifi_only';
  static const String _compressDataKey = 'google_drive_compress_data';
  static const String _backupOptionsKey = 'google_drive_backup_options';

  // Backup frequency options
  static const String frequencyDaily = 'daily';
  static const String frequencyWeekly = 'weekly';
  static const String frequencyMonthly = 'monthly';

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
    return prefs.getString(_backupFrequencyKey) ?? frequencyDaily;
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
    return prefs.getBool(_wifiOnlyKey) ?? true; // Default to WiFi-only for data saving
  }

  /// Enable/disable WiFi-only backup
  Future<void> setWifiOnlyEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wifiOnlyKey, enabled);
    debugPrint('Google Drive WiFi-only backup ${enabled ? "enabled" : "disabled"}');
  }

  /// Check if data compression is enabled
  Future<bool> isCompressionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_compressDataKey) ?? true; // Default to enabled for smaller backups
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
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Set last backup timestamp
  Future<void> _setLastBackupTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBackupTimeKey, time.millisecondsSinceEpoch);
  }

  /// Calculate next backup time based on frequency
  Future<DateTime?> getNextBackupTime() async {
    final lastBackup = await getLastBackupTime();
    if (lastBackup == null || !await isAutoBackupEnabled()) {
      return null;
    }

    final frequency = await getBackupFrequency();
    switch (frequency) {
      case frequencyDaily:
        return lastBackup.add(const Duration(days: 1));
      case frequencyWeekly:
        return lastBackup.add(const Duration(days: 7));
      case frequencyMonthly:
        return lastBackup.add(const Duration(days: 30));
      default:
        return lastBackup.add(const Duration(days: 1));
    }
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

  /// Get storage usage info (mock implementation for now)
  Future<Map<String, dynamic>> getStorageInfo() async {
    // In a real implementation, this would query Google Drive API
    return {
      'used_gb': 1.4,
      'total_gb': 100.0,
      'percentage': 1.4,
    };
  }

  /// Create backup to Google Drive
  Future<bool> createBackup(DevocionalProvider? provider) async {
    try {
      debugPrint('Creating Google Drive backup...');
      
      final _ = await _prepareBackupData(provider);
      
      // TODO: Implement actual Google Drive API integration
      // For now, simulate backup creation
      await Future.delayed(const Duration(seconds: 2));
      
      await _setLastBackupTime(DateTime.now());
      debugPrint('Google Drive backup created successfully');
      return true;
    } catch (e) {
      debugPrint('Error creating Google Drive backup: $e');
      return false;
    }
  }

  /// Prepare backup data
  Future<Map<String, dynamic>> _prepareBackupData(DevocionalProvider? provider) async {
    final options = await getBackupOptions();
    final backupData = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
    };

    // Include spiritual stats if enabled
    if (options['spiritual_stats'] == true) {
      // TODO: Get from SpiritualStatsService
      backupData['spiritual_stats'] = {};
    }

    // Include favorite devotionals if enabled
    if (options['favorite_devotionals'] == true && provider != null) {
      backupData['favorite_devotionals'] = provider.favoriteDevocionales
          .map((dev) => dev.toJson())
          .toList();
    }

    // Include saved prayers if enabled
    if (options['saved_prayers'] == true) {
      // TODO: Get from prayers service
      backupData['saved_prayers'] = [];
    }

    return backupData;
  }

  /// Restore from Google Drive backup
  Future<bool> restoreBackup() async {
    try {
      debugPrint('Restoring from Google Drive backup...');
      
      // TODO: Implement actual Google Drive API integration
      // For now, simulate restore
      await Future.delayed(const Duration(seconds: 2));
      
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
        if (!favoriteMap.containsKey('id') || !favoriteMap.containsKey('title')) {
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
}