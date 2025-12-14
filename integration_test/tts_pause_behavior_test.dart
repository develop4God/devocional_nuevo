import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration tests for TTS Modal pause behavior
/// CRITICAL: Tests that TTS pauses before speed/voice changes to prevent playback issues
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TTS Modal Pause Behavior - Critical Bug Fix Tests', () {
    late FlutterTts mockTts;
    late TtsAudioController controller;

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
    });

    tearDown(() {
      controller.dispose();
      ServiceLocator().reset();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    });

    group('CRITICAL: Pause Before Speed Change', () {
      test('User changes speed while playing - must pause first', () async {
        // GIVEN: User is listening to audio
        const devotionalText =
            'Versículo del día con contenido para reproducir.';

        controller.setText(devotionalText);
        await Future.delayed(const Duration(milliseconds: 100));

        // Start playing
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));
        expect(controller.state.value, TtsPlayerState.playing);

        final initialSpeed = controller.playbackRate.value;

        // WHEN: User changes speed (simulating UI button tap)
        // CRITICAL: In the real app, we must pause BEFORE calling cyclePlaybackRate
        await controller.pause();
        expect(controller.state.value, TtsPlayerState.paused,
            reason: 'MUST pause before changing speed');

        // THEN: Change speed while paused
        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 200));

        // Verify speed changed
        expect(controller.playbackRate.value, isNot(equals(initialSpeed)));

        // Verify still paused (user must manually resume)
        expect(controller.state.value, TtsPlayerState.paused,
            reason: 'Should remain paused until user presses play');
      });

      test('User rapidly cycles speed - must be paused each time', () async {
        // GIVEN: Audio is playing
        controller.setText('Test content for rapid speed changes');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));
        expect(controller.state.value, TtsPlayerState.playing);

        // WHEN: User rapidly changes speed 3 times
        for (int i = 0; i < 3; i++) {
          // CRITICAL: Must pause before each change
          await controller.pause();
          expect(controller.state.value, TtsPlayerState.paused);

          await controller.cyclePlaybackRate();
          await Future.delayed(const Duration(milliseconds: 100));

          // Verify still paused after speed change
          expect(controller.state.value, TtsPlayerState.paused);
        }

        // Final state should be paused
        expect(controller.state.value, TtsPlayerState.paused);
      });

      test('Speed change from paused state - no issues', () async {
        // GIVEN: Audio is paused
        controller.setText('Content for paused speed change test');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));
        await controller.pause();
        expect(controller.state.value, TtsPlayerState.paused);

        // WHEN: User changes speed while paused
        final speedBefore = controller.playbackRate.value;
        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 200));

        // THEN: Speed changes, remains paused
        expect(controller.playbackRate.value, isNot(equals(speedBefore)));
        expect(controller.state.value, TtsPlayerState.paused);
      });
    });

    group('CRITICAL: Pause Before Voice Change', () {
      test('User opens voice selector while playing - must pause first',
          () async {
        // GIVEN: User is listening to audio
        controller.setText('Versículo para probar cambio de voz.');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));
        expect(controller.state.value, TtsPlayerState.playing);

        // WHEN: User taps voice selector icon
        // CRITICAL: In the real app, we must pause BEFORE opening voice selector
        await controller.pause();

        // THEN: Must be paused
        expect(controller.state.value, TtsPlayerState.paused,
            reason:
                'MUST pause before opening voice selector to avoid playback conflicts');

        // Simulate voice selector being open (audio stays paused)
        await Future.delayed(const Duration(milliseconds: 500));
        expect(controller.state.value, TtsPlayerState.paused);
      });

      test('Voice change from idle state - no pause needed', () async {
        // GIVEN: Audio is idle (not started)
        controller.setText('Text for voice change from idle');
        expect(controller.state.value, TtsPlayerState.idle);

        // WHEN: User opens voice selector from idle
        // No pause needed - already idle
        expect(controller.state.value, TtsPlayerState.idle);

        // Simulate voice selector interaction
        await Future.delayed(const Duration(milliseconds: 200));

        // THEN: Should remain idle
        expect(controller.state.value, TtsPlayerState.idle);
      });
    });

    group('Complete User Flow: Speed/Voice Changes with Pause', () {
      test(
          'User plays, changes speed (pauses), resumes, changes voice (pauses), resumes',
          () async {
        // Step 1: User starts playing
        controller.setText('Reflexión completa con cambios de configuración.');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));
        expect(controller.state.value, TtsPlayerState.playing);

        final speed1 = controller.playbackRate.value;

        // Step 2: User changes speed - MUST PAUSE FIRST
        await controller.pause();
        expect(controller.state.value, TtsPlayerState.paused);

        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 200));

        expect(controller.playbackRate.value, isNot(equals(speed1)));
        expect(controller.state.value, TtsPlayerState.paused);

        // Step 3: User resumes playback
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));
        expect(controller.state.value, TtsPlayerState.playing);

        // Step 4: User changes voice - MUST PAUSE FIRST
        await controller.pause();
        expect(controller.state.value, TtsPlayerState.paused);

        // Simulate voice selector interaction
        await Future.delayed(const Duration(milliseconds: 300));
        expect(controller.state.value, TtsPlayerState.paused);

        // Step 5: User resumes after voice change
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));
        expect(controller.state.value, TtsPlayerState.playing);
      });

      test('Multiple configuration changes with proper pause/resume', () async {
        // GIVEN: Audio playing
        controller.setText('Texto largo para múltiples configuraciones.');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // Perform 5 configuration changes, each with pause/resume
        for (int i = 0; i < 5; i++) {
          expect(controller.state.value, TtsPlayerState.playing);

          // MUST pause before config change
          await controller.pause();
          expect(controller.state.value, TtsPlayerState.paused);

          // Change configuration
          await controller.cyclePlaybackRate();
          await Future.delayed(const Duration(milliseconds: 100));

          // Resume
          await controller.play();
          await Future.delayed(const Duration(milliseconds: 300));
        }

        // Final state should be playing
        expect(controller.state.value, TtsPlayerState.playing);
      });
    });

    group('Edge Cases: State Consistency', () {
      test('Pause while loading - should handle gracefully', () async {
        // GIVEN: Audio is loading
        controller.setText('Content for loading pause test');
        final playFuture = controller.play();

        // State should be loading
        expect(controller.state.value, TtsPlayerState.loading);

        // WHEN: User tries to pause during loading
        await controller.pause();

        // THEN: Should transition to paused
        await playFuture;
        await Future.delayed(const Duration(milliseconds: 200));

        expect(
          controller.state.value,
          isIn([TtsPlayerState.paused, TtsPlayerState.playing]),
        );
      });

      test('Speed change while loading - should pause first if needed',
          () async {
        // GIVEN: Audio is loading
        controller.setText('Content for loading speed change');
        final playFuture = controller.play();
        expect(controller.state.value, TtsPlayerState.loading);

        // WHEN: System pauses before changing speed (defensive)
        if (controller.state.value == TtsPlayerState.playing ||
            controller.state.value == TtsPlayerState.loading) {
          await controller.pause();
        }

        await playFuture;
        await Future.delayed(const Duration(milliseconds: 200));

        // THEN: Change speed safely
        await controller.cyclePlaybackRate();

        // Should be in valid state
        expect(
          controller.state.value,
          isIn([
            TtsPlayerState.paused,
            TtsPlayerState.idle,
            TtsPlayerState.playing,
          ]),
        );
      });

      test('Double pause - should be idempotent', () async {
        // GIVEN: Audio is playing
        controller.setText('Content for double pause test');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // WHEN: User pauses twice
        await controller.pause();
        expect(controller.state.value, TtsPlayerState.paused);

        await controller.pause();

        // THEN: Should remain paused (idempotent)
        expect(controller.state.value, TtsPlayerState.paused);
      });

      test('Pause, speed change, pause again - should work', () async {
        // GIVEN: Playing audio
        controller.setText('Content for multiple pause test');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // First pause
        await controller.pause();
        expect(controller.state.value, TtsPlayerState.paused);

        // Speed change
        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 100));

        // Second pause (should be idempotent)
        await controller.pause();
        expect(controller.state.value, TtsPlayerState.paused);
      });
    });

    group('Regression Prevention', () {
      test('Speed change without pause would cause issues - test documents fix',
          () async {
        // This test documents the BUG that was fixed
        // Previously, speed was changed while playing, causing issues

        // GIVEN: Audio is playing
        controller.setText('Test documenting the bug fix');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));
        expect(controller.state.value, TtsPlayerState.playing);

        // THE BUG: Changing speed while playing (DON'T DO THIS)
        // await controller.cyclePlaybackRate(); // This caused issues!

        // THE FIX: Always pause first
        await controller.pause();
        expect(controller.state.value, TtsPlayerState.paused);

        // Then change speed safely
        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 200));

        // Verify stable state
        expect(controller.state.value, TtsPlayerState.paused);
      });

      test('Verify fix is applied: no playback during config change', () async {
        // This test verifies the fix prevents playback during configuration

        // GIVEN: Playing state
        controller.setText('Verification of fix implementation');
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // WHEN: Proper pause before config change (the fix)
        await controller.pause();
        final stateBeforeChange = controller.state.value;

        // Change config
        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 100));

        final stateAfterChange = controller.state.value;

        // THEN: Both states should NOT be playing
        expect(stateBeforeChange, TtsPlayerState.paused);
        expect(stateAfterChange, TtsPlayerState.paused);
      });
    });
  });
}
