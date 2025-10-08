// lib/services/onboarding_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for managing onboarding state
class OnboardingService {
  // Singleton pattern
  static final OnboardingService _instance = OnboardingService._internal();

  static OnboardingService get instance => _instance;

  OnboardingService._internal();

  // Keys for SharedPreferences
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _onboardingVersionKey = 'onboarding_version';
  static const String _onboardingInProgressKey =
      'onboarding_in_progress'; // 🔧 NUEVO

  // Current onboarding version
  static const int _currentVersion = 1;

  /// Check if onboarding has been completed
  Future<bool> isOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();

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
            '✅ [OnboardingService] Onboarding completado (v$savedVersion)');
        return true;
      }

      // If version mismatch, user needs to go through onboarding again
      if (isComplete && savedVersion != _currentVersion) {
        debugPrint(
            '🔄 [OnboardingService] Nueva versión de onboarding disponible: v$savedVersion -> v$_currentVersion');
        return false;
      }

      debugPrint('📊 [OnboardingService] Onboarding no completado');
      return false;
    } catch (e) {
      debugPrint('❌ [OnboardingService] Error checking onboarding status: $e');
      return false;
    }
  }

  /// Mark onboarding as complete
  Future<void> setOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, true);
      await prefs.setInt(_onboardingVersionKey, _currentVersion);
      await prefs.remove(
          _onboardingInProgressKey); // 🔧 NUEVO: Limpiar flag de progreso
      debugPrint(
          '✅ [OnboardingService] Onboarding marcado como completado (v$_currentVersion)');
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
            '🚀 [OnboardingService] Onboarding marcado como en progreso');
      } else {
        await prefs.remove(_onboardingInProgressKey);
        debugPrint(
            '✅ [OnboardingService] Flag de onboarding en progreso eliminado');
      }
    } catch (e) {
      debugPrint(
          '❌ [OnboardingService] Error setting onboarding in progress: $e');
    }
  }

  /// Reset onboarding (for testing purposes)
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
          '❌ [OnboardingService] Error checking onboarding in progress: $e');
      return false;
    }
  }

  /// 🔧 NUEVO: NO restaurar el estado de onboarding desde backup si está en progreso
  /// Este metodo debe ser llamado desde GoogleDriveBackupService al restaurar
  Future<bool> shouldRestoreOnboardingState() async {
    final inProgress = await isOnboardingInProgress();
    if (inProgress) {
      debugPrint(
          '⚠️ [OnboardingService] Saltando restauración de onboarding - proceso en curso');
      return false;
    }
    return true;
  }

  /// Check if we should show onboarding flow
  //flag off for now
  /*Future<bool> shouldShowOnboarding() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();
      final enableOnboarding = remoteConfig.getBool('enable_onboarding_flow');

      final isComplete = await isOnboardingComplete();
      return enableOnboarding && !isComplete;
    } catch (e) {
      debugPrint('❌ [OnboardingService] Error reading remote config: $e');
      return !(await isOnboardingComplete());
    }
  }*/

  /// Get the current onboarding version
  /*int get currentVersion => _currentVersion;

  /// Check if user needs to see updated onboarding
  Future<bool> needsOnboardingUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
      final savedVersion = prefs.getInt(_onboardingVersionKey) ?? 0;

      // User needs update if completed old version
      return isComplete && savedVersion < _currentVersion;
    } catch (e) {
      debugPrint(
          '❌ [OnboardingService] Error checking for onboarding update: $e');
      return false;
    }
  }*/
  Future<bool> shouldShowOnboarding() async {
    // Onboarding permanently disabled (forced)
    return false;
  }
}
