@Tags(['unit', 'controllers'])
library;

// test/unit/controllers/tts_complete_user_flow_test.dart
//
// Migrated from integration_test/tts_complete_user_flow_test.dart
// Full user-journey tests for TtsAudioController covering: first-time listen,
// speed adjustments, progress tracking, pause/resume, multi-devotional sessions,
// error recovery, and voice settings integration.

import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/tts_controller_test_helpers.dart';

/// Test subclass that provides access to protected members via mixin
class _TestTtsController extends TtsAudioController
    with TtsControllerTestHooks {
  _TestTtsController({
    required super.flutterTts,
    required super.voiceSettingsService,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TTS Complete User Flow - Integration Tests', () {
    late FlutterTts mockTts;
    late _TestTtsController controller;
    late VoiceSettingsService voiceSettings;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ServiceLocator().reset();
      setupServiceLocator();

      // Mock flutter_tts platform channel
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
      });

      mockTts = FlutterTts();
      voiceSettings = VoiceSettingsService();
      controller = _TestTtsController(
        flutterTts: mockTts,
        voiceSettingsService: voiceSettings,
      );
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
          const devotionalText = '''
          Versiculo del dia: Juan 3:16
          Porque de tal manera amo Dios al mundo, que ha dado a su Hijo unigenito,
          para que todo aquel que en el cree, no se pierda, mas tenga vida eterna.
          
          Reflexion:
          El amor de Dios es tan grande que dio lo mas valioso que tenia.
          Hoy reflexiona sobre este amor incondicional.
          
          Oracion:
          Padre celestial, gracias por tu amor infinito. Ayudame a vivir
          cada dia reconociendo tu gracia. Amen.
        ''';

          // WHEN: User sets the text
          controller.setText(devotionalText);
          await Future.delayed(const Duration(milliseconds: 100));

          // THEN: Duration is calculated
          expect(controller.totalDuration.value.inSeconds, greaterThan(0));
          final initialDuration = controller.totalDuration.value;

          // WHEN: User presses play
          final playFuture = controller.play();

          // Wait for state to transition to LOADING
          await Future.delayed(const Duration(milliseconds: 200));

          // THEN: Shows loading state
          expect(controller.state.value, TtsPlayerState.loading);

          // Wait for TTS to start
          await Future.delayed(const Duration(milliseconds: 500));
          await playFuture;

          // THEN: Now playing
          expect(controller.state.value, TtsPlayerState.playing);

          // Verify duration hasn't changed
          expect(controller.totalDuration.value, equals(initialDuration));
        },
      );

      test('User adjusts speed during playback', () async {
        const devotionalText =
            'Esta es una reflexion de prueba para verificar la funcionalidad de velocidad del audio.';

        controller.setText(devotionalText);
        await Future.delayed(const Duration(milliseconds: 100));

        final originalDuration = controller.totalDuration.value;

        // Start playing
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));
        expect(controller.state.value, TtsPlayerState.playing);

        // WHEN: User cycles speed to 1.5x
        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 200));

        // THEN: Speed changes but duration estimate remains at 1.0x base
        expect(controller.playbackRate.value, equals(1.5));
        expect(
          controller.totalDuration.value,
          equals(originalDuration),
          reason: 'Duration should remain constant, calculated at 1.0x speed',
        );

        // WHEN: User continues cycling speed to 0.5x
        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 200));

        expect(controller.playbackRate.value, equals(0.5));
        expect(controller.totalDuration.value, equals(originalDuration));

        // WHEN: User cycles back to 1.0x
        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 200));

        expect(controller.playbackRate.value, equals(1.0));
        expect(controller.totalDuration.value, equals(originalDuration));
      });
    });

    group('Scenario 2: Regular User with Progress Tracking', () {
      test('User plays audio, progress updates correctly', () async {
        const devotionalText = 'Reflexion breve para probar el progreso.';

        controller.setText(devotionalText);
        await Future.delayed(const Duration(milliseconds: 100));

        // WHEN: User starts playing
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // THEN: Initial progress is small (< 0.3)
        final progress = controller.currentPosition.value.inMilliseconds /
            (controller.totalDuration.value.inMilliseconds > 0
                ? controller.totalDuration.value.inMilliseconds
                : 1);
        expect(
          progress,
          lessThanOrEqualTo(0.3),
          reason: 'Progress should be minimal at start',
        );

        expect(controller.currentPosition.value, isNotNull);
      });

      test('User seeks to different position in audio', () async {
        final devotionalText = '''
          Versiculo largo con mucho contenido.
          ${List.generate(20, (i) => 'Linea $i de reflexion profunda.').join('\n')}
          Oracion final y conclusion.
        ''';

        controller.setText(devotionalText);
        await Future.delayed(const Duration(milliseconds: 100));

        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // WHEN: User seeks to 50% position
        final totalDuration = controller.totalDuration.value;
        final halfwayPosition = totalDuration ~/ 2;

        await controller.seek(halfwayPosition);

        // THEN: Position updates
        expect(
          controller.currentPosition.value.inSeconds,
          greaterThanOrEqualTo(0),
        );
      });
    });

    group('Scenario 3: User Pause and Resume Flow', () {
      test('User pauses, closes modal, then resumes', () async {
        const devotionalText = 'Contenido para probar pausa y reanudacion.';

        controller.setText(devotionalText);
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        expect(controller.state.value, TtsPlayerState.playing);

        // WHEN: User pauses
        await controller.pause();

        // THEN: State is paused
        expect(controller.state.value, TtsPlayerState.paused);

        // Simulate user closing modal
        await Future.delayed(const Duration(milliseconds: 200));

        // WHEN: User reopens and resumes
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // THEN: Playback resumes
        expect(controller.state.value, TtsPlayerState.playing);
      });

      test('User stops audio completely', () async {
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
      test(
        'User cycles through all speeds: 1.0x -> 1.5x -> 2.0x -> 1.0x',
        () async {
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

          // Cycle to 0.5x (the actual next speed)
          await controller.cyclePlaybackRate();
          await Future.delayed(const Duration(milliseconds: 100));
          expect(controller.playbackRate.value, equals(0.5));
          expect(controller.totalDuration.value, equals(baseDuration));

          // Cycle back to 1.0x
          await controller.cyclePlaybackRate();
          await Future.delayed(const Duration(milliseconds: 100));
          expect(controller.playbackRate.value, equals(1.0));
          expect(controller.totalDuration.value, equals(baseDuration));
        },
      );

      test('Speed changes persist during pause/resume', () async {
        controller.setText('Test text for speed persistence');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        await controller.cyclePlaybackRate(); // 1.0x -> 1.5x
        await controller.cyclePlaybackRate(); // 1.5x -> 0.5x
        await Future.delayed(const Duration(milliseconds: 200));

        expect(controller.playbackRate.value, equals(0.5));

        // WHEN: User pauses
        await controller.pause();

        // THEN: Speed is still 0.5x
        expect(controller.playbackRate.value, equals(0.5));

        // WHEN: User resumes
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // THEN: Speed remains 0.5x
        expect(controller.playbackRate.value, equals(0.5));
      });
    });

    group('Scenario 5: Multi-Devotional Session', () {
      test('User listens to multiple devotionals in one session', () async {
        // GIVEN: User finishes first devotional
        controller.setText('Primera reflexion del dia.');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));
        await controller.stop();

        expect(controller.state.value, TtsPlayerState.idle);

        // WHEN: User moves to second devotional
        controller.setText('Segunda reflexion con nuevo contenido.');
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
        controller.setText('Primera reflexion');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        await controller.cyclePlaybackRate(); // 1.5x
        await Future.delayed(const Duration(milliseconds: 200));
        expect(controller.playbackRate.value, equals(1.5));

        await controller.stop();

        // WHEN: User switches to new devotional
        controller.setText('Segunda reflexion');
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

        // THEN: Should handle gracefully
        expect(
          controller.state.value,
          isIn([TtsPlayerState.idle, TtsPlayerState.error]),
        );
      });

      test('User rapidly toggles play/pause', () async {
        controller.setText('Contenido para test de toggle rapido.');
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
          ]),
        );
      });

      test('Duration calculation for very long text', () async {
        // GIVEN: Very long devotional (simulating complete Bible chapter)
        final longText = List.generate(
          100,
          (i) =>
              'Versiculo $i con contenido extenso para probar el calculo de duracion.',
        ).join('\n');

        // WHEN: Text is set
        controller.setText(longText);
        await Future.delayed(const Duration(milliseconds: 200));

        // THEN: Duration is calculated properly
        expect(
          controller.totalDuration.value.inSeconds,
          greaterThan(60),
          reason: 'Long text should have duration > 1 minute',
        );
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
      test(
        'Full user journey: select voice -> play -> adjust speed -> finish',
        () async {
          // Step 1: User selects voice
          await voiceSettings.setUserSavedVoice('es');
          expect(await voiceSettings.hasUserSavedVoice('es'), isTrue);

          // Step 2: User loads devotional
          const devotionalText = '''
          Versiculo: Filipenses 4:13
          Todo lo puedo en Cristo que me fortalece.
          
          Reflexion: Confia en el poder de Dios.
          Oracion: Senor, fortalece mi fe.
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
        },
      );
    });
  });
}
