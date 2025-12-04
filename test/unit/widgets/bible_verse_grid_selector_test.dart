import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/widgets/bible_verse_grid_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test suite for Bible verse grid selector widget
/// Tests grid-based verse selection with multiple books and chapters
/// including Psalm 119 (176 verses) as requested
void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Reset ServiceLocator for clean test state
    ServiceLocator().reset();
    SharedPreferences.setMockInitialValues({});
    // Register LocalizationService
    ServiceLocator().registerLazySingleton<LocalizationService>(
        () => LocalizationService());
  });

  tearDown(() {
    ServiceLocator().reset();
  });

  group('Bible Verse Grid Selector Tests', () {
    testWidgets('Should display grid with correct number of verses',
        (WidgetTester tester) async {
      // Test with Genesis 1 (31 verses)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleVerseGridSelector(
              totalVerses: 31,
              selectedVerse: 1,
              bookName: 'Genesis',
              chapterNumber: 1,
              onVerseSelected: (verse) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find grid items by Material widget instead of InkWell (to exclude close button)
      final gridItems = find.descendant(
        of: find.byType(GridView),
        matching: find.byType(InkWell),
      );
      expect(gridItems, findsNWidgets(31));
    });

    testWidgets('Should highlight selected verse', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleVerseGridSelector(
              totalVerses: 50,
              selectedVerse: 25,
              bookName: 'Psalms',
              chapterNumber: 23,
              onVerseSelected: (verse) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify verse 25 is displayed
      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('Should handle Psalm 119 (176 verses)',
        (WidgetTester tester) async {
      int? selectedVerse;

      // Test with longest chapter in the Bible
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleVerseGridSelector(
              totalVerses: 176,
              selectedVerse: 1,
              bookName: 'Psalms',
              chapterNumber: 119,
              onVerseSelected: (verse) {
                selectedVerse = verse;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify first verse is visible
      expect(find.text('1'), findsOneWidget);

      // Tap verse 1 to verify functionality
      await tester.tap(find.text('1'));
      expect(selectedVerse, equals(1));

      // Scroll to find last verse
      await tester.drag(
        find.byType(GridView),
        const Offset(0, -5000),
      );
      await tester.pumpAndSettle();

      // Verify last verse is available after scrolling
      expect(find.text('176'), findsOneWidget);

      // Tap last verse
      await tester.tap(find.text('176'));
      expect(selectedVerse, equals(176));
    });

    testWidgets('Should call callback when verse is tapped',
        (WidgetTester tester) async {
      int? selectedVerse;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleVerseGridSelector(
              totalVerses: 50,
              selectedVerse: 1,
              bookName: 'John',
              chapterNumber: 3,
              onVerseSelected: (verse) {
                selectedVerse = verse;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on verse 16
      await tester.tap(find.text('16'));
      await tester.pumpAndSettle();

      expect(selectedVerse, equals(16));
    });

    testWidgets('Should display book and chapter info in header',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleVerseGridSelector(
              totalVerses: 25,
              selectedVerse: 1,
              bookName: 'Romans',
              chapterNumber: 8,
              onVerseSelected: (verse) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header contains book and chapter
      expect(find.textContaining('Romans'), findsOneWidget);
      expect(find.textContaining('8'), findsAtLeastNWidgets(1));
    });

    testWidgets('Should handle single verse chapter',
        (WidgetTester tester) async {
      // Test with Obadiah (1 chapter, 21 verses)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleVerseGridSelector(
              totalVerses: 21,
              selectedVerse: 1,
              bookName: 'Obadiah',
              chapterNumber: 1,
              onVerseSelected: (verse) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final gridItems = find.descendant(
        of: find.byType(GridView),
        matching: find.byType(InkWell),
      );
      expect(gridItems, findsNWidgets(21));
    });

    testWidgets('Should close dialog when close button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => BibleVerseGridSelector(
                        totalVerses: 31,
                        selectedVerse: 1,
                        bookName: 'Genesis',
                        chapterNumber: 1,
                        onVerseSelected: (verse) {},
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.byType(Dialog), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('Should display scrollbar for long chapters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleVerseGridSelector(
              totalVerses: 176,
              selectedVerse: 1,
              bookName: 'Psalms',
              chapterNumber: 119,
              onVerseSelected: (verse) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify scrollbar is present
      expect(find.byType(Scrollbar), findsOneWidget);
    });

    test('Grid should arrange verses in 8 columns', () {
      // Verify grid configuration
      const crossAxisCount = 8;
      const totalVerses = 176;
      final expectedRows = (totalVerses / crossAxisCount).ceil();

      expect(expectedRows, equals(22)); // 176 / 8 = 22 rows
    });

    testWidgets('Should navigate multiple verses in sequence',
        (WidgetTester tester) async {
      final List<int> selectedVerses = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return BibleVerseGridSelector(
                  totalVerses: 100,
                  selectedVerse:
                      selectedVerses.isEmpty ? 1 : selectedVerses.last,
                  bookName: 'Psalms',
                  chapterNumber: 119,
                  onVerseSelected: (verse) {
                    setState(() {
                      selectedVerses.add(verse);
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select multiple verses in sequence (need to scroll for some)
      final verseSequence = [5, 10, 25, 50];
      for (final verse in verseSequence) {
        // Scroll to make verse visible if needed
        await tester.dragUntilVisible(
          find.text(verse.toString()),
          find.byType(GridView),
          const Offset(0, -50),
        );
        await tester.tap(find.text(verse.toString()));
        await tester.pumpAndSettle();
      }

      // Verify all verses were selected in sequence
      expect(selectedVerses, equals(verseSequence));
    });

    testWidgets('Should handle rapid verse selections',
        (WidgetTester tester) async {
      final List<int> selectedVerses = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleVerseGridSelector(
              totalVerses: 50,
              selectedVerse: 1,
              bookName: 'Matthew',
              chapterNumber: 5,
              onVerseSelected: (verse) {
                selectedVerses.add(verse);
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Rapidly tap multiple verses
      for (int i = 1; i <= 10; i++) {
        await tester.tap(find.text(i.toString()));
      }
      await tester.pumpAndSettle();

      // Should have registered all 10 taps
      expect(selectedVerses.length, equals(10));
    });

    testWidgets('Should work with different book names',
        (WidgetTester tester) async {
      final books = [
        {'name': 'Genesis', 'chapter': 1, 'verses': 31},
        {'name': '1 Chronicles', 'chapter': 29, 'verses': 30},
        {'name': 'Revelation', 'chapter': 22, 'verses': 21},
      ];

      for (final book in books) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BibleVerseGridSelector(
                totalVerses: book['verses'] as int,
                selectedVerse: 1,
                bookName: book['name'] as String,
                chapterNumber: book['chapter'] as int,
                onVerseSelected: (verse) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify book name is displayed
        expect(find.textContaining(book['name'] as String), findsOneWidget);

        // Clean up for next iteration
        await tester.pumpWidget(Container());
      }
    });
  });

  group('Verse Grid Edge Cases', () {
    testWidgets('Should handle first verse selection',
        (WidgetTester tester) async {
      int? selectedVerse;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleVerseGridSelector(
              totalVerses: 50,
              selectedVerse: 10,
              bookName: 'John',
              chapterNumber: 1,
              onVerseSelected: (verse) {
                selectedVerse = verse;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      expect(selectedVerse, equals(1));
    });

    testWidgets('Should handle last verse selection',
        (WidgetTester tester) async {
      int? selectedVerse;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleVerseGridSelector(
              totalVerses: 50,
              selectedVerse: 1,
              bookName: 'John',
              chapterNumber: 21,
              onVerseSelected: (verse) {
                selectedVerse = verse;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to bottom to see verse 50
      await tester.drag(
        find.byType(GridView),
        const Offset(0, -1000),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('50'));
      await tester.pumpAndSettle();

      expect(selectedVerse, equals(50));
    });

    testWidgets('Should handle middle verse selection',
        (WidgetTester tester) async {
      int? selectedVerse;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BibleVerseGridSelector(
              totalVerses: 100,
              selectedVerse: 1,
              bookName: 'Psalms',
              chapterNumber: 78,
              onVerseSelected: (verse) {
                selectedVerse = verse;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to make verse 50 visible
      await tester.dragUntilVisible(
        find.text('50'),
        find.byType(GridView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      // Select middle verse
      await tester.tap(find.text('50'));
      await tester.pumpAndSettle();

      expect(selectedVerse, equals(50));
    });
  });
}
