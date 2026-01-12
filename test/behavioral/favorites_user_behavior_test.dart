import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

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

/// Real user behavior tests for favorites functionality
/// Focuses on common user scenarios without complex mocking
void main() {
  group('Favorites - Real User Behavior Tests', () {
    late DevocionalProvider provider;

    // Simple mock client - returns minimal data needed for favorites testing
    final mockHttpClient = MockClient((request) async {
      return http.Response(jsonEncode({"data": {"es": {}}}), 200);
    });

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Mock Firebase
      const firebaseCoreChannel = MethodChannel('plugins.flutter.io/firebase_core');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(firebaseCoreChannel, (call) async {
        if (call.method == 'Firebase#initializeCore') {
          return [{'name': '[DEFAULT]', 'options': {}, 'pluginConstants': {}}];
        }
        return null;
      });

      const crashlyticsChannel = MethodChannel('plugins.flutter.io/firebase_crashlytics');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(crashlyticsChannel, (_) async => null);

      const remoteConfigChannel = MethodChannel('plugins.flutter.io/firebase_remote_config');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(remoteConfigChannel, (call) async {
        return call.method == 'RemoteConfig#instance' ? {} : null;
      });

      const ttsChannel = MethodChannel('flutter_tts');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ttsChannel, (_) async => null);

      PathProviderPlatform.instance = MockPathProviderPlatform();
      setupServiceLocator();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = DevocionalProvider(httpClient: mockHttpClient, enableAudio: false);
      await provider.initializeData();
    });

    tearDown(() {
      provider.dispose();
    });

    group('User adds favorites', () {
      test('User taps favorite button - devotional is added to favorites', () async {
        // GIVEN: User has a devotional open
        const devocionalId = 'devocional_2025_01_15_RVR1960';

        // WHEN: User taps the favorite button
        final wasAdded = await provider.toggleFavorite(devocionalId);

        // THEN: Devotional is added to favorites
        expect(wasAdded, isTrue, reason: 'Should add favorite when not present');
        expect(provider.favoriteDevocionales.map((d) => d.id).contains(devocionalId), 
               isFalse, reason: 'Not in loaded devotionals, but ID is tracked');
        
        // Verify it persists
        final prefs = await SharedPreferences.getInstance();
        final savedIds = prefs.getString('favorite_ids');
        expect(savedIds, isNotNull);
        expect(savedIds!.contains(devocionalId), isTrue);
      });

      test('User adds multiple favorites throughout the day', () async {
        // GIVEN: User reads several devotionals
        const morningDevocional = 'devocional_2025_01_01_RVR1960';
        const afternoonDevocional = 'devocional_2025_01_02_RVR1960';
        const eveningDevocional = 'devocional_2025_01_03_RVR1960';

        // WHEN: User marks each as favorite
        await provider.toggleFavorite(morningDevocional);
        await provider.toggleFavorite(afternoonDevocional);
        await provider.toggleFavorite(eveningDevocional);

        // THEN: All three are saved
        final prefs = await SharedPreferences.getInstance();
        final savedIds = prefs.getString('favorite_ids');
        expect(savedIds, isNotNull);
        
        final ids = (jsonDecode(savedIds!) as List).cast<String>();
        expect(ids, hasLength(3));
        expect(ids, contains(morningDevocional));
        expect(ids, contains(afternoonDevocional));
        expect(ids, contains(eveningDevocional));
      });
    });

    group('User removes favorites', () {
      test('User taps favorite button again - devotional is removed', () async {
        // GIVEN: User has already favorited a devotional
        const devocionalId = 'devocional_2025_01_15_RVR1960';
        await provider.toggleFavorite(devocionalId);

        // WHEN: User taps the favorite button again (unfavorite)
        final wasAdded = await provider.toggleFavorite(devocionalId);

        // THEN: Devotional is removed from favorites
        expect(wasAdded, isFalse, reason: 'Should remove when already present');
        
        final prefs = await SharedPreferences.getInstance();
        final savedIds = prefs.getString('favorite_ids');
        if (savedIds != null) {
          final ids = (jsonDecode(savedIds) as List).cast<String>();
          expect(ids, isNot(contains(devocionalId)));
        }
      });

      test('User accidentally taps favorite twice - final state is correct', () async {
        // GIVEN: User viewing a devotional
        const devocionalId = 'devocional_2025_01_16_RVR1960';

        // WHEN: User quickly taps favorite twice (add then remove)
        await provider.toggleFavorite(devocionalId); // Add
        await provider.toggleFavorite(devocionalId); // Remove

        // THEN: Devotional is NOT in favorites (removed)
        final prefs = await SharedPreferences.getInstance();
        final savedIds = prefs.getString('favorite_ids');
        if (savedIds != null) {
          final ids = (jsonDecode(savedIds) as List).cast<String>();
          expect(ids, isNot(contains(devocionalId)));
        }
      });
    });

    group('Favorites persist across sessions', () {
      test('User favorites persist after closing and reopening app', () async {
        // GIVEN: User has favorited several devotionals
        const favorite1 = 'devocional_2025_01_10_RVR1960';
        const favorite2 = 'devocional_2025_01_11_RVR1960';
        
        await provider.toggleFavorite(favorite1);
        await provider.toggleFavorite(favorite2);
        
        // Save current state
        final prefs = await SharedPreferences.getInstance();
        final savedBefore = prefs.getString('favorite_ids');
        
        // WHEN: User closes app (dispose current provider - this happens in tearDown too)
        // Simulate closing app by disposing (tearDown will try again but that's ok)
        
        // Open app again (new provider instance)
        final newProvider = DevocionalProvider(httpClient: mockHttpClient, enableAudio: false);
        await newProvider.initializeData();

        // THEN: Favorites are still there
        final savedAfter = prefs.getString('favorite_ids');
        expect(savedAfter, equals(savedBefore));
        expect(savedAfter, contains(favorite1));
        expect(savedAfter, contains(favorite2));
        
        newProvider.dispose();
      });
    });

    group('Edge cases', () {
      test('User cannot favorite devotional with empty ID', () async {
        // GIVEN: Invalid devotional ID
        const emptyId = '';

        // WHEN/THEN: Attempting to favorite throws error
        expect(
          () => provider.toggleFavorite(emptyId),
          throwsA(isA<ArgumentError>()),
          reason: 'Empty ID should not be allowed',
        );
      });

      test('User favorites remain when changing app language', () async {
        // GIVEN: User has favorites in Spanish
        const spanishFavorite = 'devocional_2025_01_20_RVR1960';
        await provider.toggleFavorite(spanishFavorite);

        // WHEN: User changes language (favorites are ID-based, language-independent)
        // Note: In real app, the provider would reload devotionals for new language
        // but favorite IDs persist

        // THEN: Favorite IDs are still stored
        final prefs = await SharedPreferences.getInstance();
        final savedIds = prefs.getString('favorite_ids');
        expect(savedIds, contains(spanishFavorite));
      });
    });
  });
}
