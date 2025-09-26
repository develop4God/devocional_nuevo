// lib/services/backup_scheduler_service.dart
import 'package:flutter/foundation.dart';

import 'connectivity_service.dart';
import 'google_drive_backup_service.dart';

/// Service for backup scheduling calculations (WorkManager removed)
class BackupSchedulerService {
  final GoogleDriveBackupService _backupService;
  final ConnectivityService _connectivityService;

  BackupSchedulerService({
    required GoogleDriveBackupService backupService,
    required ConnectivityService connectivityService,
  })  : _backupService = backupService,
        _connectivityService = connectivityService;

  /// Initialize - No longer needed but kept for compatibility
  static Future<void> initialize() async {
    debugPrint('🔧 [SCHEDULER] Startup backup mode - no WorkManager needed');
  }

  /// Schedule automatic backup - Now just logs (no actual scheduling)
  Future<void> scheduleAutomaticBackup() async {
    debugPrint('🔧 [SCHEDULER] Using startup backup approach');
  }

  /// Cancel automatic backup - Now just logs
  Future<void> cancelAutomaticBackup() async {
    debugPrint('🔧 [SCHEDULER] Startup backup - no cancellation needed');
  }

  /// Check if backup should run now
  Future<bool> shouldRunBackup() async {
    debugPrint('🔍 [SCHEDULER] Checking backup conditions...');

    final autoEnabled = await _backupService.isAutoBackupEnabled();
    if (!autoEnabled) return false;

    final shouldCreate = await _backupService.shouldCreateAutoBackup();
    if (!shouldCreate) return false;

    final wifiOnlyEnabled = await _backupService.isWifiOnlyEnabled();
    final connectivityOk =
        await _connectivityService.shouldProceedWithBackup(wifiOnlyEnabled);

    return connectivityOk;
  }
}
