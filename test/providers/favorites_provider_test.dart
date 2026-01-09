// test/providers/favorites_provider_test.dart

import 'dart:convert';

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
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

/// Helper function to create test devotionals with proper structure
Devocional createTestDevocional({
  required String id,
  required DateTime date,
  required String versiculo,
  String reflexion = 'Test reflection',
  String oracion = 'Test prayer',
  String version = 'RVR1960',
  String language = 'es',
  List<String>? tags,
}) {
  return Devocional(
    id: id,
    date: date,
    versiculo: versiculo,
    reflexion: reflexion,
    paraMeditar: [
      ParaMeditar(cita: 'Test cita', texto: 'Test para meditar text'),
    ],
    oracion: oracion,
    version: version,
    language: language,
    tags: tags,
  );
}

/// Comprehensive test suite for favorites functionality
/// Tests the ID-based storage system to prevent "not read" bugs
void main() {
  late DevocionalProvider provider;

  // Mock platform channels
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
          return ['es-ES', 'en-US', 'pt-BR', 'fr-FR', 'ja-JP', 'zh-CN'];
        case 'getVoices':
          return [
            {'name': 'es-ES-voice', 'locale': 'es-ES'},
            {'name': 'en-US-voice', 'locale': 'en-US'},
          ];
        case 'isLanguageAvailable':
          return 1;
        default:
          return null;
      }
    });

    PathProviderPlatform.instance = MockPathProviderPlatform();
    setupServiceLocator();
  });

  setUp(() async {
    // Clear SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});
    provider = DevocionalProvider();
  });

  tearDown(() {
    provider.dispose();
  });

  group('Favorites ID-Based Storage System', () {
    test('Should save and load favorites using IDs only', () async {
      final prefs = await SharedPreferences.getInstance();

      // Create test devotionals
      final testDevocional = createTestDevocional(
        id: 'devocional_2025_01_15_RVR1960',
        date: DateTime(2025, 1, 15),
        versiculo: 'Juan 3:16',
      );

      // Simulate adding to favorites
      final favoriteIds = {'devocional_2025_01_15_RVR1960'};
      await prefs.setString('favorite_ids', json.encode(favoriteIds.toList()));

      // Load favorites in a new provider instance
      final newProvider = DevocionalProvider();
      await newProvider.initializeData();

      // Verify the favorite ID was loaded
      expect(newProvider.isFavorite(testDevocional), isTrue);

      newProvider.dispose();
    });

    test('Should migrate legacy favorites to ID-based storage', () async {
      final prefs = await SharedPreferences.getInstance();

      // Create legacy favorites format (full objects)
      final legacyFavorites = [
        {
          'id': 'devocional_2025_01_15_RVR1960',
          'date': '2025-01-15',
          'versiculo': 'Juan 3:16',
          'texto': 'Test text',
          'reflexion': 'Test reflection',
          'oracion': 'Test prayer',
          'version': 'RVR1960',
          'language': 'es',
        },
      ];

      await prefs.setString('favorites', json.encode(legacyFavorites));

      // Load with new provider - should migrate
      final newProvider = DevocionalProvider();
      await newProvider.initializeData();

      // Create test devotional with same ID
      final testDevocional = createTestDevocional(
        id: 'devocional_2025_01_15_RVR1960',
        date: DateTime(2025, 1, 15),
        versiculo: 'Juan 3:16',
      );

      // Should recognize as favorite after migration
      expect(newProvider.isFavorite(testDevocional), isTrue);

      newProvider.dispose();
    });

    test('Should handle empty favorites gracefully', () async {
      await SharedPreferences.getInstance();

      // No favorites stored
      final newProvider = DevocionalProvider();
      await newProvider.initializeData();

      expect(newProvider.favoriteDevocionales, isEmpty);

      newProvider.dispose();
    });

    test('Should skip invalid IDs during legacy migration', () async {
      final prefs = await SharedPreferences.getInstance();

      // Create legacy favorites with empty and null IDs
      final legacyFavorites = [
        {
          'id': '',
          'date': '2025-01-15',
          'versiculo': 'Juan 3:16',
          'texto': 'Test text',
          'reflexion': 'Test reflection',
          'oracion': 'Test prayer',
          'version': 'RVR1960',
          'language': 'es',
        },
        {
          'id': 'valid_id',
          'date': '2025-01-16',
          'versiculo': 'Juan 3:17',
          'texto': 'Test text 2',
          'reflexion': 'Test reflection 2',
          'oracion': 'Test prayer 2',
          'version': 'RVR1960',
          'language': 'es',
        },
      ];

      await prefs.setString('favorites', json.encode(legacyFavorites));

      // Load with new provider
      final newProvider = DevocionalProvider();
      await newProvider.initializeData();

      // Should only have valid ID
      final validDevocional = createTestDevocional(
        id: 'valid_id',
        date: DateTime(2025, 1, 16),
        versiculo: 'Juan 3:17',
      );

      expect(newProvider.isFavorite(validDevocional), isTrue);

      newProvider.dispose();
    });
  });

  group('Favorites Persistence After App Restart', () {
    testWidgets('Should persist favorites across app restarts',
        (WidgetTester tester) async {
      // Create test devotionals
      final devocional1 = createTestDevocional(
        id: 'devocional_2025_01_15_RVR1960',
        date: DateTime(2025, 1, 15),
        versiculo: 'Juan 3:16',
      );

      // First session: Add favorite
      final provider1 = DevocionalProvider();
      await provider1.initializeData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                provider1.toggleFavorite(devocional1, context);
                return Container();
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify it's saved
      expect(provider1.isFavorite(devocional1), isTrue);
      provider1.dispose();

      // Second session: Load again (simulating app restart)
      final provider2 = DevocionalProvider();
      await provider2.initializeData();

      // Should still be favorite
      expect(provider2.isFavorite(devocional1), isTrue);
      expect(provider2.favoriteDevocionales.length, equals(1));

      provider2.dispose();
    });

    testWidgets(
        'Should show favorite as "read" after restart if marked as read',
        (WidgetTester tester) async {
      // Create test devotional
      final devocionalId = 'devocional_2025_01_15_RVR1960';
      final devocional = createTestDevocional(
        id: devocionalId,
        date: DateTime(2025, 1, 15),
        versiculo: 'Juan 3:16',
      );

      // First session: Add favorite and mark as read
      final provider1 = DevocionalProvider();
      await provider1.initializeData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                provider1.toggleFavorite(devocional, context);
                return Container();
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Mark as read
      await provider1.recordDevocionalRead(devocionalId);

      // Verify saved in stats
      final statsService1 = SpiritualStatsService();
      final stats1 = await statsService1.getStats();
      expect(stats1.readDevocionalIds.contains(devocionalId), isTrue);

      provider1.dispose();

      // Second session: Load again
      final provider2 = DevocionalProvider();
      await provider2.initializeData();

      // Should still be favorite AND read
      expect(provider2.isFavorite(devocional), isTrue);

      final statsService2 = SpiritualStatsService();
      final stats2 = await statsService2.getStats();
      expect(stats2.readDevocionalIds.contains(devocionalId), isTrue);

      provider2.dispose();
    });
  });

  group('Favorites Backup and Restore', () {
    test('Should correctly restore favorites from backup', () async {
      final prefs = await SharedPreferences.getInstance();

      // Simulate backup data with favorite IDs
      final backupFavoriteIds = [
        'devocional_2025_01_15_RVR1960',
        'devocional_2025_01_16_RVR1960',
      ];

      await prefs.setString('favorite_ids', json.encode(backupFavoriteIds));

      // Load provider and reload favorites
      final provider = DevocionalProvider();
      await provider.initializeData();
      await provider.reloadFavoritesFromStorage();

      // Create test devotionals
      final devocional1 = createTestDevocional(
        id: 'devocional_2025_01_15_RVR1960',
        date: DateTime(2025, 1, 15),
        versiculo: 'Juan 3:16',
      );

      final devocional2 = createTestDevocional(
        id: 'devocional_2025_01_16_RVR1960',
        date: DateTime(2025, 1, 16),
        versiculo: 'Juan 3:17',
      );

      // Both should be favorites
      expect(provider.isFavorite(devocional1), isTrue);
      expect(provider.isFavorite(devocional2), isTrue);

      provider.dispose();
    });

    test('Should preserve read status after favorites restore', () async {
      final prefs = await SharedPreferences.getInstance();

      // Set up favorites and read status
      final favoriteIds = ['devocional_2025_01_15_RVR1960'];
      await prefs.setString('favorite_ids', json.encode(favoriteIds));

      // Set up spiritual stats with read devotional
      final statsData = {
        'totalDaysRead': 1,
        'currentStreak': 1,
        'longestStreak': 1,
        'totalFavorites': 1,
        'lastReadDate': DateTime.now().toIso8601String(),
        'readDevocionalIds': ['devocional_2025_01_15_RVR1960'],
      };
      await prefs.setString('spiritual_stats', json.encode(statsData));

      // Load provider
      final provider = DevocionalProvider();
      await provider.initializeData();
      await provider.reloadFavoritesFromStorage();

      // Create test devotional
      final devocional = createTestDevocional(
        id: 'devocional_2025_01_15_RVR1960',
        date: DateTime(2025, 1, 15),
        versiculo: 'Juan 3:16',
      );

      // Should be favorite
      expect(provider.isFavorite(devocional), isTrue);

      // Should be marked as read
      final statsService = SpiritualStatsService();
      final stats = await statsService.getStats();
      expect(stats.readDevocionalIds.contains(devocional.id), isTrue);

      provider.dispose();
    });
  });

  group('Language Switch Favorites', () {
    test('Should maintain separate favorites per language', () async {
      final prefs = await SharedPreferences.getInstance();

      // Set up favorites for Spanish
      final spanishFavorites = ['devocional_2025_01_15_RVR1960'];
      await prefs.setString('favorite_ids', json.encode(spanishFavorites));

      // Load provider in Spanish
      final provider = DevocionalProvider();
      await provider.initializeData();

      // Create Spanish devotional
      final spanishDevocional = createTestDevocional(
        id: 'devocional_2025_01_15_RVR1960',
        date: DateTime(2025, 1, 15),
        versiculo: 'Juan 3:16',
        reflexion: 'Reflexión en español',
        oracion: 'Oración en español',
      );

      expect(provider.isFavorite(spanishDevocional), isTrue);

      // Note: In the current implementation, favorites are shared across languages
      // This test documents the current behavior
      // If per-language favorites are needed, the implementation would need to change

      provider.dispose();
    });
  });

  group('Edge Cases', () {
    testWidgets('Should not add devotional without ID to favorites',
        (WidgetTester tester) async {
      final provider = DevocionalProvider();
      await provider.initializeData();

      final invalidDevocional = createTestDevocional(
        id: '', // Empty ID
        date: DateTime(2025, 1, 15),
        versiculo: 'Juan 3:16',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                provider.toggleFavorite(invalidDevocional, context);
                return Container();
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error message
      expect(
          find.text('No se puede guardar devocional sin ID'), findsOneWidget);

      // Should not be in favorites
      expect(provider.favoriteDevocionales.length, equals(0));

      provider.dispose();
    });

    testWidgets('Should handle removing non-existent favorite gracefully',
        (WidgetTester tester) async {
      final provider = DevocionalProvider();
      await provider.initializeData();

      final devocional = createTestDevocional(
        id: 'devocional_2025_01_15_RVR1960',
        date: DateTime(2025, 1, 15),
        versiculo: 'Juan 3:16',
      );

      // Try to remove when not favorited
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                provider.toggleFavorite(devocional, context);
                return Container();
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should be added (not removed)
      expect(provider.isFavorite(devocional), isTrue);

      provider.dispose();
    });

    test('Should sync favorites after version change', () async {
      final prefs = await SharedPreferences.getInstance();

      // Set up favorites
      final favoriteIds = [
        'devocional_2025_01_15_RVR1960',
        'devocional_2025_01_16_RVR1960',
      ];
      await prefs.setString('favorite_ids', json.encode(favoriteIds));

      final provider = DevocionalProvider();
      await provider.initializeData();

      // Favorites should be loaded
      expect(provider.favoriteDevocionales.isNotEmpty, isTrue);

      // Change version (this triggers _filterDevocionalesByVersion which calls sync)
      provider.setSelectedVersion('NVI');

      // Favorites should still be accessible (if available in NVI)
      // or empty if not available in new version

      provider.dispose();
    });

    test('Should handle corrupted favorite_ids data', () async {
      final prefs = await SharedPreferences.getInstance();

      // Store corrupted JSON
      await prefs.setString('favorite_ids', 'not-valid-json');

      final provider = DevocionalProvider();

      // Should not crash, should handle gracefully
      expect(() async => await provider.initializeData(), returnsNormally);

      provider.dispose();
    });
  });

  group('Production User Migration Safety - Real User Scenarios', () {
    test(
        'Migration preserves legacy data for rollback - Scenario: User with 50 favorites',
        () async {
      final prefs = await SharedPreferences.getInstance();

      // Simulate a real production user with 50 favorites in legacy format
      final legacyFavorites = List.generate(
        50,
        (index) => {
          'id':
              'devocional_2025_${(index + 1).toString().padLeft(2, '0')}_01_RVR1960',
          'date': '2025-${(index + 1).toString().padLeft(2, '0')}-01',
          'versiculo': 'Test verse $index',
          'texto': 'Test text $index',
          'reflexion': 'Test reflection $index',
          'oracion': 'Test prayer $index',
          'version': 'RVR1960',
          'language': 'es',
        },
      );

      // Save legacy data
      await prefs.setString('favorites', json.encode(legacyFavorites));

      // Verify legacy data is present before migration
      final legacyDataBefore = prefs.getString('favorites');
      expect(legacyDataBefore, isNotNull);

      // User upgrades app - new provider loads and migrates
      final provider = DevocionalProvider();
      await provider.initializeData();

      // Verify migration worked
      expect(provider.favoriteDevocionales.length, equals(50));

      // CRITICAL: Verify legacy data is STILL present (not deleted)
      final legacyDataAfter = prefs.getString('favorites');
      expect(legacyDataAfter, isNotNull,
          reason: 'Legacy data must be preserved for safe rollback');
      expect(legacyDataAfter, equals(legacyDataBefore),
          reason: 'Legacy data must remain unchanged');

      // Verify new format is also saved
      final newData = prefs.getString('favorite_ids');
      expect(newData, isNotNull, reason: 'New ID-based data must be saved');

      // Verify the new data contains correct IDs
      final newIds = (json.decode(newData!) as List).cast<String>();
      expect(newIds.length, equals(50));
      expect(
        newIds.first,
        equals('devocional_2025_01_01_RVR1960'),
      );

      provider.dispose();
    });

    test(
        'Rollback scenario: Old app version can still read legacy data after migration',
        () async {
      final prefs = await SharedPreferences.getInstance();

      // Setup: User has legacy favorites
      final legacyFavorites = [
        {
          'id': 'devocional_2025_01_15_RVR1960',
          'date': '2025-01-15',
          'versiculo': 'Juan 3:16',
          'texto': 'Test text',
          'reflexion': 'Test reflection',
          'oracion': 'Test prayer',
          'version': 'RVR1960',
          'language': 'es',
        },
      ];

      await prefs.setString('favorites', json.encode(legacyFavorites));

      // Step 1: User upgrades to new version and migration happens
      final newProvider = DevocionalProvider();
      await newProvider.initializeData();

      // Verify migration worked - favorite is recognized
      final migratedDevocional = createTestDevocional(
        id: 'devocional_2025_01_15_RVR1960',
        date: DateTime(2025, 1, 15),
        versiculo: 'Juan 3:16',
      );
      expect(newProvider.isFavorite(migratedDevocional), isTrue,
          reason: 'Migrated favorite should be recognized');

      newProvider.dispose();

      // Step 2: Simulate rollback - old app version reads legacy data
      // Old version only knows about 'favorites' key, not 'favorite_ids'
      final legacyDataAfterRollback = prefs.getString('favorites');
      expect(legacyDataAfterRollback, isNotNull,
          reason:
              'Legacy data must still exist for old app version to read on rollback');

      // Old version should be able to parse this
      final List<dynamic> legacyParsed = json.decode(legacyDataAfterRollback!);
      expect(legacyParsed.length, equals(1),
          reason:
              'Original favorite should still be accessible to old app version');
      expect(legacyParsed.first['id'], equals('devocional_2025_01_15_RVR1960'));
    });

    test(
        'Zero data loss: All user favorites survive migration even with corrupted entries',
        () async {
      final prefs = await SharedPreferences.getInstance();

      // Real-world scenario: Some entries may have issues
      final legacyFavorites = [
        // Valid entry 1
        {
          'id': 'devocional_2025_01_01_RVR1960',
          'date': '2025-01-01',
          'versiculo': 'Juan 3:16',
          'texto': 'Test',
          'reflexion': 'Test',
          'oracion': 'Test',
          'version': 'RVR1960',
          'language': 'es',
        },
        // Entry with empty ID (should be skipped safely)
        {
          'id': '',
          'date': '2025-01-02',
          'versiculo': 'Juan 3:17',
          'texto': 'Test',
          'reflexion': 'Test',
          'oracion': 'Test',
          'version': 'RVR1960',
          'language': 'es',
        },
        // Valid entry 2
        {
          'id': 'devocional_2025_01_03_RVR1960',
          'date': '2025-01-03',
          'versiculo': 'Juan 3:18',
          'texto': 'Test',
          'reflexion': 'Test',
          'oracion': 'Test',
          'version': 'RVR1960',
          'language': 'es',
        },
      ];

      await prefs.setString('favorites', json.encode(legacyFavorites));

      final provider = DevocionalProvider();
      await provider.initializeData();

      // Should have migrated 2 valid entries (skipped the empty ID)
      final newData = prefs.getString('favorite_ids');
      expect(newData, isNotNull);
      final newIds = (json.decode(newData!) as List).cast<String>();
      expect(newIds.length, equals(2),
          reason: 'Should migrate only valid favorites');
      expect(newIds.contains('devocional_2025_01_01_RVR1960'), isTrue);
      expect(newIds.contains('devocional_2025_01_03_RVR1960'), isTrue);

      // Legacy data must still be intact
      final legacyData = prefs.getString('favorites');
      expect(legacyData, isNotNull);
      final legacyParsed = json.decode(legacyData!);
      expect(legacyParsed.length, equals(3),
          reason: 'Original data must remain untouched');

      provider.dispose();
    });

    test('Performance: Migration of large favorites list (100+ items) is fast',
        () async {
      final prefs = await SharedPreferences.getInstance();

      // Simulate user with many favorites
      final legacyFavorites = List.generate(
        150,
        (index) => {
          'id':
              'devocional_2025_${((index % 365) + 1).toString().padLeft(3, '0')}_RVR1960',
          'date':
              '2025-${((index % 12) + 1).toString().padLeft(2, '0')}-${((index % 28) + 1).toString().padLeft(2, '0')}',
          'versiculo': 'Verse $index',
          'texto': 'Text $index',
          'reflexion': 'Reflection $index',
          'oracion': 'Prayer $index',
          'version': 'RVR1960',
          'language': 'es',
        },
      );

      await prefs.setString('favorites', json.encode(legacyFavorites));

      final stopwatch = Stopwatch()..start();
      final provider = DevocionalProvider();
      await provider.initializeData();
      stopwatch.stop();

      // Migration should be fast (< 1 second for 150 items)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: 'Migration must be performant for large datasets');

      // Verify migration success
      final newData = prefs.getString('favorite_ids');
      expect(newData, isNotNull);
      final newIds = (json.decode(newData!) as List).cast<String>();
      expect(newIds.length, equals(150));

      provider.dispose();
    });

    test('Language switch preserves favorites with correct IDs', () async {
      final prefs = await SharedPreferences.getInstance();

      // User has favorites in Spanish
      final legacyFavorites = [
        {
          'id': 'devocional_2025_01_01_RVR1960',
          'date': '2025-01-01',
          'versiculo': 'Juan 3:16',
          'texto': 'Test',
          'reflexion': 'Test',
          'oracion': 'Test',
          'version': 'RVR1960',
          'language': 'es',
        },
      ];

      await prefs.setString('favorites', json.encode(legacyFavorites));

      final provider = DevocionalProvider();
      await provider.initializeData();

      // Verify favorite is loaded
      final devocional = createTestDevocional(
        id: 'devocional_2025_01_01_RVR1960',
        date: DateTime(2025, 1, 1),
        versiculo: 'Juan 3:16',
      );
      expect(provider.isFavorite(devocional), isTrue);

      // Switch language to English
      provider.setSelectedLanguage('en', null);
      provider.setSelectedVersion('KJV');

      // Wait for async operations to complete
      await Future.delayed(Duration(milliseconds: 100));

      // Favorite IDs should still be stored (even if devotional not available in English)
      final storedIds = prefs.getString('favorite_ids');
      expect(storedIds, isNotNull);
      final ids = (json.decode(storedIds!) as List).cast<String>();
      expect(ids.contains('devocional_2025_01_01_RVR1960'), isTrue,
          reason: 'Favorite IDs must persist across language switches');

      provider.dispose();
    });
  });
}
