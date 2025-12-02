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
library;

import 'package:devocional_nuevo/services/tts/i_tts_service.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:devocional_nuevo/services/tts_service.dart';

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
  T get<T>() {
    // Check singletons first
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }

    // Check factories
    if (_factories.containsKey(T)) {
      return _factories[T]!() as T;
    }

    throw Exception(
        'Service of type $T not registered. Call registerFactory or registerSingleton first.');
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

  // Register VoiceSettingsService as a lazy singleton (created when first accessed)
  // This must be registered before TtsService as TtsService depends on it
  locator.registerLazySingleton<VoiceSettingsService>(
      () => VoiceSettingsService());

  // Register TTS service as a lazy singleton (created when first accessed)
  locator.registerLazySingleton<ITtsService>(() => TtsService());

  // Add more service registrations here as needed
  // Example:
  // locator.registerLazySingleton<IAnalyticsService>(() => AnalyticsService());
  // locator.registerFactory<IApiClient>(() => ApiClient());
}

/// Convenience getter for accessing the service locator
ServiceLocator get serviceLocator => ServiceLocator();

/// Convenience function for getting services
T getService<T>() => ServiceLocator().get<T>();
