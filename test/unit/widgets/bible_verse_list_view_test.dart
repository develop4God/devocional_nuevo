@Tags(['unit', 'widgets'])
library;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/bible_note_state.dart';
import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:devocional_nuevo/widgets/bible/bible_verse_list_view.dart';
import 'package:devocional_nuevo/widgets/bible/bible_verse_note_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../helpers/test_helpers.dart';

BibleVersion _version({String? disclaimer}) {
  return BibleVersion(
    name: 'Test Version',
    language: 'Test',
    languageCode: 'en',
    assetPath: '',
    dbFileName: 'test.SQLite3',
    isDownloaded: true,
    disclaimer: disclaimer,
  );
}

void main() {
  setUp(() async {
    await registerTestServices();
  });

  Future<void> pumpList(
    WidgetTester tester, {
    required BibleReaderState state,
    BibleNoteState? bibleNoteState,
    int? currentSpokenVerseIndex,
    void Function(int verseNumber)? onVerseTap,
    void Function(String key)? onVerseLongPress,
    void Function(String bookName, int chapter, int verseNumber)? onNoteTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BibleVerseListView(
            state: state,
            bibleNoteState: bibleNoteState ?? BibleNoteInitial(),
            itemScrollController: ItemScrollController(),
            itemPositionsListener: ItemPositionsListener.create(),
            currentSpokenVerseIndex: currentSpokenVerseIndex,
            cleanVerseText: (text) => text?.toString() ?? '',
            onVerseTap: onVerseTap ?? (_) {},
            onVerseLongPress: onVerseLongPress ?? (_) {},
            onNoteTap: onNoteTap ?? (_, __, ___) {},
          ),
        ),
      ),
    );
    // Use pump() rather than pumpAndSettle() — the loading state renders a
    // Lottie animation whose internal ticker never settles.
    await tester.pump();
  }

  testWidgets('shows a loading placeholder when there are no verses', (
    tester,
  ) async {
    await pumpList(
      tester,
      state: BibleReaderState(selectedVersion: _version()),
    );

    expect(find.text('bible.loading_version'), findsOneWidget);
    expect(find.byType(ScrollablePositionedList), findsNothing);
  });

  testWidgets('renders the chapter title, verses, and copyright disclaimer', (
    tester,
  ) async {
    await pumpList(
      tester,
      state: BibleReaderState(
        selectedVersion: _version(disclaimer: 'Test disclaimer'),
        books: [
          {'name': 'Genesis', 'book_number': 1},
        ],
        selectedBookName: 'Genesis',
        selectedChapter: 1,
        verses: const [
          {'verse': 1, 'text': 'In the beginning'},
          {'verse': 2, 'text': 'And the earth was'},
        ],
      ),
    );

    expect(find.text('Genesis 1'), findsOneWidget);
    expect(
      find.textContaining('In the beginning', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('And the earth was', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Test disclaimer'), findsOneWidget);
  });

  testWidgets('invokes onVerseTap when a verse is tapped', (tester) async {
    int? tappedVerse;
    await pumpList(
      tester,
      state: BibleReaderState(
        selectedVersion: _version(),
        selectedBookName: 'Genesis',
        selectedChapter: 1,
        verses: const [
          {'verse': 1, 'text': 'In the beginning'},
        ],
      ),
      onVerseTap: (v) => tappedVerse = v,
    );

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(tappedVerse, 1);
  });

  testWidgets('invokes onVerseLongPress with the verse key on long-press', (
    tester,
  ) async {
    String? longPressedKey;
    await pumpList(
      tester,
      state: BibleReaderState(
        selectedVersion: _version(),
        selectedBookName: 'Genesis',
        selectedChapter: 1,
        verses: const [
          {'verse': 1, 'text': 'In the beginning'},
        ],
      ),
      onVerseLongPress: (key) => longPressedKey = key,
    );

    await tester.longPress(find.byType(GestureDetector));
    await tester.pump();

    expect(longPressedKey, 'Genesis|1|1');
  });

  testWidgets(
    'shows a note indicator and invokes onNoteTap when a note exists',
    (tester) async {
      String? tappedBook;
      int? tappedChapter;
      int? tappedVerse;

      final noteState = BibleNoteLoaded(
        notes: [
          BibleNote(
            bookName: 'Genesis',
            chapter: 1,
            startVerse: 1,
            endVerse: 1,
            text: 'My note',
            lastModifiedDate: DateTime(2024, 1, 1),
          ),
        ],
      );

      await pumpList(
        tester,
        state: BibleReaderState(
          selectedVersion: _version(),
          selectedBookName: 'Genesis',
          selectedChapter: 1,
          verses: const [
            {'verse': 1, 'text': 'In the beginning'},
          ],
        ),
        bibleNoteState: noteState,
        onNoteTap: (book, chapter, verse) {
          tappedBook = book;
          tappedChapter = chapter;
          tappedVerse = verse;
        },
      );

      // The verse-number prefix is replaced by the note indicator widget
      // when a note covers that verse.
      expect(
        find.textContaining('1 In the beginning', findRichText: true),
        findsNothing,
      );
      expect(find.byType(BibleVerseNoteIndicator), findsOneWidget);

      await tester.tap(find.byType(BibleVerseNoteIndicator));
      await tester.pump();

      expect(tappedBook, 'Genesis');
      expect(tappedChapter, 1);
      expect(tappedVerse, 1);
    },
  );

  testWidgets('shows the verse-number prefix when no note covers the verse', (
    tester,
  ) async {
    await pumpList(
      tester,
      state: BibleReaderState(
        selectedVersion: _version(),
        selectedBookName: 'Genesis',
        selectedChapter: 1,
        verses: const [
          {'verse': 1, 'text': 'In the beginning'},
        ],
      ),
      bibleNoteState: BibleNoteLoaded(notes: const []),
    );

    expect(
      find.textContaining('1 In the beginning', findRichText: true),
      findsOneWidget,
    );
    expect(find.byType(BibleVerseNoteIndicator), findsNothing);
  });

  testWidgets('renders section titles above the verse they belong to', (
    tester,
  ) async {
    await pumpList(
      tester,
      state: BibleReaderState(
        selectedVersion: _version(),
        selectedBookName: 'Genesis',
        selectedChapter: 1,
        verses: const [
          {'verse': 1, 'text': 'In the beginning'},
        ],
        sectionTitles: const [
          {'verse': 1, 'title': 'The Creation'},
        ],
      ),
    );

    expect(find.text('The Creation'), findsOneWidget);
  });
}
