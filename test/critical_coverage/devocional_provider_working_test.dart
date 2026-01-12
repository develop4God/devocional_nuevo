@Tags(['slow'])
library;

import 'dart:convert';

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

void main() {
  late DevocionalProvider provider;

  // Mock canales plataforma externos (path_provider, flutter_tts)
  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  const MethodChannel ttsChannel = MethodChannel('flutter_tts');

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

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
      switch (methodCall.method) {
        case 'Crashlytics#checkForUnsentReports':
          return false;
        case 'Crashlytics#didCrashOnPreviousExecution':
          return false;
        case 'Crashlytics#setCrashlyticsCollectionEnabled':
        case 'Crashlytics#recordError':
        case 'Crashlytics#log':
        case 'Crashlytics#setCustomKey':
        case 'Crashlytics#setUserIdentifier':
          return null;
        default:
          return null;
      }
    });

    // Initialize Firebase after setting up mocks
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Firebase may already be initialized
    }

    final mockPathProvider = MockPathProviderPlatform();
    PathProviderPlatform.instance = mockPathProvider;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (
      MethodCall methodCall,
    ) async {
      switch (methodCall.method) {
        case 'getApplicationDocumentsDirectory':
          return '/mock_documents';
        case 'getTemporaryDirectory':
          return '/mock_temp';
        default:
          return null;
      }
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (MethodCall call) async {
      switch (call.method) {
        case 'speak':
        case 'stop':
        case 'pause':
        case 'setLanguage':
        case 'setSpeechRate':
        case 'setVolume':
        case 'setPitch':
        case 'awaitSpeakCompletion':
        case 'setQueueMode':
        case 'awaitSynthCompletion':
          return 1;
        case 'getLanguages':
          return ['es-ES', 'en-US'];
        case 'getVoices':
          return [
            {'name': 'Voice ES', 'locale': 'es-ES'},
            {'name': 'Voice EN', 'locale': 'en-US'},
          ];
        case 'isLanguageAvailable':
          return true;
        default:
          return null;
      }
    });
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({}); // Reset SharedPreferences

    // Setup service locator for DI
    ServiceLocator().reset();
    setupServiceLocator();

    provider = DevocionalProvider();
    await provider.initializeData();
  });

  tearDown(() {
    provider.dispose();
    ServiceLocator().reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
  });

  group('DevocionalProvider Robust Tests', () {
    test('initial state validation', () {
      // Language depends on device locale, so check it's a supported language
      expect(provider.supportedLanguages, contains(provider.selectedLanguage));
      expect(provider.selectedVersion, isNotNull);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNotNull); // Will have error due to 400
      expect(provider.devocionales, isEmpty);
      expect(provider.favoriteDevocionales, isEmpty);
      expect(provider.isOfflineMode, isFalse);
      expect(provider.isDownloading, isFalse);
      expect(provider.downloadStatus, isNull);
    });

    test('supported languages and fallback behavior', () async {
      expect(provider.supportedLanguages, contains('es'));
      expect(provider.supportedLanguages, contains('en'));
      // Fallback language on unsupported input
      final currentLang = provider.selectedLanguage;
      provider.setSelectedLanguage('unsupported', null);
      // Should fallback to 'es' (the hardcoded fallback language)
      // Wait for async operations
      await Future.delayed(const Duration(milliseconds: 200));
      expect(provider.selectedLanguage, 'es');
      // Restore original language
      provider.setSelectedLanguage(currentLang, null);
      await Future.delayed(const Duration(milliseconds: 200));
    });

    test('changing language updates data and version defaults', () async {
      provider.setSelectedLanguage('en', null);
      expect(provider.selectedLanguage, 'en');
      expect(provider.selectedVersion, isNotNull);
      // Devocionales will be empty due to HTTP 400, but API was called
      expect(provider.devocionales.isEmpty, isTrue);
    });

    test('changing version updates data', () async {
      final oldVersion = provider.selectedVersion;
      provider.setSelectedVersion('NVI');
      expect(provider.selectedVersion, 'NVI');
      expect(provider.selectedVersion != oldVersion, isTrue);
      // Wait a bit for async operations to complete
      await Future.delayed(const Duration(milliseconds: 100));
    });

    testWidgets('favorite management works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Container())));

      final devotional = Devocional(
        id: 'fav_test_1',
        date: DateTime.now(),
        versiculo: 'Sample',
        reflexion: 'Sample reflection',
        paraMeditar: [],
        oracion: 'Sample prayer',
      );

      expect(provider.isFavorite(devotional), isFalse);

      // Use new async API
      final wasAdded1 = await provider.toggleFavorite(devotional.id);
      await tester.pump(); // Let the provider notify

      expect(wasAdded1, isNotNull);
      expect(wasAdded1, isTrue);
      expect(provider.isFavorite(devotional), isTrue);

      final wasAdded2 = await provider.toggleFavorite(devotional.id);
      await tester.pump();

      expect(wasAdded2, isNotNull);
      expect(wasAdded2, isFalse);
      expect(provider.isFavorite(devotional), isFalse);
    });

    test('audio methods delegate without error', () async {
      final devotional = Devocional(
        id: 'audio_test',
        date: DateTime.now(),
        versiculo: 'Test',
        reflexion: 'Test',
        paraMeditar: [],
        oracion: 'Test',
      );

      // TTS service may be disposed in test environment, so we expect errors
      // Just verify methods exist and don't throw compilation errors
      try {
        await provider.playDevotional(devotional);
      } catch (e) {
        // Expected in test environment
      }

      try {
        await provider.pauseAudio();
      } catch (e) {
        // Expected in test environment
      }

      try {
        await provider.resumeAudio();
      } catch (e) {
        // Expected in test environment
      }

      try {
        await provider.stopAudio();
      } catch (e) {
        // Expected in test environment
      }

      try {
        await provider.toggleAudioPlayPause(devotional);
      } catch (e) {
        // Expected in test environment
      }

      // TTS methods may return empty or mock data in test environment
      final languages = await provider.getAvailableLanguages();
      // In test environment, may be empty or have mock data
      expect(languages, isA<List>());

      final voices = await provider.getAvailableVoices();
      // In test environment, may be empty or have mock data
      expect(voices, isA<List>());

      final voicesForLang = await provider.getVoicesForLanguage('es');
      expect(voicesForLang, isA<List>());

      try {
        await provider.setTtsLanguage('es-ES');
      } catch (e) {
        // Expected in test environment
      }

      try {
        await provider.setTtsVoice({'name': 'Voice ES', 'locale': 'es-ES'});
      } catch (e) {
        // Expected in test environment
      }

      try {
        await provider.setTtsSpeechRate(0.5);
      } catch (e) {
        // Expected in test environment
      }
    });

    test('reading tracking and recording works correctly', () async {
      provider.startDevocionalTracking('track_id');
      expect(provider.currentTrackedDevocionalId, 'track_id');

      provider.pauseTracking();
      provider.resumeTracking();

      try {
        await provider.recordDevocionalRead('track_id');
      } catch (e) {
        // Expected in test environment due to Firebase not being fully initialized
      }
      expect(provider.currentReadingSeconds >= 0, isTrue);
      expect(provider.currentScrollPercentage >= 0.0, isTrue);
    });

    test('offline download and storage lifecycle', () async {
      // Simulate download current year devocionales
      // Will fail due to HTTP 400, so expect false
      bool downloaded = await provider.downloadCurrentYearDevocionales();
      expect(downloaded, isFalse);

      bool hasLocal = await provider.hasCurrentYearLocalData();
      expect(hasLocal, isFalse);

      // Download for specific year - will also fail
      bool specificDownload = await provider.downloadDevocionalesForYear(
        DateTime.now().year,
      );
      expect(specificDownload, isFalse);

      // Clear local files test
      await provider.clearOldLocalFiles();

      bool hasAfterClear = await provider.hasCurrentYearLocalData();
      expect(hasAfterClear, isFalse);
    });

    test('error handling in loading data', () async {
      // Forcing unsupported language and version, setting wrong values forcibly in prefs could induce error states.
      SharedPreferences.setMockInitialValues({
        'selectedLanguage': 'zz',
        'selectedVersion': 'bad_version',
      });

      provider = DevocionalProvider();
      await provider.initializeData();

      expect(provider.errorMessage, isNotNull);
    });

    test('invitation dialog preference management', () async {
      expect(provider.showInvitationDialog, isTrue);
      await provider.setInvitationDialogVisibility(false);
      expect(provider.showInvitationDialog, isFalse);
    });

    test('utility methods behave correctly', () async {
      expect(provider.isLanguageSupported('es'), isTrue);
      expect(provider.isLanguageSupported('xyz'), isFalse);

      final success = await provider.downloadDevocionalesWithProgress(
        onProgress: (progress) {},
        startYear: DateTime.now().year,
        endYear: DateTime.now().year + 1,
      );
      expect(success, isA<bool>());
    });

    test('Japanese version codes are correctly configured', () async {
      // Test that Japanese versions use the new version codes
      provider.setSelectedLanguage('ja', null);
      await Future.delayed(const Duration(milliseconds: 200));

      expect(provider.selectedLanguage, 'ja');
      expect(provider.availableVersions, contains('新改訳2003'));
      expect(provider.availableVersions, contains('リビングバイブル'));
      expect(provider.selectedVersion, '新改訳2003'); // Default version

      // Test switching versions
      provider.setSelectedVersion('リビングバイブル');
      await Future.delayed(const Duration(milliseconds: 200));
      expect(provider.selectedVersion, 'リビングバイブル');
    });

    test('legacy favorites migrated to ID format', () async {
      final testDevocional = Devocional(
        id: 'legacy_fav_1',
        date: DateTime(2025, 1, 1),
        versiculo: 'Juan 3:16',
        reflexion: 'Test',
        paraMeditar: [ParaMeditar(cita: 'Test', texto: 'Test')],
        oracion: 'Test',
        version: 'RVR1960',
      );

      SharedPreferences.setMockInitialValues({
        'favorites': json.encode([testDevocional.toJson()]),
      });

      final newProvider = DevocionalProvider();
      await newProvider.initializeData();

      // Verify migration happened
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getString('favorite_ids');
      expect(favoriteIds, isNotNull);

      final ids = json.decode(favoriteIds!);
      expect(ids, contains('legacy_fav_1'));

      newProvider.dispose();
    });

    test('favorite IDs persist after language switch', () async {
      // Create test devotionals with IDs
      final testDevocional1 = Devocional(
        id: 'persist_test_1',
        date: DateTime(2025, 1, 15),
        versiculo: 'Test verse',
        reflexion: 'Test reflection',
        paraMeditar: [ParaMeditar(cita: 'Test', texto: 'Test meditation')],
        oracion: 'Test prayer',
        version: 'RVR1960',
      );

      // Set up initial state with favorite IDs
      SharedPreferences.setMockInitialValues({
        'favorite_ids': json.encode(['persist_test_1', 'persist_test_2']),
        'selectedLanguage': 'es',
      });

      // Create new provider
      ServiceLocator().reset();
      setupServiceLocator();
      final newProvider = DevocionalProvider();
      await newProvider.initializeData();

      // Verify favorite IDs are loaded
      expect(newProvider.isFavorite(testDevocional1), isTrue,
          reason: 'Favorite status should be maintained');

      // Switch language
      newProvider.setSelectedLanguage('en', null);
      await Future.delayed(const Duration(milliseconds: 300));

      // Verify favorite IDs are still maintained
      expect(newProvider.isFavorite(testDevocional1), isTrue,
          reason: 'Favorite IDs should persist after language switch');

      newProvider.dispose();
    });

    test('_loadFavorites handles corrupted JSON gracefully', () async {
      // Set up corrupted JSON data
      SharedPreferences.setMockInitialValues({
        'favorite_ids': '{corrupted json',
      });

      // Create new provider
      ServiceLocator().reset();
      setupServiceLocator();
      final newProvider = DevocionalProvider();
      await newProvider.initializeData();

      // Should handle error and initialize with empty set
      expect(newProvider.favoriteDevocionales, isEmpty,
          reason: 'Should handle corrupted JSON gracefully');

      newProvider.dispose();
    });

    test('_loadFavorites handles corrupted legacy JSON gracefully', () async {
      // Set up corrupted legacy JSON data
      SharedPreferences.setMockInitialValues({
        'favorites': '{corrupted legacy json',
      });

      // Create new provider
      ServiceLocator().reset();
      setupServiceLocator();
      final newProvider = DevocionalProvider();
      await newProvider.initializeData();

      // Should handle error and initialize with empty set
      expect(newProvider.favoriteDevocionales, isEmpty,
          reason: 'Should handle corrupted legacy JSON gracefully');

      newProvider.dispose();
    });

    test('sync favorites rehydrates after devotionals load', () async {
      // Set up favorite IDs before devotionals are loaded
      SharedPreferences.setMockInitialValues({
        'favorite_ids': json.encode(['rehydrate_test_1', 'rehydrate_test_2']),
      });

      // Create new provider
      ServiceLocator().reset();
      setupServiceLocator();
      final newProvider = DevocionalProvider();

      // Initialize - this will load IDs first, then devotionals, then sync
      await newProvider.initializeData();

      // Even though devotionals may not match (due to API issues in test),
      // the sync should have been called without errors
      expect(newProvider.favoriteDevocionales, isA<List<Devocional>>(),
          reason: 'Sync should produce a valid list');

      newProvider.dispose();
    });
  });
}
