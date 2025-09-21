// lib/blocs/backup_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../providers/devocional_provider.dart';
import '../services/backup_scheduler_service.dart';
import '../services/google_drive_backup_service.dart';
import 'backup_event.dart';
import 'backup_state.dart';

/// BLoC for managing Google Drive backup functionality
class BackupBloc extends Bloc<BackupEvent, BackupState> {
  final GoogleDriveBackupService _backupService;
  final BackupSchedulerService? _schedulerService;
  DevocionalProvider? _devocionalProvider;

  BackupBloc({
    required GoogleDriveBackupService backupService,
    BackupSchedulerService? schedulerService,
    DevocionalProvider? devocionalProvider,
    dynamic prayerBloc, // Este parámetro se acepta pero no se usa
  })  : _backupService = backupService,
        _schedulerService = schedulerService,
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

  // 🆕 PUNTO #7: Método helper para generar errores específicos con claves i18n
  String _getSpecificErrorMessage(String originalError) {
    debugPrint('🔍 [BLOC] Analizando error: $originalError');

    final errorLower = originalError.toLowerCase();

    // Network/connectivity errors
    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('timeout') ||
        errorLower.contains('unreachable')) {
      debugPrint('🔍 [BLOC] Error identificado como: NETWORK');
      return 'backup.error_network';
    }

    // Internet connectivity
    if (errorLower.contains('internet') ||
        errorLower.contains('connectivity') ||
        errorLower.contains('offline')) {
      debugPrint('🔍 [BLOC] Error identificado como: NO_INTERNET');
      return 'backup.error_no_internet';
    }

    // Authentication errors
    if (errorLower.contains('auth') ||
        errorLower.contains('sign') ||
        errorLower.contains('token') ||
        errorLower.contains('unauthorized') ||
        errorLower.contains('permission')) {
      debugPrint('🔍 [BLOC] Error identificado como: AUTH_FAILED');
      return 'backup.error_auth_failed';
    }

    // Storage/quota errors
    if (errorLower.contains('storage') ||
        errorLower.contains('quota') ||
        errorLower.contains('space') ||
        errorLower.contains('limit exceeded')) {
      debugPrint('🔍 [BLOC] Error identificado como: STORAGE_FULL');
      return 'backup.error_storage_full';
    }

    // Generic fallback
    debugPrint('🔍 [BLOC] Error no específico, usando genérico');
    return 'backup.error_generic';
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
    debugPrint('🔄 [BLOC] === INICIANDO LoadBackupSettings ===');

    try {
      emit(const BackupLoading());

      // CAMBIO: Primero verificar autenticación
      final isAuthenticated = await _backupService.isAuthenticated();
      debugPrint('📊 [BLOC] Autenticado: $isAuthenticated');

      // CAMBIO: Solo obtener storageInfo SI está autenticado (evita error de log)
      Map<String, dynamic> storageInfo = {};
      if (isAuthenticated) {
        storageInfo = await _backupService.getStorageInfo();
        debugPrint('📊 [BLOC] Storage info cargado');
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

      debugPrint('📊 [BLOC] Configuraciones cargadas:');
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
        isAuthenticated: isAuthenticated,
        userEmail: results[8] as String?,
      ));

      debugPrint('✅ [BLOC] BackupLoaded emitido exitosamente');
    } catch (e) {
      debugPrint('❌ [BLOC] Error loading backup settings: $e');
      // 🆕 PUNTO #7: Usar error específico
      emit(BackupError(_getSpecificErrorMessage(e.toString())));
    }

    debugPrint('🏁 [BLOC] === FIN LoadBackupSettings ===');
  }

  /// Toggle automatic backup
  Future<void> _onToggleAutoBackup(
    ToggleAutoBackup event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint(
        '🔄 [BLOC] === INICIANDO ToggleAutoBackup: ${event.enabled} ===');

    try {
      await _backupService.setAutoBackupEnabled(event.enabled);

      // 🆕 NUEVO COMPORTAMIENTO: Si se activa auto-backup y frecuencia es "deactivated",
      // cambiar automáticamente a "daily" (diariamente a las 2:00 AM)
      if (event.enabled) {
        final currentFrequency = await _backupService.getBackupFrequency();
        debugPrint('🔍 [BLOC] Frecuencia actual: $currentFrequency');

        if (currentFrequency == GoogleDriveBackupService.frequencyDeactivated) {
          debugPrint(
              '🔧 [BLOC] Auto-backup activado con frecuencia "deactivated", cambiando a "daily"');
          await _backupService
              .setBackupFrequency(GoogleDriveBackupService.frequencyDaily);
          debugPrint('✅ [BLOC] Frecuencia cambiada automáticamente a "daily"');
        }
      }

      // 🆕 ARREGLO: Actualizar scheduler cuando se habilita/deshabilita auto backup
      if (_schedulerService != null) {
        debugPrint('🔧 [BLOC] Auto backup cambió, actualizando scheduler...');
        await _schedulerService!.scheduleAutomaticBackup();
        debugPrint('✅ [BLOC] Scheduler actualizado por toggle auto backup');
      } else {
        debugPrint('⚠️ [BLOC] Scheduler service no disponible');
      }

      if (state is BackupLoaded) {
        final currentState = state as BackupLoaded;

        // 🆕 CAMBIO: Obtener la frecuencia actualizada (por si cambió arriba)
        final updatedFrequency = await _backupService.getBackupFrequency();

        // Recalculate next backup time
        final nextBackupTime = await _backupService.getNextBackupTime();
        debugPrint('📊 [BLOC] Nuevo próximo backup: $nextBackupTime');

        emit(currentState.copyWith(
          autoBackupEnabled: event.enabled,
          backupFrequency: updatedFrequency,
          nextBackupTime: nextBackupTime,
        ));
      } else {
        // Reload all settings
        add(const LoadBackupSettings());
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error toggling auto backup: $e');
      // 🆕 PUNTO #7: Usar error específico
      emit(BackupError(_getSpecificErrorMessage(e.toString())));
    }

    debugPrint('🏁 [BLOC] === FIN ToggleAutoBackup ===');
  }

  /// Change backup frequency
  Future<void> _onChangeBackupFrequency(
    ChangeBackupFrequency event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint(
        '🔄 [BLOC] === INICIANDO ChangeBackupFrequency: ${event.frequency} ===');

    try {
      await _backupService.setBackupFrequency(event.frequency);

      // Handle deactivation - sign out and keep backup info for reference
      if (event.frequency == GoogleDriveBackupService.frequencyDeactivated) {
        debugPrint('🚪 [BLOC] Frecuencia desactivada, cerrando sesión...');
        await _backupService.signOut();
      }

      // 🆕 ARREGLO PRINCIPAL: Actualizar scheduler cuando cambia frecuencia
      if (_schedulerService != null) {
        debugPrint(
            '🔧 [BLOC] Frecuencia cambió a ${event.frequency}, reprogramando scheduler...');
        await _schedulerService!.scheduleAutomaticBackup();
        debugPrint('✅ [BLOC] Scheduler reprogramado por cambio de frecuencia');
      } else {
        debugPrint(
            '⚠️ [BLOC] Scheduler service no disponible para reprogramar');
      }

      if (state is BackupLoaded) {
        final currentState = state as BackupLoaded;

        // Recalculate next backup time
        final nextBackupTime = await _backupService.getNextBackupTime();
        debugPrint('📊 [BLOC] Próximo backup recalculado: $nextBackupTime');

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
      // 🆕 PUNTO #7: Usar error específico
      emit(BackupError(_getSpecificErrorMessage(e.toString())));
    }

    debugPrint('🏁 [BLOC] === FIN ChangeBackupFrequency ===');
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
      // 🆕 PUNTO #7: Usar error específico
      emit(BackupError(_getSpecificErrorMessage(e.toString())));
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
      // 🆕 PUNTO #7: Usar error específico
      emit(BackupError(_getSpecificErrorMessage(e.toString())));
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
      // 🆕 PUNTO #7: Usar error específico
      emit(BackupError(_getSpecificErrorMessage(e.toString())));
    }
  }

  /// Create manual backup
  Future<void> _onCreateManualBackup(
    CreateManualBackup event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('🚀 [BLOC] === INICIANDO CreateManualBackup ===');

    try {
      emit(const BackupCreating());
      debugPrint('📤 [BLOC] Estado BackupCreating emitido');

      final success = await _backupService.createBackup(_devocionalProvider);
      debugPrint('📤 [BLOC] Resultado del backup: $success');

      if (success) {
        final timestamp = DateTime.now();
        debugPrint('✅ [BLOC] Backup manual exitoso en: $timestamp');

        // 🆕 ARREGLO: Reprogramar scheduler después de backup manual exitoso
        if (_schedulerService != null) {
          debugPrint(
              '🔧 [BLOC] Backup manual exitoso, reprogramando siguiente backup automático...');
          await _schedulerService!.scheduleAutomaticBackup();
          debugPrint(
              '✅ [BLOC] Scheduler reprogramado después de backup manual');
        } else {
          debugPrint(
              '⚠️ [BLOC] Scheduler service no disponible para reprogramar');
        }

        emit(BackupCreated(timestamp));

        // Reload settings to update last backup time and next backup time
        add(const LoadBackupSettings());
        debugPrint(
            '🔄 [BLOC] Recargando configuraciones para actualizar tiempos');
      } else {
        debugPrint('❌ [BLOC] Backup manual falló');
        // 🆕 PUNTO #7: Usar error específico
        emit(BackupError(_getSpecificErrorMessage('Failed to create backup')));
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error creating manual backup: $e');
      // 🆕 PUNTO #7: Usar error específico
      emit(BackupError(_getSpecificErrorMessage(e.toString())));
    }

    debugPrint('🏁 [BLOC] === FIN CreateManualBackup ===');
  }

  /// Restore from backup
  Future<void> _onRestoreFromBackup(
    RestoreFromBackup event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('🔄 [BLOC] === INICIANDO RestoreFromBackup ===');

    try {
      emit(const BackupRestoring());
      debugPrint('📥 [BLOC] Estado BackupRestoring emitido');

      final success = await _backupService.restoreBackup();
      debugPrint('📥 [BLOC] Resultado del restore: $success');

      if (success) {
        debugPrint('✅ [BLOC] Restore exitoso');

        // 🆕 ARREGLO: Reprogramar scheduler después de restore exitoso
        if (_schedulerService != null) {
          debugPrint(
              '🔧 [BLOC] Restore exitoso, reprogramando siguiente backup automático...');
          await _schedulerService!.scheduleAutomaticBackup();
          debugPrint('✅ [BLOC] Scheduler reprogramado después de restore');
        } else {
          debugPrint(
              '⚠️ [BLOC] Scheduler service no disponible para reprogramar');
        }

        emit(const BackupRestored());

        // Reload settings
        add(const LoadBackupSettings());
        debugPrint('🔄 [BLOC] Recargando configuraciones después de restore');
      } else {
        debugPrint('❌ [BLOC] Restore falló');
        // 🆕 PUNTO #7: Usar error específico
        emit(BackupError(_getSpecificErrorMessage('Failed to restore backup')));
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error restoring backup: $e');
      // 🆕 PUNTO #7: Usar error específico
      emit(BackupError(_getSpecificErrorMessage(e.toString())));
    }

    debugPrint('🏁 [BLOC] === FIN RestoreFromBackup ===');
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
      // 🆕 PUNTO #7: Usar error específico
      emit(BackupError(_getSpecificErrorMessage(e.toString())));
    }
  }

  /// Refresh backup status
  Future<void> _onRefreshBackupStatus(
    RefreshBackupStatus event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('🔄 [BLOC] Refrescando estado de backup');
    // Simply reload all settings
    add(const LoadBackupSettings());
  }

  /// Sign in to Google Drive
  Future<void> _onSignInToGoogleDrive(
    SignInToGoogleDrive event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('🔐 [BLOC] === INICIANDO SignInToGoogleDrive ===');

    try {
      emit(const BackupLoading());

      final success = await _backupService.signIn();
      debugPrint('🔐 [BLOC] Resultado sign-in: $success');

      // CAMBIO: Manejar cancelación de usuario (null)
      if (success == null) {
        debugPrint(
            '🔄 [DEBUG] Usuario canceló el sign-in - volviendo al estado anterior');
        // Simplemente recargar el estado anterior sin mostrar error
        add(const LoadBackupSettings());
        return;
      }

      if (success) {
        // ➕ ACTIVAR AUTO-BACKUP POR DEFECTO AL LOGUEAR
        final isAutoEnabled = await _backupService.isAutoBackupEnabled();
        if (!isAutoEnabled) {
          await _backupService.setAutoBackupEnabled(true);
          debugPrint('✅ [BLOC] Auto-backup activado automáticamente al login');

          // ➕ PROGRAMAR INMEDIATAMENTE
          if (_schedulerService != null) {
            await _schedulerService!.scheduleAutomaticBackup();
            debugPrint('✅ [BLOC] Backup automático programado tras login');
          }
        }

        // Check for existing backups
        final existingBackup = await _backupService.checkForExistingBackup();

        if (existingBackup != null && existingBackup['found'] == true) {
          emit(BackupExistingFound(existingBackup));
        } else {
          // Reload settings to get updated authentication status
          add(const LoadBackupSettings());
        }
      } else {
        debugPrint('❌ [BLOC] Sign-in falló');
        // 🆕 PUNTO #7: Usar error específico para autenticación
        emit(BackupError(_getSpecificErrorMessage('authentication failed')));
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error signing in to Google Drive: $e');
      // 🆕 PUNTO #7: Usar error específico
      emit(BackupError(_getSpecificErrorMessage(e.toString())));
    }

    debugPrint('🏁 [BLOC] === FIN SignInToGoogleDrive ===');
  }

  /// Sign out from Google Drive
  Future<void> _onSignOutFromGoogleDrive(
    SignOutFromGoogleDrive event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('🚪 [BLOC] === INICIANDO SignOutFromGoogleDrive ===');

    try {
      await _backupService.signOut();
      debugPrint('✅ [BLOC] Sign-out exitoso');

      // 🆕 ARREGLO: Cancelar backups programados al cerrar sesión
      if (_schedulerService != null) {
        debugPrint('🛑 [BLOC] Cancelando backups programados por sign-out...');
        await _schedulerService!.cancelAutomaticBackup();
        debugPrint('✅ [BLOC] Backups programados cancelados');
      }

      // Reload settings to get updated authentication status
      add(const LoadBackupSettings());
    } catch (e) {
      debugPrint('❌ [BLOC] Error signing out from Google Drive: $e');
      // 🆕 PUNTO #7: Usar error específico
      emit(BackupError(_getSpecificErrorMessage(e.toString())));
    }

    debugPrint('🏁 [BLOC] === FIN SignOutFromGoogleDrive ===');
  }

  /// Restore existing backup from Google Drive
  Future<void> _onRestoreExistingBackup(
    RestoreExistingBackup event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('📥 [BLOC] === INICIANDO RestoreExistingBackup ===');
    try {
      emit(const BackupRestoring());

      // Debug de parámetros que se van a pasar
      debugPrint(
          '🔧 [BLOC] DevocionalProvider disponible: ${_devocionalProvider != null}');
      debugPrint('📋 [BLOC] FileId para restore: ${event.fileId}');

      // CAMBIO PRINCIPAL: Pasar los parámetros necesarios
      final success = await _backupService.restoreExistingBackup(
        event.fileId,
        devocionalProvider: _devocionalProvider,
        prayerBloc: null,
      );

      debugPrint('📥 [BLOC] Resultado restore existente: $success');

      if (success) {
        debugPrint('✅ [BLOC] Restore existente exitoso');

        // Verificar si los providers fueron notificados correctamente
        if (_devocionalProvider != null) {
          debugPrint(
              '✅ [BLOC] DevocionalProvider fue pasado correctamente al restore');
        } else {
          debugPrint(
              '⚠️ [BLOC] ADVERTENCIA: DevocionalProvider es null - favoritos no se refrescarán automáticamente');
        }

        // ARREGLO: Reprogramar scheduler después de restore existente exitoso
        if (_schedulerService != null) {
          debugPrint(
              '🔧 [BLOC] Restore existente exitoso, reprogramando scheduler...');
          await _schedulerService!.scheduleAutomaticBackup();
          debugPrint(
              '✅ [BLOC] Scheduler reprogramado después de restore existente');
        }

        emit(const BackupRestored());

        // Reload settings to get updated data
        add(const LoadBackupSettings());
      } else {
        debugPrint('❌ [BLOC] Restore existente falló');
        // 🆕 PUNTO #7: Usar error específico
        emit(BackupError(_getSpecificErrorMessage('backup restore failed')));
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error restoring existing backup: $e');
      // 🆕 PUNTO #7: Usar error específico
      emit(BackupError(_getSpecificErrorMessage(e.toString())));
    }
    debugPrint('🏁 [BLOC] === FIN RestoreExistingBackup ===');
  }

  /// Skip restoring existing backup
  Future<void> _onSkipExistingBackup(
    SkipExistingBackup event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('⏭️ [BLOC] Saltando restore de backup existente');
    // Just reload settings without restoring
    add(const LoadBackupSettings());
  }
}
