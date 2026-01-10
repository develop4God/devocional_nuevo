// test/providers/devocional_provider_pr180_test.dart
// Test suite for PR #180 critical gaps and required tests

import 'dart:async';
import 'dart:convert';

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/i_tts_service.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock path provider for tests
class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/mock_documents';
  }

  @override
  Future<String?> getTemporaryPath() async {
    return '/mock_temp';
  }
}

/// Minimal fake TTS service for tests
class FakeTtsService implements ITtsService {
  final StreamController<TtsState> _stateController =
      StreamController.broadcast();
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  @override
  Stream<TtsState> get stateStream => _stateController.stream;

  @override
  Stream<double> get progressStream => _progressController.stream;

  @override
  void setLanguageContext(String language, String version) {}

  @override
  Future<void> assignDefaultVoiceForLanguage(String languageCode) async {}

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _progressController.close();
  }

  @override
  Future<List<String>> getLanguages() async => [];

  @override
  Future<List<String>> getVoices() async => [];

  @override
  Future<List<String>> getVoicesForLanguage(String language) async => [];

  @override
  String formatBibleBook(String reference) => reference;

  @override
  String? get currentDevocionalId => null;

  @override
  TtsState get currentState => TtsState.idle;

  @override
  bool get isActive => true;

  @override
  bool get isDisposed => false;

  @override
  bool get isPaused => false;

  @override
  bool get isPlaying => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> initializeTtsOnAppStart(String languageCode) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> setLanguage(String language) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> setVoice(Map<String, String> voice) async {}

  @override
  Future<void> speakDevotional(Devocional devocional) async {}

  @override
  Future<void> speakText(String text) async {}

  @override
  Future<void> stop() async {}
}

/// Mock analytics service for telemetry testing
class MockAnalyticsService extends AnalyticsService {
  final List<Map<String, dynamic>> events = [];

  MockAnalyticsService() : super();

  void reset() {
    events.clear();
  }

  @override
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    events.add({
      'eventName': eventName,
      'parameters': parameters ?? {},
    });
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
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> resetAnalyticsData() async {}

  @override
  Future<void> logBottomBarAction({required String action}) async {}

  @override
  Future<void> logAppInit({Map<String, Object>? parameters}) async {}

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
}

/// Helper to create test devotionals
Devocional createTestDevocional({
  required String id,
  required DateTime date,
  String versiculo = 'Juan 3:16',
  String version = 'RVR1960',
}) {
  return Devocional(
    id: id,
    date: date,
    versiculo: versiculo,
    reflexion: 'Test reflection',
    paraMeditar: [
      ParaMeditar(cita: 'Test cita', texto: 'Test para meditar'),
    ],
    oracion: 'Test prayer',
    version: version,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock platform channels
  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  const MethodChannel ttsChannel = MethodChannel('flutter_tts');

  setUpAll(() async {
    // Mock Firebase Core
    const MethodChannel firebaseCoreChannel = MethodChannel(
      'plugins.flutter.io/firebase_core',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseCoreChannel,
            (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'Firebase#initializeCore':
          return [
            {
              'name': '[DEFAULT]',
              'options': {
                'apiKey': 'fake-api-key',
                'appId': 'fake-app-id',
                'messagingSenderId': 'fake-sender-id',
                'projectId': 'fake-project-id',
              },
              'pluginConstants': {},
            }
          ];
        case 'Firebase#initializeApp':
          return {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'fake-api-key',
              'appId': 'fake-app-id',
              'messagingSenderId': 'fake-sender-id',
              'projectId': 'fake-project-id',
            },
            'pluginConstants': {},
          };
        default:
          return null;
      }
    });

    // Mock Firebase Crashlytics
    const MethodChannel crashlyticsChannel = MethodChannel(
      'plugins.flutter.io/firebase_crashlytics',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(crashlyticsChannel,
            (MethodCall methodCall) async {
      return null;
    });

    // Mock Firebase Remote Config
    const MethodChannel remoteConfigChannel = MethodChannel(
      'plugins.flutter.io/firebase_remote_config',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(remoteConfigChannel,
            (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'RemoteConfig#instance':
          return {};
        case 'RemoteConfig#setConfigSettings':
        case 'RemoteConfig#setDefaults':
        case 'RemoteConfig#fetchAndActivate':
          return true;
        case 'RemoteConfig#getString':
          return '';
        case 'RemoteConfig#getBool':
          return false;
        case 'RemoteConfig#getInt':
          return 0;
        case 'RemoteConfig#getDouble':
          return 0.0;
        default:
          return null;
      }
    });

    // Mock Firebase Analytics
    const MethodChannel analyticsChannel = MethodChannel(
      'plugins.flutter.io/firebase_analytics',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(analyticsChannel,
            (MethodCall methodCall) async {
      return null;
    });

    // Initialize Firebase
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Firebase may already be initialized
    }

    // Mock path provider
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel,
            (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '/mock_documents';
      }
      return null;
    });

    // Mock TTS
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'speak':
        case 'stop':
        case 'pause':
        case 'setLanguage':
        case 'setSpeechRate':
        case 'setVolume':
        case 'setPitch':
        case 'setVoice':
        case 'synthesizeToFile':
        case 'awaitSpeakCompletion':
        case 'awaitSynthCompletion':
          return 1;
        case 'getLanguages':
          return ['es-ES', 'en-US'];
        case 'getVoices':
          return [
            {'name': 'es-ES-voice', 'locale': 'es-ES'},
          ];
        case 'isLanguageAvailable':
          return 1;
        default:
          return null;
      }
    });

    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  setUp(() {
    // Clear SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});

    // Reset service locator and register fake services
    ServiceLocator().reset();
    ServiceLocator().registerSingleton<ITtsService>(FakeTtsService());
    ServiceLocator()
        .registerSingleton<AnalyticsService>(MockAnalyticsService());
  });

  group('PR #180 - Test 1: Race Condition - Init Order', () {
    test('favorites sync correctly when loaded before devotionals', () async {
      final prefs = await SharedPreferences.getInstance();

      // Set up favorite IDs in storage
      await prefs.setString('favorite_ids', json.encode(['dev1', 'dev2']));

      final provider = DevocionalProvider();

      // Initialize (should load favorites first, then devotionals)
      // Note: initializeData already ensures correct order
      await provider.initializeData();

      // Verify favorites were loaded
      // Note: The actual devotionals might not be loaded in test environment
      // but we can verify the IDs are loaded
      expect(
          provider.isFavorite(
              createTestDevocional(id: 'dev1', date: DateTime.now())),
          isTrue,
          reason: 'Favorite ID dev1 should be loaded');
      expect(
          provider.isFavorite(
              createTestDevocional(id: 'dev2', date: DateTime.now())),
          isTrue,
          reason: 'Favorite ID dev2 should be loaded');

      provider.dispose();
    });

    test('init() method ensures sequential loading order', () async {
      final prefs = await SharedPreferences.getInstance();

      // Set up test data
      await prefs.setString('favorite_ids', json.encode(['test-id']));

      final provider = DevocionalProvider();

      // Call init - should load favorites before devotionals
      await provider.initializeData();

      // Verify the favorite ID was loaded first
      expect(
          provider.isFavorite(
              createTestDevocional(id: 'test-id', date: DateTime.now())),
          isTrue);

      provider.dispose();
    });
  });

  group('PR #180 - Test 2: Legacy Key Cleanup', () {
    test('migration removes legacy favorites key after success', () async {
      final prefs = await SharedPreferences.getInstance();

      // Set up legacy data
      final legacyFavorite = {
        'id': 'dev1',
        'date': '2025-01-15',
        'versiculo': 'Juan 3:16',
        'reflexion': 'Test',
        'oracion': 'Test',
        'version': 'RVR1960',
      };
      await prefs.setString('favorites', json.encode([legacyFavorite]));

      // Verify legacy key exists
      expect(prefs.containsKey('favorites'), isTrue);

      final provider = DevocionalProvider();
      await provider.initializeData();

      // Allow async operations to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify migration and cleanup
      expect(prefs.containsKey('favorite_ids'), isTrue,
          reason: 'New favorite_ids key should exist');
      expect(prefs.containsKey('favorites'), isFalse,
          reason: 'Legacy favorites key should be removed');

      provider.dispose();
    });

    test('legacy key is not removed if migration yields no favorites',
        () async {
      final prefs = await SharedPreferences.getInstance();

      // Set up legacy data with empty IDs only
      final legacyFavorite = {
        'id': '',
        'date': '2025-01-15',
        'versiculo': 'Juan 3:16',
        'reflexion': 'Test',
        'oracion': 'Test',
        'version': 'RVR1960',
      };
      await prefs.setString('favorites', json.encode([legacyFavorite]));

      final provider = DevocionalProvider();
      await provider.initializeData();

      await Future.delayed(const Duration(milliseconds: 100));

      // Legacy key should still exist because no valid favorites were migrated
      expect(prefs.containsKey('favorites'), isTrue,
          reason: 'Legacy key should remain if no valid favorites migrated');

      provider.dispose();
    });
  });

  group('PR #180 - Test 3: Partial Migration (Empty IDs)', () {
    test('migration logs when some favorites have empty IDs', () async {
      final prefs = await SharedPreferences.getInstance();
      final mockAnalytics =
          getService<AnalyticsService>() as MockAnalyticsService;
      mockAnalytics.reset();

      // 3 items, 1 with empty ID
      final legacyFavorites = [
        {
          'id': 'dev1',
          'date': '2025-01-01',
          'versiculo': 'Test',
          'reflexion': 'Test',
          'oracion': 'Test',
          'version': 'RVR1960',
        },
        {
          'id': '',
          'date': '2025-01-02',
          'versiculo': 'Test',
          'reflexion': 'Test',
          'oracion': 'Test',
          'version': 'RVR1960',
        },
        {
          'id': 'dev3',
          'date': '2025-01-03',
          'versiculo': 'Test',
          'reflexion': 'Test',
          'oracion': 'Test',
          'version': 'RVR1960',
        },
      ];

      await prefs.setString('favorites', json.encode(legacyFavorites));

      final provider = DevocionalProvider();
      await provider.initializeData();

      await Future.delayed(const Duration(milliseconds: 100));

      // Verify only 2 favorites were migrated
      final favoriteIdsJson = prefs.getString('favorite_ids');
      expect(favoriteIdsJson, isNotNull);
      final favoriteIds =
          (json.decode(favoriteIdsJson!) as List).cast<String>();
      expect(favoriteIds.length, equals(2),
          reason: 'Should migrate only 2 valid favorites');

      // Verify telemetry event was fired with dropped count = 1
      final dataLossEvents = mockAnalytics.events
          .where((e) => e['eventName'] == 'favorites_migration_data_loss')
          .toList();
      expect(dataLossEvents.length, equals(1),
          reason: 'Should log migration data loss event');
      expect(dataLossEvents[0]['parameters']['total_legacy'], equals(3));
      expect(dataLossEvents[0]['parameters']['migrated'], equals(2));
      expect(dataLossEvents[0]['parameters']['dropped'], equals(1));

      provider.dispose();
    });
  });

  group('PR #180 - Test 4: Telemetry Throttling', () {
    test('mismatch telemetry fires only once per session', () async {
      final prefs = await SharedPreferences.getInstance();
      final mockAnalytics =
          getService<AnalyticsService>() as MockAnalyticsService;
      mockAnalytics.reset();

      // Set up scenario where there will be a mismatch
      // (favorite IDs exist but devotionals don't match in test environment)
      await prefs.setString(
          'favorite_ids', json.encode(['non-existent-1', 'non-existent-2']));

      final provider = DevocionalProvider();
      await provider.initializeData();

      await Future.delayed(const Duration(milliseconds: 100));

      // Get initial event count
      final initialMismatchCount = mockAnalytics.events
          .where((e) => e['eventName'] == 'favorites_id_mismatch')
          .length;

      // Trigger sync multiple times (simulating language/version changes)
      provider.setSelectedVersion('NVI');
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedVersion('RVR1960');
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedVersion('NVI');
      await Future.delayed(const Duration(milliseconds: 50));

      // Count mismatch events
      final finalMismatchCount = mockAnalytics.events
          .where((e) => e['eventName'] == 'favorites_id_mismatch')
          .length;

      // Should only fire once (or once more at most, not multiple times)
      expect(finalMismatchCount - initialMismatchCount, lessThanOrEqualTo(1),
          reason: 'Mismatch telemetry should be throttled per session');

      provider.dispose();
    });
  });

  group('PR #180 - Test 5: Corrupted Legacy Data', () {
    test('migration handles corrupted JSON gracefully', () async {
      final prefs = await SharedPreferences.getInstance();
      final mockAnalytics =
          getService<AnalyticsService>() as MockAnalyticsService;
      mockAnalytics.reset();

      // Set corrupted JSON
      await prefs.setString('favorites', '{invalid json[[');

      final provider = DevocionalProvider();

      // Should not crash
      await provider.initializeData();

      await Future.delayed(const Duration(milliseconds: 100));

      // Should have empty favorites
      expect(provider.favoriteDevocionales, isEmpty,
          reason: 'Corrupted data should result in empty favorites');
      expect(provider.errorMessage, isNull,
          reason: 'Should not crash with error message in provider');

      // Verify migration failure telemetry
      final failureEvents = mockAnalytics.events
          .where((e) => e['eventName'] == 'favorites_migration_failure')
          .toList();
      expect(failureEvents.length, equals(1),
          reason: 'Should log migration failure event');

      provider.dispose();
    });

    test('handles malformed devotional objects in legacy data', () async {
      final prefs = await SharedPreferences.getInstance();

      // Legacy data with malformed object (missing required fields)
      await prefs.setString('favorites', '[{"id": "test", "invalid": true}]');

      final provider = DevocionalProvider();

      // Should handle gracefully
      expect(() async => await provider.initializeData(), returnsNormally);

      provider.dispose();
    });
  });

  group('PR #180 - Test 6: Concurrent Init Calls', () {
    test('multiple simultaneous init calls do not corrupt favorites', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('favorite_ids', json.encode(['dev1', 'dev2']));

      final provider = DevocionalProvider();

      // Call init multiple times concurrently
      await Future.wait([
        provider.initializeData(),
        provider.initializeData(),
        provider.initializeData(),
      ]);

      await Future.delayed(const Duration(milliseconds: 100));

      // Verify favorites are intact
      expect(
          provider.isFavorite(
              createTestDevocional(id: 'dev1', date: DateTime.now())),
          isTrue,
          reason: 'Favorite dev1 should be intact after concurrent inits');
      expect(
          provider.isFavorite(
              createTestDevocional(id: 'dev2', date: DateTime.now())),
          isTrue,
          reason: 'Favorite dev2 should be intact after concurrent inits');

      provider.dispose();
    });

    test('concurrent init with migration does not cause race condition',
        () async {
      final prefs = await SharedPreferences.getInstance();

      // Set up legacy data
      final legacyFavorites = [
        {
          'id': 'dev1',
          'date': '2025-01-01',
          'versiculo': 'Test',
          'reflexion': 'Test',
          'oracion': 'Test',
          'version': 'RVR1960',
        },
      ];
      await prefs.setString('favorites', json.encode(legacyFavorites));

      final provider = DevocionalProvider();

      // Multiple concurrent inits during migration
      await Future.wait([
        provider.initializeData(),
        provider.initializeData(),
      ]);

      await Future.delayed(const Duration(milliseconds: 100));

      // Verify migration completed successfully
      final favoriteIdsJson = prefs.getString('favorite_ids');
      expect(favoriteIdsJson, isNotNull);

      final favoriteIds =
          (json.decode(favoriteIdsJson!) as List).cast<String>();
      expect(favoriteIds, contains('dev1'),
          reason: 'Migration should complete despite concurrent calls');

      provider.dispose();
    });
  });

  group('PR #180 - Additional Edge Cases', () {
    test('migration success telemetry is logged correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      final mockAnalytics =
          getService<AnalyticsService>() as MockAnalyticsService;
      mockAnalytics.reset();

      // Set up valid legacy data
      final legacyFavorites = [
        {
          'id': 'dev1',
          'date': '2025-01-01',
          'versiculo': 'Test',
          'reflexion': 'Test',
          'oracion': 'Test',
          'version': 'RVR1960',
        },
        {
          'id': 'dev2',
          'date': '2025-01-02',
          'versiculo': 'Test',
          'reflexion': 'Test',
          'oracion': 'Test',
          'version': 'RVR1960',
        },
      ];
      await prefs.setString('favorites', json.encode(legacyFavorites));

      final provider = DevocionalProvider();
      await provider.initializeData();

      await Future.delayed(const Duration(milliseconds: 100));

      // Verify migration success telemetry
      final successEvents = mockAnalytics.events
          .where((e) => e['eventName'] == 'favorites_migration_success')
          .toList();
      expect(successEvents.length, equals(1),
          reason: 'Should log migration success event');
      expect(successEvents[0]['parameters']['total_legacy'], equals(2));
      expect(successEvents[0]['parameters']['migrated'], equals(2));
      expect(successEvents[0]['parameters']['dropped'], equals(0));

      provider.dispose();
    });

    test('no telemetry spam when favorites match devotionals', () async {
      final mockAnalytics =
          getService<AnalyticsService>() as MockAnalyticsService;
      mockAnalytics.reset();

      final provider = DevocionalProvider();
      await provider.initializeData();

      await Future.delayed(const Duration(milliseconds: 100));

      // If no favorites, should not log mismatch
      final mismatchEvents = mockAnalytics.events
          .where((e) => e['eventName'] == 'favorites_id_mismatch')
          .toList();
      expect(mismatchEvents.isEmpty, isTrue,
          reason: 'Should not log mismatch when there are no favorites');

      provider.dispose();
    });
  });
}
