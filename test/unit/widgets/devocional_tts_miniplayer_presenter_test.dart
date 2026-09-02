@Tags(['unit', 'widgets', 'tts'])
library;

import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocional_tts_miniplayer_presenter.dart';
import 'package:devocional_nuevo/widgets/tts_miniplayer_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFlutterTts extends Mock implements FlutterTts {
  @override
  Future<dynamic> speak(String text, {bool focus = false}) async => 1;

  @override
  Future<dynamic> pause() async => 1;

  @override
  Future<dynamic> stop() async => 1;

  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async => 1;

  @override
  void setCompletionHandler(VoidCallback handler) {}

  @override
  void setStartHandler(VoidCallback handler) {}

  @override
  void setCancelHandler(VoidCallback handler) {}

  @override
  void setErrorHandler(Function(dynamic) handler) {}
}

void main() {
  group('DevocionalTtsMiniplayerPresenter', () {
    late MockFlutterTts mockTts;
    late TtsAudioController controller;
    late DevocionalTtsMiniplayerPresenter presenter;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ServiceLocator().reset();
      setupServiceLocator();

      mockTts = MockFlutterTts();
      controller = TtsAudioController(
        flutterTts: mockTts,
        voiceSettingsService: VoiceSettingsService(),
      );
      presenter = DevocionalTtsMiniplayerPresenter(
        ttsAudioController: controller,
      );
    });

    tearDown(() {
      presenter.dispose();
      controller.dispose();
      ServiceLocator().reset();
    });

    Future<void> pumpHost(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () =>
                    presenter.showMiniplayerModal(context, () => null),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows the modal and marks the presenter as showing', (
      tester,
    ) async {
      await pumpHost(tester);

      expect(presenter.isShowing, isFalse);

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TtsMiniplayerModal), findsOneWidget);
      expect(presenter.isShowing, isTrue);
    });

    testWidgets('a second call while already showing is a no-op', (
      tester,
    ) async {
      await pumpHost(tester);

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TtsMiniplayerModal), findsOneWidget);

      // Calling again directly (simulating a duplicate trigger) must not
      // open a second modal.
      presenter.showMiniplayerModal(
        tester.element(find.byType(TtsMiniplayerModal)),
        () => null,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TtsMiniplayerModal), findsOneWidget);
    });

    testWidgets('tapping stop closes the modal and stops the controller', (
      tester,
    ) async {
      await pumpHost(tester);

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.stop_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TtsMiniplayerModal), findsNothing);
      expect(controller.state.value, TtsPlayerState.idle);
      expect(presenter.isShowing, isFalse);
    });

    testWidgets('dismissing the modal resets the showing flag', (
      tester,
    ) async {
      await pumpHost(tester);

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(presenter.isShowing, isTrue);

      // Simulate the system back gesture dismissing the sheet.
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TtsMiniplayerModal), findsNothing);
      expect(presenter.isShowing, isFalse);
    });

    test('resetModalState clears the showing flag without side effects', () {
      presenter.resetModalState();
      expect(presenter.isShowing, isFalse);
    });

    test('dispose clears the showing flag', () {
      presenter.dispose();
      expect(presenter.isShowing, isFalse);
    });
  });
}
