import 'dart:io';

import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/i_analytics_service.dart';
import 'package:devocional_nuevo/services/auth_service.dart';
import 'package:devocional_nuevo/services/i_spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sets up Firebase Method Channel mocks to avoid initialization errors in tests
Future<void> setupFirebaseMocks() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/firebase_core',
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    if (methodCall.method == 'Firebase#initializeCore') {
      return [
        {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': '123',
            'appId': '123',
            'messagingSenderId': '123',
            'projectId': '123',
          },
          'pluginConstants': {
            'plugins.flutter.io/firebase_auth': {'persistence': 'local'},
          },
        },
      ];
    }
    if (methodCall.method == 'Firebase#initializeApp') {
      return {
        'name': '[DEFAULT]',
        'options': {
          'apiKey': '123',
          'appId': '123',
          'messagingSenderId': '123',
          'projectId': '123',
        },
        'pluginConstants': {},
      };
    }
    return null;
  });

  // Mock Firebase pigeon channel for core
  const MethodChannel pigeonChannel = MethodChannel(
    'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi',
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pigeonChannel, (MethodCall methodCall) async {
    if (methodCall.method == 'initializeCore') {
      return [
        {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': '123',
            'appId': '123',
            'messagingSenderId': '123',
            'projectId': '123',
          },
          'pluginConstants': {
            'core': {'version': '1.0.0'},
            'plugins.flutter.io/firebase_auth': {'persistence': 'local'},
          },
        },
      ];
    }
    if (methodCall.method == 'initializeApp') {
      return {
        'name': '[DEFAULT]',
        'options': {
          'apiKey': '123',
          'appId': '123',
          'messagingSenderId': '123',
          'projectId': '123',
        },
        'pluginConstants': {},
      };
    }
    if (methodCall.method == 'options') {
      return {
        'apiKey': '123',
        'appId': '123',
        'messagingSenderId': '123',
        'projectId': '123',
      };
    }
    return null;
  });

  // Mock Firebase Auth channel
  const MethodChannel authChannel = MethodChannel(
    'plugins.flutter.io/firebase_auth',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(authChannel, (MethodCall methodCall) async {
    if (methodCall.method == 'Auth#registerIdTokenListener') return null;
    if (methodCall.method == 'Auth#registerAuthStateListener') return null;
    if (methodCall.method == 'Auth#currentUser') {
      return {
        'uid': 'fake-uid',
        'email': 'test@example.com',
        'isAnonymous': false,
      };
    }
    return null;
  });

  // Mock Firebase Auth Pigeon channel
  const MethodChannel authPigeonChannel = MethodChannel(
    'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(authPigeonChannel, (
    MethodCall methodCall,
  ) async {
    return null;
  });

  // Mock Firebase Crashlytics
  const MethodChannel crashlyticsChannel = MethodChannel(
    'plugins.flutter.io/firebase_crashlytics',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(crashlyticsChannel, (call) async => null);

  // Mock Firebase Analytics
  const MethodChannel analyticsChannel = MethodChannel(
    'plugins.flutter.io/firebase_analytics',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(analyticsChannel, (call) async => null);

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: '123',
          appId: '123',
          messagingSenderId: '123',
          projectId: '123',
        ),
      );
    }
  } catch (e) {
    // If already initialized, ignore
  }
}

/// Sets up all required services for testing
/// This ensures tests have access to all necessary dependencies
Future<void> registerTestServices() async {
  ServiceLocator().reset();
  SharedPreferences.setMockInitialValues({});
  PathProviderPlatform.instance = MockPathProviderPlatform();
  await setupServiceLocator();
}

/// Sets up test services with fake implementations that don't require Firebase
/// Use this instead of registerTestServices() for widget tests that need analytics
Future<void> registerTestServicesWithFakes() async {
  ServiceLocator().reset();
  SharedPreferences.setMockInitialValues({});
  PathProviderPlatform.instance = MockPathProviderPlatform();
  await setupServiceLocator();

  // Override AnalyticsService with fake that doesn't require Firebase
  final locator = ServiceLocator();
  if (locator.isRegistered<IAnalyticsService>()) {
    locator.unregister<IAnalyticsService>();
  }
  locator.registerSingleton<IAnalyticsService>(FakeAnalyticsService());

  if (locator.isRegistered<IAuthService>()) {
    locator.unregister<IAuthService>();
  }
  locator.registerSingleton<IAuthService>(FakeAuthService());
}

/// Fake AnalyticsService that doesn't require Firebase initialization
/// Use this in widget tests to avoid Firebase initialization errors
class FakeAnalyticsService extends AnalyticsService
    implements IAnalyticsService {
  @override
  Future<void> logBottomBarAction({required String action}) async {
    // No-op for tests - don't actually log to Firebase
  }

  @override
  Future<void> logTtsPlay() async {}

  @override
  Future<void> logDevocionalComplete({
    required String devocionalId,
    required String campaignTag,
    String source = 'read',
    int? readingTimeSeconds,
    double? scrollPercentage,
    double? listenedPercentage,
  }) async {}

  @override
  Future<void> logNavigationNext({
    required int currentIndex,
    required int totalDevocionales,
    required String viaBloc,
    String? fallbackReason,
  }) async {}

  @override
  Future<void> logNavigationPrevious({
    required int currentIndex,
    required int totalDevocionales,
    required String viaBloc,
    String? fallbackReason,
  }) async {}

  @override
  Future<void> logFabTapped({required String source}) async {}

  @override
  Future<void> logFabChoiceSelected({
    required String source,
    required String choice,
  }) async {}

  @override
  Future<void> logDiscoveryAction({
    required String action,
    String? studyId,
  }) async {}

  @override
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> resetAnalyticsData() async {}

  @override
  Future<void> logAppInit({Map<String, Object>? parameters}) async {}

  @override
  Future<void> logBibleOpen({
    String? translation,
    String? book,
    int? chapter,
  }) async {}

  @override
  Future<void> logTtsBiblePlay({
    String? translation,
    String? book,
    int? chapter,
  }) async {}

  @override
  Future<void> logEncounterAction({
    required String action,
    String? encounterId,
    int? cardOrder,
  }) async {}
}

/// Fake AuthService for testing
class FakeAuthService implements IAuthService {
  @override
  String? get currentUserId => 'fake-uid';
}

/// Mock PathProvider for testing
/// Returns system temp directory for all path queries
class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }
}

/// Fake [ISpiritualStatsService] for tests that need a [PrayerBloc].
/// All methods are no-ops or return empty defaults.
class FakeSpiritualStatsService implements ISpiritualStatsService {
  @override
  Future<SpiritualStats> getStats() async => SpiritualStats();

  @override
  Future<void> saveStats(SpiritualStats stats) async {}

  @override
  Future<SpiritualStats> recordDevocionalRead({
    required String devocionalId,
    int? favoritesCount,
    int readingTimeSeconds = 0,
    double scrollPercentage = 0.0,
  }) async =>
      SpiritualStats();

  @override
  Future<SpiritualStats> recordDevocionalHeard({
    required String devocionalId,
    required double listenedPercentage,
    int? favoritesCount,
  }) async =>
      SpiritualStats();

  @override
  Future<SpiritualStats> recordDevocionalCompletado({
    required String devocionalId,
    int readingTimeSeconds = 0,
    double scrollPercentage = 0.0,
    double listenedPercentage = 0.0,
    int? favoritesCount,
    String source = 'unknown',
  }) async =>
      SpiritualStats();

  @override
  Future<Map<String, dynamic>> getAllStats() async => {};

  @override
  Future<void> restoreStats(Map<String, dynamic> backupData) async {}

  @override
  Future<bool> isJsonBackupEnabled() async => false;

  @override
  Future<void> setJsonBackupEnabled(bool enabled) async {}

  @override
  Future<bool> hasDevocionalBeenRead(String devocionalId) async => false;

  @override
  Future<List<DateTime>> getReadDatesForVisualization() async => [];

  @override
  Future<void> resetStats() async {}

  @override
  Future<String?> exportStatsAsJson() async => null;

  @override
  Future<bool> importStatsFromJson(String jsonString) async => false;

  @override
  Future<String?> getBackupFilePath() async => null;

  @override
  Future<SpiritualStats> updateFavoritesCount(int favoritesCount) async =>
      SpiritualStats();

  @override
  Future<SpiritualStats> updateAnsweredPrayersCount(
    int answeredPrayersCount,
  ) async =>
      SpiritualStats();

  @override
  Future<bool> createManualBackup() async => false;

  @override
  Future<void> bulkMarkAsRead(List<String> ids) async {}
}
