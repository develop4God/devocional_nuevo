// test/providers/favorites_provider_test.dart
// High-value user behavior tests for favorites functionality

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

/// Real user behavior tests for favorites
/// Focuses on common scenarios without implementation details
void main() {
  late DevocionalProvider provider;

  // Simple mock client
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

  group('Real User Behavior - Favorites', () {
    test('User rapidly taps favorite button - handles concurrent toggles',
        () async {
      // GIVEN: User viewing a devotional
      const devocionalId = 'dev_123';

      // WHEN: User rapidly taps favorite button multiple times (10 taps)
      final futures =
          List.generate(10, (_) => provider.toggleFavorite(devocionalId));
      await Future.wait(futures);

      // THEN: After even number of toggles (10), should NOT be in favorites
      // Starting state: not favorite (0)
      // After 10 toggles: back to not favorite
      final prefs = await SharedPreferences.getInstance();
      final savedIds = prefs.getString('favorite_ids');
      if (savedIds != null) {
        final ids = (jsonDecode(savedIds) as List).cast<String>();
        expect(ids, isNot(contains(devocionalId)),
            reason: 'Even number of toggles should result in not favorite');
      }
    });

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

    test('User can handle corrupted data gracefully', () async {
      // GIVEN: User has corrupted favorite data (edge case)
      // This can happen from manual SharedPreferences editing or file corruption

      // Create a separate provider just for this test
      final newProvider =
          DevocionalProvider(httpClient: mockHttpClient, enableAudio: false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('favorite_ids', 'not-valid-json');

      // WHEN: Provider initializes with corrupted data
      // THEN: Should not crash, should handle gracefully
      await expectLater(newProvider.initializeData(), completes,
          reason: 'Should handle corrupted data without crashing');

      newProvider.dispose();
    });
  });
}
