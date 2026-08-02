@Tags(['unit', 'widgets', 'notes'])
library;

import 'package:devocional_nuevo/widgets/bible/bible_verse_note_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows the verse number', (tester) async {
    await tester.pumpWidget(
      wrap(
        BibleVerseNoteIndicator(
          verseNumber: 16,
          color: Colors.blue,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('16'), findsOneWidget);
  });

  testWidgets('invokes onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        BibleVerseNoteIndicator(
          verseNumber: 1,
          color: Colors.blue,
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(BibleVerseNoteIndicator));
    expect(tapped, isTrue);
  });

  testWidgets('renders the verse text in the given color', (tester) async {
    await tester.pumpWidget(
      wrap(
        BibleVerseNoteIndicator(
          verseNumber: 3,
          color: Colors.red,
          onTap: () {},
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('3'));
    expect(text.style?.color, Colors.red);
  });
}
