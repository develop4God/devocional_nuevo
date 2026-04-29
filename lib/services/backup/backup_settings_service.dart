import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'i_backup_settings_service.dart';

class BackupSettingsService implements IBackupSettingsService {
  static const String _lastBackupTimeKey = 'last_google_drive_backup_time';
  static const String _autoBackupEnabledKey =
      'google_drive_auto_backup_enabled';
  static const String _backupFrequencyKey = 'google_drive_backup_frequency';
  static const String _wifiOnlyKey = 'google_drive_wifi_only';
  static const String _compressDataKey = 'google_drive_compress_data';

  @override
  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupEnabledKey) ?? false;
  }

  @override
  Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupEnabledKey, enabled);
    debugPrint('Google Drive auto-backup ${enabled ? "enabled" : "disabled"}');
  }

  @override
  Future<String> getBackupFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backupFrequencyKey) ??
        IBackupSettingsService.frequencyDaily;
  }

  @override
  Future<void> setBackupFrequency(String frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupFrequencyKey, frequency);
    debugPrint('Google Drive backup frequency set to: $frequency');
  }

  @override
  Future<bool> isWifiOnlyEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wifiOnlyKey) ?? true;
  }

  @override
  Future<void> setWifiOnlyEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wifiOnlyKey, enabled);
    debugPrint('Google Drive wifi-only ${enabled ? "enabled" : "disabled"}');
  }

  @override
  Future<bool> isCompressionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_compressDataKey) ?? true;
  }

  @override
  Future<void> setCompressionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compressDataKey, enabled);
    debugPrint('Google Drive compression ${enabled ? "enabled" : "disabled"}');
  }

  @override
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastBackupTimeKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  @override
  Future<void> setLastBackupTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBackupTimeKey, time.millisecondsSinceEpoch);
  }

  @override
  Future<DateTime?> getNextBackupTime() async {
    final frequency = await getBackupFrequency();
    if (frequency == IBackupSettingsService.frequencyDeactivated ||
        frequency == IBackupSettingsService.frequencyManual) {
      return null;
    }
    if (!await isAutoBackupEnabled()) return null;
    final lastBackup = await getLastBackupTime();
    if (lastBackup == null) return DateTime.now();
    switch (frequency) {
      case IBackupSettingsService.frequencyDaily:
        return lastBackup.add(const Duration(hours: 6));
      default:
        return null;
    }
  }
}
