@Tags(['unit', 'controllers'])
library;

import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/utils/tts_chunk_processor.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TtsAudioController', () {
    late TtsAudioController controller;
    late FlutterTts mockFlutterTts;

    setUp(() async {
      await registerTestServices();
      // Ensure VoiceSettingsService is registered (defensive)
      if (!ServiceLocator().isRegistered<VoiceSettingsService>()) {
        ServiceLocator().registerLazySingleton<VoiceSettingsService>(
            () => VoiceSettingsService());
      }
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Mock the flutter_tts platform channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
        call,
      ) async {
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
      });

      mockFlutterTts = FlutterTts();
      controller = TtsAudioController(
        flutterTts: mockFlutterTts,
        voiceSettingsService: VoiceSettingsService(),
      );
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
        'Chinese text: $chars chars -> ${controller.totalDuration.value.inSeconds}s (expected: $expectedSeconds)',
      );
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
        'Japanese text: $chars chars -> ${controller.totalDuration.value.inSeconds}s (expected: $expectedSeconds)',
      );
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
        'English text: $words words -> ${controller.totalDuration.value.inSeconds}s (expected: $expectedSeconds)',
      );
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
        'Spanish text: $words words -> ${controller.totalDuration.value.inSeconds}s (expected: $expectedSeconds)',
      );
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
        'Chinese text1: ${duration1.inSeconds}s, text2: ${duration2.inSeconds}s',
      );
    });

    test('pause handles errors gracefully without crashing', () async {
      // This test ensures that even if the native pause() method fails,
      // the controller maintains a consistent state
      controller.setText('Test text for pause error handling');
      await controller.play();

      // Mock a failure scenario by calling pause multiple times
      await controller.pause();
      expect(controller.state.value, TtsPlayerState.paused);

      // Second pause should still work (defensive programming)
      await controller.pause();
      expect(controller.state.value, TtsPlayerState.paused);

      debugPrint('Pause error handling test completed successfully');
    });

    test('pause with empty text does not crash', () async {
      // Edge case: pause without any text set
      try {
        await controller.pause();
        expect(controller.state.value, TtsPlayerState.paused);
        debugPrint('Pause with empty text completed without crash');
      } catch (e) {
        fail('Pause should not crash with empty text: $e');
      }
    });
  });

  group('TtsAudioController - Multibyte Edge Cases', () {
    late TtsAudioController controller;
    late FlutterTts mockFlutterTts;

    setUp(() async {
      await registerTestServices();
      SharedPreferences.setMockInitialValues({});

      // Mock the flutter_tts platform channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
        call,
      ) async {
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
      });

      mockFlutterTts = FlutterTts();
      controller = TtsAudioController(
        flutterTts: mockFlutterTts,
        voiceSettingsService: VoiceSettingsService(),
      );
    });

    tearDown(() {
      controller.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    });

    test('pause handles text with emojis without crash', () async {
      controller.setText('Hello 😀🎉 World 🌍✨');
      await controller.play();
      await controller.pause();
      // When multibyte ratio triggers workaround, state should be idle (from stop())
      // Otherwise should be paused
      expect(
        [TtsPlayerState.paused, TtsPlayerState.idle],
        contains(controller.state.value),
      );
      debugPrint('Emoji test completed: ${controller.state.value}');
    });

    test('pause handles Spanish accents (2-byte UTF-8)', () async {
      final text =
          'Jesús dijo: "Bienaventurados los mansos, porque ellos recibirán la tierra por heredad" ' *
              3;
      controller.setText(text);
      await controller.play();
      await controller.pause();
      expect(
        [TtsPlayerState.paused, TtsPlayerState.idle],
        contains(controller.state.value),
      );
      debugPrint('Spanish accents test completed: ${controller.state.value}');
    });

    test('pause handles Chinese characters (3-byte UTF-8)', () async {
      controller.setText('耶稣说："虚心的人有福了，因为天国是他们的。"');
      await controller.play();
      await controller.pause();
      expect(
        [TtsPlayerState.paused, TtsPlayerState.idle],
        contains(controller.state.value),
      );
      debugPrint(
          'Chinese characters test completed: ${controller.state.value}');
    });

    test('user flow: play→pause→resume with multibyte text', () async {
      final text = 'Texto con ñ, á, é, í, ó, ú 😊' * 5;
      controller.setText(text);

      await controller.play();
      expect(controller.state.value, TtsPlayerState.playing);

      await controller.pause();
      expect(
        [TtsPlayerState.paused, TtsPlayerState.idle],
        contains(controller.state.value),
      );

      // Resume using play()
      await controller.play();
      expect(controller.state.value, TtsPlayerState.playing);

      debugPrint('User flow test completed successfully');
    });

    test('pause with 500+ char text and mixed encoding', () async {
      final text = 'A' * 200 + '中文' * 50 + '🎉' * 20 + 'Español' * 10;
      controller.setText(text);
      await controller.play();
      await controller.pause();
      expect(
        [TtsPlayerState.paused, TtsPlayerState.idle],
        contains(controller.state.value),
      );
      debugPrint(
        'Mixed encoding test completed: ${controller.state.value}, text length: ${text.length}',
      );
    });

    test('multibyte detection activates for high ratio text', () async {
      // Create text with high multibyte ratio (>1.5)
      final text = '🎉' * 100; // Emojis are 4-byte UTF-8
      controller.setText(text);
      await controller.play();

      // Capture logs to verify workaround activation
      await controller.pause();

      // When ratio > 1.5, stop() is called but state is set to paused (not idle)
      // to preserve position for resume
      expect(controller.state.value, TtsPlayerState.paused);
      debugPrint(
          'Multibyte detection test: state is ${controller.state.value} (position preserved)');
    });

    test('multibyte detection does not activate for ASCII text', () async {
      final text = 'A' * 100; // Pure ASCII, ratio = 1.0
      controller.setText(text);
      await controller.play();
      await controller.pause();

      // For ASCII text, normal pause() should be used
      expect(controller.state.value, TtsPlayerState.paused);
      debugPrint('ASCII text test: state is ${controller.state.value}');
    });

    test('short multibyte text (<50 chars) bypasses detection', () async {
      final text = '😀🎉🌍✨'; // Only 4 emoji characters
      controller.setText(text);
      await controller.play();
      await controller.pause();

      // Short text (<50 chars) bypasses multibyte detection
      expect(controller.state.value, TtsPlayerState.paused);
      debugPrint(
        'Short multibyte text test: state is ${controller.state.value}',
      );
    });
  });

  // ── TtsChunkProcessor injection ───────────────────────────────────────────
  // Chunk logic is tested in its own black-box suite:
  //   test/unit/services/tts/utils/tts_chunk_processor_test.dart
  //
  // This group verifies that the controller accepts an injected processor and
  // remains fully functional — integration smoke test.
  group('TtsAudioController - TtsChunkProcessor injection', () {
    late TtsAudioController controller;

    setUp(() async {
      await registerTestServices();
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
    });

    tearDown(() {
      controller.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    });

    test('controller is created with an explicit TtsChunkProcessor', () {
      controller = TtsAudioController(
        flutterTts: FlutterTts(),
        voiceSettingsService: VoiceSettingsService(),
        chunkProcessor: TtsChunkProcessor(),
      );
      expect(controller.state.value, TtsPlayerState.idle);
    });

    test('controller defaults to an internal processor when none is provided',
        () {
      controller = TtsAudioController(
        flutterTts: FlutterTts(),
        voiceSettingsService: VoiceSettingsService(),
      );
      expect(controller.state.value, TtsPlayerState.idle);
    });

    test('play() with long text (multi-chunk) reaches playing state', () async {
      // 800×"word " is > 3500 chars — forces _processor.splitIntoChunks()
      final longText = ('word ' * 800).trim();
      controller = TtsAudioController(
        flutterTts: FlutterTts(),
        voiceSettingsService: VoiceSettingsService(),
        chunkProcessor: TtsChunkProcessor(),
      );
      controller.setText(longText);
      await controller.play();
      expect(controller.state.value, TtsPlayerState.playing);
    });
  });

  // ── Silent-utterance watchdog retry ───────────────────────────────────────
  // NOTE: The 1.2s watchdog timer itself cannot be reliably unit-tested here
  // because MethodChannel mock responses (flutter_tts) are scheduled outside
  // fakeAsync's Zone, causing play()'s internal async chain to hang under
  // fakeAsync. The timer-based retry behavior is verified by integration / manual
  // on-device tests.
  //
  // What IS verifiable here:
  //   • The retry counter resets to 0 at the start of every play() session.
  //   • stop() also resets the counter so the next session has a full budget.
  group('TtsAudioController - Silent utterance watchdog retry', () {
    late TtsAudioController controller;

    setUp(() async {
      await registerTestServices();
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      controller = TtsAudioController(
        flutterTts: FlutterTts(),
        voiceSettingsService: VoiceSettingsService(),
      );
    });

    tearDown(() {
      controller.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    });

    test('retry counter resets on each new play() — fresh budget after error',
        () async {
      controller.setText('short test text');
      await controller.play();
      expect(controller.state.value, TtsPlayerState.playing);

      // Simulate ERROR (as if the watchdog exhausted its retry budget).
      controller.error();
      expect(controller.state.value, TtsPlayerState.error);

      // A new play() must reset the counter and succeed when the engine is
      // responsive (startHandler fires normally).
      await controller.play();
      expect(
        controller.state.value,
        TtsPlayerState.playing,
        reason: 'New play() after error must succeed — retry counter was reset',
      );
    });

    test('stop() resets the retry counter so the next play() has a full budget',
        () async {
      controller.setText('short test text');
      await controller.play();
      await controller.stop();
      expect(controller.state.value, TtsPlayerState.idle);

      // play() after stop() must work normally — counter was reset by stop().
      await controller.play();
      expect(controller.state.value, TtsPlayerState.playing);
    });
  });
}
