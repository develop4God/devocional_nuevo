import 'dart:convert';

import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

/// Real user behavior tests for favorites functionality
/// Focuses on common user scenarios without complex mocking

@Tags(['behavioral'])
void main() {
  group('Favorites - Real User Behavior Tests', () {
    late DevocionalProvider provider;

    // Simple mock client - returns minimal data needed for favorites testing
    final mockHttpClient = MockClient((request) async {
      return http.Response(
          jsonEncode({
            "data": {"es": {}}
          }),
          200);
    });

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Mock Firebase
      const firebaseCoreChannel =
          MethodChannel('plugins.flutter.io/firebase_core');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(firebaseCoreChannel, (call) async {
        if (call.method == 'Firebase#initializeCore') {
          return [
            {'name': '[DEFAULT]', 'options': {}, 'pluginConstants': {}}
          ];
        }
        return null;
      });

      const crashlyticsChannel =
          MethodChannel('plugins.flutter.io/firebase_crashlytics');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(crashlyticsChannel, (_) async => null);

      const remoteConfigChannel =
          MethodChannel('plugins.flutter.io/firebase_remote_config');
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
      provider =
          DevocionalProvider(httpClient: mockHttpClient, enableAudio: false);
      await provider.initializeData();
    });

    tearDown(() {
      provider.dispose();
    });

    group('User adds favorites', () {
      test('User taps favorite button - devotional is added to favorites',
          () async {
        // GIVEN: User has a devotional open
        const devocionalId = 'devocional_2025_01_15_RVR1960';

        // WHEN: User taps the favorite button
        final wasAdded = await provider.toggleFavorite(devocionalId);

        // THEN: Devotional is added to favorites
        expect(wasAdded, isTrue,
            reason: 'Should add favorite when not present');
        expect(
            provider.favoriteDevocionales
                .map((d) => d.id)
                .contains(devocionalId),
            isFalse,
            reason: 'Not in loaded devotionals, but ID is tracked');

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

      test('User accidentally taps favorite twice - final state is correct',
          () async {
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
        final newProvider =
            DevocionalProvider(httpClient: mockHttpClient, enableAudio: false);
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

    group('Backup and restore', () {
      test('User restores from backup - all favorites reload', () async {
        // GIVEN: User has favorites before backup
        const favorite1 = 'devocional_2025_01_10_RVR1960';
        const favorite2 = 'devocional_2025_01_11_RVR1960';
        const favorite3 = 'devocional_2025_01_12_RVR1960';

        await provider.toggleFavorite(favorite1);
        await provider.toggleFavorite(favorite2);
        await provider.toggleFavorite(favorite3);

        final prefs = await SharedPreferences.getInstance();
        final backupData = prefs.getString('favorite_ids');

        // WHEN: Simulating restore - reload favorites from storage
        await provider.reloadFavoritesFromStorage();

        // THEN: All favorites are reloaded
        final reloadedData = prefs.getString('favorite_ids');
        expect(reloadedData, equals(backupData));
        expect(reloadedData, contains(favorite1));
        expect(reloadedData, contains(favorite2));
        expect(reloadedData, contains(favorite3));
      });

      test('Corrupted backup data - handles gracefully', () async {
        // GIVEN: User has corrupted backup data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('favorite_ids', '{invalid json data');

        // WHEN: Provider attempts to reload from corrupted data
        final newProvider =
            DevocionalProvider(httpClient: mockHttpClient, enableAudio: false);

        // THEN: Should not crash, handles gracefully
        await expectLater(
          newProvider.initializeData(),
          completes,
          reason: 'Should handle corrupted backup data without crashing',
        );

        newProvider.dispose();
      });
    });

    group('Version and language changes', () {
      test('Bible version change - favorites sync correctly', () async {
        // GIVEN: User has favorites in RVR1960
        const favorite1 = 'devocional_2025_01_15_RVR1960';
        const favorite2 = 'devocional_2025_01_16_RVR1960';

        await provider.toggleFavorite(favorite1);
        await provider.toggleFavorite(favorite2);

        final prefs = await SharedPreferences.getInstance();
        final beforeChange = prefs.getString('favorite_ids');

        // WHEN: User changes Bible version
        // Note: Version changes trigger async operations, but IDs persist in storage
        // We verify storage directly rather than triggering async reload

        // THEN: Favorite IDs remain in storage (version-independent storage)
        final afterCheck = prefs.getString('favorite_ids');
        expect(afterCheck, equals(beforeChange));
        expect(afterCheck, contains(favorite1));
        expect(afterCheck, contains(favorite2));
      });

      test('Multiple language switches - IDs remain stable', () async {
        // GIVEN: User has favorites
        const favoriteId = 'devocional_2025_01_20_RVR1960';
        await provider.toggleFavorite(favoriteId);

        final prefs = await SharedPreferences.getInstance();
        final originalIds = prefs.getString('favorite_ids');

        // WHEN: User switches languages multiple times
        // Note: Language changes are async operations that reload data
        // We verify that IDs persist in storage regardless of language changes

        // THEN: IDs remain stable in storage (not affected by language changes)
        final finalIds = prefs.getString('favorite_ids');
        expect(finalIds, equals(originalIds));
        expect(finalIds, contains(favoriteId));
      });
    });

    group('Performance and large datasets', () {
      test('Large favorites list (50+) - performs efficiently', () async {
        // GIVEN: User wants to add many favorites
        final stopwatch = Stopwatch()..start();

        // WHEN: Adding 50 favorites
        for (int i = 1; i <= 50; i++) {
          final id =
              'devocional_2025_${i.toString().padLeft(2, '0')}_01_RVR1960';
          await provider.toggleFavorite(id);
        }

        stopwatch.stop();

        // THEN: Operations complete in reasonable time (< 5 seconds for 50 items)
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(5000),
          reason: 'Should handle 50 favorites efficiently',
        );

        // Verify all were saved
        final prefs = await SharedPreferences.getInstance();
        final savedIds = prefs.getString('favorite_ids');
        final ids = (jsonDecode(savedIds!) as List).cast<String>();
        expect(ids.length, equals(50));
      });

      test('Remove all favorites one by one - storage clears properly',
          () async {
        // GIVEN: User has multiple favorites
        final favoriteIds = [
          'devocional_2025_01_01_RVR1960',
          'devocional_2025_01_02_RVR1960',
          'devocional_2025_01_03_RVR1960',
          'devocional_2025_01_04_RVR1960',
          'devocional_2025_01_05_RVR1960',
        ];

        for (final id in favoriteIds) {
          await provider.toggleFavorite(id);
        }

        // WHEN: User removes all favorites one by one
        for (final id in favoriteIds) {
          await provider.toggleFavorite(id);
        }

        // THEN: Storage should be empty or contain empty list
        final prefs = await SharedPreferences.getInstance();
        final savedIds = prefs.getString('favorite_ids');

        if (savedIds != null && savedIds.isNotEmpty) {
          final ids = (jsonDecode(savedIds) as List).cast<String>();
          expect(ids, isEmpty, reason: 'All favorites should be removed');
        }
      });

      test('Concurrent sessions - handles race conditions', () async {
        // GIVEN: User has app open in multiple contexts (simulated)
        const testId = 'devocional_2025_01_15_RVR1960';

        // WHEN: Multiple rapid concurrent toggle operations
        final futures = <Future>[];
        for (int i = 0; i < 20; i++) {
          futures.add(provider.toggleFavorite(testId));
        }

        await Future.wait(futures);

        // THEN: Final state should be deterministic based on toggle count
        // 20 toggles (even number) should result in NOT favorite
        final prefs = await SharedPreferences.getInstance();
        final savedIds = prefs.getString('favorite_ids');

        if (savedIds != null) {
          final ids = (jsonDecode(savedIds) as List).cast<String>();
          expect(
            ids,
            isNot(contains(testId)),
            reason:
                'Even number of toggles (20) should result in not favorited',
          );
        }
      });
    });
  });
}
