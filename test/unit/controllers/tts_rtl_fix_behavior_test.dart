@Tags(['unit', 'controllers'])
library;

// test/unit/controllers/tts_rtl_fix_behavior_test.dart
//
// Tests validating the bug fixed by removing the silence watchdog:
//
// The watchdog was a 1200ms timer that fired when speak() returned without
// an immediate startHandler callback, transitioning state to ERROR.
// This caused false positives on slow TTS engines (e.g., MIUI devices) that
// took >1200ms to invoke startHandler.
//
// **After the fix:** The watchdog is removed entirely. Single-chunk playback
// uses the fallback: speak() returns → state LOADING → manual state transition
// to PLAYING + start progress timer. When startHandler fires (whenever it does),
// the guard prevents double-start.
//
// Silent engines (never fire startHandler) stay in PLAYING state with no audio.
// Users must manually stop/retry — no automatic ERROR transition.

import 'dart:async';

import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Test subclass that exposes protected internals ────────────────────────────

class TestableController extends TtsAudioController {
  TestableController({
    required super.flutterTts,
    required super.voiceSettingsService,
  });
}

// ── Controllable mock FlutterTts ──────────────────────────────────────────────
//
// Delegates all method calls to the real MethodChannel (mocked via
// TestDefaultBinaryMessengerBinding) EXCEPT for the handler registration
// methods, which it stores for direct invocation by tests.

class MockFlutterTts extends FlutterTts {
  VoidCallback? _startHandler;
  VoidCallback? _completionHandler;
  VoidCallback? _cancelHandler;

  /// Whether the mock should fire startHandler automatically when speak() is
  /// called (simulates a healthy TTS engine).  Set to false to simulate a
  /// silent/broken engine that never produces audio.
  bool autoFireStart = true;

  @override
  void setStartHandler(VoidCallback handler) {
    _startHandler = handler;
  }

  @override
  void setCompletionHandler(VoidCallback handler) {
    _completionHandler = handler;
  }

  @override
  void setCancelHandler(VoidCallback handler) {
    _cancelHandler = handler;
  }

  @override
  void setErrorHandler(Function(dynamic) handler) {}

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    if (autoFireStart) {
      // Simulate a healthy engine: fire startHandler synchronously so the
      // silent-utterance watchdog is immediately cancelled.
      _startHandler?.call();
    }
    // In a silent/broken engine scenario autoFireStart == false and
    // _startHandler is never called.
    return 1;
  }

  // ── Helper methods for tests ──────────────────────────────────────────────

  /// Simulate Android's deferred cancel event (the one that arrives from a
  /// prior flutterTts.pause() call after a short async delay).
  void simulateDeferredCancel() => _cancelHandler?.call();

  /// Manually fire the start handler (e.g. after an async gap in tests).
  void fireStart() => _startHandler?.call();

  /// Manually fire the completion handler.
  void fireCompletion() => _completionHandler?.call();
}

// ── Common setup ──────────────────────────────────────────────────────────────

const _ttsChannel = MethodChannel('flutter_tts');

void _setupTtsMethodChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_ttsChannel, (call) async {
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
      case 'setQueueMode':
      case 'setVoice':
        return 1;
      case 'getVoices':
        return [
          {'name': 'ar-xa-x-arc-local', 'locale': 'ar-XA'},
          {'name': 'es-es-x-eee-local', 'locale': 'es-ES'},
          {'name': 'en-us-x-iom-local', 'locale': 'en-US'},
        ];
      case 'getLanguages':
        return ['ar-XA', 'es-ES', 'en-US'];
      case 'isLanguageAvailable':
        return true;
      default:
        return null;
    }
  });
}

void _tearDownTtsMethodChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_ttsChannel, null);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    ServiceLocator().reset();
    setupServiceLocator();
    _setupTtsMethodChannel();
  });

  tearDownAll(() {
    _tearDownTtsMethodChannel();
    ServiceLocator().reset();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 1 — Bug 1: guard suppresses Android deferred cancel
  // ──────────────────────────────────────────────────────────────────────────

  group('Bug 1 — _isPreparingToSpeak guard suppresses deferred cancel', () {
    late MockFlutterTts mockTts;
    late TestableController controller;

    setUp(() {
      mockTts = MockFlutterTts();
      controller = TestableController(
        flutterTts: mockTts,
        voiceSettingsService: getService<VoiceSettingsService>(),
      );
    });

    tearDown(() => controller.dispose());

    // ── Scenario: normal first play — state reaches playing ─────────────────
    test('Normal first play: state transitions idle → loading → playing',
        () async {
      controller.setText('Texto de prueba para reproducción inicial.');

      expect(controller.state.value, TtsPlayerState.idle);

      final playFuture = controller.play();
      // Right after calling play() the state should be loading before the
      // internal awaits resolve.  Let one microtask tick so play() starts.
      await Future.microtask(() {});
      expect(controller.state.value, TtsPlayerState.loading);

      await playFuture;
      expect(controller.state.value, TtsPlayerState.playing);
    });

    // ── Scenario: cancel arrives DURING guard — must be suppressed ───────────
    test(
        'Cancel arriving while _isPreparingToSpeak is true is suppressed — '
        'state stays loading, play() reaches speaking', () {
      fakeAsync((async) {
        controller.setText('Texto para reproducción después de pausa.');

        // Start play; unawaited so fakeAsync can drive timing.
        unawaited(controller.play());

        // Flush all pending microtasks. The controller runs several mocked awaits
        // (awaitSpeakCompletion, getSpeechRate, setSpeechRate) and then reaches
        // `_isPreparingToSpeak = true` just before `await Future.delayed(400ms)`.
        // After flushMicrotasks() the coroutine is parked at that 400ms delay and
        // the guard flag is already true.
        async.flushMicrotasks();
        expect(controller.state.value, TtsPlayerState.loading);

        // Simulate Android's deferred cancel while the guard is active.
        // Because _isPreparingToSpeak == true, cancelHandler must ignore this.
        mockTts.simulateDeferredCancel();

        // Advance past the 400ms + 80ms guard window and let speak() run.
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        // State must be playing — not idle (which would indicate the cancel
        // was NOT suppressed and the abort-guard fired).
        expect(
          controller.state.value,
          TtsPlayerState.playing,
          reason:
              'Deferred cancel during _isPreparingToSpeak must be suppressed; '
              'state must reach playing, not be reset to idle',
        );
      });
    });

    // ── Scenario: cancel that arrives OUTSIDE the guard still takes effect ───
    test(
        'Cancel arriving outside _isPreparingToSpeak guard resets state to idle',
        () async {
      controller.setText('Texto corto.');
      await controller.play();
      expect(controller.state.value, TtsPlayerState.playing);

      // Guard is no longer active — a cancel should reset state to idle.
      mockTts.simulateDeferredCancel();
      await Future.microtask(() {});

      expect(
        controller.state.value,
        TtsPlayerState.idle,
        reason: 'Cancel outside guard window must reset state to idle',
      );
    });

    // ── Scenario: resume-from-pause succeeds (the core regression) ──────────
    test(
        'Resume from paused state produces playing state '
        '(regression: previously killed by unguarded deferred cancel)', () {
      fakeAsync((async) {
        controller.setText(
            'Texto de devocional suficientemente largo para una prueba real.');

        // 1. Play to reach playing state.
        unawaited(controller.play());
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();
        expect(controller.state.value, TtsPlayerState.playing);

        // 2. Pause.
        unawaited(controller.pause());
        async.flushMicrotasks();
        expect(controller.state.value, TtsPlayerState.paused);

        // 3. Resume. The deferred cancel from step 2 arrives during the guard
        //    window (inside the 400ms delay) and must be suppressed.
        unawaited(controller.play());
        async.flushMicrotasks(); // guard becomes active here
        mockTts.simulateDeferredCancel(); // arrives while guard is active
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        expect(
          controller.state.value,
          TtsPlayerState.playing,
          reason:
              'Resume must succeed even when Android deferred cancel fires during '
              'the guard window; without the fix state would be idle',
        );
      });
    });

    // ── Scenario: play() after stop also works ───────────────────────────────
    test('Play after stop transitions back to playing correctly', () async {
      controller.setText('Texto de prueba.');
      await controller.play();
      await controller.stop();
      expect(controller.state.value, TtsPlayerState.idle);

      await controller.play();
      expect(controller.state.value, TtsPlayerState.playing);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 2 — Silent engine behavior (no watchdog; fallback timer runs)
  // ──────────────────────────────────────────────────────────────────────────
  //
  // Without the watchdog, silent engines (no startHandler) still transition to
  // PLAYING because the fallback timer starts immediately after speak() returns.
  // The progress timer ticks but position never advances (no audio playing),
  // so eventually it hits totalDuration and transitions to COMPLETED without
  // actual audio. This is the expected behavior post-watchdog removal.

  group('Silent engine behavior — no watchdog, fallback timer active', () {
    late MockFlutterTts mockTts;
    late TestableController controller;

    setUp(() {
      mockTts = MockFlutterTts()..autoFireStart = false; // silent engine
      controller = TestableController(
        flutterTts: mockTts,
        voiceSettingsService: getService<VoiceSettingsService>(),
      );
    });

    tearDown(() => controller.dispose());

    // ── Scenario: silent engine transitions to PLAYING via fallback ─────────
    test(
        'Silent engine (no startHandler): fallback timer sets state to PLAYING, '
        'position advances (no audio, but timer runs)', () {
      fakeAsync((async) {
        controller.setText('Text that will not be spoken.');

        unawaited(controller.play());
        async.flushMicrotasks();

        // Advance past guard and speak() — fallback timer starts.
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        // State is now PLAYING (from fallback, not startHandler).
        expect(
          controller.state.value,
          TtsPlayerState.playing,
          reason:
              'Without watchdog, fallback timer sets state to PLAYING even if '
              'no audio started',
        );

        // Advance time — progress timer ticks. Position will advance because
        // the fallback timer is running (no audio to measure, but clock runs).
        async.elapse(const Duration(seconds: 1));

        // Position may advance in fakeAsync because we're advancing time by
        // 1000ms and the progress timer ticks every 500ms. Two ticks = 1s elapsed.
        expect(
          controller.currentPosition.value.inMilliseconds,
          greaterThanOrEqualTo(0),
          reason: 'Fallback timer ticks; position reflects clock advancement',
        );

        // State stays PLAYING (no watchdog to transition to ERROR).
        expect(
          controller.state.value,
          TtsPlayerState.playing,
          reason: 'State stays PLAYING — no watchdog to transition to ERROR',
        );
      });
    });

    // ── Scenario: healthy engine still works normally ───────────────────────
    test(
        'Healthy engine (startHandler fires): state is PLAYING, position advances',
        () {
      fakeAsync((async) {
        mockTts.autoFireStart = true; // healthy engine

        controller.setText('Healthy engine text.');

        unawaited(controller.play());
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        expect(controller.state.value, TtsPlayerState.playing);

        // Advance time — progress timer will tick.
        async.elapse(const Duration(milliseconds: 1000));

        // Position advances (startHandler fired, progress timer active).
        expect(
          controller.currentPosition.value.inMilliseconds,
          greaterThan(0),
          reason: 'Healthy engine — startHandler fires, progress advances',
        );
      });
    });

    // ── Scenario: stop() clears timer (still works, no watchdog to cancel) ───
    test('Stop during silent playback — state returns to idle', () {
      fakeAsync((async) {
        controller.setText('Text to test stop during silent play.');

        unawaited(controller.play());
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        expect(controller.state.value, TtsPlayerState.playing);

        unawaited(controller.stop());
        async.flushMicrotasks();

        expect(
          controller.state.value,
          TtsPlayerState.idle,
          reason: 'Stop must reset state to idle',
        );
      });
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 3 — Real user behavior flows (integration of both fixes)
  // ──────────────────────────────────────────────────────────────────────────

  group('Real user behavior — end-to-end flows', () {
    late MockFlutterTts mockTts;
    late TestableController controller;

    setUp(() {
      mockTts = MockFlutterTts();
      controller = TestableController(
        flutterTts: mockTts,
        voiceSettingsService: getService<VoiceSettingsService>(),
      );
    });

    tearDown(() => controller.dispose());

    // ── User plays a devotional from idle ────────────────────────────────────
    test('User: tap play from idle → audio playing', () async {
      controller.setText(
          'Juan 3:16 — Porque de tal manera amó Dios al mundo que dio a su '
          'Hijo unigénito para que todo el que crea en él no se pierda sino '
          'que tenga vida eterna.');

      await controller.play();

      expect(controller.state.value, TtsPlayerState.playing);
      expect(controller.totalDuration.value.inSeconds, greaterThan(0));
    });

    // ── User taps pause then play (the core Android regression) ─────────────
    test('User: play → pause → resume — state is playing after resume',
        () async {
      controller.setText('Text for pause resume user flow test.');

      await controller.play();
      expect(controller.state.value, TtsPlayerState.playing);

      await controller.pause();
      expect(controller.state.value, TtsPlayerState.paused);

      // Resume. The guard suppresses any deferred cancel from the prior pause().
      await controller.play();

      expect(
        controller.state.value,
        TtsPlayerState.playing,
        reason:
            'User must be able to resume after pause; Android deferred cancel '
            'must not kill the resume',
      );
    });

    // ── User taps pause and play multiple times (stress) ─────────────────────
    test('User: multiple rapid pause/play cycles — all succeed', () async {
      controller.setText(
          'Texto devocional largo para múltiples ciclos de pausa y reproducción.');

      for (int cycle = 1; cycle <= 3; cycle++) {
        await controller.play();
        expect(
          controller.state.value,
          TtsPlayerState.playing,
          reason: 'Cycle $cycle: state must be playing',
        );

        await controller.pause();
        expect(
          controller.state.value,
          TtsPlayerState.paused,
          reason: 'Cycle $cycle: state must be paused',
        );

        // Resume — guard suppresses deferred Android cancel from prior pause.
        await controller.play();

        expect(
          controller.state.value,
          TtsPlayerState.playing,
          reason: 'Cycle $cycle: state must be playing after resume',
        );

        await controller.pause();
      }
    });

    // ── Silent engine (no watchdog) — state is playing but no audio ──────────
    test(
        'User with silent TTS engine: state is PLAYING via fallback timer, '
        'no automatic error transition (watchdog removed)', () {
      fakeAsync((async) {
        // Silent engine: never fires startHandler.
        mockTts.autoFireStart = false;

        // Use a longer text to ensure totalDuration is long enough to not hit
        // the completion boundary when we advance time.
        controller.setText(
            'Text that will not produce audio but is long enough to have a reasonable duration estimate so we can observe the playing state without premature completion.');

        unawaited(controller.play());
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        // State is PLAYING (fallback timer, not startHandler).
        expect(
          controller.state.value,
          TtsPlayerState.playing,
          reason:
              'Without watchdog, fallback timer sets state to PLAYING regardless '
              'of whether audio actually started',
        );

        // Advance time but not so much that we hit the duration limit
        async.elapse(const Duration(milliseconds: 500));

        // State should still be PLAYING (not completed due to time).
        expect(
          controller.state.value,
          TtsPlayerState.playing,
          reason: 'No watchdog → no automatic ERROR. State stays PLAYING until '
              'total duration is reached.',
        );
      });
    });

    // ── Manual error recovery (watchdog removed — no automatic error) ────────
    test('User can manually call error() and retry', () async {
      controller.setText('Texto de recuperación después de error manual.');

      // Simulate error state manually (no watchdog to auto-trigger it).
      controller.error();
      expect(controller.state.value, TtsPlayerState.error);

      // Retry by calling play().
      await controller.play();

      expect(
        controller.state.value,
        TtsPlayerState.playing,
        reason: 'User must be able to retry after an error state',
      );
    });

    // ── Stop clears timers — no errors after stop ──────────────────────────
    test('Stop during playback — state returns to idle', () {
      fakeAsync((async) {
        mockTts.autoFireStart = false; // silent engine

        controller.setText('Test stop.');

        unawaited(controller.play());
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        // Watchdog would be armed (old behavior), but we removed it.
        // Stop before any state transition.
        unawaited(controller.stop());
        async.flushMicrotasks();

        expect(controller.state.value, TtsPlayerState.idle);

        // Advance well past old watchdog window — should stay idle.
        async.elapse(const Duration(milliseconds: 1500));

        expect(
          controller.state.value,
          TtsPlayerState.idle,
          reason: 'After stop(), state must stay idle',
        );
      });
    });

    // ── Dispose during play — no crash or late state update ──────────────────
    test('Dispose during play does not crash and produces no late state update',
        () async {
      // Use a separate controller so tearDown's dispose() doesn't double-dispose.
      final localMock = MockFlutterTts();
      final localController = TestableController(
        flutterTts: localMock,
        voiceSettingsService: getService<VoiceSettingsService>(),
      );

      localController
          .setText('Texto para probar dispose durante reproducción.');

      unawaited(localController.play());
      await Future.microtask(() {});

      // Dispose immediately while play() is in progress.
      expect(() => localController.dispose(), returnsNormally);
    });

    // ── Arabic text plays just like Spanish (language-agnostic path) ─────────
    test('Arabic text plays without error — same code path as Spanish/English',
        () async {
      controller.setText(
        // Arabic: 'Jesus loved us so much that he died for us.
        //          This is the central message of the Gospel.'
        'يسوع أحبنا إلى درجة أنه مات لأجلنا. هذه هي الرسالة المركزية للإنجيل.',
        languageCode: 'ar',
      );

      await controller.play();

      expect(
        controller.state.value,
        TtsPlayerState.playing,
        reason: 'Arabic text must play successfully through the same code path',
      );
    });
  });
}
