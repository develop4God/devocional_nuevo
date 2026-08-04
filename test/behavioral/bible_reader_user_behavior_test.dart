@Tags(['behavioral', 'pages', 'notes'])
library;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/bible_note_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_note_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/pages/bible_reader_page.dart';
import 'package:devocional_nuevo/repositories/i_bible_notes_repository.dart';
import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:devocional_nuevo/widgets/bible/bible_note_modal.dart';
import 'package:devocional_nuevo/widgets/bible/bible_note_viewer.dart';
import 'package:devocional_nuevo/widgets/bible/bible_verse_note_indicator.dart';
import 'package:devocional_nuevo/widgets/floating_font_control_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import '../helpers/test_helpers.dart';

class MockThemeBloc extends Mock implements ThemeBloc {}

class MockBibleReaderService extends Mock implements BibleReaderService {}

class MockBiblePreferencesService extends Mock
    implements BiblePreferencesService {}

class MockBibleDbService extends Mock implements BibleDbService {}

class MockLocalizationService extends Mock implements LocalizationService {}

class FakeBibleNotesRepository implements IBibleNotesRepository {
  final List<BibleNote> notes;

  FakeBibleNotesRepository([this.notes = const []]);

  @override
  Future<void> deleteNote(String noteId) async {}

  @override
  Future<List<BibleNote>> loadNotes() async => notes;

  @override
  Future<void> saveNote(BibleNote note) async {}
}

void main() {
  group('BibleReaderPage Behavioral Tests', () {
    late MockThemeBloc mockThemeBloc;
    late MockBibleReaderService mockReaderService;
    late MockBiblePreferencesService mockPreferencesService;
    late MockBibleDbService mockDbService;
    late MockLocalizationService mockLocalizationService;
    late List<BibleVersion> mockVersions;

    setUpAll(() {
      registerFallbackValue(const BibleReaderState());
    });

    setUp(() async {
      await registerTestServicesWithFakes();

      // Override LocalizationService with mock
      mockLocalizationService = MockLocalizationService();
      if (ServiceLocator().isRegistered<LocalizationService>()) {
        ServiceLocator().unregister<LocalizationService>();
      }
      ServiceLocator().registerSingleton<LocalizationService>(
        mockLocalizationService,
      );

      when(
        () => mockLocalizationService.translate(any(), any()),
      ).thenAnswer((invocation) => invocation.positionalArguments[0] as String);

      mockThemeBloc = MockThemeBloc();
      mockReaderService = MockBibleReaderService();
      mockPreferencesService = MockBiblePreferencesService();
      mockDbService = MockBibleDbService();

      // Setup BibleDbService mock
      when(
        () => mockDbService.initDb(any(), any()),
      ).thenAnswer((_) async => {});

      // Explicit <String, dynamic> is required — Dart infers map literals with
      // mixed int/String values as Map<String, Object>.  getAllBooks() returns
      // List<Map<String, dynamic>> in production (SQLite), so the mock must
      // match to avoid a runtime _TypeError in firstWhere's orElse check.
      final books = [
        <String, dynamic>{
          'book_number': 1,
          'short_name': 'GN',
          'long_name': 'Génesis',
        },
      ];
      when(() => mockDbService.getAllBooks()).thenAnswer((_) async => books);
      when(
        () => mockDbService.getMaxChapter(any()),
      ).thenAnswer((_) async => 50);
      when(() => mockDbService.getChapterVerses(any(), any())).thenAnswer(
        (_) async => [
          <String, dynamic>{
            'verse': 1,
            'text': 'En el principio creó Dios los cielos y la tierra.',
          },
          <String, dynamic>{
            'verse': 2,
            'text': 'Y la tierra estaba desordenada y vacía.',
          },
        ],
      );
      when(
        () => mockDbService.getSectionTitles(
          bookNumber: any(named: 'bookNumber'),
          chapter: any(named: 'chapter'),
        ),
      ).thenAnswer((_) async => []);

      final mockVersion = BibleVersion(
        name: 'Reina Valera 1960 (RVR1960)',
        language: 'Español',
        languageCode: 'es',
        assetPath: 'assets/biblia/RVR1960_es.SQLite3',
        dbFileName: 'RVR1960_es.SQLite3',
        service: mockDbService,
      );
      mockVersions = [mockVersion];

      when(() => mockThemeBloc.state).thenReturn(
        ThemeLoaded.withThemeData(
          themeFamily: 'Deep Purple',
          brightness: Brightness.light,
        ),
      );
      when(() => mockThemeBloc.stream).thenAnswer((_) => const Stream.empty());

      // Mock BibleReaderService calls
      when(() => mockReaderService.dbService).thenReturn(mockDbService);
      when(
        () => mockReaderService.getLastPosition(),
      ).thenAnswer((_) async => null);
      when(
        () => mockReaderService.saveReadingPosition(
          bookName: any(named: 'bookName'),
          bookNumber: any(named: 'bookNumber'),
          chapter: any(named: 'chapter'),
          verse: any(named: 'verse'),
          version: any(named: 'version'),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => {});

      // Mock BiblePreferencesService calls
      when(
        () => mockPreferencesService.getFontSize(),
      ).thenAnswer((_) async => 18.0);
      when(
        () => mockPreferencesService.getMarkedVerses(),
      ).thenAnswer((_) async => <String>{});
      when(
        () => mockPreferencesService.saveFontSize(any()),
      ).thenAnswer((_) async => {});
    });

    Future<void> pumpBiblePage(
      WidgetTester tester, {
      ({String bookName, int chapter, int verse})? initialReference,
      List<BibleNote> notes = const [],
    }) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<ThemeBloc>.value(value: mockThemeBloc),
            BlocProvider<BibleNoteBloc>(
              create: (_) => BibleNoteBloc(
                bibleNotesRepository: FakeBibleNotesRepository(notes),
              )..add(LoadBibleNotes()),
            ),
          ],
          // Providers must wrap MaterialApp (not sit inside `home:`), matching
          // main.dart's tree — otherwise a modal route opened from within
          // another modal route (viewer -> editor) lands as a sibling route
          // without these ancestors, throwing ProviderNotFoundException.
          child: MaterialApp(
            home: BibleReaderPage(
              versions: mockVersions,
              readerService: mockReaderService,
              preferencesService: mockPreferencesService,
              initialReference: initialReference,
            ),
          ),
        ),
      );
      // First pump to let initState run
      await tester.pump();
      // Second pump to let BibleReaderController.initialize finish (it's async)
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'BibleReaderPage displays verses and allows font size adjustment',
      (WidgetTester tester) async {
        // GIVEN: BibleReaderPage is loaded
        await pumpBiblePage(tester);

        // THEN: It should display the book and chapter
        expect(find.textContaining('Génesis 1'), findsAtLeast(1));

        // THEN: It should display the verse text
        // findRichText: true is required — verse content is rendered via
        // RichText (TextSpan), which is NOT searched by find.textContaining()
        // when the default findRichText: false is used.
        expect(
          find.textContaining('En el principio creó Dios', findRichText: true),
          findsOneWidget,
        );

        // WHEN: User taps the font size adjustment button in AppBar
        final fontSettingsButton = find.byIcon(Icons.text_increase_outlined);
        expect(fontSettingsButton, findsOneWidget);
        await tester.tap(fontSettingsButton);
        // pump() instead of pumpAndSettle(): FloatingFontControlButtons contains
        // a Lottie animation with repeat:true that keeps the widget perpetually
        // dirty, so pumpAndSettle() would time out.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // THEN: Font size adjustment buttons should be visible
        expect(find.byType(FloatingFontControlButtons), findsOneWidget);

        // WHEN: User increases font size
        final increaseButton = find.text('A+');
        await tester.tap(increaseButton);
        // Same reason as above — no pumpAndSettle(), use pump() instead
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // THEN: Preferences service should be called to save new font size (18.0 + 2.0 = 20.0)
        verify(() => mockPreferencesService.saveFontSize(20.0)).called(1);
      },
    );

    testWidgets('BibleReaderPage allows navigation between chapters', (
      WidgetTester tester,
    ) async {
      // GIVEN: BibleReaderPage is loaded
      await pumpBiblePage(tester);

      // Setup for next chapter
      when(
        () => mockReaderService.navigateToNextChapter(
          currentBookNumber: any(named: 'currentBookNumber'),
          currentChapter: any(named: 'currentChapter'),
          books: any(named: 'books'),
        ),
      ).thenAnswer(
        (_) async => {'bookNumber': 1, 'chapter': 2, 'scrollToTop': true},
      );

      when(() => mockDbService.getChapterVerses(1, 2)).thenAnswer(
        (_) async => [
          <String, dynamic>{
            'verse': 1,
            'text': 'Fueron, pues, acabados los cielos y la tierra.',
          },
        ],
      );

      // WHEN: User taps next chapter button
      final nextButton = find.byIcon(Icons.arrow_forward_ios);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // THEN: It should display chapter 2
      expect(find.textContaining('Génesis 2'), findsAtLeast(1));
      // findRichText: true — verse content is in RichText widgets
      expect(
        find.textContaining('Fueron, pues, acabados', findRichText: true),
        findsOneWidget,
      );

      verify(
        () => mockReaderService.navigateToNextChapter(
          currentBookNumber: 1,
          currentChapter: 1,
          books: any(named: 'books'),
        ),
      ).called(1);
    });

    testWidgets(
      'BibleReaderPage jumps to the initialReference verse after loading',
      (WidgetTester tester) async {
        // GIVEN: BibleReaderPage is loaded with an initialReference
        await pumpBiblePage(
          tester,
          initialReference: (bookName: 'GN', chapter: 1, verse: 2),
        );

        // THEN: The verse selector button reflects the referenced verse
        expect(find.text('V. 2'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping the verse note indicator opens the read-only viewer, '
      'and Edit opens the note editor',
      (WidgetTester tester) async {
        // GIVEN: verse 1 already has a saved note
        final note = BibleNote(
          bookName: 'GN',
          chapter: 1,
          startVerse: 1,
          endVerse: 1,
          text: 'My reflection on creation',
          lastModifiedDate: DateTime(2026, 1, 1),
        );
        await pumpBiblePage(tester, notes: [note]);

        // WHEN: user taps the note indicator badge next to verse 1
        await tester.tap(find.byType(BibleVerseNoteIndicator));
        await tester.pumpAndSettle();

        // THEN: the read-only viewer opens with the note text, not the editor
        expect(find.byType(BibleNoteViewer), findsOneWidget);
        expect(find.byType(BibleNoteModal), findsNothing);
        expect(
          find.descendant(
            of: find.byType(BibleNoteViewer),
            matching: find.text('My reflection on creation'),
          ),
          findsOneWidget,
        );

        // WHEN: user taps Edit inside the viewer
        await tester.tap(find.text('notes.edit'));
        await tester.pumpAndSettle();

        // THEN: the editor opens pre-filled with the existing note
        expect(find.byType(BibleNoteModal), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(BibleNoteModal),
            matching: find.text('My reflection on creation'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping the note icon in the verse selection action sheet opens the '
      'read-only viewer when a note already exists',
      (WidgetTester tester) async {
        // GIVEN: verse 1 already has a saved note
        final note = BibleNote(
          bookName: 'GN',
          chapter: 1,
          startVerse: 1,
          endVerse: 1,
          text: 'My reflection on creation',
          lastModifiedDate: DateTime(2026, 1, 1),
        );
        await pumpBiblePage(tester, notes: [note]);

        // WHEN: user taps verse 1 to select it, opening the action sheet
        await tester.tap(
          find.textContaining(
            'En el principio creó Dios',
            findRichText: true,
          ),
        );
        await tester.pumpAndSettle();

        // THEN: the action sheet shows the filled note icon (hasNote: true)
        expect(find.byIcon(Icons.sticky_note_2_rounded), findsOneWidget);

        // WHEN: user taps the note icon
        await tester.tap(find.byIcon(Icons.sticky_note_2_rounded));
        await tester.pumpAndSettle();

        // THEN: the read-only viewer opens instead of the editor
        expect(find.byType(BibleNoteViewer), findsOneWidget);
        expect(find.byType(BibleNoteModal), findsNothing);
        expect(
          find.descendant(
            of: find.byType(BibleNoteViewer),
            matching: find.text('My reflection on creation'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
