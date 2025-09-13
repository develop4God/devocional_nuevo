// lib/blocs/backup_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../providers/devocional_provider.dart';
import '../services/google_drive_backup_service.dart';
import 'backup_event.dart';
import 'backup_state.dart';

/// BLoC for managing Google Drive backup functionality
class BackupBloc extends Bloc<BackupEvent, BackupState> {
  final GoogleDriveBackupService _backupService;
  DevocionalProvider? _devocionalProvider;

  BackupBloc({
    required GoogleDriveBackupService backupService,
    DevocionalProvider? devocionalProvider,
  })  : _backupService = backupService,
        _devocionalProvider = devocionalProvider,
        super(const BackupInitial()) {
    // Register event handlers
    on<LoadBackupSettings>(_onLoadBackupSettings);
    on<ToggleAutoBackup>(_onToggleAutoBackup);
    on<ChangeBackupFrequency>(_onChangeBackupFrequency);
    on<ToggleWifiOnly>(_onToggleWifiOnly);
    on<ToggleCompression>(_onToggleCompression);
    on<UpdateBackupOptions>(_onUpdateBackupOptions);
    on<CreateManualBackup>(_onCreateManualBackup);
    on<RestoreFromBackup>(_onRestoreFromBackup);
    on<LoadStorageInfo>(_onLoadStorageInfo);
    on<RefreshBackupStatus>(_onRefreshBackupStatus);
    on<SignInToGoogleDrive>(_onSignInToGoogleDrive);
    on<SignOutFromGoogleDrive>(_onSignOutFromGoogleDrive);
    on<RestoreExistingBackup>(_onRestoreExistingBackup);
    on<SkipExistingBackup>(_onSkipExistingBackup);
  }

  /// Set the devotional provider (for dependency injection)
  void setDevocionalProvider(DevocionalProvider provider) {
    _devocionalProvider = provider;
  }

  /// Load all backup settings and status
  Future<void> _onLoadBackupSettings(
    LoadBackupSettings event,
    Emitter<BackupState> emit,
  ) async {
    try {
      emit(const BackupLoading());

      // CAMBIO: Primero verificar autenticación
      final isAuthenticated = await _backupService.isAuthenticated();

      // CAMBIO: Solo obtener storageInfo SI está autenticado (evita error de log)
      Map<String, dynamic> storageInfo = {};
      if (isAuthenticated) {
        storageInfo = await _backupService.getStorageInfo();
      }

      // Cargar el resto de configuraciones en paralelo
      final results = await Future.wait([
        _backupService.isAutoBackupEnabled(),
        _backupService.getBackupFrequency(),
        _backupService.isWifiOnlyEnabled(),
        _backupService.isCompressionEnabled(),
        _backupService.getBackupOptions(),
        _backupService.getLastBackupTime(),
        _backupService.getNextBackupTime(),
        _backupService.getEstimatedBackupSize(_devocionalProvider),
        _backupService.getUserEmail(),
      ]);

      emit(BackupLoaded(
        autoBackupEnabled: results[0] as bool,
        backupFrequency: results[1] as String,
        wifiOnlyEnabled: results[2] as bool,
        compressionEnabled: results[3] as bool,
        backupOptions: results[4] as Map<String, bool>,
        lastBackupTime: results[5] as DateTime?,
        nextBackupTime: results[6] as DateTime?,
        estimatedSize: results[7] as int,
        storageInfo: storageInfo,
        // Usar el storageInfo condicional
        isAuthenticated: isAuthenticated,
        userEmail: results[8] as String?,
      ));
    } catch (e) {
      debugPrint('Error loading backup settings: $e');
      emit(BackupError('Error loading backup settings: ${e.toString()}'));
    }
  }

  /// Toggle automatic backup
  Future<void> _onToggleAutoBackup(
    ToggleAutoBackup event,
    Emitter<BackupState> emit,
  ) async {
    try {
      await _backupService.setAutoBackupEnabled(event.enabled);

      if (state is BackupLoaded) {
        final currentState = state as BackupLoaded;

        // Recalculate next backup time
        final nextBackupTime = await _backupService.getNextBackupTime();

        emit(currentState.copyWith(
          autoBackupEnabled: event.enabled,
          nextBackupTime: nextBackupTime,
        ));
      } else {
        // Reload all settings
        add(const LoadBackupSettings());
      }
    } catch (e) {
      debugPrint('Error toggling auto backup: $e');
      emit(BackupError('Error updating auto backup: ${e.toString()}'));
    }
  }

  /// Change backup frequency
  Future<void> _onChangeBackupFrequency(
    ChangeBackupFrequency event,
    Emitter<BackupState> emit,
  ) async {
    try {
      await _backupService.setBackupFrequency(event.frequency);

      // Handle deactivation - sign out and keep backup info for reference
      if (event.frequency == GoogleDriveBackupService.frequencyDeactivated) {
        await _backupService.signOut();
      }

      if (state is BackupLoaded) {
        final currentState = state as BackupLoaded;

        // Recalculate next backup time
        final nextBackupTime = await _backupService.getNextBackupTime();

        // Update authentication status if deactivated
        final isAuthenticated =
            event.frequency == GoogleDriveBackupService.frequencyDeactivated
                ? false
                : currentState.isAuthenticated;

        emit(currentState.copyWith(
          backupFrequency: event.frequency,
          nextBackupTime: nextBackupTime,
          isAuthenticated: isAuthenticated,
        ));
      } else {
        add(const LoadBackupSettings());
      }
    } catch (e) {
      debugPrint('Error changing backup frequency: $e');
      emit(BackupError('Error updating backup frequency: ${e.toString()}'));
    }
  }

  /// Toggle WiFi-only backup
  Future<void> _onToggleWifiOnly(
    ToggleWifiOnly event,
    Emitter<BackupState> emit,
  ) async {
    try {
      await _backupService.setWifiOnlyEnabled(event.enabled);

      if (state is BackupLoaded) {
        final currentState = state as BackupLoaded;
        emit(currentState.copyWith(wifiOnlyEnabled: event.enabled));
      } else {
        add(const LoadBackupSettings());
      }
    } catch (e) {
      debugPrint('Error toggling WiFi only: $e');
      emit(BackupError('Error updating WiFi setting: ${e.toString()}'));
    }
  }

  /// Toggle data compression
  Future<void> _onToggleCompression(
    ToggleCompression event,
    Emitter<BackupState> emit,
  ) async {
    try {
      await _backupService.setCompressionEnabled(event.enabled);

      if (state is BackupLoaded) {
        final currentState = state as BackupLoaded;
        emit(currentState.copyWith(compressionEnabled: event.enabled));
      } else {
        add(const LoadBackupSettings());
      }
    } catch (e) {
      debugPrint('Error toggling compression: $e');
      emit(BackupError('Error updating compression: ${e.toString()}'));
    }
  }

  /// Update backup options
  Future<void> _onUpdateBackupOptions(
    UpdateBackupOptions event,
    Emitter<BackupState> emit,
  ) async {
    try {
      await _backupService.setBackupOptions(event.options);

      if (state is BackupLoaded) {
        final currentState = state as BackupLoaded;

        // Recalculate estimated size
        final estimatedSize =
            await _backupService.getEstimatedBackupSize(_devocionalProvider);

        emit(currentState.copyWith(
          backupOptions: event.options,
          estimatedSize: estimatedSize,
        ));
      } else {
        add(const LoadBackupSettings());
      }
    } catch (e) {
      debugPrint('Error updating backup options: $e');
      emit(BackupError('Error updating backup options: ${e.toString()}'));
    }
  }

  /// Create manual backup
  Future<void> _onCreateManualBackup(
    CreateManualBackup event,
    Emitter<BackupState> emit,
  ) async {
    try {
      emit(const BackupCreating());

      final success = await _backupService.createBackup(_devocionalProvider);

      if (success) {
        final timestamp = DateTime.now();
        emit(BackupCreated(timestamp));

        // Reload settings to update last backup time and next backup time
        add(const LoadBackupSettings());
      } else {
        emit(const BackupError('Failed to create backup'));
      }
    } catch (e) {
      debugPrint('Error creating manual backup: $e');
      emit(BackupError('Error creating backup: ${e.toString()}'));
    }
  }

  /// Restore from backup
  Future<void> _onRestoreFromBackup(
    RestoreFromBackup event,
    Emitter<BackupState> emit,
  ) async {
    try {
      emit(const BackupRestoring());

      final success = await _backupService.restoreBackup();

      if (success) {
        emit(const BackupRestored());

        // Reload settings
        add(const LoadBackupSettings());
      } else {
        emit(const BackupError('Failed to restore backup'));
      }
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      emit(BackupError('Error restoring backup: ${e.toString()}'));
    }
  }

  /// Load storage information
  Future<void> _onLoadStorageInfo(
    LoadStorageInfo event,
    Emitter<BackupState> emit,
  ) async {
    try {
      final storageInfo = await _backupService.getStorageInfo();

      if (state is BackupLoaded) {
        final currentState = state as BackupLoaded;
        emit(currentState.copyWith(storageInfo: storageInfo));
      } else {
        add(const LoadBackupSettings());
      }
    } catch (e) {
      debugPrint('Error loading storage info: $e');
      emit(BackupError('Error loading storage info: ${e.toString()}'));
    }
  }

  /// Refresh backup status
  Future<void> _onRefreshBackupStatus(
    RefreshBackupStatus event,
    Emitter<BackupState> emit,
  ) async {
    // Simply reload all settings
    add(const LoadBackupSettings());
  }

  /// Sign in to Google Drive
  Future<void> _onSignInToGoogleDrive(
    SignInToGoogleDrive event,
    Emitter<BackupState> emit,
  ) async {
    try {
      emit(const BackupLoading());

      final success = await _backupService.signIn();

      // CAMBIO: Manejar cancelación de usuario (null)
      if (success == null) {
        debugPrint(
            '🔄 [DEBUG] Usuario canceló el sign-in - volviendo al estado anterior');
        // Simplemente recargar el estado anterior sin mostrar error
        add(const LoadBackupSettings());
        return;
      }

      if (success) {
        // Check for existing backups
        final existingBackup = await _backupService.checkForExistingBackup();

        if (existingBackup != null && existingBackup['found'] == true) {
          // Show dialog or emit special state to ask user about restoring
          emit(BackupExistingFound(existingBackup));
        } else {
          // Reload settings to get updated authentication status
          add(const LoadBackupSettings());
        }
      } else {
        // Fallo real de autenticación (no cancelación)
        emit(const BackupError('backup.sign_in_failed'));
      }
    } catch (e) {
      debugPrint('Error signing in to Google Drive: $e');
      emit(BackupError('backup.sign_in_failed'));
    }
  }

  /// Sign out from Google Drive
  Future<void> _onSignOutFromGoogleDrive(
    SignOutFromGoogleDrive event,
    Emitter<BackupState> emit,
  ) async {
    try {
      await _backupService.signOut();

      // Reload settings to get updated authentication status
      add(const LoadBackupSettings());
    } catch (e) {
      debugPrint('Error signing out from Google Drive: $e');
      emit(BackupError('Error signing out: ${e.toString()}'));
    }
  }

  /// Restore existing backup from Google Drive
  Future<void> _onRestoreExistingBackup(
    RestoreExistingBackup event,
    Emitter<BackupState> emit,
  ) async {
    try {
      emit(const BackupRestoring());

      final success = await _backupService.restoreExistingBackup(event.fileId);

      if (success) {
        emit(const BackupRestored());
        // Reload settings to get updated data
        add(const LoadBackupSettings());
      } else {
        emit(const BackupError('backup.restore_failed'));
      }
    } catch (e) {
      debugPrint('Error restoring existing backup: $e');
      emit(BackupError('backup.restore_failed'));
    }
  }

  /// Skip restoring existing backup
  Future<void> _onSkipExistingBackup(
    SkipExistingBackup event,
    Emitter<BackupState> emit,
  ) async {
    // Just reload settings without restoring
    add(const LoadBackupSettings());
  }
}
