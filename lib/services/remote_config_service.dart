// lib/services/remote_config_service.dart
//
// RemoteConfigService - reads Firebase Remote Config flags.
// Registered in ServiceLocator as a lazy singleton for testability.
//
// Usage:
//   final remoteConfigService = getService<RemoteConfigService>();
//   await remoteConfigService.initialize();
//
// ALWAYS use ServiceLocator:
//   ✅ final service = getService<RemoteConfigService>();
//   ❌ final service = RemoteConfigService(); // COMPILE ERROR - constructor is private

import 'dart:developer' as developer;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  bool _isInitialized = false;
  bool _isReady = false;

  RemoteConfigService._({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  factory RemoteConfigService.create({FirebaseRemoteConfig? remoteConfig}) {
    return RemoteConfigService._(remoteConfig: remoteConfig);
  }

  /// Check if Remote Config is ready to use
  bool get isReady => _isReady;

  /// Initialize Remote Config with default values.
  /// Should be called once at app startup, before runApp.
  Future<void> initialize() async {
    if (_isInitialized) {
      developer.log(
        'RemoteConfigService: Already initialized, skipping...',
        name: 'RemoteConfigService',
      );
      return;
    }

    try {
      await _remoteConfig.setDefaults({
        'enable_onboarding_flow': false,
      });

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // Debug: 1 min for testing, Prod: 12 hours (Google recommendation)
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 1)
              : const Duration(hours: 12),
        ),
      );

      await _remoteConfig.fetchAndActivate();

      _isInitialized = true;
      _isReady = true;
    } catch (e, stack) {
      developer.log(
        'RemoteConfigService: Failed to initialize',
        name: 'RemoteConfigService',
        error: e,
        stackTrace: stack,
      );
      // Use defaults on error but still mark as ready
      _isInitialized = true;
      _isReady = true;
    }
  }

  /// Get enable_onboarding_flow flag value.
  /// Returns false if not initialized or on error.
  bool get enableOnboardingFlow {
    try {
      return _remoteConfig.getBool('enable_onboarding_flow');
    } catch (e) {
      developer.log(
        'RemoteConfigService: Error reading enable_onboarding_flow, using default: false',
        name: 'RemoteConfigService',
        error: e,
      );
      return false;
    }
  }
}
