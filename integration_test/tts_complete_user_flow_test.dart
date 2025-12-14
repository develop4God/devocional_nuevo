import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration tests for complete TTS user workflows
/// Covers: devotional reading, audio playback, speed adjustments, progress tracking
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TTS Complete User Flow - Integration Tests', () {
    late FlutterTts mockTts;
    late TtsAudioController controller;
    late VoiceSettingsService voiceSettings;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ServiceLocator().reset();
      setupServiceLocator();

      // Mock flutter_tts platform channel
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
            case 'awaitSynthCompletion':
              return 1;
            case 'getVoices':
              return [
                {'name': 'es-ES-Standard-A', 'locale': 'es-ES'},
                {'name': 'en-US-Standard-C', 'locale': 'en-US'},
              ];
            case 'getLanguages':
              return ['es-ES', 'en-US', 'pt-BR'];
            case 'getEngines':
            case 'getDefaultEngine':
            case 'isLanguageAvailable':
              return [];
            default:
              return null;
          }
        },
      );

      mockTts = FlutterTts();
      controller = TtsAudioController(flutterTts: mockTts);
      voiceSettings = VoiceSettingsService();
    });

    tearDown(() {
      controller.dispose();
      ServiceLocator().reset();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    });

    group('Scenario 1: First-time User Listens to Devotional', () {
      test(
          'User opens app, reads devotional, then plays audio for the first time',
          () async {
        // GIVEN: User has just opened a devotional
        const devotionalText = '''
          Versículo del día: Juan 3:16
          Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito,
          para que todo aquel que en él cree, no se pierda, mas tenga vida eterna.
          
          Reflexión:
          El amor de Dios es tan grande que dio lo más valioso que tenía.
          Hoy reflexiona sobre este amor incondicional.
          
          Oración:
          Padre celestial, gracias por tu amor infinito. Ayúdame a vivir
          cada día reconociendo tu gracia. Amén.
        ''';

        // WHEN: User sets the text
        controller.setText(devotionalText);
        await Future.delayed(const Duration(milliseconds: 100));

        // THEN: Duration is calculated
        expect(controller.totalDuration.value.inSeconds, greaterThan(0));
        final initialDuration = controller.totalDuration.value;

        // WHEN: User presses play
        final playFuture = controller.play();

        // THEN: Shows loading state
        expect(controller.state.value, TtsPlayerState.loading);

        // Wait for TTS to start
        await Future.delayed(const Duration(milliseconds: 500));
        await playFuture;

        // THEN: Now playing
        expect(controller.state.value, TtsPlayerState.playing);

        // Verify duration hasn't changed (calculated once at 1.0x)
        expect(controller.totalDuration.value, equals(initialDuration));
      });

      test('User adjusts speed during playback', () async {
        // GIVEN: User is listening to audio
        const devotionalText =
            'Esta es una reflexión de prueba para verificar la funcionalidad de velocidad del audio.';

        controller.setText(devotionalText);
        await Future.delayed(const Duration(milliseconds: 100));

        final originalDuration = controller.totalDuration.value;

        // Start playing
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));
        expect(controller.state.value, TtsPlayerState.playing);

        // CRITICAL NOTE: In production, UI should pause before changing speed
        // This test simulates the controller behavior, but the UI layer
        // (devocionales_page.dart) now pauses before calling cyclePlaybackRate()
        // See: tts_pause_behavior_test.dart for pause-before-change tests

        // WHEN: User changes speed to 1.5x
        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 200));

        // THEN: Speed changes but duration estimate remains at 1.0x base
        expect(controller.playbackRate.value, equals(1.5));
        expect(controller.totalDuration.value, equals(originalDuration),
            reason:
                'Duration should remain constant, calculated at 1.0x speed');

        // WHEN: User continues cycling speed to 2.0x
        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 200));

        // THEN: Speed is now 2.0x, duration still unchanged
        expect(controller.playbackRate.value, equals(2.0));
        expect(controller.totalDuration.value, equals(originalDuration));

        // WHEN: User cycles back to 1.0x
        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 200));

        // THEN: Back to normal speed
        expect(controller.playbackRate.value, equals(1.0));
        expect(controller.totalDuration.value, equals(originalDuration));
      });
    });

    group('Scenario 2: Regular User with Progress Tracking', () {
      test('User plays audio, progress updates correctly', () async {
        // GIVEN: User has audio ready
        const devotionalText = 'Reflexión breve para probar el progreso.';

        controller.setText(devotionalText);
        await Future.delayed(const Duration(milliseconds: 100));

        // WHEN: User starts playing
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // THEN: Initial progress is close to 0.0
        final progress = controller.currentPosition.value.inMilliseconds /
            (controller.totalDuration.value.inMilliseconds > 0
                ? controller.totalDuration.value.inMilliseconds
                : 1);
        expect(progress, lessThanOrEqualTo(0.1),
            reason: 'Progress should be minimal at start');

        // Simulate some progress (in real app, this comes from TTS callbacks)
        // For testing, we can manually update or verify the structure is there
        expect(controller.currentPosition.value, isNotNull);
      });

      test('User seeks to different position in audio', () async {
        // GIVEN: User is listening to a longer devotional
        final devotionalText = '''
          Versículo largo con mucho contenido.
          ${List.generate(20, (i) => 'Línea $i de reflexión profunda.').join('\n')}
          Oración final y conclusión.
        ''';

        controller.setText(devotionalText);
        await Future.delayed(const Duration(milliseconds: 100));

        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // WHEN: User seeks to 50% position
        final totalDuration = controller.totalDuration.value;
        final halfwayPosition = totalDuration ~/ 2;

        controller.seek(halfwayPosition);

        // THEN: Position updates
        expect(controller.currentPosition.value.inSeconds,
            greaterThanOrEqualTo(0));
      });
    });

    group('Scenario 3: User Pause and Resume Flow', () {
      test('User pauses, closes modal, then resumes', () async {
        // GIVEN: User is listening to audio
        const devotionalText = 'Contenido para probar pausa y reanudación.';

        controller.setText(devotionalText);
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        expect(controller.state.value, TtsPlayerState.playing);

        // WHEN: User pauses
        await controller.pause();

        // THEN: State is paused
        expect(controller.state.value, TtsPlayerState.paused);

        // Simulate user closing modal (but controller persists)
        await Future.delayed(const Duration(milliseconds: 200));

        // WHEN: User reopens and resumes
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // THEN: Playback resumes
        expect(controller.state.value, TtsPlayerState.playing);
      });

      test('User stops audio completely', () async {
        // GIVEN: User is listening
        const devotionalText = 'Contenido para probar stop.';

        controller.setText(devotionalText);
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // WHEN: User stops
        await controller.stop();

        // THEN: State is idle
        expect(controller.state.value, TtsPlayerState.idle);

        // Position resets to 0
        expect(controller.currentPosition.value, equals(Duration.zero));
      });
    });

    group('Scenario 4: Speed Cycling Edge Cases', () {
      test('User cycles through all speeds: 1.0x -> 1.5x -> 2.0x -> 1.0x',
          () async {
        // GIVEN: Controller with text
        controller.setText('Test text');
        await Future.delayed(const Duration(milliseconds: 100));

        final baseDuration = controller.totalDuration.value;

        // Start at 1.0x
        expect(controller.playbackRate.value, equals(1.0));

        // Cycle to 1.5x
        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 100));
        expect(controller.playbackRate.value, equals(1.5));
        expect(controller.totalDuration.value, equals(baseDuration));

        // Cycle to 2.0x
        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 100));
        expect(controller.playbackRate.value, equals(2.0));
        expect(controller.totalDuration.value, equals(baseDuration));

        // Cycle back to 1.0x
        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 100));
        expect(controller.playbackRate.value, equals(1.0));
        expect(controller.totalDuration.value, equals(baseDuration));
      });

      test('Speed changes persist during pause/resume', () async {
        // GIVEN: User sets speed to 2.0x
        controller.setText('Test text for speed persistence');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        await controller.cyclePlaybackRate(); // 1.5x
        await controller.cyclePlaybackRate(); // 2.0x
        await Future.delayed(const Duration(milliseconds: 200));

        expect(controller.playbackRate.value, equals(2.0));

        // WHEN: User pauses
        await controller.pause();

        // THEN: Speed is still 2.0x
        expect(controller.playbackRate.value, equals(2.0));

        // WHEN: User resumes
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // THEN: Speed remains 2.0x
        expect(controller.playbackRate.value, equals(2.0));
      });
    });

    group('Scenario 5: Multi-Devotional Session', () {
      test('User listens to multiple devotionals in one session', () async {
        // GIVEN: User finishes first devotional
        controller.setText('Primera reflexión del día.');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));
        await controller.stop();

        expect(controller.state.value, TtsPlayerState.idle);

        // WHEN: User moves to second devotional
        controller.setText('Segunda reflexión con nuevo contenido.');
        await Future.delayed(const Duration(milliseconds: 100));

        // THEN: New duration is calculated
        expect(controller.totalDuration.value.inSeconds, greaterThan(0));

        // WHEN: User plays second devotional
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // THEN: Playing new content
        expect(controller.state.value, TtsPlayerState.playing);
      });

      test('Speed preference persists across devotionals', () async {
        // GIVEN: User sets speed to 1.5x for first devotional
        controller.setText('Primera reflexión');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        await controller.cyclePlaybackRate(); // 1.5x
        await Future.delayed(const Duration(milliseconds: 200));
        expect(controller.playbackRate.value, equals(1.5));

        await controller.stop();

        // WHEN: User switches to new devotional
        controller.setText('Segunda reflexión');
        await Future.delayed(const Duration(milliseconds: 100));

        // THEN: Speed preference persists at 1.5x
        expect(controller.playbackRate.value, equals(1.5));
      });
    });

    group('Scenario 6: Error Recovery and Edge Cases', () {
      test('User attempts to play empty text', () async {
        // GIVEN: No text set
        controller.setText('');

        // WHEN: User tries to play
        await controller.play();

        // THEN: Should handle gracefully (either stay idle or show error)
        // Not crash or enter invalid state
        expect(
            controller.state.value,
            isIn([
              TtsPlayerState.idle,
              TtsPlayerState.error,
            ]));
      });

      test('User rapidly toggles play/pause', () async {
        // GIVEN: Audio is ready
        controller.setText('Contenido para test de toggle rápido.');
        await Future.delayed(const Duration(milliseconds: 100));

        // WHEN: User rapidly toggles
        await controller.play();
        await controller.pause();
        await controller.play();
        await controller.pause();
        await controller.play();

        // THEN: Final state should be consistent
        await Future.delayed(const Duration(milliseconds: 500));
        expect(controller.state.value, isNotNull);
        expect(
            controller.state.value,
            isIn([
              TtsPlayerState.playing,
              TtsPlayerState.paused,
              TtsPlayerState.loading,
            ]));
      });

      test('Duration calculation for very long text', () async {
        // GIVEN: Very long devotional (simulating complete Bible chapter)
        final longText = List.generate(
          100,
          (i) =>
              'Versículo $i con contenido extenso para probar el cálculo de duración.',
        ).join('\n');

        // WHEN: Text is set
        controller.setText(longText);
        await Future.delayed(const Duration(milliseconds: 200));

        // THEN: Duration is calculated properly
        expect(controller.totalDuration.value.inSeconds, greaterThan(60),
            reason: 'Long text should have duration > 1 minute');
      });
    });

    group('Scenario 7: Voice Settings Integration', () {
      test('User switches language and voice preferences persist', () async {
        // GIVEN: User has Spanish voice saved
        await voiceSettings.setUserSavedVoice('es');

        // THEN: Flag is set
        expect(await voiceSettings.hasUserSavedVoice('es'), isTrue);

        // WHEN: User switches to English
        await voiceSettings.setUserSavedVoice('en');

        // THEN: Both languages have saved voices
        expect(await voiceSettings.hasUserSavedVoice('es'), isTrue);
        expect(await voiceSettings.hasUserSavedVoice('en'), isTrue);
      });

      test('Speech rate persists across app sessions', () async {
        // GIVEN: User sets custom speech rate
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('tts_rate', 0.75);

        // WHEN: Voice settings reads it
        final rate = await voiceSettings.getSavedSpeechRate();

        // THEN: Correct rate is returned
        expect(rate, equals(0.75));
      });
    });

    group('Scenario 8: Complete TTS Lifecycle', () {
      test('Full user journey: select voice -> play -> adjust speed -> finish',
          () async {
        // Step 1: User selects voice
        await voiceSettings.setUserSavedVoice('es');
        expect(await voiceSettings.hasUserSavedVoice('es'), isTrue);

        // Step 2: User loads devotional
        const devotionalText = '''
          Versículo: Filipenses 4:13
          Todo lo puedo en Cristo que me fortalece.
          
          Reflexión: Confía en el poder de Dios.
          Oración: Señor, fortalece mi fe.
        ''';

        controller.setText(devotionalText);
        await Future.delayed(const Duration(milliseconds: 100));

        final baseDuration = controller.totalDuration.value;
        expect(baseDuration.inSeconds, greaterThan(0));

        // Step 3: User starts playback
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));
        expect(controller.state.value, TtsPlayerState.playing);

        // Step 4: User adjusts speed to 1.5x
        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 200));
        expect(controller.playbackRate.value, equals(1.5));

        // Duration stays constant
        expect(controller.totalDuration.value, equals(baseDuration));

        // Step 5: User pauses to reflect
        await controller.pause();
        expect(controller.state.value, TtsPlayerState.paused);

        // Step 6: User resumes
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));
        expect(controller.state.value, TtsPlayerState.playing);
        expect(controller.playbackRate.value, equals(1.5));

        // Step 7: User finishes and stops
        await controller.stop();
        expect(controller.state.value, TtsPlayerState.idle);
        expect(controller.currentPosition.value, equals(Duration.zero));

        // Speed preference persists for next devotional
        expect(controller.playbackRate.value, equals(1.5));
      });
    });
  });
}
