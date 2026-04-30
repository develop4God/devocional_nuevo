// lib/blocs/backup_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/devocional_provider.dart';
import '../services/backup/i_google_drive_backup_service.dart';
import 'backup_event.dart';
import 'backup_state.dart';
import 'devocionales/devocionales_navigation_bloc.dart';
import 'devocionales/devocionales_navigation_event.dart';
import 'discovery/discovery_bloc.dart';
import 'discovery/discovery_event.dart';
import 'encounter/encounter_bloc.dart';
import 'encounter/encounter_event.dart';
import 'package:devocional_nuevo/utils/constants/constants.dart';

/// BLoC for managing Google Drive backup functionality
class BackupBloc extends Bloc<BackupEvent, BackupState> {
  final IGoogleDriveBackupService _backupService;
  DevocionalProvider? _devocionalProvider;
  final DiscoveryBloc? _discoveryBloc;
  final EncounterBloc? _encounterBloc;
  final DevocionalesNavigationBloc? _navigationBloc;

  BackupBloc({
    required IGoogleDriveBackupService backupService,
    DevocionalProvider? devocionalProvider,
    DiscoveryBloc? discoveryBloc,
    EncounterBloc? encounterBloc,
    DevocionalesNavigationBloc? navigationBloc,
    dynamic prayerBloc,
  })  : _backupService = backupService,
        _devocionalProvider = devocionalProvider,
        _discoveryBloc = discoveryBloc,
        _encounterBloc = encounterBloc,
        _navigationBloc = navigationBloc,
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
    on<RefreshBackupStatus>(_onRefreshBackupStatus);
    on<SignInToGoogleDrive>(_onSignInToGoogleDrive);
    on<SignOutFromGoogleDrive>(_onSignOutFromGoogleDrive);
    on<CheckStartupBackup>(_onCheckStartupBackup);
    debugPrint('[BACKUP] 🔨 BackupBloc constructed, firing CheckStartupBackup');
    add(const CheckStartupBackup());
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
    debugPrint('🔄 [BLOC] === START LoadBackupSettings ===');

    try {
      emit(const BackupLoading());

      final isAuthenticated = await _backupService.isAuthenticated();
      debugPrint('📊 [BLOC] Authenticated: $isAuthenticated');

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

      debugPrint('📊 [BLOC] Settings loaded:');
      debugPrint('📊 [BLOC] - Auto backup: ${results[0]}');
      debugPrint('📊 [BLOC] - Frequency: ${results[1]}');
      debugPrint('📊 [BLOC] - Last backup: ${results[5]}');
      debugPrint('📊 [BLOC] - Next backup: ${results[6]}');

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
          isAuthenticated: isAuthenticated,
          userEmail: results[8] as String?,
        ),
      );

      debugPrint('✅ [BLOC] BackupLoaded emitted successfully');
    } catch (e) {
      debugPrint('❌ [BLOC] Error loading backup settings: $e');
      emit(BackupError('Error loading backup settings: ${e.toString()}'));
    }

    debugPrint('🏁 [BLOC] === END LoadBackupSettings ===');
  }

  /// Toggle automatic backup
  Future<void> _onToggleAutoBackup(
    ToggleAutoBackup event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint(
      '🔄 [BLOC] === START ToggleAutoBackup: ${event.enabled} ===',
    );

    try {
      await _backupService.setAutoBackupEnabled(event.enabled);

      if (event.enabled) {
        final currentFrequency = await _backupService.getBackupFrequency();
        debugPrint('🔍 [BLOC] Current frequency: $currentFrequency');

        if (currentFrequency == kBackupFrequencyDeactivated) {
          debugPrint(
            '🔧 [BLOC] Auto-backup activated with frequency "deactivated", changing to "daily"',
          );
          await _backupService.setBackupFrequency(
            kBackupFrequencyDaily,
          );
          debugPrint('✅ [BLOC] Frequency auto-changed to "daily"');
        }
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

    debugPrint('🏁 [BLOC] === END ToggleAutoBackup ===');
  }

  /// Change backup frequency
  Future<void> _onChangeBackupFrequency(
    ChangeBackupFrequency event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint(
        '🔄 [BLOC] === START ChangeBackupFrequency: ${event.frequency} ===');

    try {
      // Sign out first — if this throws, frequency is not persisted,
      // avoiding an inconsistent state (deactivated frequency + failed sign out).
      if (event.frequency == kBackupFrequencyDeactivated) {
        debugPrint('🚪 [BLOC] Frequency deactivated, signing out...');
        await _backupService.signOut();
      }

      await _backupService.setBackupFrequency(event.frequency);

      if (state is BackupLoaded) {
        final currentState = state as BackupLoaded;
        final nextBackupTime = await _backupService.getNextBackupTime();
        debugPrint('📊 [BLOC] Next backup recalculated: $nextBackupTime');

        emit(
          currentState.copyWith(
            backupFrequency: event.frequency,
            nextBackupTime: nextBackupTime,
            isAuthenticated: event.frequency == kBackupFrequencyDeactivated
                ? false
                : currentState.isAuthenticated,
          ),
        );
      } else {
        add(const LoadBackupSettings());
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error changing backup frequency: $e');
      emit(BackupError('Error changing backup frequency: ${e.toString()}'));
    }

    debugPrint('🏁 [BLOC] === END ChangeBackupFrequency ===');
  }

  /// Toggle WiFi-only backup
  Future<void> _onToggleWifiOnly(
    ToggleWifiOnly event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('🔄 [BLOC] === START ToggleWifiOnly: ${event.enabled} ===');

    try {
      await _backupService.setWifiOnlyEnabled(event.enabled);

      if (state is BackupLoaded) {
        final currentState = state as BackupLoaded;
        emit(currentState.copyWith(wifiOnlyEnabled: event.enabled));
      } else {
        add(const LoadBackupSettings());
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error toggling WiFi only: $e');
      emit(BackupError('Error updating WiFi setting: ${e.toString()}'));
    }

    debugPrint('🏁 [BLOC] === END ToggleWifiOnly ===');
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
    debugPrint('🚀 [BLOC] === START CreateManualBackup ===');

    try {
      emit(const BackupCreating());
      debugPrint('📤 [BLOC] BackupCreating state emitted');

      final success = await _backupService.createBackup(_devocionalProvider);
      debugPrint('📤 [BLOC] Backup result: $success');

      if (success) {
        final timestamp = DateTime.now();
        debugPrint('✅ [BLOC] Manual backup successful at: $timestamp');

        emit(BackupCreated(timestamp));
        add(const LoadBackupSettings());
        debugPrint('🔄 [BLOC] Reloading settings to refresh times');
      } else {
        debugPrint('❌ [BLOC] Manual backup failed');
        emit(const BackupError('Failed to create backup'));
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error creating manual backup: $e');
      emit(BackupError('Error creating backup: ${e.toString()}'));
    }

    debugPrint('🏁 [BLOC] === END CreateManualBackup ===');
  }

  /// Restore from backup
  Future<void> _onRestoreFromBackup(
    RestoreFromBackup event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('🔄 [BLOC] === START RestoreFromBackup ===');

    try {
      emit(const BackupRestoring());
      debugPrint('📥 [BLOC] BackupRestoring state emitted');

      // Combined callback: reload favorites AND spiritual stats after restore.
      // Both must be called so that the provider notifies widgets of
      // newly-restored read IDs and favourite lists simultaneously.
      final onRestored = _devocionalProvider != null
          ? () async {
              await _devocionalProvider!.reloadVersionFromStorage();
              await _devocionalProvider!.reloadFavoritesFromStorage();
              await _devocionalProvider!.reloadSpiritualStatsFromStorage();
              debugPrint(
                '✅ [BLOC] Provider reloaded: version + favorites + spiritual stats',
              );
            }
          : null;

      final success = await _backupService.restoreBackup(
        onRestored: onRestored,
      );
      debugPrint('📥 [BLOC] Restore result: $success');

      if (success) {
        debugPrint('✅ [BLOC] Restore successful');
        debugPrint(
            '📊 [BLOC] Provider stats updated — UI rebuilds with restored data');

        // Reload discovery and encounter state
        _discoveryBloc?.add(RefreshDiscoveryStudies(forceRefresh: true));
        if (_discoveryBloc != null) {
          debugPrint('🔄 [BLOC] RefreshDiscoveryStudies event dispatched');
        }

        _encounterBloc?.add(LoadEncounterIndex(forceRefresh: true));
        if (_encounterBloc != null) {
          debugPrint('🔄 [BLOC] LoadEncounterIndex event dispatched');
        }

        // Recalculate current devotional index from restored read IDs
        if (_navigationBloc != null && _devocionalProvider != null) {
          _navigationBloc!.add(NavigateToFirstUnread(
            _devocionalProvider!.lastRestoredReadIds.toList(),
          ));
          debugPrint(
            '🧭 [BLOC] NavigateToFirstUnread dispatched — ${_devocionalProvider!.lastRestoredReadIds.length} read IDs',
          );
        }

        final prefs = await SharedPreferences.getInstance();
        final restoredVersion = prefs.getString('selectedVersion');
        emit(BackupRestored(restoredVersion: restoredVersion));
        add(const LoadBackupSettings());
        debugPrint('🔄 [BLOC] Reloading settings after restore');
      } else {
        debugPrint('❌ [BLOC] Restore failed');
        emit(const BackupError('Failed to restore backup'));
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error restoring backup: $e');
      emit(BackupError('Error restoring backup: ${e.toString()}'));
    }

    debugPrint('🏁 [BLOC] === END RestoreFromBackup ===');
  }

  /// Load storage information

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
    debugPrint('🔐 [BLOC] === START SignInToGoogleDrive ===');

    try {
      emit(const BackupSigningIn());

      final success = await _backupService.signIn();
      debugPrint('🔐 [BLOC] Sign-in result: $success');

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
          debugPrint('✅ [BLOC] Auto-backup enabled automatically on login');
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
            prayerBloc: null,
          );

          if (restored) {
            debugPrint('✅ [BLOC] Data restored automatically');

            // Reload discovery and encounter state
            _discoveryBloc?.add(RefreshDiscoveryStudies(forceRefresh: true));
            if (_discoveryBloc != null) {
              debugPrint(
                  '🔄 [BLOC] RefreshDiscoveryStudies event dispatched (login restore)');
            }

            _encounterBloc?.add(LoadEncounterIndex(forceRefresh: true));
            if (_encounterBloc != null) {
              debugPrint(
                  '🔄 [BLOC] LoadEncounterIndex event dispatched (login restore)');
            }

            // Reload provider state: version + favorites + spiritual stats
            await _devocionalProvider?.reloadVersionFromStorage();
            await _devocionalProvider?.reloadFavoritesFromStorage();
            await _devocionalProvider?.reloadSpiritualStatsFromStorage();
            debugPrint(
              '✅ [BLOC] Provider reloaded: version + favorites + spiritual stats (sign-in restore)',
            );

            // Recalculate current devotional index from restored read IDs
            if (_navigationBloc != null && _devocionalProvider != null) {
              _navigationBloc!.add(NavigateToFirstUnread(
                _devocionalProvider!.lastRestoredReadIds.toList(),
              ));
              debugPrint(
                '🧭 [BLOC] NavigateToFirstUnread dispatched (sign-in restore) — ${_devocionalProvider!.lastRestoredReadIds.length} read IDs',
              );
            }

            emit(
              const BackupSuccess(
                'backup.sign_in_success',
                'backup.restored_successfully',
              ),
            );
          } else {
            debugPrint('❌ [BLOC] Error in automatic restore');
            emit(const BackupError('backup.restore_failed'));
          }
        } else {
          // No existing backup — create the first one immediately
          debugPrint('📤 [BLOC] No backup found, creating initial backup...');
          await _backupService.createBackup(_devocionalProvider);
          debugPrint('✅ [BLOC] Initial backup created');
          emit(
            const BackupSuccess(
              'backup.sign_in_success',
              'backup.created_successfully',
            ),
          );
        }

        // Recargar configuración después de 2 segundos
        await Future.delayed(const Duration(seconds: 2));
        add(const LoadBackupSettings());
      } else {
        debugPrint('❌ [BLOC] Sign-in failed');
        emit(const BackupError('backup.sign_in_failed'));
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error signing in to Google Drive: $e');
      emit(BackupError('backup.sign_in_failed'));
    }

    debugPrint('🏁 [BLOC] === END SignInToGoogleDrive ===');
  }

  /// Sign out from Google Drive
  Future<void> _onSignOutFromGoogleDrive(
    SignOutFromGoogleDrive event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('🚪 [BLOC] === START SignOutFromGoogleDrive ===');

    try {
      await _backupService.signOut();
      debugPrint('✅ [BLOC] Sign-out successful');

      add(const LoadBackupSettings());
    } catch (e) {
      debugPrint('❌ [BLOC] Error signing out from Google Drive: $e');
      emit(BackupError('Error signing out: ${e.toString()}'));
    }

    debugPrint('🏁 [BLOC] === END SignOutFromGoogleDrive ===');
  }

  /// Check and execute startup backup if interval has elapsed
  Future<void> _onCheckStartupBackup(
    CheckStartupBackup event,
    Emitter<BackupState> emit,
  ) async {
    debugPrint('🌅 [BLOC] === START CheckStartupBackup ===');

    try {
      debugPrint('[BACKUP] checking auto enabled...');
      final isAutoEnabled = await _backupService.isAutoBackupEnabled();
      final isAuthenticated = await _backupService.isAuthenticated();

      if (!isAutoEnabled || !isAuthenticated) {
        debugPrint('⚠️ [BLOC] Auto backup disabled or not authenticated');
        return;
      }

      final lastBackupTime = await _backupService.getLastBackupTime();
      final now = DateTime.now();

      if (lastBackupTime != null) {
        final forceBypass = event.forceBypass;
        final hoursSinceLastBackup = now.difference(lastBackupTime).inHours;
        debugPrint('⏰ [BLOC] Hours since last backup: $hoursSinceLastBackup');

        if (forceBypass ||
            hoursSinceLastBackup >= BackupSchedule.intervalHours) {
          debugPrint(
              '🚀 [BLOC] ${BackupSchedule.intervalHours}+ hours (or forced), executing startup backup');

          final success = await _backupService.createBackup(
            _devocionalProvider,
          );

          if (success) {
            debugPrint('✅ [BLOC] Startup backup successful');
            add(const LoadBackupSettings());
          }
        }
      } else {
        debugPrint('🎯 [BLOC] No previous backup — creating initial');
        final success = await _backupService.createBackup(_devocionalProvider);
        if (success) {
          add(const LoadBackupSettings());
        }
      }
    } catch (e) {
      debugPrint('❌ [BLOC] Error in startup backup: $e');
    }

    debugPrint('🏁 [BLOC] === END CheckStartupBackup ===');
  }
}
