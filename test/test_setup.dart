import 'dart:io';

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

    // Mock path_provider plugin with a more realistic temp directory
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getApplicationDocumentsDirectory':
            return Directory.systemTemp.path; // Use actual temp directory
          case 'getTemporaryDirectory':
            return Directory.systemTemp.path;
          case 'getApplicationSupportDirectory':
            return Directory.systemTemp.path;
          default:
            return Directory.systemTemp.path;
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
            return null;
          case 'setQueueMode':
            return null;
          case 'stop':
            return null;
          case 'pause':
            return null;
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
