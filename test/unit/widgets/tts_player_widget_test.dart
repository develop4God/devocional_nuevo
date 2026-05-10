@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:devocional_nuevo/widgets/tts_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

// MockFlutterTts para pruebas

class MockFlutterTts extends FlutterTts {
  bool speakCalled = false;
  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    speakCalled = true;
    return 1;
  }
}

Devocional _makeDevocional({String id = 'test_1'}) => Devocional(
      id: id,
      versiculo: 'John 3:16',
      reflexion: 'Test reflection',
      paraMeditar: [],
      oracion: 'Test prayer',
      date: DateTime.now(),
    );

Widget _wrap(Widget child) => MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => DevocionalProvider(),
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
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
          return 1;
        default:
          return null;
      }
    });
    registerTestServices();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  testWidgets('TtsPlayerWidget renders and play button is present', (
    WidgetTester tester,
  ) async {
    final mockTts = MockFlutterTts();
    final controller = TtsAudioController(
      flutterTts: mockTts,
      voiceSettingsService: VoiceSettingsService(),
    );

    await tester.pumpWidget(
      _wrap(
        TtsPlayerWidget(
          devocional: _makeDevocional(),
          audioController: controller,
          onCompleted: () {},
        ),
      ),
    );

    // Wait for widget to settle
    await tester.pumpAndSettle();

    // Check for play button (IconButton with play icon)
    expect(find.byType(TtsPlayerWidget), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsWidgets);
  });

  // ── Lifecycle guard tests ──────────────────────────────────────────────────

  testWidgets(
    'lifecycle inactive does NOT pause TTS when state is idle (bug fix)',
    (WidgetTester tester) async {
      final controller = TtsAudioController(
        flutterTts: FlutterTts(),
        voiceSettingsService: VoiceSettingsService(),
      );
      // TTS starts in idle state
      expect(controller.state.value, TtsPlayerState.idle);

      await tester.pumpWidget(
        _wrap(
          TtsPlayerWidget(
            devocional: _makeDevocional(),
            audioController: controller,
            onCompleted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate app going to background while TTS is idle
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      // State MUST remain idle — pause() must NOT be called on an idle controller
      expect(
        controller.state.value,
        TtsPlayerState.idle,
        reason: 'pause() should not transition idle TTS to paused on lifecycle',
      );

      controller.dispose();
    },
  );

  testWidgets('lifecycle inactive DOES pause TTS when state is playing', (
    WidgetTester tester,
  ) async {
    final controller = TtsAudioController(
      flutterTts: FlutterTts(),
      voiceSettingsService: VoiceSettingsService(),
    );
    // Direct state set avoids play()'s Future.delayed deadlocking the widget
    // test's fake clock. play() contains 400ms + 80ms delays that need
    // tester.pump() — setting state directly is the correct test approach.
    controller.state.value = TtsPlayerState.playing;
    expect(controller.state.value, TtsPlayerState.playing);

    await tester.pumpWidget(
      _wrap(
        TtsPlayerWidget(
          devocional: _makeDevocional(),
          audioController: controller,
          onCompleted: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Simulate app going to background while TTS is playing
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    // Allow pause() async to complete
    await tester.pumpAndSettle();

    // State MUST become paused
    expect(
      controller.state.value,
      TtsPlayerState.paused,
      reason: 'pause() should be called when TTS is playing on lifecycle',
    );

    controller.dispose();
  });

  testWidgets('lifecycle inactive does NOT pause TTS when state is paused', (
    WidgetTester tester,
  ) async {
    final controller = TtsAudioController(
      flutterTts: FlutterTts(),
      voiceSettingsService: VoiceSettingsService(),
    );
    // Set state to paused directly — avoids Future.delayed deadlock.
    controller.state.value = TtsPlayerState.paused;
    expect(controller.state.value, TtsPlayerState.paused);

    await tester.pumpWidget(
      _wrap(
        TtsPlayerWidget(
          devocional: _makeDevocional(),
          audioController: controller,
          onCompleted: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Simulate lifecycle while already paused
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    await tester.pumpAndSettle();

    // Must remain paused, not reset to idle or change otherwise
    expect(
      controller.state.value,
      TtsPlayerState.paused,
      reason: 'already-paused TTS must remain paused after lifecycle event',
    );

    controller.dispose();
  });
}
