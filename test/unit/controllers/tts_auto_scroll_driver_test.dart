@Tags(['unit', 'controllers'])
library;

import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/controllers/tts_auto_scroll_driver.dart';
import 'package:devocional_nuevo/controllers/tts_scroll_target.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records every fraction the driver requests, so tests can assert the
/// position→scroll mapping without a real scroll view.
class FakeScrollTarget implements TtsScrollTarget {
  final List<double> fractions = [];
  final List<int> indices = [];

  @override
  void scrollToFraction(double fraction) => fractions.add(fraction);

  @override
  void scrollToIndex(int itemIndex, int itemCount) => indices.add(itemIndex);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel ttsChannel = MethodChannel('flutter_tts');

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    ServiceLocator().reset();
    await setupServiceLocator();

    // Minimal TTS channel mock — the driver never speaks, but the controller
    // constructor touches the channel via VoiceSettingsService.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (MethodCall call) async => 1);
  });

  late TtsAudioController controller;
  late FakeScrollTarget target;
  late TtsAutoScrollDriver driver;

  setUp(() {
    controller = TtsAudioController(
      flutterTts: FlutterTts(),
      voiceSettingsService: VoiceSettingsService(),
    );
    target = FakeScrollTarget();
    driver = TtsAutoScrollDriver(controller: controller, target: target)
      ..attach();
  });

  tearDown(() {
    driver.dispose();
    controller.dispose();
  });

  test('scrolls to rising fractions as playback position advances', () {
    controller.totalDuration.value = const Duration(seconds: 100);
    controller.state.value = TtsPlayerState.playing;
    target.fractions
        .clear(); // drop the initial fraction-0 tick from state change

    controller.currentPosition.value = const Duration(seconds: 25);
    controller.currentPosition.value = const Duration(seconds: 50);
    controller.currentPosition.value = const Duration(seconds: 90);

    expect(target.fractions, [0.25, 0.5, 0.9]);
  });

  test('does not scroll when not playing', () {
    controller.totalDuration.value = const Duration(seconds: 100);
    controller.state.value = TtsPlayerState.paused;

    controller.currentPosition.value = const Duration(seconds: 50);

    expect(target.fractions, isEmpty);
  });

  test('does not scroll when total duration is zero', () {
    controller.totalDuration.value = Duration.zero;
    controller.state.value = TtsPlayerState.playing;

    controller.currentPosition.value = const Duration(seconds: 10);

    expect(target.fractions, isEmpty);
  });

  test('clamps fraction to 1.0 when position exceeds total', () {
    controller.totalDuration.value = const Duration(seconds: 100);
    controller.state.value = TtsPlayerState.playing;
    target.fractions.clear(); // drop the initial fraction-0 tick

    controller.currentPosition.value = const Duration(seconds: 150);

    expect(target.fractions, [1.0]);
  });

  test('stops scrolling after dispose', () {
    controller.totalDuration.value = const Duration(seconds: 100);
    controller.state.value = TtsPlayerState.playing;
    target.fractions.clear(); // drop the initial fraction-0 tick

    driver.dispose();
    controller.currentPosition.value = const Duration(seconds: 50);

    expect(target.fractions, isEmpty);
  });

  group('currentIndex', () {
    late TtsAutoScrollDriver indexDriver;

    setUp(() {
      indexDriver = TtsAutoScrollDriver(
        controller: controller,
        target: target,
        // Flat 10-item mapping for these driver-level assertions.
        indexForFraction: (f) => (f * 10).floor().clamp(0, 9),
      )..attach();
    });

    tearDown(() => indexDriver.dispose());

    test('maps fraction to floored verse index while playing', () {
      controller.totalDuration.value = const Duration(seconds: 100);
      controller.state.value = TtsPlayerState.playing;

      controller.currentPosition.value = const Duration(seconds: 25);
      expect(indexDriver.currentIndex.value, 2); // 0.25 * 10 = 2.5 -> 2

      controller.currentPosition.value = const Duration(seconds: 58);
      expect(indexDriver.currentIndex.value, 5); // 0.58 * 10 = 5.8 -> 5
    });

    test('clamps index to last verse when position exceeds total', () {
      controller.totalDuration.value = const Duration(seconds: 100);
      controller.state.value = TtsPlayerState.playing;

      controller.currentPosition.value = const Duration(seconds: 150);
      expect(indexDriver.currentIndex.value, 9); // clamp to count-1
    });

    test('is null when not playing', () {
      controller.totalDuration.value = const Duration(seconds: 100);
      controller.currentPosition.value = const Duration(seconds: 50);
      controller.state.value = TtsPlayerState.paused;

      expect(indexDriver.currentIndex.value, isNull);
    });
  });

  group('scroll follows the resolved index (not the estimate)', () {
    // Isolated controller/target/driver so the outer setUp's driver (which
    // shares the top-level controller+target) can't pollute these assertions.
    late TtsAudioController c;
    late FakeScrollTarget t;
    late TtsAutoScrollDriver d;

    setUp(() {
      c = TtsAudioController(
        flutterTts: FlutterTts(),
        voiceSettingsService: VoiceSettingsService(),
      );
      t = FakeScrollTarget();
      d = TtsAutoScrollDriver(
        controller: c,
        target: t,
        indexForCharOffset: (offset) => 3, // word-accurate → verse 3
        indexForFraction: (f) => 0,
        itemCount: () => 10,
      )..attach();
    });

    tearDown(() {
      d.dispose();
      c.dispose();
    });

    test('scrolls by index when a word-accurate offset is available', () {
      c.totalDuration.value = const Duration(seconds: 100);
      c.state.value = TtsPlayerState.playing;
      c.wordTracker.beginSegment(0);

      c.wordTracker.onProgress(30); // char offset ≥ 0 → word-accurate

      expect(t.indices.last, 3);
      // The fast estimated fraction must NOT drive the scroll here.
      expect(t.fractions, isEmpty);
    });

    test('uses the estimated fraction index when offset is unknown (-1)', () {
      c.totalDuration.value = const Duration(seconds: 100);
      c.state.value = TtsPlayerState.playing;
      // No progress event → spokenCharOffset stays -1, so the estimated
      // fraction resolver drives the index (here it returns 0).
      c.currentPosition.value = const Duration(seconds: 50);

      expect(t.indices, everyElement(0));
      expect(t.indices, isNotEmpty);
    });

    test('pure fraction scroll when no resolver/itemCount is available', () {
      final t2 = FakeScrollTarget();
      final d2 = TtsAutoScrollDriver(
        controller: c,
        target: t2,
        // No resolvers, no itemCount → fraction path only.
      )..attach();
      addTearDown(d2.dispose);

      c.totalDuration.value = const Duration(seconds: 100);
      c.state.value = TtsPlayerState.playing;
      c.currentPosition.value = const Duration(seconds: 50);

      expect(t2.fractions, isNotEmpty);
      expect(t2.indices, isEmpty);
    });

    test(
      'throttles rapid word-progress events instead of scrolling on every one',
      () {
        // Native engines fire wordTracker progress several times/sec — far
        // faster than the driver's intended ~2/sec tick cadence (matched to
        // TtsAudioController.progressTickInterval, 500ms). Without a
        // throttle, each one restarts the scroll animation.
        c.totalDuration.value = const Duration(seconds: 100);
        c.state.value = TtsPlayerState.playing;
        c.wordTracker.beginSegment(0);
        t.indices.clear();

        // Five rapid progress events, back-to-back (no real delay between
        // them) — simulating several native callbacks landing well within
        // one throttle window.
        c.wordTracker.onProgress(10);
        c.wordTracker.onProgress(11);
        c.wordTracker.onProgress(12);
        c.wordTracker.onProgress(13);
        c.wordTracker.onProgress(14);

        expect(
          t.indices.length,
          1,
          reason: 'Only the first of several rapid word-progress events '
              'within one throttle window should trigger a scroll call.',
        );
      },
    );
  });
}
