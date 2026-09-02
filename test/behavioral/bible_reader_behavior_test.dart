// test/behavioral/bible_reader_behavior_test.dart

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/bible_note_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_note_event.dart';
import 'package:devocional_nuevo/blocs/bible_note_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/pages/bible_reader_page.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/test_helpers.dart';
import '../helpers/widget_pump_helper.dart';

class MockLocalizationService extends Mock implements LocalizationService {}

class MockFlutterTts extends Mock implements FlutterTts {}

class MockVoiceSettingsService extends Mock implements VoiceSettingsService {}

class MockBibleNoteBloc extends Mock implements BibleNoteBloc {
  @override
  Stream<BibleNoteState> get stream => Stream.value(BibleNoteLoaded(notes: []));
  @override
  BibleNoteState get state => BibleNoteLoaded(notes: []);
  @override
  void add(BibleNoteEvent event) {}
  @override
  Future<void> close() async {}
}

class FakeBibleDbService extends Fake implements BibleDbService {
  @override
  Future<void> initDb(String assetPath, String dbFileName) async {}

  @override
  Future<List<Map<String, dynamic>>> getAllBooks() async => [
        {'book_number': 470, 'short_name': 'Jn', 'long_name': 'Juan'},
        {'book_number': 10, 'short_name': 'Gn', 'long_name': 'Génesis'},
      ];
  @override
  Future<int> getMaxChapter(int bookNumber) async => 21;
  @override
  Future<List<Map<String, dynamic>>> getChapterVerses(
          int bookNumber, int chapter) async =>
      [
        {'verse': 1, 'text': 'Verse 1 text'},
        {'verse': 2, 'text': 'Verse 2 text'},
      ];
  @override
  Future<Map<String, dynamic>?> findBookByName(String name) async =>
      {'book_number': 470, 'short_name': 'Jn', 'long_name': 'Juan'};

  @override
  Future<List<Map<String, dynamic>>> getSectionTitles(
          {required int bookNumber, required int chapter}) async =>
      [];

  @override
  Future<List<Map<String, dynamic>>> searchVerses(String query) async => [];

  @override
  Future<Map<String, dynamic>?> getVerse(
          {required int bookNumber,
          required int chapter,
          required int verse}) async =>
      {'verse': verse, 'text': 'Verse $verse text'};
}

void main() {
  late MockLocalizationService mockLocalization;
  late MockFlutterTts mockTts;
  late MockVoiceSettingsService mockVoiceService;
  late ThemeBloc themeBloc;
  late BibleVersion testVersion;
  late BibleVersion otherVersion;
  late BibleReaderService readerService;

  setUpAll(() {
    registerFallbackValue(const Locale('es'));
    registerFallbackValue(FlutterTts());
  });

  setUp(() async {
    await registerTestServicesWithFakes();
    mockLocalization = MockLocalizationService();
    mockTts = MockFlutterTts();
    mockVoiceService = MockVoiceSettingsService();
    themeBloc = ThemeBloc()..add(InitializeThemeDefaults());

    when(() => mockLocalization.translate(any()))
        .thenAnswer((i) => i.positionalArguments[0]);
    when(() => mockLocalization.translate(any(), any()))
        .thenAnswer((i) => i.positionalArguments[0]);

    // TTS mocks
    when(() => mockTts.setStartHandler(any())).thenAnswer((_) async {});
    when(() => mockTts.setCompletionHandler(any())).thenAnswer((_) async {});
    when(() => mockTts.setErrorHandler(any())).thenAnswer((_) async {});
    when(() => mockTts.setProgressHandler(any())).thenAnswer((_) async {});
    when(() => mockTts.setPauseHandler(any())).thenAnswer((_) async {});
    when(() => mockTts.setCancelHandler(any())).thenAnswer((_) async {});
    when(() => mockTts.setLanguage(any())).thenAnswer((_) async => 1);
    when(() => mockTts.setSpeechRate(any())).thenAnswer((_) async => 1);
    when(() => mockTts.setVolume(any())).thenAnswer((_) async => 1);
    when(() => mockTts.setPitch(any())).thenAnswer((_) async => 1);
    when(() => mockTts.stop()).thenAnswer((_) async => 1);
    when(() => mockTts.getVoices).thenAnswer((_) async => []);
    when(() => mockTts.speak(any())).thenAnswer((_) async => 1);
    when(() => mockTts.awaitSpeakCompletion(any())).thenAnswer((_) async => 1);

    // Voice Service mocks
    when(() => mockVoiceService.getSavedSpeechRate())
        .thenAnswer((_) async => 0.5);
    when(() => mockVoiceService.hasUserSavedVoice(any()))
        .thenAnswer((_) async => true);
    when(() => mockVoiceService.loadSavedVoice(any()))
        .thenAnswer((_) async => 'Test Voice');
    when(() => mockVoiceService.applyVoiceToInstance(any(), any()))
        .thenAnswer((_) async {});

    final locator = ServiceLocator();
    locator.unregister<LocalizationService>();
    locator.registerSingleton<LocalizationService>(mockLocalization);
    locator.unregister<VoiceSettingsService>();
    locator.registerSingleton<VoiceSettingsService>(mockVoiceService);

    final fakeDb = FakeBibleDbService();
    readerService = BibleReaderService(
      dbService: fakeDb,
      positionService: BibleReadingPositionService(),
    );

    testVersion = BibleVersion(
      name: 'RVR1960',
      language: 'Español',
      languageCode: 'es',
      assetPath: 'assets/fake.db',
      dbFileName: 'fake.db',
    );
    testVersion.service = fakeDb;

    otherVersion = BibleVersion(
      name: 'KJV',
      language: 'English',
      languageCode: 'en',
      assetPath: 'assets/kjv.db',
      dbFileName: 'kjv.db',
    );
    otherVersion.service = fakeDb;
  });

  Widget createWidgetUnderTest({
    ({String bookName, int chapter, int verse})? initialReference,
    List<BibleVersion>? versions,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>.value(value: themeBloc),
        BlocProvider<BibleNoteBloc>(create: (_) => MockBibleNoteBloc()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: DefaultAssetBundle(
          bundle: TestAssetBundle(),
          child: BibleReaderPage(
            versions: versions ?? [testVersion, otherVersion],
            readerService: readerService,
            flutterTts: mockTts,
            initialReference: initialReference,
          ),
        ),
      ),
    );
  }

  Future<void> waitForReader(WidgetTester tester) async {
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      final richTextFinder = find.byWidgetPredicate((w) =>
          w is RichText && w.text.toPlainText().contains('Verse 1 text'));
      if (tester.any(richTextFinder)) {
        return;
      }
    }
  }

  testWidgets('BibleReaderPage navigates to initialReference on load',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      initialReference: (bookName: 'Jn', chapter: 3, verse: 16),
    ));

    await waitForReader(tester);

    expect(find.textContaining('Juan'), findsWidgets);
    expect(find.textContaining('3'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('BibleReaderPage toggles font controls overlay', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await waitForReader(tester);

    final appBar = find.byType(AppBar);
    final actions =
        find.descendant(of: appBar, matching: find.byType(IconButton));

    await tester.tap(actions.at(1));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('A+'), findsWidgets);
    expect(find.text('A-'), findsWidgets);

    await tester.tap(find.byIcon(Icons.close_outlined));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('A+'), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('BibleReaderPage shows book selector dialog', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await waitForReader(tester);

    final juanText = find.textContaining('Juan');
    expect(juanText, findsWidgets);

    await tester.tap(juanText.first);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('bible.search_book'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('BibleReaderPage shows search overlay', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await waitForReader(tester);

    final appBar = find.byType(AppBar);
    final actions =
        find.descendant(of: appBar, matching: find.byType(IconButton));

    await tester.tap(actions.at(0)); // Search
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(TextField), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets(
      'BibleReaderPage workflow: TTS play from bottom bar triggers miniplayer',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await waitForReader(tester);

    final playBtn = find.byIcon(Icons.play_arrow);
    expect(playBtn, findsWidgets);

    await tester.tap(playBtn.last);

    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.any(find.byIcon(Icons.pause))) break;
    }

    expect(find.byIcon(Icons.pause), findsWidgets);

    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('BibleReaderPage workflow: Next/Previous chapter',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await waitForReader(tester);

    expect(find.textContaining('1'), findsWidgets); // Chapter 1

    final nextBtn = find.byTooltip('bible.next_chapter');
    await tester.tap(nextBtn);
    await tester.pump(const Duration(milliseconds: 500));
    await waitForReader(tester);

    expect(find.textContaining('2'), findsWidgets); // Chapter 2

    final prevBtn = find.byTooltip('bible.previous_chapter');
    await tester.tap(prevBtn);
    await tester.pump(const Duration(milliseconds: 500));
    await waitForReader(tester);

    expect(find.textContaining('1'), findsWidgets); // Back to 1
  });
}
