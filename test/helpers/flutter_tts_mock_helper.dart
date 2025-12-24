import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper class to set up flutter_tts plugin mocking for tests
/// This avoids MissingPluginException in tests that interact with TTS functionality
class FlutterTtsMockHelper {
  /// The flutter_tts MethodChannel - shared across all mock methods
  static const MethodChannel _ttsChannel = MethodChannel('flutter_tts');

  /// Sets up mock method call handler for flutter_tts plugin
  ///
  /// This should be called in setUp() of tests that use TTS features.
  /// It mocks all essential flutter_tts methods including getVoices,
  /// setLanguage, setSpeechRate, speak, stop, pause, etc.
  ///
  /// Example usage:
  /// ```dart
  /// setUp(() {
  ///   TestWidgetsFlutterBinding.ensureInitialized();
  ///   FlutterTtsMockHelper.setupMockFlutterTts();
  ///   // ... other setup
  /// });
  /// ```
  static void setupMockFlutterTts() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      _ttsChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getVoices':
            // Return comprehensive list of voices for all supported languages
            // This includes Spanish, English, Portuguese, French, Japanese, and Chinese
            return _getMockVoices();
          case 'setLanguage':
          case 'setSpeechRate':
          case 'speak':
          case 'stop':
          case 'pause':
          case 'setVolume':
          case 'setPitch':
          case 'setQueueMode':
          case 'awaitSpeakCompletion':
          case 'setVoice':
            // Return success for all setter methods
            return Future.value(1);
          case 'getLanguages':
            // Return list of supported languages
            return ['es-ES', 'en-US', 'pt-BR', 'fr-FR', 'ja-JP', 'zh-CN'];
          default:
            // Return null for any other method
            return Future.value();
        }
      },
    );
  }

  /// Returns a mock list of TTS voices for all supported languages
  static List<Map<String, String>> _getMockVoices() {
    return [
      // Spanish voices
      {'name': 'es-es-x-eee-local', 'locale': 'es-ES'},
      {'name': 'es-es-x-eef-local', 'locale': 'es-ES'},
      {'name': 'es-us-x-sfb-local', 'locale': 'es-US'},

      // English voices
      {'name': 'en-us-x-iom-local', 'locale': 'en-US'},
      {'name': 'en-us-x-iog-local', 'locale': 'en-US'},
      {'name': 'en-gb-x-gba-local', 'locale': 'en-GB'},

      // Portuguese voices
      {'name': 'pt-br-x-afs-local', 'locale': 'pt-BR'},
      {'name': 'pt-br-x-afe-local', 'locale': 'pt-BR'},

      // French voices
      {'name': 'fr-fr-x-vlf-local', 'locale': 'fr-FR'},
      {'name': 'fr-fr-x-fre-local', 'locale': 'fr-FR'},

      // Japanese voices
      {'name': 'ja-jp-x-jab-local', 'locale': 'ja-JP'},
      {'name': 'ja-jp-x-jac-local', 'locale': 'ja-JP'},

      // Chinese voices (Simplified and Traditional)
      {'name': 'cmn-cn-x-cce-local', 'locale': 'zh-CN'},
      {'name': 'cmn-cn-x-ccc-local', 'locale': 'zh-CN'},
      {'name': 'cmn-tw-x-cte-network', 'locale': 'zh-TW'},
      {'name': 'cmn-tw-x-ctc-network', 'locale': 'zh-TW'},
    ];
  }

  /// Cleans up the mock handler
  /// Call this in tearDown() if you need to reset the mock state
  static void tearDownMockFlutterTts() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_ttsChannel, null);
  }
}
