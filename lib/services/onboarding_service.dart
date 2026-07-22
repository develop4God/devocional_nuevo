// lib/services/onboarding_service.dart
import 'dart:convert';

import 'package:devocional_nuevo/blocs/onboarding/onboarding_models.dart';
import 'package:devocional_nuevo/services/i_spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/remote_config_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for managing onboarding state
///
/// Registered in ServiceLocator as a lazy singleton.
/// Usage: `getService<OnboardingService>()`
class OnboardingService {
  final RemoteConfigService _remoteConfigService;
  final ISpiritualStatsService _statsService;

  OnboardingService._({
    required RemoteConfigService remoteConfigService,
    required ISpiritualStatsService statsService,
  })  : _remoteConfigService = remoteConfigService,
        _statsService = statsService;

  factory OnboardingService.create({
    required RemoteConfigService remoteConfigService,
    required ISpiritualStatsService statsService,
  }) {
    return OnboardingService._(
      remoteConfigService: remoteConfigService,
      statsService: statsService,
    );
  }

  // Keys for SharedPreferences
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _onboardingVersionKey = 'onboarding_version';
  static const String _onboardingInProgressKey =
      'onboarding_in_progress'; // 🔧 NUEVO
  static const String _onboardingBackfillAppliedKey =
      'onboarding_backfill_applied';

  // Current onboarding version
  static const int _currentVersion = 1;

  // Onboarding didn't exist for most of this app's lifetime, so no existing
  // user has ever completed it. Reuses the same "engaged user" threshold
  // already established by InAppReviewService's first-time milestone check
  // (5+ devotionals read) to avoid showing onboarding to people who installed
  // the app long before this flow existed.
  static const int _existingUserDevocionalThreshold = 5;

  // Configuration/progress persistence keys
  static const String _configurationKey = 'onboarding_configuration';
  static const String _progressKey = 'onboarding_progress';

  // Schema versioning for configuration/progress persistence migration
  static const int _currentSchemaVersion = 1;

  Future<void>? _writeQueue;

  /// Serializes SharedPreferences writes so concurrent saveConfiguration()/
  /// saveProgress() calls don't interleave.
  Future<T> _serialized<T>(Future<T> Function() operation) {
    final previous = _writeQueue ?? Future.value();
    final result = previous.then((_) => operation());
    _writeQueue = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Check if onboarding has been completed.
  ///
  /// Side effect: on the first call ever made to this method (or any method
  /// that calls it, e.g. [shouldShowOnboarding]), it also runs the one-time
  /// [_backfillExistingUser] migration, which may write to SharedPreferences.
  /// Safe to call from multiple sites — the write is idempotent and guarded.
  Future<bool> isOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await _serialized(() => _backfillExistingUser(prefs));

      // 🔧 NUEVO: Si el onboarding está en progreso, retornar false
      final inProgress = prefs.getBool(_onboardingInProgressKey) ?? false;
      if (inProgress) {
        debugPrint('📊 [OnboardingService] Onboarding en progreso detectado');
        return false;
      }

      final isComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
      final savedVersion = prefs.getInt(_onboardingVersionKey) ?? 0;

      // Check if onboarding was completed and version matches
      if (isComplete && savedVersion == _currentVersion) {
        debugPrint(
          '✅ [OnboardingService] Onboarding completado (v$savedVersion)',
        );
        return true;
      }

      // If version mismatch, user needs to go through onboarding again
      if (isComplete && savedVersion != _currentVersion) {
        debugPrint(
          '🔄 [OnboardingService] Nueva versión de onboarding disponible: v$savedVersion -> v$_currentVersion',
        );
        return false;
      }

      debugPrint('📊 [OnboardingService] Onboarding no completado');
      return false;
    } catch (e) {
      debugPrint('❌ [OnboardingService] Error checking onboarding status: $e');
      return false;
    }
  }

  /// One-time backfill for users who installed the app before onboarding
  /// existed. If the device already has real reading history, mark
  /// onboarding as complete so it isn't shown retroactively once
  /// enable_onboarding_flow is turned on. Runs at most once per device,
  /// guarded by [_onboardingBackfillAppliedKey].
  Future<void> _backfillExistingUser(SharedPreferences prefs) async {
    if (prefs.getBool(_onboardingBackfillAppliedKey) ?? false) return;

    try {
      final stats = await _statsService.getStats();
      if (stats.totalDevocionalesRead >= _existingUserDevocionalThreshold) {
        await prefs.setBool(_onboardingCompleteKey, true);
        await prefs.setInt(_onboardingVersionKey, _currentVersion);
        debugPrint(
          '🔄 [OnboardingService] Backfilled onboarding_complete for '
          'existing user (${stats.totalDevocionalesRead} devotionals read)',
        );
      }
    } catch (e) {
      debugPrint('❌ [OnboardingService] Error backfilling existing user: $e');
    } finally {
      await prefs.setBool(_onboardingBackfillAppliedKey, true);
    }
  }

  /// Mark onboarding as complete
  Future<void> setOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, true);
      await prefs.setInt(_onboardingVersionKey, _currentVersion);
      await prefs.remove(
        _onboardingInProgressKey,
      ); // 🔧 NUEVO: Limpiar flag de progreso
      debugPrint(
        '✅ [OnboardingService] Onboarding marcado como completado (v$_currentVersion)',
      );
    } catch (e) {
      debugPrint('❌ [OnboardingService] Error setting onboarding complete: $e');
    }
  }

  /// 🔧 NUEVO: Marcar que el onboarding está en progreso
  Future<void> setOnboardingInProgress(bool inProgress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (inProgress) {
        await prefs.setBool(_onboardingInProgressKey, true);
        debugPrint(
          '🚀 [OnboardingService] Onboarding marcado como en progreso',
        );
      } else {
        await prefs.remove(_onboardingInProgressKey);
        debugPrint(
          '✅ [OnboardingService] Flag de onboarding en progreso eliminado',
        );
      }
    } catch (e) {
      debugPrint(
        '❌ [OnboardingService] Error setting onboarding in progress: $e',
      );
    }
  }

  /// Reset onboarding (for testing purposes)
  ///
  /// Deliberately does NOT remove [_onboardingBackfillAppliedKey]: on a
  /// device with real reading history, clearing it would let
  /// [_backfillExistingUser] immediately re-mark onboarding as complete on
  /// the next check, defeating the point of a manual QA reset.
  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompleteKey);
      await prefs.remove(_onboardingVersionKey);
      await prefs.remove(_onboardingInProgressKey); // 🔧 NUEVO
      debugPrint('🔄 [OnboardingService] Onboarding reset completado');
    } catch (e) {
      debugPrint('❌ [OnboardingService] Error resetting onboarding: $e');
    }
  }

  /// 🔧 NUEVO: Verificar si el onboarding está en progreso
  Future<bool> isOnboardingInProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingInProgressKey) ?? false;
    } catch (e) {
      debugPrint(
        '❌ [OnboardingService] Error checking onboarding in progress: $e',
      );
      return false;
    }
  }

  /// 🔧 NUEVO: NO restaurar el estado de onboarding desde backup si está en progreso
  /// Este metodo debe ser llamado desde GoogleDriveBackupService al restaurar
  Future<bool> shouldRestoreOnboardingState() async {
    final inProgress = await isOnboardingInProgress();
    if (inProgress) {
      debugPrint(
        '⚠️ [OnboardingService] Saltando restauración de onboarding - proceso en curso',
      );
      return false;
    }
    return true;
  }

  /// Check if we should show onboarding flow.
  /// Gated by the enable_onboarding_flow remote config flag and whether
  /// the user has already completed onboarding.
  Future<bool> shouldShowOnboarding() async {
    try {
      if (!_remoteConfigService.isReady) return false;
      if (!_remoteConfigService.enableOnboardingFlow) return false;
      return !(await isOnboardingComplete());
    } catch (e) {
      debugPrint('❌ [OnboardingService] Error reading remote config: $e');
      return false;
    }
  }

  /// Load saved onboarding configuration from SharedPreferences
  Future<Map<String, dynamic>> loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configurationKey);

      if (configJson != null) {
        Map<String, dynamic> wrapper;
        try {
          wrapper = jsonDecode(configJson) as Map<String, dynamic>;
        } catch (e) {
          debugPrint(
            '❌ [OnboardingService] Corrupted JSON detected in configuration: $e',
          );
          debugPrint(
            '🔄 [OnboardingService] Clearing corrupted configuration data',
          );
          await prefs.remove(_configurationKey);
          return {};
        }

        final schemaVersion = wrapper['schemaVersion'] as int? ?? 0;
        Map<String, dynamic> config =
            wrapper['payload'] as Map<String, dynamic>? ?? wrapper;

        if (schemaVersion < _currentSchemaVersion) {
          debugPrint(
            '🔄 [OnboardingService] Configuration migrated from v$schemaVersion to v$_currentSchemaVersion',
          );
          await saveConfiguration(config);
        }

        debugPrint(
          '📊 [OnboardingService] Configuración cargada: ${config.keys}',
        );
        return config;
      }
    } catch (e) {
      debugPrint(
        '⚠️ [OnboardingService] Error loading saved configuration: $e',
      );
      debugPrint('🔄 [OnboardingService] Falling back to empty configuration');
    }
    return {};
  }

  /// Save onboarding configuration to SharedPreferences with schema versioning
  Future<void> saveConfiguration(Map<String, dynamic> configuration) {
    return _serialized(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final wrapper = {
          'schemaVersion': _currentSchemaVersion,
          'payload': configuration,
        };
        await prefs.setString(_configurationKey, jsonEncode(wrapper));
        debugPrint(
          '💾 [OnboardingService] Configuración guardada: ${configuration.keys}',
        );
      } catch (e) {
        debugPrint('⚠️ [OnboardingService] Error saving configuration: $e');
      }
    });
  }

  /// Clear saved onboarding configuration
  Future<void> clearConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_configurationKey);
      debugPrint('🗑️ [OnboardingService] Configuración limpiada');
    } catch (e) {
      debugPrint('⚠️ [OnboardingService] Error clearing configuration: $e');
    }
  }

  /// Load saved onboarding progress from SharedPreferences
  Future<OnboardingProgress?> loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_progressKey);

      if (progressJson != null) {
        Map<String, dynamic> wrapper;
        try {
          wrapper = jsonDecode(progressJson) as Map<String, dynamic>;
        } catch (e) {
          debugPrint(
            '❌ [OnboardingService] Corrupted JSON detected in progress: $e',
          );
          debugPrint('🔄 [OnboardingService] Clearing corrupted progress data');
          await prefs.remove(_progressKey);
          return null;
        }

        if (!_isValidProgressStructure(wrapper)) {
          debugPrint(
            '⚠️ [OnboardingService] Invalid progress structure detected, falling back to defaults',
          );
          await prefs.remove(_progressKey);
          return null;
        }

        final schemaVersion = wrapper['schemaVersion'] as int? ?? 0;
        Map<String, dynamic> progressData =
            wrapper['payload'] as Map<String, dynamic>? ?? wrapper;

        if (schemaVersion < _currentSchemaVersion) {
          progressData = _migrateProgress(progressData, schemaVersion);
          debugPrint(
            '🔄 [OnboardingService] Progress migrated from v$schemaVersion to v$_currentSchemaVersion',
          );
        }

        final progress = OnboardingProgress.fromJson(progressData);
        debugPrint(
          '📊 [OnboardingService] Progreso cargado: ${progress.completedSteps}/${progress.totalSteps}',
        );
        return progress;
      }
    } catch (e) {
      debugPrint('⚠️ [OnboardingService] Error loading saved progress: $e');
      debugPrint('🔄 [OnboardingService] Falling back to null progress');
    }
    return null;
  }

  /// Save onboarding progress to SharedPreferences with schema versioning
  Future<void> saveProgress(OnboardingProgress progress) {
    return _serialized(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final wrapper = {
          'schemaVersion': _currentSchemaVersion,
          'payload': progress.toJson(),
        };
        await prefs.setString(_progressKey, jsonEncode(wrapper));
        debugPrint(
          '💾 [OnboardingService] Progreso guardado: ${progress.completedSteps}/${progress.totalSteps}',
        );
      } catch (e) {
        debugPrint('⚠️ [OnboardingService] Error saving progress: $e');
      }
    });
  }

  /// Clear saved onboarding progress
  Future<void> clearProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey);
      debugPrint('🗑️ [OnboardingService] Progreso limpiado');
    } catch (e) {
      debugPrint('⚠️ [OnboardingService] Error clearing progress: $e');
    }
  }

  /// Migrate progress data from older schema versions
  Map<String, dynamic> _migrateProgress(
    Map<String, dynamic> progressData,
    int fromVersion,
  ) {
    debugPrint(
      '🔄 [OnboardingService] Migrating progress from version $fromVersion to $_currentSchemaVersion',
    );

    try {
      Map<String, dynamic> migratedProgress = Map<String, dynamic>.from(
        progressData,
      );

      if (fromVersion < 1) {
        migratedProgress['totalSteps'] ??= 4;
        migratedProgress['completedSteps'] ??= 0;
        migratedProgress['stepCompletionStatus'] ??= List<bool>.filled(
          4,
          false,
        );
        migratedProgress['progressPercentage'] ??= 0.0;
        debugPrint('✅ [OnboardingService] Progress migration v0->v1 completed');
      }

      return migratedProgress;
    } catch (e) {
      debugPrint('❌ [OnboardingService] Progress migration failed: $e');
      debugPrint(
        '🔄 [OnboardingService] Falling back to original progress data',
      );
      return progressData;
    }
  }

  /// Validate progress JSON structure
  bool _isValidProgressStructure(Map<String, dynamic> data) {
    try {
      if (data.containsKey('schemaVersion') && data.containsKey('payload')) {
        final payload = data['payload'];
        if (payload is! Map<String, dynamic>) return false;
        return _isValidProgressPayload(payload);
      }
      return _isValidProgressPayload(data);
    } catch (e) {
      debugPrint(
        '❌ [OnboardingService] Progress structure validation failed: $e',
      );
      return false;
    }
  }

  /// Validate progress payload structure
  bool _isValidProgressPayload(Map<String, dynamic> payload) {
    const requiredKeys = [
      'totalSteps',
      'completedSteps',
      'stepCompletionStatus',
      'progressPercentage',
    ];

    for (final key in requiredKeys) {
      if (!payload.containsKey(key)) {
        debugPrint('❌ [OnboardingService] Missing required progress key: $key');
        return false;
      }
    }

    if (payload['totalSteps'] is! int || payload['completedSteps'] is! int) {
      debugPrint('❌ [OnboardingService] Invalid progress step count types');
      return false;
    }

    if (payload['stepCompletionStatus'] is! List ||
        payload['progressPercentage'] is! num) {
      debugPrint('❌ [OnboardingService] Invalid progress data types');
      return false;
    }

    return true;
  }
}
