import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Common test setup utilities for mocking Flutter plugins
class TestSetup {
  /// Sets up common plugin mocks required by most tests
  static void setupCommonMocks() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Mock MethodChannel for platform-specific services
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getAll':
            return <String, dynamic>{}; // Empty preferences
          case 'getBool':
          case 'getInt':
          case 'getDouble':
          case 'getString':
          case 'getStringList':
            return null;
          case 'setBool':
          case 'setInt':
          case 'setDouble':
          case 'setString':
          case 'setStringList':
            return true;
          case 'remove':
          case 'clear':
            return true;
          default:
            return null;
        }
      },
    );

    // Mock path_provider plugin with web-compatible mock paths
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        // Use web-compatible mock paths
        final mockPath = kIsWeb ? '/mock_app_dir' : (Directory.systemTemp.path);
        switch (methodCall.method) {
          case 'getApplicationDocumentsDirectory':
            return mockPath;
          case 'getTemporaryDirectory':
            return mockPath;
          case 'getApplicationSupportDirectory':
            return mockPath;
          default:
            return mockPath;
        }
      },
    );

    // Mock flutter_tts plugin
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'speak':
            return null;
          case 'setLanguage':
            return 1;
          case 'setSpeechRate':
            return 1;
          case 'setVolume':
            return 1;
          case 'setPitch':
            return 1;
          case 'setVoice':
            return null;
          case 'getLanguages':
            return ['es-ES', 'en-US', 'pt-BR', 'fr-FR'];
          case 'getVoices':
            return [
              {'name': 'Spanish Voice', 'locale': 'es-ES'},
              {'name': 'English Voice', 'locale': 'en-US'},
              {'name': 'Portuguese Voice', 'locale': 'pt-BR'},
              {'name': 'French Voice', 'locale': 'fr-FR'},
            ];
          case 'awaitSpeakCompletion':
            return true;
          case 'setQueueMode':
            return null;
          case 'stop':
            return null;
          case 'pause':
            return null;
          case 'getEngines':
            return [];
          case 'setEngine':
            return 1;
          case 'isLanguageAvailable':
            return true;
          default:
            return null;
        }
      },
    );

    // Mock other commonly used channels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/package_info_plus'),
      (MethodCall methodCall) async {
        return {
          'appName': 'Test App',
          'packageName': 'com.test.app',
          'version': '1.0.0',
          'buildNumber': '1',
        };
      },
    );

    // Mock Firebase-related plugins to avoid web compatibility issues
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_core'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'Firebase#initializeCore':
            return [];
          case 'Firebase#initializeApp':
            return null;
          default:
            return null;
        }
      },
    );

    // Mock connectivity plugin for web compatibility
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'check':
            return 'wifi';
          case 'wifiName':
          case 'wifiBSSID':
          case 'wifiIPAddress':
            return null;
          default:
            return null;
        }
      },
    );

    // Ensure additional web compatibility
    if (kIsWeb) {
      // Additional web-specific setup if needed
    }
  }

  /// Cleans up plugin mocks after tests
  static void cleanupMocks() {
    // Clean up method channel mocks
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/package_info_plus'),
      null,
    );
  }
}
