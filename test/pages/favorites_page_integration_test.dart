// test/providers/favorites_high_value_test.dart

import 'dart:convert';

import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock TTS channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => null,
    );

    // Mock audio channels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_session'),
      (call) async {
        if (call.method == 'getConfiguration') {
          return {'androidAudioAttributes': 1, 'androidAudioFocusGainType': 1};
        }
        return null;
      },
    );

    // Mock path_provider
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getApplicationDocumentsDirectory':
          case 'getApplicationDocumentsPath': // Support both
            return '/mock_documents';
          case 'getTemporaryDirectory':
          case 'getTemporaryPath': // Support both
            return '/mock_temp';
          default:
            return null;
        }
      },
    );

    setupServiceLocator();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Favorites persist across app restarts', () async {
    // Session 1: Add favorite
    final provider1 = DevocionalProvider();
    await provider1.addFavoriteId('dev_123');
    await provider1.saveFavorites();
    provider1.dispose(); // Timers disposed here

    // Session 2: Verify persistence
    final provider2 = DevocionalProvider();
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('favorite_ids');
    expect(stored, contains('dev_123'));
    provider2.dispose(); // Timers disposed here
  });

  test('Favorites survive language change', () async {
    SharedPreferences.setMockInitialValues({'favorite_ids': '["dev_123"]'});
    final provider = DevocionalProvider();
    await provider.addFavoriteId('dev_123');

    // Switch languages
    provider.setSelectedLanguage('en', null);
    provider.setSelectedLanguage('es', null);

    // Verify favorite still in memory
    final prefs = await SharedPreferences.getInstance();
    final stored = json.decode(prefs.getString('favorite_ids')!);
    expect(stored, contains('dev_123'));
    provider.dispose(); // Dispose only after all usage
  });

  test('Multiple rapid toggles resolve correctly', () async {
    final provider = DevocionalProvider();
    final id = 'dev_concurrent';

    // 5 rapid toggles
    await Future.wait(List.generate(5, (_) => provider.toggleFavorite(id)));

    // Should be added (odd number)
    final prefs = await SharedPreferences.getInstance();
    final stored = json.decode(prefs.getString('favorite_ids')!);
    expect(stored, contains(id));
    expect(stored.where((x) => x == id).length, equals(1)); // No duplicates

    provider.dispose();
  });
}
