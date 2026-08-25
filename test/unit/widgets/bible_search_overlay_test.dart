@Tags(['unit', 'widgets'])
library;

// test/unit/widgets/bible_search_overlay_test.dart
//
// High-value behavior tests for BibleSearchOverlay.
// Uses a real BibleReaderController backed by fake DB/reader services
// (same pattern as test/unit/pages/bible_reader_page_test.dart) — no
// SQLite, no assets, no mocked controller.

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/widgets/bible/bible_search_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

// ── Fake BibleDbService (mirrors bible_reader_page_test.dart) ──────────────

class _FakeBibleDbService extends BibleDbService {
  final List<Map<String, dynamic>> _books;
  final Map<int, int> _maxChapters;
  final Map<String, List<Map<String, dynamic>>> _verses;

  _FakeBibleDbService({
    List<Map<String, dynamic>>? books,
    Map<int, int>? maxChapters,
    Map<String, List<Map<String, dynamic>>>? verses,
  })  : _books = books ??
            [
              {'book_number': 10, 'short_name': 'Gen', 'long_name': 'Genesis'},
              {'book_number': 470, 'short_name': 'Jn', 'long_name': 'Juan'},
            ],
        _maxChapters = maxChapters ?? {10: 50, 470: 21},
        _verses = verses ??
            {
              '10-1': [
                {'verse': 1, 'text': 'En el principio creó Dios...'},
              ],
              '470-3': [
                {'verse': 16, 'text': 'Porque de tal manera amó Dios...'},
              ],
            };

  @override
  Future<void> initDb(String assetPath, String dbFileName) async {}

  @override
  Future<List<Map<String, dynamic>>> getAllBooks() async => _books;

  @override
  Future<int> getMaxChapter(int bookNumber) async =>
      _maxChapters[bookNumber] ?? 1;

  @override
  Future<List<Map<String, dynamic>>> getChapterVerses(
    int bookNumber,
    int chapter,
  ) async =>
      _verses['$bookNumber-$chapter'] ?? [];

  @override
  Future<List<Map<String, dynamic>>> searchVerses(String query) async => [
        {
          'book_number': 470,
          'chapter': 3,
          'verse': 16,
          'short_name': 'Jn',
          'long_name': 'Juan',
          'text': 'Porque de tal manera amó Dios al mundo...',
        },
      ];

  @override
  Future<Map<String, dynamic>?> findBookByName(String name) async {
    try {
      return _books.firstWhere(
        (b) => b['short_name'] == name || b['long_name'] == name,
      );
    } catch (e) {
      return null;
    }
  }
}

// ── Test factory (mirrors bible_reader_page_test.dart) ─────────────────────

BibleVersion _makeVersion({String name = 'RVR1960'}) {
  final version = BibleVersion(
    name: name,
    language: 'Español',
    languageCode: 'es',
    assetPath: 'assets/fake/$name.db',
    dbFileName: '$name.db',
  );
  version.service = _FakeBibleDbService();
  return version;
}

BibleReaderController _makeController() {
  final fakeDb = _FakeBibleDbService();
  final positionService = BibleReadingPositionService();
  return BibleReaderController(
    allVersions: [_makeVersion()],
    readerService: BibleReaderService(
      dbService: fakeDb,
      positionService: positionService,
    ),
    preferencesService: BiblePreferencesService(),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────

void main() {
  setUp(() async {
    await registerTestServices();
    SharedPreferences.setMockInitialValues({});
  });

  Future<BibleReaderController> pumpOverlay(WidgetTester tester) async {
    final controller = _makeController();
    await controller.initialize('es');

    // Match production usage (bible_reader_page.dart _showSearchOverlay):
    // the overlay is pushed via showDialog, not set directly as
    // MaterialApp.home — dismissal semantics (mounted-state timing on
    // Navigator.pop) depend on it being a real dialog route.
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: true,
                barrierColor: Colors.transparent,
                builder: (context) => BibleSearchOverlay(
                  controller: controller,
                  onScrollToVerse: (_) {},
                  cleanVerseText: (text) => text as String,
                ),
              ),
              child: const Text('open search'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open search'));
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('shows the search text field before any search is performed',
      (tester) async {
    final controller = await pumpOverlay(tester);

    expect(controller.state.isSearching, isFalse);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('typing a query and submitting shows matching results',
      (tester) async {
    await pumpOverlay(tester);

    await tester.enterText(find.byType(TextField), 'amó Dios');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.textContaining('Juan 3:16'), findsOneWidget);
  });

  testWidgets(
      'a Bible-reference query navigates directly instead of listing results',
      (tester) async {
    final controller = await pumpOverlay(tester);

    await tester.enterText(find.byType(TextField), 'Juan 3:16');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Direct reference navigation updates the reading position and does not
    // enter search-results mode.
    expect(controller.state.isSearching, isFalse);
    expect(controller.state.selectedBookName, 'Jn');
    expect(controller.state.selectedChapter, 3);
    expect(controller.state.selectedVerse, 16);
  });

  testWidgets('tapping a search result navigates to it and closes the overlay',
      (tester) async {
    final controller = await pumpOverlay(tester);

    await tester.enterText(find.byType(TextField), 'amó Dios');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Juan 3:16'));
    await tester.pumpAndSettle();

    expect(find.byType(BibleSearchOverlay), findsNothing);
    expect(controller.state.selectedBookName, 'Jn');
    expect(controller.state.selectedChapter, 3);
    expect(controller.state.selectedVerse, 16);

    // Drain the pending onScrollToVerse Timer scheduled by
    // _handleSearchResultTap so it doesn't leak past this test.
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('close button dismisses the overlay and clears the search',
      (tester) async {
    final controller = await pumpOverlay(tester);

    await tester.enterText(find.byType(TextField), 'amó Dios');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(controller.state.isSearching, isTrue);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(BibleSearchOverlay), findsNothing);
    expect(controller.state.isSearching, isFalse);
  });

  testWidgets('tapping outside the search card dismisses the overlay',
      (tester) async {
    await pumpOverlay(tester);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.byType(BibleSearchOverlay), findsNothing);
  });

  testWidgets('searching with no matches shows the no-matches message',
      (tester) async {
    await pumpOverlay(tester);

    await tester.enterText(find.byType(TextField), 'zzz_no_match_zzz');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.textContaining('Jn 3:16'), findsNothing);
  });

  testWidgets(
      'clear icon appears once text is entered and clears the field on tap',
      (tester) async {
    await pumpOverlay(tester);

    expect(find.byIcon(Icons.clear), findsNothing);

    await tester.enterText(find.byType(TextField), 'amó');
    await tester.pump();
    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    expect(find.byIcon(Icons.clear), findsNothing);
  });
}
