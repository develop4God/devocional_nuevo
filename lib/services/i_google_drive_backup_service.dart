// lib/services/i_google_drive_backup_service.dart
//
// Abstract interface for [GoogleDriveBackupService].
// Depend on this interface (not the concrete class) for
// Dependency Inversion and easy test mocking.

import '../blocs/prayer_bloc.dart';
import '../providers/devocional_provider.dart';

/// Frequency constant — backup runs daily (app startup check).
const String kBackupFrequencyDaily = 'daily';

/// Frequency constant — backup only runs on explicit user action.
const String kBackupFrequencyManual = 'manual';

/// Frequency constant — backup is deactivated.
const String kBackupFrequencyDeactivated = 'deactivated';

/// Abstract interface defining Google Drive backup service capabilities.
abstract class IGoogleDriveBackupService {
  // ── Settings ───────────────────────────────────────────────────────────────

  /// Check if Google Drive backup is enabled.
  Future<bool> isAutoBackupEnabled();

  /// Enable/disable automatic Google Drive backup.
  Future<void> setAutoBackupEnabled(bool enabled);

  /// Get backup frequency.
  Future<String> getBackupFrequency();

  /// Set backup frequency.
  Future<void> setBackupFrequency(String frequency);

  /// Check if WiFi-only backup is enabled.
  Future<bool> isWifiOnlyEnabled();

  /// Enable/disable WiFi-only backup.
  Future<void> setWifiOnlyEnabled(bool enabled);

  /// Check if data compression is enabled.
  Future<bool> isCompressionEnabled();

  /// Enable/disable data compression.
  Future<void> setCompressionEnabled(bool enabled);

  /// Get backup options (what to include in backup).
  Future<Map<String, bool>> getBackupOptions();

  /// Set backup options.
  Future<void> setBackupOptions(Map<String, bool> options);

  /// Get last backup timestamp.
  Future<DateTime?> getLastBackupTime();

  /// Calculate next backup time.
  Future<DateTime?> getNextBackupTime();

  /// Get estimated backup size in bytes.
  Future<int> getEstimatedBackupSize(DevocionalProvider? provider);

  /// Get storage usage info from Google Drive API.
  Future<Map<String, dynamic>> getStorageInfo();

  // ── Backup / Restore ───────────────────────────────────────────────────────

  /// Create a backup on Google Drive.
  Future<bool> createBackup(DevocionalProvider? provider);

  /// Restore the most recent backup from Google Drive.
  Future<bool> restoreBackup();

  /// Check whether an automatic backup should be created now.
  Future<bool> shouldCreateAutoBackup();

  /// Check for existing backups on Google Drive when user signs in.
  Future<Map<String, dynamic>?> checkForExistingBackup();

  /// Restore backup from existing file on Google Drive.
  Future<bool> restoreExistingBackup(
    String fileId, {
    DevocionalProvider? devocionalProvider,
    PrayerBloc? prayerBloc,
  });

  // ── Auth proxy methods ─────────────────────────────────────────────────────

  /// Check if user is authenticated with Google Drive.
  Future<bool> isAuthenticated();

  /// Sign in to Google Drive.
  Future<bool?> signIn();

  /// Sign out from Google Drive.
  Future<void> signOut();

  /// Get current user email.
  Future<String?> getUserEmail();
}
