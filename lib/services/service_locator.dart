// ignore_for_file: dangling_library_doc_comments
/// Service Locator for Dependency Injection
library;

import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/discovery_favorites_service.dart'; // NEW
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

  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  void registerSingleton<T>(T instance) {
    _singletons[T] = instance;
  }

  void registerLazySingleton<T>(T Function() factory) {
    _factories[T] = () {
      if (!_singletons.containsKey(T)) {
        _singletons[T] = factory();
      }
      return _singletons[T];
    };
  }

  T get<T>() {
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }
    if (_factories.containsKey(T)) {
      return _factories[T]!() as T;
    }
    throw StateError(
        'Service ${T.toString()} not registered. Did you forget to call setupServiceLocator() in main()?');
  }

  bool isRegistered<T>() =>
      _factories.containsKey(T) || _singletons.containsKey(T);
  void reset() {
    _factories.clear();
    _singletons.clear();
  }

  void unregister<T>() {
    _factories.remove(T);
    _singletons.remove(T);
  }
}

void setupServiceLocator() {
  final locator = ServiceLocator();

  locator
      .registerLazySingleton<LocalizationService>(() => LocalizationService());
  locator.registerLazySingleton<VoiceSettingsService>(
      () => VoiceSettingsService());
  locator.registerLazySingleton<ITtsService>(() => TtsService());
  locator.registerLazySingleton<AnalyticsService>(() => AnalyticsService());
  locator
      .registerLazySingleton<NotificationService>(NotificationService.create);
  locator
      .registerLazySingleton<RemoteConfigService>(RemoteConfigService.create);
  locator.registerLazySingleton<http.Client>(() => http.Client());

  locator.registerLazySingleton<DiscoveryRepository>(
    () => DiscoveryRepository(httpClient: locator.get<http.Client>()),
  );

  locator.registerLazySingleton<DiscoveryProgressTracker>(
      () => DiscoveryProgressTracker());

  // ✅ REGISTER DISCOVERY FAVORITES SERVICE
  locator.registerLazySingleton<DiscoveryFavoritesService>(
      () => DiscoveryFavoritesService());
}

ServiceLocator get serviceLocator => ServiceLocator._instance;
T getService<T>() => ServiceLocator().get<T>();
