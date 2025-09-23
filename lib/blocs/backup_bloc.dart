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
    dynamic prayerBloc,
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

      final isAuthenticated = await _backupService.isAuthenticated();
      debugPrint('📊 [BLOC] Autenticado: $isAuthenticated');

      Map<String, dynamic> storageInfo = {};
      if (isAuthenticated) {
        storageInfo = await _backupService.getStorageInfo();
        debugPrint('📊 [BLOC] Storage info cargado');
      }

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

      emit(
        BackupLoaded(
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
        ),
      );

      debugPrint('✅ [BLOC] BackupLoaded emitido exitosamente');
    } catch (e) {
      debugPrint('❌ [BLOC] Error loading backup settings: $e');
      emit(BackupError('Error loading backup settings: ${e.toString()}'));
    }

    debugPrint('🏁 [BLOC] === FIN LoadBackupSettings ===');
  }

  /// Toggle automatic backup
  Future<void> _onToggleAutoBackup(
    ToggleAutoBackup event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint(
      '🔄 [BLOC] === INICIANDO ToggleAutoBackup: ${event.enabled} ===',
    );

    try {
      await _backupService.setAutoBackupEnabled(event.enabled);

      if (event.enabled) {
        final currentFrequency = await _backupService.getBackupFrequency();
        debugPrint('🔍 [BLOC] Frecuencia actual: $currentFrequency');

        if (currentFrequency == GoogleDriveBackupService.frequencyDeactivated) {
          debugPrint(
            '🔧 [BLOC] Auto-backup activado con frecuencia "deactivated", cambiando a "daily"',
          );
          await _backupService.setBackupFrequency(
            GoogleDriveBackupService.frequencyDaily,
          );
          debugPrint('✅ [BLOC] Frecuencia cambiada automáticamente a "daily"');
        }
      }

      if (_schedulerService != null) {
        debugPrint('🔧 [BLOC] Auto backup cambió, actualizando scheduler...');
        await _schedulerService!.scheduleAutomaticBackup();
        debugPrint('✅ [BLOC] Scheduler actualizado por toggle auto backup');
      } else {
        debugPrint('⚠️ [BLOC] Scheduler service no disponible');
      }

      if (state is BackupLoaded) {
        final currentState = state as BackupLoaded;
        final updatedFrequency = await _backupService.getBackupFrequency();
        final nextBackupTime = await _backupService.getNextBackupTime();
        debugPrint('📊 [BLOC] Nuevo próximo backup: $nextBackupTime');

        emit(
          currentState.copyWith(
            autoBackupEnabled: event.enabled,
            backupFrequency: updatedFrequency,
            nextBackupTime: nextBackupTime,
          ),
        );
      } else {
        add(const LoadBackupSettings());
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error toggling auto backup: $e');
      emit(BackupError('Error updating auto backup: ${e.toString()}'));
    }

    debugPrint('🏁 [BLOC] === FIN ToggleAutoBackup ===');
  }

  /// Change backup frequency
  Future<void> _onChangeBackupFrequency(
    ChangeBackupFrequency event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint(
      '🔄 [BLOC] === INICIANDO ChangeBackupFrequency: ${event.frequency} ===',
    );

    try {
      await _backupService.setBackupFrequency(event.frequency);

      if (event.frequency == GoogleDriveBackupService.frequencyDeactivated) {
        debugPrint('🚪 [BLOC] Frecuencia desactivada, cerrando sesión...');
        await _backupService.signOut();
      }

      if (_schedulerService != null) {
        debugPrint(
          '🔧 [BLOC] Frecuencia cambió a ${event.frequency}, reprogramando scheduler...',
        );
        await _schedulerService!.scheduleAutomaticBackup();
        debugPrint('✅ [BLOC] Scheduler reprogramado por cambio de frecuencia');
      } else {
        debugPrint(
          '⚠️ [BLOC] Scheduler service no disponible para reprogramar',
        );
      }

      if (state is BackupLoaded) {
        final currentState = state as BackupLoaded;
        final nextBackupTime = await _backupService.getNextBackupTime();
        debugPrint('📊 [BLOC] Próximo backup recalculado: $nextBackupTime');

        final isAuthenticated =
            event.frequency == GoogleDriveBackupService.frequencyDeactivated
                ? false
                : currentState.isAuthenticated;

        emit(
          currentState.copyWith(
            backupFrequency: event.frequency,
            nextBackupTime: nextBackupTime,
            isAuthenticated: isAuthenticated,
          ),
        );
      } else {
        add(const LoadBackupSettings());
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error changing backup frequency: $e');
      emit(BackupError('Error updating backup frequency: ${e.toString()}'));
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
        final estimatedSize = await _backupService.getEstimatedBackupSize(
          _devocionalProvider,
        );

        emit(
          currentState.copyWith(
            backupOptions: event.options,
            estimatedSize: estimatedSize,
          ),
        );
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
    debugPrint('🚀 [BLOC] === INICIANDO CreateManualBackup ===');

    try {
      emit(const BackupCreating());
      debugPrint('📤 [BLOC] Estado BackupCreating emitido');

      final success = await _backupService.createBackup(_devocionalProvider);
      debugPrint('📤 [BLOC] Resultado del backup: $success');

      if (success) {
        final timestamp = DateTime.now();
        debugPrint('✅ [BLOC] Backup manual exitoso en: $timestamp');

        if (_schedulerService != null) {
          debugPrint(
            '🔧 [BLOC] Backup manual exitoso, reprogramando siguiente backup automático...',
          );
          await _schedulerService!.scheduleAutomaticBackup();
          debugPrint(
            '✅ [BLOC] Scheduler reprogramado después de backup manual',
          );
        } else {
          debugPrint(
            '⚠️ [BLOC] Scheduler service no disponible para reprogramar',
          );
        }

        emit(BackupCreated(timestamp));
        add(const LoadBackupSettings());
        debugPrint(
          '🔄 [BLOC] Recargando configuraciones para actualizar tiempos',
        );
      } else {
        debugPrint('❌ [BLOC] Backup manual falló');
        emit(const BackupError('Failed to create backup'));
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error creating manual backup: $e');
      emit(BackupError('Error creating backup: ${e.toString()}'));
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

        if (_schedulerService != null) {
          debugPrint(
            '🔧 [BLOC] Restore exitoso, reprogramando siguiente backup automático...',
          );
          await _schedulerService!.scheduleAutomaticBackup();
          debugPrint('✅ [BLOC] Scheduler reprogramado después de restore');
        } else {
          debugPrint(
            '⚠️ [BLOC] Scheduler service no disponible para reprogramar',
          );
        }

        emit(const BackupRestored());
        add(const LoadBackupSettings());
        debugPrint('🔄 [BLOC] Recargando configuraciones después de restore');
      } else {
        debugPrint('❌ [BLOC] Restore falló');
        emit(const BackupError('Failed to restore backup'));
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error restoring backup: $e');
      emit(BackupError('Error restoring backup: ${e.toString()}'));
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
      emit(BackupError('Error loading storage info: ${e.toString()}'));
    }
  }

  /// Refresh backup status
  Future<void> _onRefreshBackupStatus(
    RefreshBackupStatus event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('🔄 [BLOC] Refrescando estado de backup');
    add(const LoadBackupSettings());
  }

  /// Sign in to Google Drive - METODO ACTUALIZADO CON RESTAURACIÓN AUTOMÁTICA
  Future<void> _onSignInToGoogleDrive(
    SignInToGoogleDrive event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('🔐 [BLOC] === INICIANDO SignInToGoogleDrive ===');

    try {
      emit(const BackupLoading());

      final success = await _backupService.signIn();
      debugPrint('🔐 [BLOC] Resultado sign-in: $success');

      if (success == null) {
        debugPrint(
          '🔄 [DEBUG] Usuario canceló el sign-in - volviendo al estado anterior',
        );
        add(const LoadBackupSettings());
        return;
      }

      if (success) {
        // Activar auto-backup por defecto
        final isAutoEnabled = await _backupService.isAutoBackupEnabled();
        if (!isAutoEnabled) {
          await _backupService.setAutoBackupEnabled(true);
          debugPrint('✅ [BLOC] Auto-backup activado automáticamente al login');

          if (_schedulerService != null) {
            await _schedulerService!.scheduleAutomaticBackup();
            debugPrint('✅ [BLOC] Backup automático programado tras login');
          }
        }

        // RESTAURACIÓN AUTOMÁTICA - SIN INTERVENCIÓN DEL USUARIO
        final existingBackup = await _backupService.checkForExistingBackup();

        if (existingBackup != null && existingBackup['found'] == true) {
          debugPrint(
            '📥 [BLOC] Backup existente encontrado, restaurando automáticamente...',
          );
          emit(const BackupRestoring());

          final restored = await _backupService.restoreExistingBackup(
            existingBackup['fileId'],
            devocionalProvider: _devocionalProvider,
            prayerBloc: null,
          );

          if (restored) {
            debugPrint('✅ [BLOC] Datos restaurados automáticamente');

            // 🔧 ARREGLO: Programar scheduler después de restauración automática
            if (_schedulerService != null) {
              debugPrint(
                '🔧 [BLOC] Restauración exitosa, programando scheduler...',
              );
              await _schedulerService!.scheduleAutomaticBackup();
              debugPrint(
                '✅ [BLOC] Scheduler programado después de restauración automática',
              );
            } else {
              debugPrint(
                '⚠️ [BLOC] Scheduler service no disponible después de restore',
              );
            }

            emit(
              const BackupSuccess(
                'backup.sign_in_success',
                'backup.restored_successfully',
              ),
            );
          } else {
            debugPrint('❌ [BLOC] Error en restauración automática');
            emit(const BackupError('backup.restore_failed'));
          }
        }

        // Recargar configuración después de 2 segundos
        await Future.delayed(const Duration(seconds: 2));
        add(const LoadBackupSettings());
      } else {
        debugPrint('❌ [BLOC] Sign-in falló');
        emit(const BackupError('backup.sign_in_failed'));
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error signing in to Google Drive: $e');
      emit(BackupError('backup.sign_in_failed'));
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

      if (_schedulerService != null) {
        debugPrint('🛑 [BLOC] Cancelando backups programados por sign-out...');
        await _schedulerService!.cancelAutomaticBackup();
        debugPrint('✅ [BLOC] Backups programados cancelados');
      }

      add(const LoadBackupSettings());
    } catch (e) {
      debugPrint('❌ [BLOC] Error signing out from Google Drive: $e');
      emit(BackupError('Error signing out: ${e.toString()}'));
    }

    debugPrint('🏁 [BLOC] === FIN SignOutFromGoogleDrive ===');
  }
}
