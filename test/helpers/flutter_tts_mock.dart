// test/helpers/flutter_tts_mock.dart

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart' as flutter_test;

class FlutterTtsMock {
  static const MethodChannel _channel = MethodChannel('flutter_tts');

  static void setup() {
    flutter_test
        .TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, _handleMethodCall);
  }

  static void tearDown() {
    flutter_test
        .TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'setSpeechRate':
      case 'setLanguage':
      case 'speak':
      case 'stop':
      case 'pause':
      case 'setVolume':
      case 'setPitch':
      case 'awaitSpeakCompletion':
      case 'awaitSynthCompletion':
        return 1;
      case 'getLanguages':
        return ['en-US', 'es-ES'];
      case 'getVoices':
        return [
          {'name': 'en-US-Standard-C', 'locale': 'en-US'},
          {'name': 'es-ES-Standard-A', 'locale': 'es-ES'},
        ];
      default:
        return null;
    }
  }
}
