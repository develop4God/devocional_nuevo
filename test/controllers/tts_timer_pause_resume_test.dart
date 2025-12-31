import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/services/service_locator.dart';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_async/fake_async.dart';

/// Comprehensive test for TTS timer pause/resume behavior
/// Tests the critical bug where timer doesn't properly resume after pause
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock FlutterTTS method channel
  const MethodChannel ttsChannel = MethodChannel('flutter_tts');

  setUpAll(() {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Setup service locator for dependencies
    ServiceLocator().reset();
    setupServiceLocator();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (MethodCall call) async {
      switch (call.method) {
        case 'speak':
        case 'stop':
        case 'pause':
        case 'setLanguage':
        case 'setSpeechRate':
        case 'setVolume':
        case 'setPitch':
        case 'awaitSpeakCompletion':
        case 'setQueueMode':
        case 'awaitSynthCompletion':
          return 1;
        case 'getLanguages':
          return ['es-ES', 'en-US'];
        case 'getVoices':
          return [
            {'name': 'Voice ES', 'locale': 'es-ES'},
            {'name': 'Voice EN', 'locale': 'en-US'},
          ];
        case 'isLanguageAvailable':
          return true;
        default:
          return null;
      }
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
    ServiceLocator().reset();
  });

  group('TTS Timer Pause/Resume Behavior', () {
    late TtsAudioController controller;
    late FlutterTts mockTts;

    setUp(() {
      mockTts = FlutterTts();
      controller = TtsAudioController(flutterTts: mockTts);
    });

    tearDown(() async {
      // Stop any ongoing playback and cancel timers before disposing
      await controller.stop();
      // Give time for async operations to complete
      await Future.delayed(const Duration(milliseconds: 50));
      // Now safely dispose the controller
      controller.dispose();
    });

    // NOTE: these tests use fakeAsync to control Timer-based progress inside
    // the controller. fakeAsync captures Timer and periodic Timer created
    // by the controller so we can deterministically advance virtual time.

    test('should maintain accumulated time after pause and resume', () {
      fakeAsync((async) {
        controller.setText(
          'This is a test devotional text for testing pause and resume functionality. It needs to be long enough to have a meaningful duration.',
          languageCode: 'en',
        );

        // Verify initial state
        expect(controller.state.value, TtsPlayerState.idle);
        expect(controller.currentPosition.value, Duration.zero);
        expect(controller.totalDuration.value.inSeconds, greaterThan(0));

        final initialDuration = controller.totalDuration.value;

        // Start playing - schedule internal awaits; advance enough time so play() completes
        controller.play();
        async.flushMicrotasks();
        // Elapse enough to pass internal Future.delayed and speak() mocked call
        async.elapse(const Duration(milliseconds: 600));

        // Start the progress timer explicitly for test (simulates start handler)
        controller.startProgressTimerForTest();

        // Let a small amount of virtual time pass to simulate playback progress
        async.elapse(const Duration(milliseconds: 1600));

        // Verify position is advancing
        final positionBeforePause = controller.currentPosition.value;
        expect(positionBeforePause.inMilliseconds, greaterThan(0));
        expect(positionBeforePause, lessThan(initialDuration));

        // Pause playback
        controller.pause();
        async.flushMicrotasks();
        expect(controller.state.value, TtsPlayerState.paused);

        // Advance virtual time while paused - position should not advance
        async.elapse(const Duration(milliseconds: 1200));

        final positionDuringPause = controller.currentPosition.value;
        expect(
          (positionDuringPause - positionBeforePause).inMilliseconds.abs(),
          lessThan(600),
        );

        // Resume playback
        controller.play();
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        controller.startProgressTimerForTest();

        // Advance more virtual time
        async.elapse(const Duration(milliseconds: 1600));

        final positionAfterResume = controller.currentPosition.value;

        expect(positionAfterResume, greaterThanOrEqualTo(positionDuringPause));
        expect(
          positionAfterResume.inMilliseconds,
          greaterThan(positionDuringPause.inMilliseconds + 400),
        );
      });
    });

    test('should handle multiple pause/resume cycles correctly', () {
      fakeAsync((async) {
        controller.setText(
          'Testing multiple pause and resume cycles to ensure timer robustness.',
          languageCode: 'en',
        );

        final List<Duration> positions = [];

        // Start playing and let it complete
        controller.play();
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        controller.startProgressTimerForTest();

        // Cycle 1
        async.elapse(const Duration(milliseconds: 600));
        positions.add(controller.currentPosition.value);
        controller.pause();
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 300));

        // Cycle 2
        controller.play();
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        controller.startProgressTimerForTest();
        async.elapse(const Duration(milliseconds: 600));
        positions.add(controller.currentPosition.value);
        controller.pause();
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 300));

        // Cycle 3
        controller.play();
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        controller.startProgressTimerForTest();
        async.elapse(const Duration(milliseconds: 600));
        positions.add(controller.currentPosition.value);

        for (int i = 1; i < positions.length; i++) {
          expect(positions[i], greaterThan(positions[i - 1]));
        }
      });
    });

    test('should reset timer correctly after stop', () {
      fakeAsync((async) {
        controller.setText(
          'Testing stop behavior resets timer correctly.',
          languageCode: 'en',
        );

        // Play and allow internal awaits to complete
        controller.play();
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        controller.startProgressTimerForTest();
        async.elapse(const Duration(milliseconds: 900));

        final positionBeforeStop = controller.currentPosition.value;
        expect(positionBeforeStop.inMilliseconds, greaterThan(0));

        // Stop
        controller.stop();
        async.flushMicrotasks();
        expect(controller.state.value, TtsPlayerState.idle);
        expect(controller.currentPosition.value, Duration.zero);

        // Play again - should start from beginning
        controller.play();
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        controller.startProgressTimerForTest();
        async.elapse(const Duration(milliseconds: 900));

        final positionAfterRestart = controller.currentPosition.value;
        expect(
          positionAfterRestart.inMilliseconds,
          lessThan(positionBeforeStop.inMilliseconds * 1.5),
        );
      });
    });

    test('should handle pause immediately after play', () {
      fakeAsync((async) {
        controller.setText(
          'Testing immediate pause after play.',
          languageCode: 'en',
        );

        // Play and allow to start
        controller.play();
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        controller.startProgressTimerForTest();

        // Quick pause
        async.elapse(const Duration(milliseconds: 120));
        controller.pause();
        async.flushMicrotasks();

        final positionAfterQuickPause = controller.currentPosition.value;

        // Resume
        controller.play();
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        controller.startProgressTimerForTest();
        async.elapse(const Duration(milliseconds: 900));

        final positionAfterResume = controller.currentPosition.value;
        expect(positionAfterResume, greaterThan(positionAfterQuickPause));
      });
    });
  });
}
