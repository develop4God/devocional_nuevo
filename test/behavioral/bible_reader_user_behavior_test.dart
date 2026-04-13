@Tags(['behavioral', 'bible'])
library;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/pages/bible_reader_page.dart';
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
      ServiceLocator()
          .registerSingleton<LocalizationService>(mockLocalizationService);

      when(() => mockLocalizationService.translate(any(), any())).thenAnswer(
          (invocation) => invocation.positionalArguments[0] as String);

      mockThemeBloc = MockThemeBloc();
      mockReaderService = MockBibleReaderService();
      mockPreferencesService = MockBiblePreferencesService();
      mockDbService = MockBibleDbService();

      // Setup BibleDbService mock
      when(() => mockDbService.initDb(any(), any()))
          .thenAnswer((_) async => {});

      final books = [
        {'book_number': 1, 'short_name': 'GN', 'long_name': 'Génesis'},
      ];
      when(() => mockDbService.getAllBooks()).thenAnswer((_) async => books);
      when(() => mockDbService.getMaxChapter(any()))
          .thenAnswer((_) async => 50);
      when(() => mockDbService.getChapterVerses(any(), any()))
          .thenAnswer((_) async => [
                {
                  'verse': 1,
                  'text': 'En el principio creó Dios los cielos y la tierra.'
                },
                {'verse': 2, 'text': 'Y la tierra estaba desordenada y vacía.'},
              ]);

      final mockVersion = BibleVersion(
        name: 'Reina Valera 1960 (RVR1960)',
        language: 'Español',
        languageCode: 'es',
        assetPath: 'assets/biblia/RVR1960_es.SQLite3',
        dbFileName: 'RVR1960_es.SQLite3',
        service: mockDbService,
      );
      mockVersions = [mockVersion];

      when(() => mockThemeBloc.state).thenReturn(ThemeLoaded.withThemeData(
        themeFamily: 'Deep Purple',
        brightness: Brightness.light,
      ));
      when(() => mockThemeBloc.stream).thenAnswer((_) => const Stream.empty());

      // Mock BibleReaderService calls
      when(() => mockReaderService.dbService).thenReturn(mockDbService);
      when(() => mockReaderService.getLastPosition())
          .thenAnswer((_) async => null);
      when(() => mockReaderService.saveReadingPosition(
            bookName: any(named: 'bookName'),
            bookNumber: any(named: 'bookNumber'),
            chapter: any(named: 'chapter'),
            verse: any(named: 'verse'),
            version: any(named: 'version'),
            languageCode: any(named: 'languageCode'),
          )).thenAnswer((_) async => {});

      // Mock BiblePreferencesService calls
      when(() => mockPreferencesService.getFontSize())
          .thenAnswer((_) async => 18.0);
      when(() => mockPreferencesService.getMarkedVerses())
          .thenAnswer((_) async => <String>{});
      when(() => mockPreferencesService.saveFontSize(any()))
          .thenAnswer((_) async => {});
    });

    Future<void> pumpBiblePage(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ThemeBloc>.value(
            value: mockThemeBloc,
            child: BibleReaderPage(
              versions: mockVersions,
              readerService: mockReaderService,
              preferencesService: mockPreferencesService,
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
      expect(find.textContaining('En el principio creó Dios'), findsOneWidget);

      // WHEN: User taps the font size adjustment button in AppBar
      final fontSettingsButton = find.byIcon(Icons.text_increase_outlined);
      expect(fontSettingsButton, findsOneWidget);
      await tester.tap(fontSettingsButton);
      await tester.pumpAndSettle();

      // THEN: Font size adjustment buttons should be visible
      expect(find.byType(FloatingFontControlButtons), findsOneWidget);

      // WHEN: User increases font size
      final increaseButton = find.text('A+');
      await tester.tap(increaseButton);
      await tester.pumpAndSettle();

      // THEN: Preferences service should be called to save new font size (18.0 + 2.0 = 20.0)
      verify(() => mockPreferencesService.saveFontSize(20.0)).called(1);
    });

    testWidgets('BibleReaderPage allows navigation between chapters',
        (WidgetTester tester) async {
      // GIVEN: BibleReaderPage is loaded
      await pumpBiblePage(tester);

      // Setup for next chapter
      when(() => mockReaderService.navigateToNextChapter(
            currentBookNumber: any(named: 'currentBookNumber'),
            currentChapter: any(named: 'currentChapter'),
            books: any(named: 'books'),
          )).thenAnswer((_) async => {
            'bookNumber': 1,
            'chapter': 2,
            'scrollToTop': true,
          });

      when(() => mockDbService.getChapterVerses(1, 2)).thenAnswer((_) async => [
            {
              'verse': 1,
              'text': 'Fueron, pues, acabados los cielos y la tierra.'
            },
          ]);

      // WHEN: User taps next chapter button
      final nextButton = find.byIcon(Icons.arrow_forward_ios);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // THEN: It should display chapter 2
      expect(find.textContaining('Génesis 2'), findsAtLeast(1));
      expect(find.textContaining('Fueron, pues, acabados'), findsOneWidget);

      verify(() => mockReaderService.navigateToNextChapter(
            currentBookNumber: 1,
            currentChapter: 1,
            books: any(named: 'books'),
          )).called(1);
    });
  });
}
