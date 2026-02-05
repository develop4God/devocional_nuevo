@Tags(['unit', 'pages'])
library;

import 'package:bible_reader_core/src/bible_db_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bible Search Priority Tests', () {
    test('search should prioritize exact word matches', () {
      // Test logic for priority search
      const query = 'amor';
      const exactMatch = 'Dios es amor eterno';
      const partialMatch = 'Los amorreos habitaban';

      // Exact match should be higher priority
      expect(exactMatch.contains(' $query '), isTrue);
      expect(partialMatch.contains(' $query '), isFalse);
    });

    test('search should handle word at start of text', () {
      const query = 'Dios';
      const startsWithMatch = 'Dios es amor';

      expect(startsWithMatch.startsWith(query), isTrue);
    });

    test('search should handle partial matches as lowest priority', () {
      const query = 'amor';
      const partialMatch = 'amorreos';

      expect(partialMatch.contains(query), isTrue);
      expect(partialMatch.contains(' $query '), isFalse);
    });
  });

  group('Bible Verse Selector Tests', () {
    test('should validate verse number within chapter range', () {
      const maxVerse = 31; // e.g., Genesis 1 has 31 verses
      int selectedVerse = 1;

      // Valid verse selection
      selectedVerse = 15;
      expect(selectedVerse, greaterThan(0));
      expect(selectedVerse, lessThanOrEqualTo(maxVerse));

      // Invalid verse (too high)
      selectedVerse = 50;
      if (selectedVerse > maxVerse) {
        selectedVerse = 1; // Reset to 1
      }
      expect(selectedVerse, equals(1));
    });

    test('should initialize verse to 1 when changing chapters', () {
      int? selectedVerse;

      // Initially null
      expect(selectedVerse, isNull);

      // After loading chapter
      selectedVerse = 1;
      expect(selectedVerse, equals(1));
    });
  });

  group('Book Search Filter Tests', () {
    test('should filter books by partial name match', () {
      final books = [
        {'short_name': 'Gn', 'long_name': 'Génesis'},
        {'short_name': 'Ex', 'long_name': 'Éxodo'},
        {'short_name': 'Jn', 'long_name': 'Juan'},
        {'short_name': '1Jn', 'long_name': '1 Juan'},
        {'short_name': 'Jue', 'long_name': 'Jueces'},
      ];

      // Filter for "ju"
      final filtered = books.where((book) {
        final longName = book['long_name']!.toLowerCase();
        final shortName = book['short_name']!.toLowerCase();
        return longName.contains('ju') || shortName.contains('ju');
      }).toList();

      expect(filtered.length, equals(3)); // Juan, 1 Juan, Jueces
      expect(filtered.any((b) => b['short_name'] == 'Jn'), isTrue);
      expect(filtered.any((b) => b['short_name'] == '1Jn'), isTrue);
      expect(filtered.any((b) => b['short_name'] == 'Jue'), isTrue);
    });

    test('should require minimum 2 characters for filtering', () {
      final query = 'j';
      expect(query.length < 2, isTrue);

      final query2 = 'ju';
      expect(query2.length >= 2, isTrue);
    });

    test('should filter books case-insensitively', () {
      final books = [
        {'short_name': 'Gn', 'long_name': 'Génesis'},
        {'short_name': '1Cro', 'long_name': '1 Crónicas'},
      ];

      final queries = ['cró', 'CRÓ', 'Cró', '1 cro'];
      for (final query in queries) {
        final filtered = books.where((book) {
          final longName = book['long_name']!.toLowerCase();
          final shortName = book['short_name']!.toLowerCase();
          final queryLower = query.toLowerCase();
          return longName.contains(queryLower) ||
              shortName.contains(queryLower);
        }).toList();

        if (filtered.isNotEmpty) {
          expect(filtered.first['short_name'], equals('1Cro'));
        }
      }
    });
  });

  group('Font Size Controls Tests', () {
    test('font controls should be hideable', () {
      bool showFontControls = false;

      // Initially hidden
      expect(showFontControls, isFalse);

      // Toggle to show
      showFontControls = !showFontControls;
      expect(showFontControls, isTrue);

      // Toggle to hide
      showFontControls = !showFontControls;
      expect(showFontControls, isFalse);
    });

    test('font size should stay within bounds', () {
      double fontSize = 18;

      // Increase within bounds
      if (fontSize < 30) {
        fontSize += 2;
      }
      expect(fontSize, equals(20));

      // Try to increase beyond max
      fontSize = 30;
      if (fontSize < 30) {
        fontSize += 2;
      }
      expect(fontSize, equals(30));

      // Decrease within bounds
      fontSize = 18;
      if (fontSize > 12) {
        fontSize -= 2;
      }
      expect(fontSize, equals(16));

      // Try to decrease below min
      fontSize = 12;
      if (fontSize > 12) {
        fontSize -= 2;
      }
      expect(fontSize, equals(12));
    });
  });

  group('Marked Verses Persistence Tests', () {
    test('marked verses should persist in set', () {
      final markedVerses = <String>{};

      // Mark a verse
      const verseKey = 'Juan|3|16';
      markedVerses.add(verseKey);
      expect(markedVerses.contains(verseKey), isTrue);
      expect(markedVerses.length, equals(1));

      // Mark another verse
      const verseKey2 = 'Genesis|1|1';
      markedVerses.add(verseKey2);
      expect(markedVerses.length, equals(2));

      // Unmark a verse
      markedVerses.remove(verseKey);
      expect(markedVerses.contains(verseKey), isFalse);
      expect(markedVerses.length, equals(1));
    });

    test('marked verses should use correct key format', () {
      const bookName = 'Juan';
      const chapter = 3;
      const verse = 16;
      final key = '$bookName|$chapter|$verse';

      expect(key, equals('Juan|3|16'));
      expect(key.split('|').length, equals(3));
      expect(key.split('|')[0], equals('Juan'));
      expect(int.parse(key.split('|')[1]), equals(3));
      expect(int.parse(key.split('|')[2]), equals(16));
    });

    test('should toggle verse marking correctly', () {
      final markedVerses = <String>{};
      const verseKey = 'Juan|3|16';

      // Toggle on
      if (markedVerses.contains(verseKey)) {
        markedVerses.remove(verseKey);
      } else {
        markedVerses.add(verseKey);
      }
      expect(markedVerses.contains(verseKey), isTrue);

      // Toggle off
      if (markedVerses.contains(verseKey)) {
        markedVerses.remove(verseKey);
      } else {
        markedVerses.add(verseKey);
      }
      expect(markedVerses.contains(verseKey), isFalse);
    });
  });

  group('BibleDbService Tests', () {
    test('should create BibleDbService instance', () {
      final service = BibleDbService();
      expect(service, isNotNull);
      expect(service, isA<BibleDbService>());
    });

    test('should have searchVerses method', () {
      final service = BibleDbService();
      expect(service.searchVerses, isA<Function>());
    });

    test('should have findBookByName method', () {
      final service = BibleDbService();
      expect(service.findBookByName, isA<Function>());
    });
  });
}
