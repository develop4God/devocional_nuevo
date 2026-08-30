@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/widgets/bible/bible_book_selector_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  final books = [
    {'short_name': 'Gen', 'long_name': 'Genesis'},
    {'short_name': 'Exo', 'long_name': 'Exodus'},
    {'short_name': 'Psa', 'long_name': 'Psalms'},
    {'short_name': 'Mat', 'long_name': 'Matthew'},
  ];

  Future<void> pumpDialog(
    WidgetTester tester, {
    required List<Map<String, dynamic>> books,
    String? selectedBookName,
    required void Function(Map<String, dynamic>) onBookSelected,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => BibleBookSelectorDialog(
                      books: books,
                      selectedBookName: selectedBookName,
                      onBookSelected: onBookSelected,
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
  }

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await registerTestServices();
  });

  group('BibleBookSelectorDialog', () {
    testWidgets('displays all books when opened', (tester) async {
      await pumpDialog(tester, books: books, onBookSelected: (_) {});
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Genesis'), findsOneWidget);
      expect(find.text('Exodus'), findsOneWidget);
      expect(find.text('Psalms'), findsOneWidget);
      expect(find.text('Matthew'), findsOneWidget);
    });

    testWidgets('filters books by long name as user types', (tester) async {
      await pumpDialog(tester, books: books, onBookSelected: (_) {});
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'gen');
      await tester.pumpAndSettle();

      expect(find.text('Genesis'), findsOneWidget);
      expect(find.text('Exodus'), findsNothing);
      expect(find.text('Psalms'), findsNothing);
      expect(find.text('Matthew'), findsNothing);
    });

    testWidgets('filters books by short name as user types', (tester) async {
      await pumpDialog(tester, books: books, onBookSelected: (_) {});
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'exo');
      await tester.pumpAndSettle();

      expect(find.text('Exodus'), findsOneWidget);
      expect(find.text('Genesis'), findsNothing);
    });

    testWidgets('shows full list again when query is shorter than 2 chars', (
      tester,
    ) async {
      await pumpDialog(tester, books: books, onBookSelected: (_) {});
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'ps');
      await tester.pumpAndSettle();
      expect(find.text('Genesis'), findsNothing);

      await tester.enterText(find.byType(TextField), 'p');
      await tester.pumpAndSettle();

      expect(find.text('Genesis'), findsOneWidget);
      expect(find.text('Psalms'), findsOneWidget);
    });

    testWidgets('shows no results when search matches nothing', (
      tester,
    ) async {
      await pumpDialog(tester, books: books, onBookSelected: (_) {});
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      for (final book in books) {
        expect(find.text(book['long_name'] as String), findsNothing);
      }
    });

    testWidgets('clear button resets search and restores full list', (
      tester,
    ) async {
      await pumpDialog(tester, books: books, onBookSelected: (_) {});
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'gen');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Genesis'), findsOneWidget);
      expect(find.text('Exodus'), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets(
        'tapping a book invokes callback with book data and closes '
        'dialog', (tester) async {
      Map<String, dynamic>? selected;
      await pumpDialog(
        tester,
        books: books,
        onBookSelected: (book) => selected = book,
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Matthew'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!['short_name'], 'Mat');
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('close button dismisses dialog without invoking callback', (
      tester,
    ) async {
      var called = false;
      await pumpDialog(
        tester,
        books: books,
        onBookSelected: (_) => called = true,
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(called, isFalse);
    });

    testWidgets('marks the currently selected book as selected', (
      tester,
    ) async {
      await pumpDialog(
        tester,
        books: books,
        selectedBookName: 'Psa',
        onBookSelected: (_) {},
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final tile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Psalms'),
          matching: find.byType(ListTile),
        ),
      );
      expect(tile.selected, isTrue);
    });

    testWidgets('handles an empty books list without error', (tester) async {
      await pumpDialog(tester, books: const [], onBookSelected: (_) {});
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ListTile), findsNothing);
    });
  });
}
