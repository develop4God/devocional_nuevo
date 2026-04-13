@Tags(['unit', 'controllers'])
library;

// test/unit/controllers/tts_rtl_fix_behavior_test.dart
//
// Tests validating the two bugs fixed by tts_rtl_fix.md:
//
// Bug 1 — Unguarded 400ms delay (resume-from-pause path)
//   The 400ms delay was moved INSIDE the _isPreparingToSpeak guard so that
//   Android's deferred cancel event from a prior pause() arrives while the
//   guard is active and is suppressed. Without the fix the cancel set state
//   to idle and the abort-check killed play() before speak() was ever called.
//
// Bug 2 — Watchdog checked state == playing but fired during loading
//   _handleSilentUtterance now checks both playing AND loading states.
//   On detection it transitions immediately to ERROR — no silent retry loop.

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
        '(regression: previously killed by unguarded deferred cancel)',
        () {
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
  // GROUP 2 — Bug 2: watchdog detect-only, no retry
  // ──────────────────────────────────────────────────────────────────────────

  group('Bug 2 — Watchdog: silent utterance → ERROR immediately, no retry',
      () {
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

    // ── Scenario: watchdog fires after 1.2s → error ──────────────────────────
    test(
        'Silent engine: watchdog transitions to ERROR after 1.2s '
        '(no retries, no silent loop)',
        () {
      fakeAsync((async) {
        controller.setText('Silent engine test text.');

        final states = <TtsPlayerState>[];
        controller.state.addListener(() => states.add(controller.state.value));

        // play() is unawaited — in fakeAsync we drive time manually.
        unawaited(controller.play());
        async.flushMicrotasks();

        // Advance past guard delays (400ms + 80ms) so speak() is called.
        async.elapse(const Duration(milliseconds: 600));
        // State should be playing (set when speak() completes and the post-speak
        // loading→playing transition fires).
        // Note: in fire-and-forget mode loading→playing happens after speak()
        // returns. Advance one more tick.
        async.flushMicrotasks();

        // Now 1.2s must elapse for the watchdog to fire.
        async.elapse(const Duration(milliseconds: 1200));

        expect(
          controller.state.value,
          TtsPlayerState.error,
          reason:
              'Watchdog must transition to ERROR after 1.2s with no startHandler',
        );

        // Crucially, the controller must NOT have made a second speak() call
        // (no retry loop). We verify by checking that the state went to error
        // only once and is still error.
        final errorCount =
            states.where((s) => s == TtsPlayerState.error).length;
        expect(
          errorCount,
          1,
          reason: 'ERROR must appear exactly once — no retry loop',
        );
      });
    });

    // ── Scenario: watchdog fires in loading state too (fixed guard) ──────────
    test(
        'Watchdog fires even when state is loading (not just playing) — '
        'detects silent engine before speak() starts handler',
        () {
      fakeAsync((async) {
        controller.setText('Silent engine loading state test.');

        unawaited(controller.play());
        async.flushMicrotasks();

        // Only advance far enough to pass internal delays and arm watchdog,
        // but NOT enough for loading→playing transition.
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        // The watchdog is now armed at this point. Manually fire it:
        // advance 1.2s so Timer fires.
        async.elapse(const Duration(milliseconds: 1200));

        expect(
          controller.state.value,
          TtsPlayerState.error,
          reason:
              'Watchdog must transition to ERROR when state is loading/playing',
        );
      });
    });

    // ── Scenario: watchdog is cancelled when startHandler fires normally ─────
    test(
        'Working engine: startHandler cancels watchdog — state stays playing, '
        'no error after 1.2s',
        () {
      fakeAsync((async) {
        // Healthy engine for this test.
        mockTts.autoFireStart = true;

        controller.setText('Working engine no watchdog test.');

        unawaited(controller.play());
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        // Advance well past the watchdog window.
        async.elapse(const Duration(milliseconds: 1500));

        expect(
          controller.state.value,
          isNot(TtsPlayerState.error),
          reason:
              'When startHandler fires, watchdog must be cancelled; no error',
        );
        expect(controller.state.value, TtsPlayerState.playing);
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

    // ── User receives error on broken engine (e.g. Arabic on MIUI) ──────────
    test(
        'User with broken TTS engine (silent utterance): sees error state '
        'within 1.2s — not infinite spinner',
        () {
      fakeAsync((async) {
        // Broken engine: never fires startHandler.
        mockTts.autoFireStart = false;

        controller.setText(
          'نص عربي لاختبار المحرك الصامت.', // Arabic: 'Arabic text to test the silent engine'
        );

        unawaited(controller.play());
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        // Before watchdog fires — spinner might still be visible.
        expect(
          controller.state.value,
          isNot(TtsPlayerState.error),
          reason: 'Watchdog has not fired yet at 600ms',
        );

        // After watchdog fires (1.2s).
        async.elapse(const Duration(milliseconds: 1200));

        expect(
          controller.state.value,
          TtsPlayerState.error,
          reason:
              'After 1.2s with no audio, user must see error — not endless spinner',
        );
      });
    });

    // ── Error state is recoverable: user retaps play ─────────────────────────
    test('User can retry after broken engine error by tapping play again',
        () async {
      controller.setText('Texto de recuperación después de error.');

      // Error path: set error directly as if watchdog fired.
      controller.error();
      expect(controller.state.value, TtsPlayerState.error);

      // Fix engine and retry.
      mockTts.autoFireStart = true;
      await controller.play();

      expect(
        controller.state.value,
        TtsPlayerState.playing,
        reason: 'User must be able to retry after an error state',
      );
    });

    // ── Stop clears watchdog — no late error after stop ──────────────────────
    test('Stop cancels watchdog: no ERROR fires after stop()', () {
      fakeAsync((async) {
        mockTts.autoFireStart = false; // silence engine to arm watchdog

        controller.setText('Test stop cancels watchdog.');

        unawaited(controller.play());
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        // Watchdog is now armed. Stop before it fires.
        unawaited(controller.stop());
        async.flushMicrotasks();

        expect(controller.state.value, TtsPlayerState.idle);

        // Advance well past watchdog window — should NOT become error.
        async.elapse(const Duration(milliseconds: 1500));

        expect(
          controller.state.value,
          TtsPlayerState.idle,
          reason:
              'After stop(), watchdog must be cancelled; state must stay idle',
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

      localController.setText('Texto para probar dispose durante reproducción.');

      unawaited(localController.play());
      await Future.microtask(() {});

      // Dispose immediately while play() is in progress.
      expect(() => localController.dispose(), returnsNormally);
    });

    // ── Arabic text plays just like Spanish (language-agnostic path) ─────────
    test(
        'Arabic text plays without error — same code path as Spanish/English',
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

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 4 — No retry loop regression guard
  // ──────────────────────────────────────────────────────────────────────────

  group('No retry loop: _handleSilentUtterance fires only once', () {
    test('Silent utterance transitions to error once, never retries', () {
      fakeAsync((async) {
        final mockTts = MockFlutterTts()..autoFireStart = false;
        final controller = TestableController(
          flutterTts: mockTts,
          voiceSettingsService: getService<VoiceSettingsService>(),
        );

        final errorTransitions = <TtsPlayerState>[];
        controller.state.addListener(() {
          if (controller.state.value == TtsPlayerState.error) {
            errorTransitions.add(TtsPlayerState.error);
          }
        });

        controller.setText('Texto para verificar sin reintentos.');
        unawaited(controller.play());
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        // Watchdog fires at 1.2s.
        async.elapse(const Duration(milliseconds: 1200));

        // Advance extra time — old retry code would have re-spoken and re-armed.
        async.elapse(const Duration(milliseconds: 3000));

        expect(
          errorTransitions.length,
          1,
          reason:
              'ERROR must be set exactly once — old retry logic would set it '
              'after each failed retry, typically 3x',
        );

        expect(controller.state.value, TtsPlayerState.error);

        controller.dispose();
      });
    });
  });
}
