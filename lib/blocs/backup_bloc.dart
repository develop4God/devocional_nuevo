// lib/blocs/backup_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../providers/devocional_provider.dart';
import '../services/backup_scheduler_service.dart'; // 🆕 AGREGADO
import '../services/google_drive_backup_service.dart';
import 'backup_event.dart';
import 'backup_state.dart';

/// BLoC for managing Google Drive backup functionality
class BackupBloc extends Bloc<BackupEvent, BackupState> {
  final GoogleDriveBackupService _backupService;
  final BackupSchedulerService?
      _schedulerService; // 🆕 AGREGADO (opcional para compatibilidad)
  DevocionalProvider? _devocionalProvider;

  BackupBloc({
    required GoogleDriveBackupService backupService,
    BackupSchedulerService? schedulerService, // 🆕 AGREGADO (opcional)
    DevocionalProvider? devocionalProvider,
    dynamic
        prayerBloc, // 🆕 AGREGADO: El parámetro que faltaba (pero no se almacena)
  })  : _backupService = backupService,
        _schedulerService = schedulerService,
        // 🆕 AGREGADO
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
    debugPrint('🔄 [BLOC] === INICIANDO LoadBackupSettings ==='); // 🆕 DEBUG

    try {
      emit(const BackupLoading());

      // CAMBIO: Primero verificar autenticación
      final isAuthenticated = await _backupService.isAuthenticated();
      debugPrint('📊 [BLOC] Autenticado: $isAuthenticated'); // 🆕 DEBUG

      // CAMBIO: Solo obtener storageInfo SI está autenticado (evita error de log)
      Map<String, dynamic> storageInfo = {};
      if (isAuthenticated) {
        storageInfo = await _backupService.getStorageInfo();
        debugPrint('📊 [BLOC] Storage info cargado'); // 🆕 DEBUG
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

      debugPrint('📊 [BLOC] Configuraciones cargadas:'); // 🆕 DEBUG
      debugPrint('📊 [BLOC] - Auto backup: ${results[0]}');
      debugPrint('📊 [BLOC] - Frecuencia: ${results[1]}');
      debugPrint('📊 [BLOC] - Último backup: ${results[5]}');
      debugPrint('📊 [BLOC] - Próximo backup: ${results[6]}');

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

      debugPrint('✅ [BLOC] BackupLoaded emitido exitosamente'); // 🆕 DEBUG
    } catch (e) {
      debugPrint('❌ [BLOC] Error loading backup settings: $e');
      emit(BackupError('Error loading backup settings: ${e.toString()}'));
    }

    debugPrint('🏁 [BLOC] === FIN LoadBackupSettings ==='); // 🆕 DEBUG
  }

  /// Toggle automatic backup
  Future<void> _onToggleAutoBackup(
    ToggleAutoBackup event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint(
        '🔄 [BLOC] === INICIANDO ToggleAutoBackup: ${event.enabled} ==='); // 🆕 DEBUG

    try {
      await _backupService.setAutoBackupEnabled(event.enabled);

      // 🆕 ARREGLO: Actualizar scheduler cuando se habilita/deshabilita auto backup
      if (_schedulerService != null) {
        debugPrint(
            '🔧 [BLOC] Auto backup cambió, actualizando scheduler...'); // 🆕 DEBUG
        await _schedulerService!.scheduleAutomaticBackup();
        debugPrint(
            '✅ [BLOC] Scheduler actualizado por toggle auto backup'); // 🆕 DEBUG
      } else {
        debugPrint('⚠️ [BLOC] Scheduler service no disponible'); // 🆕 DEBUG
      }

      if (state is BackupLoaded) {
        final currentState = state as BackupLoaded;

        // Recalculate next backup time
        final nextBackupTime = await _backupService.getNextBackupTime();
        debugPrint(
            '📊 [BLOC] Nuevo próximo backup: $nextBackupTime'); // 🆕 DEBUG

        emit(currentState.copyWith(
          autoBackupEnabled: event.enabled,
          nextBackupTime: nextBackupTime,
        ));
      } else {
        // Reload all settings
        add(const LoadBackupSettings());
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error toggling auto backup: $e');
      emit(BackupError('Error updating auto backup: ${e.toString()}'));
    }

    debugPrint('🏁 [BLOC] === FIN ToggleAutoBackup ==='); // 🆕 DEBUG
  }

  /// Change backup frequency
  Future<void> _onChangeBackupFrequency(
    ChangeBackupFrequency event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint(
        '🔄 [BLOC] === INICIANDO ChangeBackupFrequency: ${event.frequency} ==='); // 🆕 DEBUG

    try {
      await _backupService.setBackupFrequency(event.frequency);

      // Handle deactivation - sign out and keep backup info for reference
      if (event.frequency == GoogleDriveBackupService.frequencyDeactivated) {
        debugPrint(
            '🚪 [BLOC] Frecuencia desactivada, cerrando sesión...'); // 🆕 DEBUG
        await _backupService.signOut();
      }

      // 🆕 ARREGLO PRINCIPAL: Actualizar scheduler cuando cambia frecuencia
      if (_schedulerService != null) {
        debugPrint(
            '🔧 [BLOC] Frecuencia cambió a ${event.frequency}, reprogramando scheduler...'); // 🆕 DEBUG
        await _schedulerService!.scheduleAutomaticBackup();
        debugPrint(
            '✅ [BLOC] Scheduler reprogramado por cambio de frecuencia'); // 🆕 DEBUG
      } else {
        debugPrint(
            '⚠️ [BLOC] Scheduler service no disponible para reprogramar'); // 🆕 DEBUG
      }

      if (state is BackupLoaded) {
        final currentState = state as BackupLoaded;

        // Recalculate next backup time
        final nextBackupTime = await _backupService.getNextBackupTime();
        debugPrint(
            '📊 [BLOC] Próximo backup recalculado: $nextBackupTime'); // 🆕 DEBUG

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
      debugPrint('❌ [BLOC] Error changing backup frequency: $e');
      emit(BackupError('Error updating backup frequency: ${e.toString()}'));
    }

    debugPrint('🏁 [BLOC] === FIN ChangeBackupFrequency ==='); // 🆕 DEBUG
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
    debugPrint('🚀 [BLOC] === INICIANDO CreateManualBackup ==='); // 🆕 DEBUG

    try {
      emit(const BackupCreating());
      debugPrint('📤 [BLOC] Estado BackupCreating emitido'); // 🆕 DEBUG

      final success = await _backupService.createBackup(_devocionalProvider);
      debugPrint('📤 [BLOC] Resultado del backup: $success'); // 🆕 DEBUG

      if (success) {
        final timestamp = DateTime.now();
        debugPrint('✅ [BLOC] Backup manual exitoso en: $timestamp'); // 🆕 DEBUG

        // 🆕 ARREGLO: Reprogramar scheduler después de backup manual exitoso
        if (_schedulerService != null) {
          debugPrint(
              '🔧 [BLOC] Backup manual exitoso, reprogramando siguiente backup automático...'); // 🆕 DEBUG
          await _schedulerService!.scheduleAutomaticBackup();
          debugPrint(
              '✅ [BLOC] Scheduler reprogramado después de backup manual'); // 🆕 DEBUG
        } else {
          debugPrint(
              '⚠️ [BLOC] Scheduler service no disponible para reprogramar'); // 🆕 DEBUG
        }

        emit(BackupCreated(timestamp));

        // Reload settings to update last backup time and next backup time
        add(const LoadBackupSettings());
        debugPrint(
            '🔄 [BLOC] Recargando configuraciones para actualizar tiempos'); // 🆕 DEBUG
      } else {
        debugPrint('❌ [BLOC] Backup manual falló'); // 🆕 DEBUG
        emit(const BackupError('Failed to create backup'));
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error creating manual backup: $e');
      emit(BackupError('Error creating backup: ${e.toString()}'));
    }

    debugPrint('🏁 [BLOC] === FIN CreateManualBackup ==='); // 🆕 DEBUG
  }

  /// Restore from backup
  Future<void> _onRestoreFromBackup(
    RestoreFromBackup event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('🔄 [BLOC] === INICIANDO RestoreFromBackup ==='); // 🆕 DEBUG

    try {
      emit(const BackupRestoring());
      debugPrint('📥 [BLOC] Estado BackupRestoring emitido'); // 🆕 DEBUG

      final success = await _backupService.restoreBackup();
      debugPrint('📥 [BLOC] Resultado del restore: $success'); // 🆕 DEBUG

      if (success) {
        debugPrint('✅ [BLOC] Restore exitoso'); // 🆕 DEBUG

        // 🆕 ARREGLO: Reprogramar scheduler después de restore exitoso
        if (_schedulerService != null) {
          debugPrint(
              '🔧 [BLOC] Restore exitoso, reprogramando siguiente backup automático...'); // 🆕 DEBUG
          await _schedulerService!.scheduleAutomaticBackup();
          debugPrint(
              '✅ [BLOC] Scheduler reprogramado después de restore'); // 🆕 DEBUG
        } else {
          debugPrint(
              '⚠️ [BLOC] Scheduler service no disponible para reprogramar'); // 🆕 DEBUG
        }

        emit(const BackupRestored());

        // Reload settings
        add(const LoadBackupSettings());
        debugPrint(
            '🔄 [BLOC] Recargando configuraciones después de restore'); // 🆕 DEBUG
      } else {
        debugPrint('❌ [BLOC] Restore falló'); // 🆕 DEBUG
        emit(const BackupError('Failed to restore backup'));
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error restoring backup: $e');
      emit(BackupError('Error restoring backup: ${e.toString()}'));
    }

    debugPrint('🏁 [BLOC] === FIN RestoreFromBackup ==='); // 🆕 DEBUG
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
    debugPrint('🔄 [BLOC] Refrescando estado de backup'); // 🆕 DEBUG
    // Simply reload all settings
    add(const LoadBackupSettings());
  }

  /// Sign in to Google Drive
  Future<void> _onSignInToGoogleDrive(
    SignInToGoogleDrive event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('🔐 [BLOC] === INICIANDO SignInToGoogleDrive ==='); // 🆕 DEBUG

    try {
      emit(const BackupLoading());

      final success = await _backupService.signIn();
      debugPrint('🔐 [BLOC] Resultado sign-in: $success'); // 🆕 DEBUG

      // CAMBIO: Manejar cancelación de usuario (null)
      if (success == null) {
        debugPrint(
            '🔄 [DEBUG] Usuario canceló el sign-in - volviendo al estado anterior');
        // Simplemente recargar el estado anterior sin mostrar error
        add(const LoadBackupSettings());
        return;
      }

      if (success) {
        debugPrint(
            '✅ [BLOC] Sign-in exitoso, verificando backup existente...'); // 🆕 DEBUG

        // Check for existing backups
        final existingBackup = await _backupService.checkForExistingBackup();

        if (existingBackup != null && existingBackup['found'] == true) {
          debugPrint('📋 [BLOC] Backup existente encontrado'); // 🆕 DEBUG
          // Show dialog or emit special state to ask user about restoring
          emit(BackupExistingFound(existingBackup));
        } else {
          debugPrint('ℹ️ [BLOC] No hay backup existente'); // 🆕 DEBUG
          // Reload settings to get updated authentication status
          add(const LoadBackupSettings());
        }
      } else {
        debugPrint('❌ [BLOC] Sign-in falló'); // 🆕 DEBUG
        // Fallo real de autenticación (no cancelación)
        emit(const BackupError('backup.sign_in_failed'));
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error signing in to Google Drive: $e');
      emit(BackupError('backup.sign_in_failed'));
    }

    debugPrint('🏁 [BLOC] === FIN SignInToGoogleDrive ==='); // 🆕 DEBUG
  }

  /// Sign out from Google Drive
  Future<void> _onSignOutFromGoogleDrive(
    SignOutFromGoogleDrive event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint(
        '🚪 [BLOC] === INICIANDO SignOutFromGoogleDrive ==='); // 🆕 DEBUG

    try {
      await _backupService.signOut();
      debugPrint('✅ [BLOC] Sign-out exitoso'); // 🆕 DEBUG

      // 🆕 ARREGLO: Cancelar backups programados al cerrar sesión
      if (_schedulerService != null) {
        debugPrint(
            '🛑 [BLOC] Cancelando backups programados por sign-out...'); // 🆕 DEBUG
        await _schedulerService!.cancelAutomaticBackup();
        debugPrint('✅ [BLOC] Backups programados cancelados'); // 🆕 DEBUG
      }

      // Reload settings to get updated authentication status
      add(const LoadBackupSettings());
    } catch (e) {
      debugPrint('❌ [BLOC] Error signing out from Google Drive: $e');
      emit(BackupError('Error signing out: ${e.toString()}'));
    }

    debugPrint('🏁 [BLOC] === FIN SignOutFromGoogleDrive ==='); // 🆕 DEBUG
  }

  /// Restore existing backup from Google Drive
  Future<void> _onRestoreExistingBackup(
    RestoreExistingBackup event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('📥 [BLOC] === INICIANDO RestoreExistingBackup ==='); // 🆕 DEBUG

    try {
      emit(const BackupRestoring());

      final success = await _backupService.restoreExistingBackup(event.fileId);
      debugPrint('📥 [BLOC] Resultado restore existente: $success'); // 🆕 DEBUG

      if (success) {
        debugPrint('✅ [BLOC] Restore existente exitoso'); // 🆕 DEBUG

        // 🆕 ARREGLO: Reprogramar scheduler después de restore existente exitoso
        if (_schedulerService != null) {
          debugPrint(
              '🔧 [BLOC] Restore existente exitoso, reprogramando scheduler...'); // 🆕 DEBUG
          await _schedulerService!.scheduleAutomaticBackup();
          debugPrint(
              '✅ [BLOC] Scheduler reprogramado después de restore existente'); // 🆕 DEBUG
        }

        emit(const BackupRestored());
        // Reload settings to get updated data
        add(const LoadBackupSettings());
      } else {
        debugPrint('❌ [BLOC] Restore existente falló'); // 🆕 DEBUG
        emit(const BackupError('backup.restore_failed'));
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error restoring existing backup: $e');
      emit(BackupError('backup.restore_failed'));
    }

    debugPrint('🏁 [BLOC] === FIN RestoreExistingBackup ==='); // 🆕 DEBUG
  }

  /// Skip restoring existing backup
  Future<void> _onSkipExistingBackup(
    SkipExistingBackup event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('⏭️ [BLOC] Saltando restore de backup existente'); // 🆕 DEBUG
    // Just reload settings without restoring
    add(const LoadBackupSettings());
  }
}
