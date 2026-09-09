@Tags(['unit', 'widgets'])
library;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/widgets/bible/bible_reader_selector_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

BibleVersion _version({String languageCode = 'en'}) {
  return BibleVersion(
    name: 'Test Version',
    language: 'Test',
    languageCode: languageCode,
    assetPath: '',
    dbFileName: 'test.SQLite3',
    isDownloaded: true,
  );
}

void main() {
  setUp(() async {
    await registerTestServices();
  });

  Future<void> pumpBar(
    WidgetTester tester, {
    required BibleReaderState state,
    VoidCallback? onBookTap,
    VoidCallback? onChapterTap,
    VoidCallback? onVerseTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BibleReaderSelectorBar(
            state: state,
            chapterPrefix: (lang) => 'C.',
            versePrefix: (lang) => 'V.',
            onBookTap: onBookTap ?? () {},
            onChapterTap: onChapterTap ?? () {},
            onVerseTap: onVerseTap ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows placeholder text when no book is selected', (
    tester,
  ) async {
    await pumpBar(tester, state: const BibleReaderState());

    expect(find.text('Seleccionar libro'), findsOneWidget);
  });

  testWidgets('resolves and shows the selected book name', (tester) async {
    final version = _version();
    await pumpBar(
      tester,
      state: BibleReaderState(
        selectedVersion: version,
        books: [
          {'name': 'Genesis', 'book_number': 1},
        ],
        selectedBookName: 'Genesis',
        selectedChapter: 3,
        selectedVerse: 5,
      ),
    );

    expect(find.text('Genesis'), findsOneWidget);
    expect(find.text('C. 3'), findsOneWidget);
    expect(find.text('V. 5'), findsOneWidget);
  });

  testWidgets('defaults chapter/verse labels to 1 when unset', (
    tester,
  ) async {
    await pumpBar(tester, state: const BibleReaderState());

    expect(find.text('C. 1'), findsOneWidget);
    expect(find.text('V. 1'), findsOneWidget);
  });

  testWidgets('invokes onBookTap when the book selector is tapped', (
    tester,
  ) async {
    var tapped = false;
    await pumpBar(
      tester,
      state: const BibleReaderState(),
      onBookTap: () => tapped = true,
    );

    await tester.tap(find.text('Seleccionar libro'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('invokes onChapterTap when the chapter button is tapped', (
    tester,
  ) async {
    var tapped = false;
    await pumpBar(
      tester,
      state: const BibleReaderState(),
      onChapterTap: () => tapped = true,
    );

    await tester.tap(find.text('C. 1'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('invokes onVerseTap when the verse button is tapped', (
    tester,
  ) async {
    var tapped = false;
    await pumpBar(
      tester,
      state: const BibleReaderState(),
      onVerseTap: () => tapped = true,
    );

    await tester.tap(find.text('V. 1'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
