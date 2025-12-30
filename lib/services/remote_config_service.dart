// lib/services/remote_config_service.dart
//
// RemoteConfigService - Migrated to Dependency Injection
// This service manages feature flags from Firebase Remote Config.
// It is registered in ServiceLocator as a lazy singleton for better
// testability and maintainability.
//
// IMPORTANT: Private Constructor Pattern
// Direct instantiation is prevented to enforce DI usage.
// The constructor is private and can only be accessed via the factory method.
//
// Usage:
//   final remoteConfigService = getService<RemoteConfigService>();
//   await remoteConfigService.initialize();
//
// DO NOT attempt direct instantiation:
//   ❌ final service = RemoteConfigService(); // COMPILE ERROR - constructor is private
//
// ALWAYS use ServiceLocator:
//   ✅ final service = getService<RemoteConfigService>();
//   ✅ final service = ServiceLocator().get<RemoteConfigService>();

import 'dart:developer' as developer;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class RemoteConfigService {
  // Firebase Remote Config instance (injected for testability)
  final FirebaseRemoteConfig _remoteConfig;

  // Flag to track initialization status
  bool _isInitialized = false;

  // Flag to track ready status (for async initialization)
  bool _isReady = false;

  // Private constructor to prevent direct instantiation
  // Always use getService<RemoteConfigService>() or ServiceLocator.get<RemoteConfigService>()
  // Receives FirebaseRemoteConfig for dependency injection (testability)
  RemoteConfigService._({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  // Factory constructor for ServiceLocator registration
  // Allows optional injection of FirebaseRemoteConfig for testing
  factory RemoteConfigService.create({FirebaseRemoteConfig? remoteConfig}) {
    return RemoteConfigService._(remoteConfig: remoteConfig);
  }

  /// Check if Remote Config is ready to use
  bool get isReady => _isReady;

  /// Initialize Remote Config with default values
  /// This should be called once at app startup, before runApp
  Future<void> initialize() async {
    if (_isInitialized) {
      developer.log(
        'RemoteConfigService: Already initialized, skipping...',
        name: 'RemoteConfigService',
      );
      return;
    }

    try {
      developer.log(
        'RemoteConfigService: Initializing with default values...',
        name: 'RemoteConfigService',
      );

      // Set default values for feature flags
      await _remoteConfig.setDefaults({
        'feature_legacy': false,
        'feature_bloc': false,
      });

      // Configure Remote Config settings with adaptive fetch interval
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // Debug: 1 min for testing, Prod: 12 hours (Google recommendation)
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 1)
              : const Duration(hours: 12),
        ),
      );

      // Fetch and activate remote values
      final activated = await _remoteConfig.fetchAndActivate();

      _isInitialized = true;
      _isReady = true; // Mark as ready for use

      developer.log(
        'RemoteConfigService: Initialized successfully. New values activated: $activated',
        name: 'RemoteConfigService',
      );
      developer.log(
        'RemoteConfigService: feature_legacy = $featureLegacy',
        name: 'RemoteConfigService',
      );
      developer.log(
        'RemoteConfigService: feature_bloc = $featureBloc',
        name: 'RemoteConfigService',
      );
    } catch (e, stack) {
      developer.log(
        'RemoteConfigService: Failed to initialize',
        name: 'RemoteConfigService',
        error: e,
        stackTrace: stack,
      );
      // Use defaults on error but still mark as ready
      _isInitialized = true;
      _isReady = true; // Ready to use defaults
    }
  }

  /// Get feature_legacy flag value
  /// Returns false if not initialized or on error
  bool get featureLegacy {
    try {
      return _remoteConfig.getBool('feature_legacy');
    } catch (e) {
      developer.log(
        'RemoteConfigService: Error reading feature_legacy, using default: false',
        name: 'RemoteConfigService',
        error: e,
      );
      return false;
    }
  }

  /// Get feature_bloc flag value
  /// Returns false if not initialized or on error
  bool get featureBloc {
    try {
      return _remoteConfig.getBool('feature_bloc');
    } catch (e) {
      developer.log(
        'RemoteConfigService: Error reading feature_bloc, using default: false',
        name: 'RemoteConfigService',
        error: e,
      );
      return false;
    }
  }

  /// Refresh remote config values on demand
  /// Useful for testing or manual refresh
  Future<void> refresh() async {
    try {
      developer.log(
        'RemoteConfigService: Refreshing remote config...',
        name: 'RemoteConfigService',
      );

      final activated = await _remoteConfig.fetchAndActivate();

      developer.log(
        'RemoteConfigService: Refresh completed. New values activated: $activated',
        name: 'RemoteConfigService',
      );
      developer.log(
        'RemoteConfigService: feature_legacy = $featureLegacy',
        name: 'RemoteConfigService',
      );
      developer.log(
        'RemoteConfigService: feature_bloc = $featureBloc',
        name: 'RemoteConfigService',
      );
    } catch (e, stack) {
      developer.log(
        'RemoteConfigService: Failed to refresh',
        name: 'RemoteConfigService',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Reset initialization status (for testing)
  void resetForTesting() {
    _isInitialized = false;
    _isReady = false;
    developer.log(
      'RemoteConfigService: Reset for testing',
      name: 'RemoteConfigService',
    );
  }
}
