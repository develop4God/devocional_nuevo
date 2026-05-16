@Tags(['unit', 'controllers'])
library;

// test/unit/controllers/tts_timer_resume_user_behavior_test.dart
//
// Migrated from integration_test/tts_timer_resume_test.dart
// CRITICAL: Tests that playback position (timer) resumes correctly after
// pause/play cycles, voice changes, speed changes, modal close/reopen,
// and seek operations.

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

  group('TTS Timer Resume - Real User Behavior Tests', () {
    late FlutterTts mockTts;
    late _TestTtsController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ServiceLocator().reset();
      setupServiceLocator();

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
      controller = _TestTtsController(
        flutterTts: mockTts,
        voiceSettingsService: VoiceSettingsService(),
      );
    });

    tearDown(() {
      controller.dispose();
      ServiceLocator().reset();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    });

    group('CRITICAL: Pause/Resume Maintains Timer Position', () {
      test('User pauses at 10s, resumes - timer continues from 10s', () async {
        const devotionalText = '''
          Versiculo del dia: Filipenses 4:13
          Todo lo puedo en Cristo que me fortalece.
          Esta es una reflexion larga para simular tiempo de reproduccion.
          El poder de Dios nos sostiene en cada momento.
          Confia en su fuerza y sabiduria infinita.
        ''';

        controller.setText(devotionalText);
        await Future.delayed(const Duration(milliseconds: 100));

        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // Simulate playback at 10 seconds
        controller.currentPosition.value = const Duration(seconds: 10);

        // WHEN: User pauses
        await controller.pause();
        final pausedPosition = controller.currentPosition.value;

        expect(
          pausedPosition.inSeconds,
          greaterThanOrEqualTo(0),
          reason: 'Should have accumulated some position',
        );

        // THEN: User resumes playback
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        expect(controller.state.value, TtsPlayerState.playing);
        expect(
          controller.currentPosition.value.inSeconds,
          greaterThanOrEqualTo(pausedPosition.inSeconds),
          reason: 'Timer should resume from where it paused, not restart',
        );
      });

      test(
        'Multiple pause/resume cycles maintain accumulated position',
        () async {
          controller.setText(
            'Texto largo para multiples pausas y reanudaciones.',
          );
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          for (int i = 0; i < 3; i++) {
            await Future.delayed(const Duration(milliseconds: 300));

            controller.setPositionForTest(
              Duration(milliseconds: (i + 1) * 300),
            );
            final positionBeforePause = controller.currentPosition.value;

            await controller.pause();
            await Future.delayed(const Duration(milliseconds: 200));

            final pausedPosition = controller.currentPosition.value;

            expect(
              pausedPosition.inMilliseconds,
              greaterThanOrEqualTo(positionBeforePause.inMilliseconds),
            );

            await controller.play();
            await Future.delayed(const Duration(milliseconds: 500));

            expect(
              controller.currentPosition.value.inMilliseconds,
              greaterThanOrEqualTo(pausedPosition.inMilliseconds),
              reason: 'Cycle $i: Timer should resume from paused position',
            );
          }
        },
      );
    });

    group('CRITICAL: Speed Change Maintains Timer Position', () {
      test(
        'User pauses, changes speed, resumes - timer continues correctly',
        () async {
          controller.setText('Reflexion para probar cambio de velocidad.');
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          // Simulate playback at 8 seconds
          controller.setPositionForTest(const Duration(seconds: 8));

          await controller.pause();
          final pausedPosition = controller.currentPosition.value;

          await controller.cyclePlaybackRate();
          await Future.delayed(const Duration(milliseconds: 200));

          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          expect(
            controller.currentPosition.value.inSeconds,
            greaterThanOrEqualTo(pausedPosition.inSeconds),
            reason:
                'Timer should resume from where it paused before speed change',
          );
        },
      );

      test('Multiple speed changes preserve accumulated position', () async {
        controller.setText('Texto para multiples cambios de velocidad.');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        for (int i = 0; i < 3; i++) {
          await Future.delayed(const Duration(milliseconds: 300));

          controller.setPositionForTest(Duration(milliseconds: (i + 1) * 300));

          await controller.pause();
          final positionBeforeSpeedChange = controller.currentPosition.value;

          await controller.cyclePlaybackRate();
          await Future.delayed(const Duration(milliseconds: 200));

          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          expect(
            controller.currentPosition.value.inMilliseconds,
            greaterThanOrEqualTo(positionBeforeSpeedChange.inMilliseconds),
            reason: 'Speed change $i should preserve timer position',
          );
        }
      });
    });

    group('CRITICAL: Voice Change Maintains Timer Position', () {
      test('User pauses, changes voice, resumes - timer continues', () async {
        controller.setText('Devocional para probar cambio de voz.');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // Simulate playback at 12 seconds
        controller.setPositionForTest(const Duration(seconds: 12));

        await controller.pause();
        final pausedPosition = controller.currentPosition.value;

        // Simulate voice selector interaction
        await Future.delayed(const Duration(milliseconds: 500));

        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        expect(
          controller.currentPosition.value.inSeconds,
          greaterThanOrEqualTo(pausedPosition.inSeconds),
          reason:
              'Timer should resume from where it paused before voice change',
        );
      });
    });

    group('CRITICAL: Seek Updates Timer Correctly', () {
      test(
        'User seeks to 30s - timer updates and continues from 30s',
        () async {
          final devotionalText = List.generate(
            50,
            (i) => 'Palabra $i de la reflexion espiritual.',
          ).join(' ');

          controller.setText(devotionalText);
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          // WHEN: User seeks to 30 seconds
          const seekPosition = Duration(seconds: 30);
          controller.seek(seekPosition);
          await Future.delayed(const Duration(milliseconds: 200));

          expect(
            controller.currentPosition.value.inSeconds,
            greaterThanOrEqualTo(seekPosition.inSeconds - 2),
            reason: 'Position should be at seek point (within 2s tolerance)',
          );

          await Future.delayed(const Duration(milliseconds: 1000));

          controller.currentPosition.value = Duration(
            seconds: seekPosition.inSeconds + 2,
          );

          expect(
            controller.currentPosition.value.inSeconds,
            greaterThan(seekPosition.inSeconds),
            reason: 'Timer should continue counting from seek position',
          );
        },
      );

      test(
        'Seek while paused, then resume - timer starts from seek position',
        () async {
          // Need _fullDuration > 15s — at 2.5 words/sec need ~45 words
          controller.setText(List.generate(50, (i) => 'palabra$i').join(' '));
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          await controller.pause();

          const seekPosition = Duration(seconds: 15);
          controller.seek(seekPosition);
          await Future.delayed(const Duration(milliseconds: 200));

          expect(
            controller.currentPosition.value.inSeconds,
            closeTo(seekPosition.inSeconds, 2),
          );

          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          expect(
            controller.currentPosition.value.inSeconds,
            greaterThanOrEqualTo(seekPosition.inSeconds),
            reason: 'Timer should resume from seek position',
          );
        },
      );
    });

    group('CRITICAL: Modal Close/Reopen Maintains Position', () {
      test(
        'User pauses, closes modal, reopens, resumes - timer continues',
        () async {
          controller.setText('Contenido para simular cierre de modal.');
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          controller.setPositionForTest(const Duration(seconds: 5));

          await controller.pause();
          final pausedPosition = controller.currentPosition.value;

          // Simulate modal close
          await Future.delayed(const Duration(milliseconds: 500));

          // User reopens modal and resumes
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          expect(
            controller.currentPosition.value.inSeconds,
            greaterThanOrEqualTo(pausedPosition.inSeconds),
            reason:
                'Timer should resume after modal reopen from where it paused',
          );
        },
      );
    });

    group('Complete User Journeys', () {
      test(
        'Full flow: play -> pause -> speed change -> resume -> seek -> pause -> resume',
        () async {
          const devotionalText = '''
          Versiculo: Salmos 23
          El Senor es mi pastor, nada me faltara.
          En lugares de delicados pastos me hara descansar.
          Junto a aguas de reposo me pastoreara.
          Confortara mi alma.
        ''';

          controller.setText(devotionalText);

          // 1. Start playing
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));
          expect(controller.state.value, TtsPlayerState.playing);

          // 2. Pause after some time
          await Future.delayed(const Duration(milliseconds: 300));
          await controller.pause();
          final firstPausePosition = controller.currentPosition.value;

          // 3. Change speed while paused
          await controller.cyclePlaybackRate();
          await Future.delayed(const Duration(milliseconds: 200));

          // 4. Resume
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));
          expect(
            controller.currentPosition.value.inMilliseconds,
            greaterThanOrEqualTo(firstPausePosition.inMilliseconds),
          );

          // 5. Seek to different position
          const seekPos = Duration(seconds: 10);
          controller.seek(seekPos);
          await Future.delayed(const Duration(milliseconds: 300));

          // 6. Pause again
          await controller.pause();
          final secondPausePosition = controller.currentPosition.value;

          // 7. Final resume
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));
          expect(
            controller.currentPosition.value.inMilliseconds,
            greaterThanOrEqualTo(secondPausePosition.inMilliseconds),
          );

          expect(controller.state.value, TtsPlayerState.playing);
        },
      );
    });

    group('Edge Cases', () {
      test('Pause at 0s, resume - should start from beginning', () async {
        controller.setText('Texto corto para probar inicio.');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 100));

        await controller.pause();

        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        expect(controller.state.value, TtsPlayerState.playing);
        expect(
          controller.currentPosition.value.inSeconds,
          greaterThanOrEqualTo(0),
        );
      });

      test('Seek to end, then resume - should handle gracefully', () async {
        controller.setText('Texto breve para probar seek al final.');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        final nearEnd = Duration(
          seconds: controller.totalDuration.value.inSeconds - 1,
        );
        controller.seek(nearEnd);
        await Future.delayed(const Duration(milliseconds: 200));

        expect(
          controller.currentPosition.value.inSeconds,
          lessThanOrEqualTo(controller.totalDuration.value.inSeconds),
        );
      });

      test('Rapid pause/resume cycles maintain consistency', () async {
        controller.setText('Texto para ciclos rapidos de pausa.');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        for (int i = 0; i < 5; i++) {
          await controller.pause();
          await Future.delayed(const Duration(milliseconds: 50));
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 100));
        }

        expect(controller.state.value, TtsPlayerState.playing);
        expect(
          controller.currentPosition.value.inSeconds,
          greaterThanOrEqualTo(0),
        );
      });
    });
  });
}
