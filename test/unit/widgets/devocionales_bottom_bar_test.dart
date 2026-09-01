@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocionales_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

Devocional _makeDevocional() => Devocional(
      id: 'test_1',
      versiculo: 'John 3:16',
      reflexion: 'Test reflection',
      paraMeditar: [],
      oracion: 'Test prayer',
      date: DateTime.now(),
    );

Widget _wrap(
  Widget child, {
  required Size size,
  TextScaler textScaler = TextScaler.noScaling,
}) =>
    MediaQuery(
      data: MediaQueryData(size: size, textScaler: textScaler),
      child: MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => DevocionalProvider()),
            ChangeNotifierProvider(
              create: (_) => AudioController(TtsService()),
            ),
          ],
          child: Scaffold(bottomNavigationBar: child),
        ),
      ),
    );

void main() {
  setUp(() async {
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
    await registerTestServices();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  Widget createWidgetUnderTest() {
    final controller = TtsAudioController(
      flutterTts: FlutterTts(),
      voiceSettingsService: VoiceSettingsService(),
    );
    return DevocionalesBottomBar(
      currentDevocional: _makeDevocional(),
      canNavigateNext: true,
      canNavigatePrevious: true,
      ttsAudioController: controller,
      onPrevious: () {},
      onNext: () {},
      onShowInvitation: () {},
    );
  }

  testWidgets('does not overflow on a narrow (small phone) screen width', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(createWidgetUnderTest(), size: const Size(320, 640)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DevocionalesBottomBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'next button label does not overflow its Row at a larger '
    'accessibility text scale on a narrow screen',
    (WidgetTester tester) async {
      // Reproduces the reported bug: at a larger text scale (accessibility
      // setting) the "next" button's label no longer fits its narrow
      // OutlinedButton slot, so the label Row must shrink instead of
      // overflowing.
      await tester.pumpWidget(
        _wrap(
          createWidgetUnderTest(),
          size: const Size(320, 640),
          textScaler: const TextScaler.linear(1.6),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DevocionalesBottomBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
