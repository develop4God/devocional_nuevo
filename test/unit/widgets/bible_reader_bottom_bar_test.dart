@Tags(['unit', 'widgets'])
library;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:devocional_nuevo/widgets/bible/bible_reader_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TtsAudioController ttsAudioController;

  setUp(() async {
    await registerTestServices();
    if (!ServiceLocator().isRegistered<VoiceSettingsService>()) {
      ServiceLocator().registerLazySingleton<VoiceSettingsService>(
        () => VoiceSettingsService(),
      );
    }
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

    ttsAudioController = TtsAudioController(
      flutterTts: FlutterTts(),
      voiceSettingsService: VoiceSettingsService(),
    );
  });

  tearDown(() {
    ttsAudioController.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  Future<void> pumpBar(
    WidgetTester tester, {
    required BibleReaderState state,
    VoidCallback? onPreviousChapter,
    VoidCallback? onNextChapter,
    VoidCallback? onBookTap,
    void Function(BibleReaderState state)? onTtsPlayPause,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BibleReaderBottomBar(
            state: state,
            ttsAudioController: ttsAudioController,
            onPreviousChapter: onPreviousChapter ?? () {},
            onNextChapter: onNextChapter ?? () {},
            onBookTap: onBookTap ?? () {},
            onTtsPlayPause: onTtsPlayPause ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows empty book label when no book is selected', (
    tester,
  ) async {
    await pumpBar(tester, state: const BibleReaderState());

    expect(find.text(''), findsWidgets);
  });

  testWidgets('shows resolved book name and chapter on the button', (
    tester,
  ) async {
    await pumpBar(
      tester,
      state: BibleReaderState(
        books: [
          {'name': 'Genesis', 'book_number': 1},
        ],
        selectedBookName: 'Genesis',
        selectedChapter: 3,
      ),
    );

    expect(find.text('Genesis 3'), findsOneWidget);
  });

  testWidgets('invokes onPreviousChapter when the back arrow is tapped', (
    tester,
  ) async {
    var tapped = false;
    await pumpBar(
      tester,
      state: const BibleReaderState(),
      onPreviousChapter: () => tapped = true,
    );

    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('invokes onNextChapter when the forward arrow is tapped', (
    tester,
  ) async {
    var tapped = false;
    await pumpBar(
      tester,
      state: const BibleReaderState(),
      onNextChapter: () => tapped = true,
    );

    await tester.tap(find.byIcon(Icons.arrow_forward_ios));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('invokes onBookTap when the chapter button is tapped', (
    tester,
  ) async {
    var tapped = false;
    await pumpBar(
      tester,
      state: BibleReaderState(
        books: [
          {'name': 'Genesis', 'book_number': 1},
        ],
        selectedBookName: 'Genesis',
        selectedChapter: 1,
      ),
      onBookTap: () => tapped = true,
    );

    await tester.tap(find.text('Genesis 1'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('TTS button shows play icon in idle state', (tester) async {
    await pumpBar(
      tester,
      state: BibleReaderState(
        verses: const [
          {'verse': 1, 'text': 'In the beginning'},
        ],
      ),
    );

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
  });

  testWidgets('TTS button is disabled (no-op) when there are no verses', (
    tester,
  ) async {
    var called = false;
    await pumpBar(
      tester,
      state: const BibleReaderState(),
      onTtsPlayPause: (_) => called = true,
    );

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();

    expect(called, isFalse);
  });

  testWidgets('invokes onTtsPlayPause with current state when verses exist', (
    tester,
  ) async {
    BibleReaderState? received;
    final state = BibleReaderState(
      verses: const [
        {'verse': 1, 'text': 'In the beginning'},
      ],
    );
    await pumpBar(
      tester,
      state: state,
      onTtsPlayPause: (s) => received = s,
    );

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();

    expect(received, same(state));
  });

  testWidgets('TTS button shows pause icon while playing', (tester) async {
    await pumpBar(
      tester,
      state: BibleReaderState(
        verses: const [
          {'verse': 1, 'text': 'In the beginning'},
        ],
      ),
    );

    ttsAudioController.state.value = TtsPlayerState.playing;
    await tester.pump();

    expect(find.byIcon(Icons.pause), findsOneWidget);
  });

  testWidgets('TTS button shows a progress indicator while loading', (
    tester,
  ) async {
    await pumpBar(
      tester,
      state: BibleReaderState(
        verses: const [
          {'verse': 1, 'text': 'In the beginning'},
        ],
      ),
    );

    ttsAudioController.state.value = TtsPlayerState.loading;
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
