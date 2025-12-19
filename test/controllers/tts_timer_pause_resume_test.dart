import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        .setMockMethodCallHandler(
      ttsChannel,
      (MethodCall call) async {
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
      },
    );
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
      await Future.delayed(const Duration(milliseconds: 100));
      // Now safely dispose the controller
      controller.dispose();
    });

    test('should maintain accumulated time after pause and resume', () async {
      // Setup text
      controller.setText(
        'This is a test devotional text for testing pause and resume functionality. It needs to be long enough to have a meaningful duration.',
        languageCode: 'en',
      );

      // Verify initial state
      expect(controller.state.value, TtsPlayerState.idle);
      expect(controller.currentPosition.value, Duration.zero);
      expect(controller.totalDuration.value.inSeconds, greaterThan(0));

      final initialDuration = controller.totalDuration.value;

      // Start playing
      await controller.play();

      // Manually trigger start handler since we're in test environment
      controller.state.value = TtsPlayerState.playing;
      // Manually start the progress timer (simulating what start handler does)
      await Future.delayed(const Duration(milliseconds: 100));

      // Wait a bit for timer to accumulate some time
      await Future.delayed(const Duration(milliseconds: 1500));

      // Verify position is advancing
      final positionBeforePause = controller.currentPosition.value;
      expect(positionBeforePause.inMilliseconds, greaterThan(0));
      expect(positionBeforePause, lessThan(initialDuration));

      debugPrint(
          '[TEST] Position before pause: ${positionBeforePause.inSeconds}s');

      // Pause
      await controller.pause();
      expect(controller.state.value, TtsPlayerState.paused);

      // Wait a bit while paused
      await Future.delayed(const Duration(milliseconds: 1000));

      // Position should NOT advance while paused
      final positionDuringPause = controller.currentPosition.value;
      debugPrint(
          '[TEST] Position during pause: ${positionDuringPause.inSeconds}s');

      // Allow small tolerance for timer update cycles
      expect(
        (positionDuringPause - positionBeforePause).inMilliseconds.abs(),
        lessThan(600), // Allow up to 600ms difference for timer cycles
        reason: 'Position should not advance significantly while paused',
      );

      // Resume playing
      await controller.play();
      controller.state.value = TtsPlayerState.playing;

      // Wait a bit more
      await Future.delayed(const Duration(milliseconds: 1500));

      // Position should continue from where it was paused
      final positionAfterResume = controller.currentPosition.value;
      debugPrint(
          '[TEST] Position after resume: ${positionAfterResume.inSeconds}s');

      // Position after resume should be >= position when paused
      expect(
        positionAfterResume,
        greaterThanOrEqualTo(positionDuringPause),
        reason:
            'Position should continue from pause point, not restart from zero',
      );

      // Position after resume should have advanced from pause point
      expect(
        positionAfterResume.inMilliseconds,
        greaterThan(positionDuringPause.inMilliseconds + 500),
        reason: 'Position should advance after resume',
      );
    });

    test('should handle multiple pause/resume cycles correctly', () async {
      controller.setText(
        'Testing multiple pause and resume cycles to ensure timer robustness.',
        languageCode: 'en',
      );

      final List<Duration> positions = [];

      // Start playing
      await controller.play();
      controller.state.value = TtsPlayerState.playing;

      // Cycle 1: Play -> Pause
      await Future.delayed(const Duration(milliseconds: 500));
      positions.add(controller.currentPosition.value);
      await controller.pause();
      await Future.delayed(const Duration(milliseconds: 300));

      // Cycle 2: Resume -> Pause
      await controller.play();
      controller.state.value = TtsPlayerState.playing;
      await Future.delayed(const Duration(milliseconds: 500));
      positions.add(controller.currentPosition.value);
      await controller.pause();
      await Future.delayed(const Duration(milliseconds: 300));

      // Cycle 3: Resume -> Pause
      await controller.play();
      controller.state.value = TtsPlayerState.playing;
      await Future.delayed(const Duration(milliseconds: 500));
      positions.add(controller.currentPosition.value);

      // Verify positions are monotonically increasing (allowing small tolerance)
      for (int i = 1; i < positions.length; i++) {
        debugPrint(
            '[TEST] Position cycle ${i - 1}: ${positions[i - 1].inSeconds}s');
        debugPrint('[TEST] Position cycle $i: ${positions[i].inSeconds}s');

        expect(
          positions[i],
          greaterThan(positions[i - 1]),
          reason:
              'Position should increase across pause/resume cycles, not reset',
        );
      }
    });

    test('should reset timer correctly after stop', () async {
      controller.setText(
        'Testing stop behavior resets timer correctly.',
        languageCode: 'en',
      );

      // Play
      await controller.play();
      controller.state.value = TtsPlayerState.playing;
      await Future.delayed(const Duration(milliseconds: 800));

      final positionBeforeStop = controller.currentPosition.value;
      expect(positionBeforeStop.inMilliseconds, greaterThan(0));

      // Stop
      await controller.stop();
      expect(controller.state.value, TtsPlayerState.idle);
      expect(controller.currentPosition.value, Duration.zero);

      // Play again - should start from beginning
      await controller.play();
      controller.state.value = TtsPlayerState.playing;
      await Future.delayed(const Duration(milliseconds: 800));

      final positionAfterRestart = controller.currentPosition.value;
      debugPrint(
          '[TEST] Position after restart: ${positionAfterRestart.inSeconds}s');

      // Should be close to the same duration as first play (not double)
      expect(
        positionAfterRestart.inMilliseconds,
        lessThan(positionBeforeStop.inMilliseconds * 1.5),
        reason: 'After stop, playback should restart from beginning',
      );
    });

    test('should handle pause immediately after play', () async {
      controller.setText(
        'Testing immediate pause after play.',
        languageCode: 'en',
      );

      // Play
      await controller.play();
      controller.state.value = TtsPlayerState.playing;

      // Immediate pause (before much time accumulates)
      await Future.delayed(const Duration(milliseconds: 100));
      await controller.pause();

      final positionAfterQuickPause = controller.currentPosition.value;

      // Resume
      await controller.play();
      controller.state.value = TtsPlayerState.playing;
      await Future.delayed(const Duration(milliseconds: 800));

      final positionAfterResume = controller.currentPosition.value;

      // Should have advanced from pause point
      expect(
        positionAfterResume,
        greaterThan(positionAfterQuickPause),
        reason: 'Should resume from pause point even with quick pause',
      );
    });
  });
}
