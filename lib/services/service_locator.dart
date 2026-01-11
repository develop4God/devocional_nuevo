// ignore_for_file: dangling_library_doc_comments
/// Service Locator for Dependency Injection
///
/// This provides a simple, agnostic DI container that works with any state management
/// solution including BLoC, Riverpod, Provider, GetIt, etc.
///
/// Usage:
/// - Call `setupServiceLocator()` once at app startup
/// - Access services via `ServiceLocator.get<ServiceType>()`
/// - For testing, use `ServiceLocator.registerFactory()` to inject mocks
///
/// Note: Services like LocalizationService, VoiceSettingsService, TtsService,
/// and AnalyticsService are registered here instead of using static singletons
/// to enable proper DI and testing.
library;

import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'package:devocional_nuevo/services/remote_config_service.dart';
import 'package:devocional_nuevo/services/tts/i_tts_service.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:http/http.dart' as http;

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic Function()> _factories = {};
  final Map<Type, dynamic> _singletons = {};

  /// Register a factory function for a service type
  /// The factory will be called each time get() is called
  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  /// Register a singleton instance
  /// The same instance will be returned each time get() is called
  void registerSingleton<T>(T instance) {
    _singletons[T] = instance;
  }

  /// Register a lazy singleton (created on first access)
  void registerLazySingleton<T>(T Function() factory) {
    _factories[T] = () {
      if (!_singletons.containsKey(T)) {
        _singletons[T] = factory();
      }
      return _singletons[T];
    };
  }

  /// Get an instance of the requested service type
  /// Throws [StateError] if service is not registered
  T get<T>() {
    // Check singletons first
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }

    // Check factories
    if (_factories.containsKey(T)) {
      return _factories[T]!() as T;
    }

    throw StateError(
      'Service ${T.toString()} not registered. '
      'Ensure setupServiceLocator() is called at app startup.',
    );
  }

  /// Check if a service is registered
  bool isRegistered<T>() {
    return _factories.containsKey(T) || _singletons.containsKey(T);
  }

  /// Clear all registrations (useful for testing)
  void reset() {
    _factories.clear();
    _singletons.clear();
  }

  /// Remove a specific registration
  void unregister<T>() {
    _factories.remove(T);
    _singletons.remove(T);
  }
}

/// Setup all services for the application
/// Call this once at app startup, before any service is used
void setupServiceLocator() {
  final locator = ServiceLocator();

  // Register LocalizationService as a lazy singleton (created when first accessed)
  // This replaces the previous static singleton pattern to enable proper DI and testing.
  // See LocalizationService documentation for usage details.
  locator.registerLazySingleton<LocalizationService>(
    () => LocalizationService(),
  );

  // Register VoiceSettingsService as a lazy singleton (created when first accessed)
  // This must be registered before TtsService as TtsService depends on it
  locator.registerLazySingleton<VoiceSettingsService>(
    () => VoiceSettingsService(),
  );

  // Register TTS service as a lazy singleton (created when first accessed)
  locator.registerLazySingleton<ITtsService>(() => TtsService());

  // Register Analytics service as a lazy singleton (created when first accessed)
  // This service tracks user events and behaviors using Firebase Analytics
  locator.registerLazySingleton<AnalyticsService>(() => AnalyticsService());

  // Register NotificationService as a lazy singleton (created when first accessed)
  // This service manages FCM, local notifications, and notification settings
  // Migrated from singleton pattern to DI for better testability and maintainability
  // Uses factory constructor to enforce DI-only instantiation
  locator.registerLazySingleton<NotificationService>(
    NotificationService.create,
  );

  // Register RemoteConfigService as a lazy singleton (created when first accessed)
  // This service manages feature flags from Firebase Remote Config
  // Migrated to DI pattern for better testability and maintainability
  // Uses factory constructor to enforce DI-only instantiation
  locator.registerLazySingleton<RemoteConfigService>(
    RemoteConfigService.create,
  );

  // Register DiscoveryRepository as a lazy singleton (created when first accessed)
  // This repository manages fetching Discovery studies from GitHub with caching
  locator.registerLazySingleton<DiscoveryRepository>(
    () => DiscoveryRepository(httpClient: http.Client()),
  );

  // Register DiscoveryProgressTracker as a lazy singleton (created when first accessed)
  // This service tracks user progress through Discovery studies
  locator.registerLazySingleton<DiscoveryProgressTracker>(
    () => DiscoveryProgressTracker(),
  );

  // Add more service registrations here as needed
  // Example:
  // locator.registerFactory<IApiClient>(() => ApiClient());
}

/// Convenience getter for accessing the service locator
ServiceLocator get serviceLocator => ServiceLocator();

/// Convenience function for getting services
T getService<T>() => ServiceLocator().get<T>();
