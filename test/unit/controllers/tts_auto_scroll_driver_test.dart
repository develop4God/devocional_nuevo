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

  @override
  void scrollToFraction(double fraction) => fractions.add(fraction);
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
}
