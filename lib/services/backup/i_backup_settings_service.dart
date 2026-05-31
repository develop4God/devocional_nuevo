// Interface for backup settings persistence and helpers
abstract class IBackupSettingsService {
  static const String frequencyDaily = 'daily';
  static const String frequencyManual = 'manual';
  static const String frequencyDeactivated = 'deactivated';

  Future<bool> isAutoBackupEnabled();
  Future<void> setAutoBackupEnabled(bool enabled);
  Future<String> getBackupFrequency();
  Future<void> setBackupFrequency(String frequency);
  Future<bool> isWifiOnlyEnabled();
  Future<void> setWifiOnlyEnabled(bool enabled);
  Future<bool> isCompressionEnabled();
  Future<void> setCompressionEnabled(bool enabled);
  Future<DateTime?> getLastBackupTime();
  Future<void> setLastBackupTime(DateTime time);
  Future<DateTime?> getNextBackupTime();
}
