import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TtsAudioController', () {
    late TtsAudioController controller;
    late FlutterTts mockFlutterTts;

    setUp(() {
      // Reset ServiceLocator for clean test state
      ServiceLocator().reset();

      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Mock the flutter_tts platform channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (call) async {
          switch (call.method) {
            case 'speak':
            case 'stop':
            case 'pause':
            case 'setLanguage':
            case 'setSpeechRate':
            case 'setVolume':
            case 'setPitch':
            case 'awaitSpeakCompletion':
              return 1;
            case 'getVoices':
              return [
                {'name': 'Voice ES', 'locale': 'es-ES'},
                {'name': 'Voice EN', 'locale': 'en-US'},
              ];
            default:
              return null;
          }
        },
      );

      // Register required services
      ServiceLocator().registerLazySingleton<VoiceSettingsService>(
          () => VoiceSettingsService());

      mockFlutterTts = FlutterTts();
      controller = TtsAudioController(flutterTts: mockFlutterTts);
    });

    tearDown(() {
      controller.dispose();
      // Clean up ServiceLocator
      ServiceLocator().reset();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    });

    test('initial state is idle', () {
      debugPrint('Estado inicial: ${controller.state.value}');
      expect(controller.state.value, TtsPlayerState.idle);
    });

    test('play sets state to loading then playing when text is set', () async {
      controller.setText('Test text');
      debugPrint('Antes de play: ${controller.state.value}');
      await controller.play();
      debugPrint('Después de play: ${controller.state.value}');
      expect(controller.state.value, TtsPlayerState.playing);
    });

    test('play sets state to error when no text is set', () async {
      debugPrint('Antes de play sin texto: ${controller.state.value}');
      await controller.play();
      debugPrint('Después de play sin texto: ${controller.state.value}');
      expect(controller.state.value, TtsPlayerState.error);
    });

    test('pause sets state to paused', () async {
      controller.setText('Test text');
      await controller.play();
      debugPrint('Antes de pause: ${controller.state.value}');
      await controller.pause();
      debugPrint('Después de pause: ${controller.state.value}');
      expect(controller.state.value, TtsPlayerState.paused);
    });

    test('stop sets state to idle', () async {
      controller.setText('Test text');
      await controller.play();
      debugPrint('Antes de stop: ${controller.state.value}');
      await controller.stop();
      debugPrint('Después de stop: ${controller.state.value}');
      expect(controller.state.value, TtsPlayerState.idle);
    });

    test('complete sets state to completed', () async {
      controller.setText('Test text');
      await controller.play();
      debugPrint('Antes de complete: ${controller.state.value}');
      controller.complete();
      debugPrint('Después de complete: ${controller.state.value}');
      expect(controller.state.value, TtsPlayerState.completed);
    });

    test('error sets state to error', () async {
      controller.setText('Test text');
      await controller.play();
      debugPrint('Antes de error: ${controller.state.value}');
      controller.error();
      debugPrint('Después de error: ${controller.state.value}');
      expect(controller.state.value, TtsPlayerState.error);
    });
  });
}
