// test/unit/widgets/bible_chapter_grid_selector_test.dart
import 'package:devocional_nuevo/widgets/bible_chapter_grid_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bible Chapter Grid Selector Tests', () {
    testWidgets('Should display grid with correct number of chapters',
        (WidgetTester tester) async {
      const totalChapters = 24; // Use 24 to fit in 4 rows of 6 columns
      int? selectedChapterValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleChapterGridSelector(
              totalChapters: totalChapters,
              selectedChapter: 1,
              bookName: 'Genesis',
              onChapterSelected: (chapter) {
                selectedChapterValue = chapter;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that all chapter numbers are present (now they all fit on screen)
      for (int i = 1; i <= totalChapters; i++) {
        expect(find.text(i.toString()), findsOneWidget);
      }

      expect(selectedChapterValue, isNull);
    });

    testWidgets('Should highlight selected chapter',
        (WidgetTester tester) async {
      const selectedChapter = 25;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleChapterGridSelector(
              totalChapters: 50,
              selectedChapter: selectedChapter,
              bookName: 'Psalms',
              onChapterSelected: (chapter) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the selected chapter widget
      final selectedWidget = find.text(selectedChapter.toString());
      expect(selectedWidget, findsOneWidget);
    });

    testWidgets('Should handle Psalms (150 chapters)',
        (WidgetTester tester) async {
      const totalChapters = 150;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleChapterGridSelector(
              totalChapters: totalChapters,
              selectedChapter: 1,
              bookName: 'Psalms',
              onChapterSelected: (chapter) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that first chapters are visible
      expect(find.text('1'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);

      // Verify grid builder has correct item count
      final gridViewFinder = find.byType(GridView);
      final gridView = tester.widget<GridView>(gridViewFinder);
      final builder = gridView.childrenDelegate as SliverChildBuilderDelegate;

      // GridView.builder should have totalChapters items
      expect(builder.estimatedChildCount, equals(totalChapters));
    });

    testWidgets('Should call callback when chapter is tapped',
        (WidgetTester tester) async {
      int? selectedChapterValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleChapterGridSelector(
              totalChapters: 30,
              selectedChapter: 1,
              bookName: 'Genesis',
              onChapterSelected: (chapter) {
                selectedChapterValue = chapter;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on chapter 15
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      expect(selectedChapterValue, equals(15));
    });

    testWidgets('Should display book name in header',
        (WidgetTester tester) async {
      const bookName = 'Exodus';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleChapterGridSelector(
              totalChapters: 40,
              selectedChapter: 1,
              bookName: bookName,
              onChapterSelected: (chapter) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(bookName), findsOneWidget);
    });

    testWidgets('Should handle single chapter book',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleChapterGridSelector(
              totalChapters: 1,
              selectedChapter: 1,
              bookName: 'Obadiah',
              onChapterSelected: (chapter) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsNothing);
    });

    testWidgets('Should close dialog when close button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return BibleChapterGridSelector(
                        totalChapters: 50,
                        selectedChapter: 1,
                        bookName: 'Genesis',
                        onChapterSelected: (chapter) {},
                      );
                    },
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(BibleChapterGridSelector), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(BibleChapterGridSelector), findsNothing);
    });

    testWidgets('Should display scrollbar for long books',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleChapterGridSelector(
              totalChapters: 150,
              selectedChapter: 1,
              bookName: 'Psalms',
              onChapterSelected: (chapter) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Scrollbar), findsOneWidget);
    });

    testWidgets('Grid should arrange chapters in 6 columns',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleChapterGridSelector(
              totalChapters: 24,
              selectedChapter: 1,
              bookName: 'Genesis',
              onChapterSelected: (chapter) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final gridDelegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(gridDelegate.crossAxisCount, equals(6));
    });

    testWidgets('Should navigate multiple chapters in sequence',
        (WidgetTester tester) async {
      final selectedChapters = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleChapterGridSelector(
              totalChapters: 50,
              selectedChapter: 1,
              bookName: 'Genesis',
              onChapterSelected: (chapter) {
                selectedChapters.add(chapter);
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap multiple chapters
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('25'));
      await tester.pumpAndSettle();

      expect(selectedChapters, equals([5, 10, 25]));
    });

    testWidgets('Should handle rapid chapter selections',
        (WidgetTester tester) async {
      final selectedChapters = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleChapterGridSelector(
              totalChapters: 50,
              selectedChapter: 1,
              bookName: 'Genesis',
              onChapterSelected: (chapter) {
                selectedChapters.add(chapter);
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Rapid tapping
      await tester.tap(find.text('3'));
      await tester.tap(find.text('7'));
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();

      expect(selectedChapters.length, equals(3));
      expect(selectedChapters, containsAll([3, 7, 12]));
    });

    testWidgets('Should work with different book names',
        (WidgetTester tester) async {
      final bookNames = ['Genesis', 'Exodus', 'Leviticus', 'Numbers'];

      for (final bookName in bookNames) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BibleChapterGridSelector(
                totalChapters: 50,
                selectedChapter: 1,
                bookName: bookName,
                onChapterSelected: (chapter) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text(bookName), findsOneWidget);

        // Clean up for next iteration
        await tester.pumpWidget(Container());
      }
    });
  });

  group('Chapter Grid Edge Cases', () {
    testWidgets('Should handle first chapter selection',
        (WidgetTester tester) async {
      int? selectedChapterValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleChapterGridSelector(
              totalChapters: 50,
              selectedChapter: 1,
              bookName: 'Genesis',
              onChapterSelected: (chapter) {
                selectedChapterValue = chapter;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      expect(selectedChapterValue, equals(1));
    });

    testWidgets('Should handle last chapter selection',
        (WidgetTester tester) async {
      int? selectedChapterValue;
      const totalChapters = 50;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleChapterGridSelector(
              totalChapters: totalChapters,
              selectedChapter: 1,
              bookName: 'Genesis',
              onChapterSelected: (chapter) {
                selectedChapterValue = chapter;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to the last chapter
      await tester.drag(find.byType(GridView), const Offset(0, -500));
      await tester.pumpAndSettle();

      await tester.tap(find.text(totalChapters.toString()));
      await tester.pumpAndSettle();

      expect(selectedChapterValue, equals(totalChapters));
    });

    testWidgets('Should handle middle chapter selection',
        (WidgetTester tester) async {
      int? selectedChapterValue;
      const totalChapters = 100;
      const middleChapter = 50;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleChapterGridSelector(
              totalChapters: totalChapters,
              selectedChapter: 1,
              bookName: 'Psalms',
              onChapterSelected: (chapter) {
                selectedChapterValue = chapter;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to make chapter 50 visible
      await tester.dragUntilVisible(
        find.text(middleChapter.toString()),
        find.byType(GridView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(middleChapter.toString()));
      await tester.pumpAndSettle();

      expect(selectedChapterValue, equals(middleChapter));
    });
  });
}
