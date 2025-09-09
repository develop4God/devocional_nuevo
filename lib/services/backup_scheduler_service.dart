// lib/services/backup_scheduler_service.dart
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'connectivity_service.dart';
import 'google_drive_backup_service.dart';

/// Service for scheduling automatic backups in the background
class BackupSchedulerService {
  static const String _taskName = 'automatic_backup_task';
  static const String _taskTag = 'backup';

  final GoogleDriveBackupService _backupService;
  final ConnectivityService _connectivityService;

  BackupSchedulerService({
    required GoogleDriveBackupService backupService,
    required ConnectivityService connectivityService,
  })  : _backupService = backupService,
        _connectivityService = connectivityService;

  /// Initialize the background task system
  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // Set to true for debugging
      );
      debugPrint('Background scheduler initialized');
    } catch (e) {
      debugPrint('Error initializing background scheduler: $e');
    }
  }

  /// Schedule automatic backup based on frequency
  Future<void> scheduleAutomaticBackup() async {
    try {
      final frequency = await _backupService.getBackupFrequency();
      final isEnabled = await _backupService.isAutoBackupEnabled();

      if (!isEnabled) {
        await cancelAutomaticBackup();
        return;
      }

      Duration initialDelay;
      Duration frequency_;

      switch (frequency) {
        case GoogleDriveBackupService.frequencyDaily:
          initialDelay = const Duration(hours: 24);
          frequency_ = const Duration(hours: 24);
          break;
        case GoogleDriveBackupService.frequencyWeekly:
          initialDelay = const Duration(days: 7);
          frequency_ = const Duration(days: 7);
          break;
        case GoogleDriveBackupService.frequencyMonthly:
          initialDelay = const Duration(days: 30);
          frequency_ = const Duration(days: 30);
          break;
        default:
          initialDelay = const Duration(hours: 24);
          frequency_ = const Duration(hours: 24);
      }

      // Cancel existing task
      await Workmanager().cancelByUniqueName(_taskName);

      // Schedule new periodic task
      await Workmanager().registerPeriodicTask(
        _taskName,
        _taskName,
        frequency: frequency_,
        initialDelay: initialDelay,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: true,
        ),
        tag: _taskTag,
      );

      debugPrint('Automatic backup scheduled with frequency: $frequency');
    } catch (e) {
      debugPrint('Error scheduling automatic backup: $e');
    }
  }

  /// Cancel automatic backup scheduling
  Future<void> cancelAutomaticBackup() async {
    try {
      await Workmanager().cancelByUniqueName(_taskName);
      debugPrint('Automatic backup scheduling cancelled');
    } catch (e) {
      debugPrint('Error cancelling automatic backup: $e');
    }
  }

  /// Cancel all scheduled tasks
  static Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      debugPrint('All scheduled tasks cancelled');
    } catch (e) {
      debugPrint('Error cancelling all tasks: $e');
    }
  }

  /// Check if backup should run now
  Future<bool> shouldRunBackup() async {
    try {
      // Check if auto backup is enabled
      if (!await _backupService.isAutoBackupEnabled()) {
        debugPrint('Auto backup is disabled');
        return false;
      }

      // Check if it's time for backup
      if (!await _backupService.shouldCreateAutoBackup()) {
        debugPrint('Not time for backup yet');
        return false;
      }

      // Check connectivity requirements
      final wifiOnlyEnabled = await _backupService.isWifiOnlyEnabled();
      if (!await _connectivityService
          .shouldProceedWithBackup(wifiOnlyEnabled)) {
        debugPrint('Connectivity requirements not met');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking if backup should run: $e');
      return false;
    }
  }

  /// Execute backup in background
  static Future<void> executeBackgroundBackup() async {
    try {
      debugPrint('Executing background backup...');

      // Note: In a real implementation, you would need to initialize
      // all required services here since this runs in an isolate

      // For now, just log that the task was triggered
      debugPrint('Background backup task triggered');

      // In practice, you would:
      // 1. Initialize services
      // 2. Check connectivity
      // 3. Perform backup
      // 4. Handle errors
    } catch (e) {
      debugPrint('Error executing background backup: $e');
    }
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('Background task executed: $task');

      switch (task) {
        case BackupSchedulerService._taskName:
          await BackupSchedulerService.executeBackgroundBackup();
          break;
        default:
          debugPrint('Unknown background task: $task');
          return false;
      }

      return true;
    } catch (e) {
      debugPrint('Background task error: $e');
      return false;
    }
  });
}
