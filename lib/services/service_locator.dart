// ignore_for_file: dangling_library_doc_comments
/// Service Locator for Dependency Injection
library;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/debug/i_debug_spiritual_stats_service.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:devocional_nuevo/repositories/devocional_repository_impl.dart';
import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:devocional_nuevo/repositories/encounter_repository.dart';
import 'package:devocional_nuevo/repositories/i_prayer_wall_repository.dart';
import 'package:devocional_nuevo/repositories/prayer_wall_repository.dart';
import 'package:devocional_nuevo/services/auth_service.dart';
import 'package:devocional_nuevo/services/cache_metadata_service.dart';
import 'package:devocional_nuevo/services/devocional_index_service.dart';
import 'package:devocional_nuevo/repositories/i_supporter_profile_repository.dart';
import 'package:devocional_nuevo/repositories/supporter_profile_repository.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/i_analytics_service.dart';
import 'package:devocional_nuevo/services/backup/connectivity_service.dart';
import 'package:devocional_nuevo/services/deep_link_handler.dart';
import 'package:devocional_nuevo/services/discovery_favorites_service.dart'; // NEW
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:devocional_nuevo/services/encounter_progress_service.dart';
import 'package:devocional_nuevo/services/backup/google_drive_auth_service.dart';
import 'package:devocional_nuevo/services/backup/google_drive_backup_service.dart';
import 'package:devocional_nuevo/services/backup/i_backup_settings_service.dart';
import 'package:devocional_nuevo/services/backup/backup_settings_service.dart';
import 'package:devocional_nuevo/services/i_connectivity_service.dart';
import 'package:devocional_nuevo/services/i_encounter_progress_service.dart';
import 'package:devocional_nuevo/services/backup/i_google_drive_auth_service.dart';
import 'package:devocional_nuevo/services/backup/i_google_drive_backup_service.dart';
import 'package:devocional_nuevo/services/i_spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/i_startup_migration_service.dart';
import 'package:devocional_nuevo/services/iap/i_iap_service.dart';
import 'package:devocional_nuevo/services/iap/iap_service.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/i_localization_service.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'package:devocional_nuevo/services/remote_config_service.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/startup_migration_service.dart';
import 'package:devocional_nuevo/services/supporter_pet_service.dart';
import 'package:devocional_nuevo/services/tts/i_tts_service.dart';
import 'package:devocional_nuevo/services/tts/utils/tts_chunk_processor.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
      'Service ${T.toString()} not registered. Did you forget to call setupServiceLocator() in main()?',
    );
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

Future<void> setupServiceLocator() async {
  final locator = ServiceLocator();
  final prefs = await SharedPreferences.getInstance();

  locator.registerSingleton<SharedPreferences>(prefs);

  locator.registerLazySingleton<IAuthService>(() => FirebaseAuthService());

  locator.registerLazySingleton<LocalizationService>(
    () => LocalizationService(),
  );
  locator.registerSingleton<ILocalizationService>(
    locator.get<LocalizationService>(),
  );
  locator.registerLazySingleton<VoiceSettingsService>(
    () => VoiceSettingsService(),
  );
  locator.registerLazySingleton<TtsChunkProcessor>(() => TtsChunkProcessor());
  locator.registerLazySingleton<ITtsService>(() => TtsService());
  locator.registerLazySingleton<IAnalyticsService>(() => AnalyticsService());
  locator.registerLazySingleton<NotificationService>(
    NotificationService.create,
  );
  locator.registerLazySingleton<RemoteConfigService>(
    RemoteConfigService.create,
  );
  locator.registerLazySingleton<http.Client>(() => http.Client());

  locator.registerLazySingleton<BaseCacheManager>(() => DefaultCacheManager());

  locator.registerLazySingleton<DiscoveryRepository>(
    () => DiscoveryRepository(httpClient: locator.get<http.Client>()),
  );

  locator.registerLazySingleton<EncounterRepository>(
    () => EncounterRepository(httpClient: locator.get<http.Client>()),
  );

  locator.registerLazySingleton<IEncounterProgressService>(
    () => EncounterProgressService(),
  );

  locator.registerLazySingleton<IVerseResolverService>(
    () => VerseResolverService(),
  );

  locator.registerLazySingleton<DiscoveryProgressTracker>(
    () => DiscoveryProgressTracker(),
  );

  // ✅ REGISTER DISCOVERY FAVORITES SERVICE
  locator.registerLazySingleton<DiscoveryFavoritesService>(
    () => DiscoveryFavoritesService(),
  );

  // ✅ REGISTER IAP SERVICE
  locator.registerLazySingleton<IIapService>(() => IapService());

  // ✅ REGISTER SUPPORTER PROFILE REPOSITORY (via interface — DIP)
  locator.registerLazySingleton<ISupporterProfileRepository>(
    () => SupporterProfileRepository(),
  );

  // ✅ REGISTER SPIRITUAL STATS SERVICE
  // Concrete instance created once; registered under both interfaces so
  // production code (ISpiritualStatsService) and debug widgets
  // (IDebugSpiritualStatsService) share the same singleton — no cast required.
  final statsService = SpiritualStatsService();
  locator.registerSingleton<ISpiritualStatsService>(statsService);
  locator.registerSingleton<IDebugSpiritualStatsService>(statsService);
  locator.registerLazySingleton<IStartupMigrationService>(
    () => StartupMigrationService(
      statsService: locator.get<ISpiritualStatsService>(),
    ),
  );

  // ✅ REGISTER CONNECTIVITY SERVICE (via interface)
  locator.registerLazySingleton<IConnectivityService>(
    () => ConnectivityService(),
  );

  // ✅ REGISTER GOOGLE DRIVE AUTH SERVICE (via interface)
  locator.registerLazySingleton<IGoogleDriveAuthService>(
    () => GoogleDriveAuthService(prefs: locator.get<SharedPreferences>()),
  );

  // ✅ REGISTER GOOGLE DRIVE BACKUP SERVICE (via interface)
  locator.registerLazySingleton<IBackupSettingsService>(
    () => BackupSettingsService(),
  );

  locator.registerLazySingleton<IGoogleDriveBackupService>(
    () => GoogleDriveBackupService(
      authService: locator.get<IGoogleDriveAuthService>(),
      connectivityService: locator.get<IConnectivityService>(),
      statsService: locator.get<ISpiritualStatsService>(),
      localizationService: locator.get<ILocalizationService>(),
      settingsService: locator.get<IBackupSettingsService>(),
    ),
  );

  locator.registerLazySingleton<SupporterPetService>(
    () => SupporterPetService(locator.get<SharedPreferences>()),
  );

  // ✅ REGISTER DEEP LINK HANDLER
  locator.registerLazySingleton<DeepLinkHandler>(() => DeepLinkHandler());

  // ✅ REGISTER DEVOCIONAL INDEX SERVICE (factory — new instance each time)
  locator.registerFactory<DevocionalIndexService>(
    () => DevocionalIndexService(locator.get<http.Client>()),
  );

  // ✅ REGISTER CACHE METADATA SERVICE (factory — new instance each time)
  locator.registerFactory<CacheMetadataService>(() => CacheMetadataService());

  // ✅ REGISTER PRAYER WALL REPOSITORY (via interface — DIP)
  locator.registerLazySingleton<IPrayerWallRepository>(
    () => PrayerWallRepository(),
  );

  // ✅ REGISTER DEVOCIONAL REPOSITORY (via interface — DIP)
  locator.registerLazySingleton<DevocionalRepository>(
    () => DevocionalRepositoryImpl(httpClient: locator.get<http.Client>()),
  );
}

ServiceLocator get serviceLocator => ServiceLocator._instance;

T getService<T>() => ServiceLocator().get<T>();
