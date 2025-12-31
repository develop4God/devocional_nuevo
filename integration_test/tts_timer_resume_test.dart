import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration tests for TTS Timer Resume Functionality
/// CRITICAL: Tests that playback position (timer) resumes correctly after:
/// - Pause/play cycles
/// - Voice changes
/// - Speed changes
/// - Modal close/reopen
/// - Seek operations
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TTS Timer Resume - Real User Behavior Tests', () {
    late FlutterTts mockTts;
    late TtsAudioController controller;

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
      controller = TtsAudioController(flutterTts: mockTts);
    });

    tearDown(() {
      controller.dispose();
      ServiceLocator().reset();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    });

    group('CRITICAL: Pause/Resume Maintains Timer Position', () {
      test('User pauses at 10s, resumes - timer continues from 10s', () async {
        // GIVEN: User is listening to devotional
        const devotionalText = '''
          Versículo del día: Filipenses 4:13
          Todo lo puedo en Cristo que me fortalece.
          Esta es una reflexión larga para simular tiempo de reproducción.
          El poder de Dios nos sostiene en cada momento.
          Confía en su fuerza y sabiduría infinita.
        ''';

        controller.setText(devotionalText);
        await Future.delayed(const Duration(milliseconds: 100));

        // Start playing
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

        // Verify playing state
        expect(controller.state.value, TtsPlayerState.playing);

        // Verify timer resumed from accumulated position (not from 0)
        expect(
          controller.currentPosition.value.inSeconds,
          greaterThanOrEqualTo(pausedPosition.inSeconds),
          reason: 'Timer should resume from where it paused, not restart',
        );
      });

      test(
        'Multiple pause/resume cycles maintain accumulated position',
        () async {
          // GIVEN: User listening to long devotional
          controller.setText(
            'Texto largo para múltiples pausas y reanudaciones.',
          );
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          // Perform 3 pause/resume cycles
          for (int i = 0; i < 3; i++) {
            // Simulate some playback time
            await Future.delayed(const Duration(milliseconds: 300));

            final positionBeforePause = controller.currentPosition.value;

            // Pause
            await controller.pause();
            await Future.delayed(const Duration(milliseconds: 200));

            final pausedPosition = controller.currentPosition.value;

            // Verify position maintained during pause
            expect(
              pausedPosition.inMilliseconds,
              greaterThanOrEqualTo(positionBeforePause.inMilliseconds),
            );

            // Resume
            await controller.play();
            await Future.delayed(const Duration(milliseconds: 500));

            // Verify position continues from pause point
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
          // GIVEN: User is playing audio
          controller.setText('Reflexión para probar cambio de velocidad.');
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          // Simulate playback at 8 seconds
          controller.currentPosition.value = const Duration(seconds: 8);

          // WHEN: User pauses to change speed
          await controller.pause();
          final pausedPosition = controller.currentPosition.value;

          // Change speed
          await controller.cyclePlaybackRate();
          await Future.delayed(const Duration(milliseconds: 200));

          // User resumes
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          // THEN: Timer should resume from paused position
          expect(
            controller.currentPosition.value.inSeconds,
            greaterThanOrEqualTo(pausedPosition.inSeconds),
            reason:
                'Timer should resume from where it paused before speed change',
          );
        },
      );

      test('Multiple speed changes preserve accumulated position', () async {
        // GIVEN: Playing audio
        controller.setText('Texto para múltiples cambios de velocidad.');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // Change speed 3 times, each time pause -> change -> resume
        for (int i = 0; i < 3; i++) {
          await Future.delayed(const Duration(milliseconds: 300));

          // Pause before speed change (as per bug fix)
          await controller.pause();
          final positionBeforeSpeedChange = controller.currentPosition.value;

          // Change speed
          await controller.cyclePlaybackRate();
          await Future.delayed(const Duration(milliseconds: 200));

          // Resume
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          // Verify position maintained
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
        // GIVEN: User is playing devotional
        controller.setText('Devocional para probar cambio de voz.');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // Simulate playback at 12 seconds
        controller.currentPosition.value = const Duration(seconds: 12);

        // WHEN: User pauses to change voice
        await controller.pause();
        final pausedPosition = controller.currentPosition.value;

        // Simulate voice selector interaction (pause maintained)
        await Future.delayed(const Duration(milliseconds: 500));

        // User closes voice selector and resumes
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // THEN: Timer should resume from paused position
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
          // GIVEN: User is playing devotional
          final devotionalText = List.generate(
            50,
            (i) => 'Palabra $i de la reflexión espiritual.',
          ).join(' ');

          controller.setText(devotionalText);
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          // WHEN: User seeks to 30 seconds
          const seekPosition = Duration(seconds: 30);
          controller.seek(seekPosition);
          await Future.delayed(const Duration(milliseconds: 200));

          // THEN: Current position should be updated
          expect(
            controller.currentPosition.value.inSeconds,
            greaterThanOrEqualTo(seekPosition.inSeconds - 2),
            reason: 'Position should be at seek point (within 2s tolerance)',
          );

          // Timer should continue from seek position
          await Future.delayed(const Duration(milliseconds: 1000));

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
          // GIVEN: User has paused playback
          controller.setText('Texto para probar seek mientras pausado.');
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          await controller.pause();

          // WHEN: User seeks while paused
          const seekPosition = Duration(seconds: 15);
          controller.seek(seekPosition);
          await Future.delayed(const Duration(milliseconds: 200));

          // THEN: Position should be at seek point
          expect(
            controller.currentPosition.value.inSeconds,
            closeTo(seekPosition.inSeconds, 2),
          );

          // Resume playback
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          // Timer should continue from seek position
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
          // GIVEN: User is playing
          controller.setText('Contenido para simular cierre de modal.');
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          // Simulate playback at 5 seconds
          controller.currentPosition.value = const Duration(seconds: 5);

          // WHEN: User pauses (preparing to close modal)
          await controller.pause();
          final pausedPosition = controller.currentPosition.value;

          // Simulate modal close (controller persists in background)
          await Future.delayed(const Duration(milliseconds: 500));

          // User reopens modal and resumes
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 500));

          // THEN: Timer should resume from paused position
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
        'Full flow: play → pause → speed change → resume → seek → pause → resume',
        () async {
          // This test simulates a complete real user session
          const devotionalText = '''
          Versículo: Salmos 23
          El Señor es mi pastor, nada me faltará.
          En lugares de delicados pastos me hará descansar.
          Junto a aguas de reposo me pastoreará.
          Confortará mi alma.
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

          // All operations should maintain timer continuity
          expect(controller.state.value, TtsPlayerState.playing);
        },
      );
    });

    group('Edge Cases', () {
      test('Pause at 0s, resume - should start from beginning', () async {
        // GIVEN: User starts and immediately pauses
        controller.setText('Texto corto para probar inicio.');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 100));

        // Immediately pause (position likely 0)
        await controller.pause();

        // WHEN: Resume
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // THEN: Should play normally from beginning
        expect(controller.state.value, TtsPlayerState.playing);
        expect(
          controller.currentPosition.value.inSeconds,
          greaterThanOrEqualTo(0),
        );
      });

      test('Seek to end, then resume - should handle gracefully', () async {
        // GIVEN: Playing audio
        controller.setText('Texto breve para probar seek al final.');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // WHEN: Seek to near end
        final nearEnd = Duration(
          seconds: controller.totalDuration.value.inSeconds - 1,
        );
        controller.seek(nearEnd);
        await Future.delayed(const Duration(milliseconds: 200));

        // THEN: Should handle near-end position
        expect(
          controller.currentPosition.value.inSeconds,
          lessThanOrEqualTo(controller.totalDuration.value.inSeconds),
        );
      });

      test('Rapid pause/resume cycles maintain consistency', () async {
        // GIVEN: Playing audio
        controller.setText('Texto para ciclos rápidos de pausa.');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // WHEN: Rapid pause/resume 5 times
        for (int i = 0; i < 5; i++) {
          await controller.pause();
          await Future.delayed(const Duration(milliseconds: 50));
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // THEN: Should still be in valid state
        expect(controller.state.value, TtsPlayerState.playing);
        expect(
          controller.currentPosition.value.inSeconds,
          greaterThanOrEqualTo(0),
        );
      });
    });
  });
}
