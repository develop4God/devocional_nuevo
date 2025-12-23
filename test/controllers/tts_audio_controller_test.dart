import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TtsAudioController', () {
    late TtsAudioController controller;
    late FlutterTts mockFlutterTts;

    setUp(() {
      registerTestServices();
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
            default:
              return null;
          }
        },
      );

      mockFlutterTts = FlutterTts();
      controller = TtsAudioController(flutterTts: mockFlutterTts);
    });

    tearDown(() {
      controller.dispose();
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

    test('setText calculates duration for Chinese text based on characters',
        () {
      const chineseText = '哥林多后书 4:16-18 和合本1919: "所以，我们不丧志；外体虽然毁坏，内心却一天新似一天。"';
      controller.setText(chineseText, languageCode: 'zh');

      // Chinese: ~7 characters per second
      final chars = chineseText.replaceAll(RegExp(r'\s+'), '').length;
      final expectedSeconds = (chars / 7.0).round();

      expect(controller.totalDuration.value.inSeconds, expectedSeconds);
      debugPrint(
          'Chinese text: $chars chars -> ${controller.totalDuration.value.inSeconds}s (expected: $expectedSeconds)');
    });

    test('setText calculates duration for Japanese text based on characters',
        () {
      const japaneseText =
          'ヨハネの福音書 3:16 新改訳2003: 「神は、実に、そのひとり子をお与えになったほどに世を愛された。」';
      controller.setText(japaneseText, languageCode: 'ja');

      // Japanese: ~7 characters per second
      final chars = japaneseText.replaceAll(RegExp(r'\s+'), '').length;
      final expectedSeconds = (chars / 7.0).round();

      expect(controller.totalDuration.value.inSeconds, expectedSeconds);
      debugPrint(
          'Japanese text: $chars chars -> ${controller.totalDuration.value.inSeconds}s (expected: $expectedSeconds)');
    });

    test('setText calculates duration for English text based on words', () {
      const englishText =
          'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.';
      controller.setText(englishText, languageCode: 'en');

      // English: words per second (150 words per minute = 2.5 words/sec)
      final words = englishText.split(RegExp(r'\s+')).length;
      final expectedSeconds = (words / (150.0 / 60.0)).round();

      expect(controller.totalDuration.value.inSeconds, expectedSeconds);
      debugPrint(
          'English text: $words words -> ${controller.totalDuration.value.inSeconds}s (expected: $expectedSeconds)');
    });

    test('setText calculates duration for Spanish text based on words', () {
      const spanishText =
          'Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito, para que todo aquel que en él cree, no se pierda, mas tenga vida eterna.';
      controller.setText(spanishText, languageCode: 'es');

      // Spanish: words per second (150 words per minute = 2.5 words/sec)
      final words = spanishText.split(RegExp(r'\s+')).length;
      final expectedSeconds = (words / (150.0 / 60.0)).round();

      expect(controller.totalDuration.value.inSeconds, expectedSeconds);
      debugPrint(
          'Spanish text: $words words -> ${controller.totalDuration.value.inSeconds}s (expected: $expectedSeconds)');
    });

    test('Chinese duration estimation is consistent', () {
      const text1 = '创世记 1:1 和合本1919: "起初，神创造天地。"';
      const text2 = '约翰福音 3:16 和合本1919: "神爱世人，甚至将他的独生子赐给他们，叫一切信他的，不至灭亡，反得永生。"';

      controller.setText(text1, languageCode: 'zh');
      final duration1 = controller.totalDuration.value;

      controller.setText(text2, languageCode: 'zh');
      final duration2 = controller.totalDuration.value;

      // text2 should take longer than text1 (more characters)
      expect(duration2.inSeconds, greaterThan(duration1.inSeconds));
      debugPrint(
          'Chinese text1: ${duration1.inSeconds}s, text2: ${duration2.inSeconds}s');
    });
  });
}
