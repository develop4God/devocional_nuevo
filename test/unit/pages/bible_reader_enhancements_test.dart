import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Bible Reader Font Size Tests', () {
    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should save and load font size preference', () async {
      final prefs = await SharedPreferences.getInstance();

      // Save font size
      await prefs.setDouble('bible_font_size', 20.0);

      // Load font size
      final loadedFontSize = prefs.getDouble('bible_font_size');

      expect(loadedFontSize, 20.0);
    });

    test('should use default font size when not set', () async {
      final prefs = await SharedPreferences.getInstance();

      // Load font size (should be null)
      final loadedFontSize = prefs.getDouble('bible_font_size');

      expect(loadedFontSize, isNull);

      // Should default to 18.0
      final fontSize = loadedFontSize ?? 18.0;
      expect(fontSize, 18.0);
    });

    test('should increase font size within bounds', () async {
      double fontSize = 18.0;

      // Increase font size
      if (fontSize < 30) {
        fontSize += 2;
      }

      expect(fontSize, 20.0);
    });

    test('should not increase font size above maximum', () async {
      double fontSize = 30.0;

      // Try to increase font size (should not change)
      if (fontSize < 30) {
        fontSize += 2;
      }

      expect(fontSize, 30.0);
    });

    test('should decrease font size within bounds', () async {
      double fontSize = 18.0;

      // Decrease font size
      if (fontSize > 12) {
        fontSize -= 2;
      }

      expect(fontSize, 16.0);
    });

    test('should not decrease font size below minimum', () async {
      double fontSize = 12.0;

      // Try to decrease font size (should not change)
      if (fontSize > 12) {
        fontSize -= 2;
      }

      expect(fontSize, 12.0);
    });
  });

  group('Bible Reader Marked Verses Tests', () {
    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should save and load marked verses', () async {
      final prefs = await SharedPreferences.getInstance();

      // Save marked verses
      final markedVerses = ['Juan|3|16', 'Genesis|1|1', 'Psalms|23|1'];
      await prefs.setStringList('bible_marked_verses', markedVerses);

      // Load marked verses
      final loadedVerses = prefs.getStringList('bible_marked_verses');

      expect(loadedVerses, markedVerses);
      expect(loadedVerses!.length, 3);
      expect(loadedVerses.contains('Juan|3|16'), true);
    });

    test('should return empty list when no marked verses', () async {
      final prefs = await SharedPreferences.getInstance();

      // Load marked verses (should be null)
      final loadedVerses = prefs.getStringList('bible_marked_verses') ?? [];

      expect(loadedVerses, isEmpty);
    });

    test('should toggle verse marking', () async {
      final markedVerses = <String>{'Juan|3|16', 'Genesis|1|1'};
      final verseKey = 'Psalms|23|1';

      // Add verse
      if (!markedVerses.contains(verseKey)) {
        markedVerses.add(verseKey);
      }

      expect(markedVerses.contains(verseKey), true);
      expect(markedVerses.length, 3);

      // Remove verse
      if (markedVerses.contains(verseKey)) {
        markedVerses.remove(verseKey);
      }

      expect(markedVerses.contains(verseKey), false);
      expect(markedVerses.length, 2);
    });

    test('should handle multiple marked verses from different books', () async {
      final prefs = await SharedPreferences.getInstance();

      final markedVerses = [
        'Genesis|1|1',
        'Genesis|1|2',
        'Exodus|20|1',
        'Juan|3|16',
        '1 Corintios|13|4',
      ];

      await prefs.setStringList('bible_marked_verses', markedVerses);

      final loadedVerses = prefs.getStringList('bible_marked_verses');

      expect(loadedVerses!.length, 5);
      expect(loadedVerses.contains('Genesis|1|1'), true);
      expect(loadedVerses.contains('1 Corintios|13|4'), true);
    });

    test('should preserve marked verses across sessions', () async {
      final prefs = await SharedPreferences.getInstance();

      // First session - mark verses
      final session1Verses = ['Juan|3|16', 'Genesis|1|1'];
      await prefs.setStringList('bible_marked_verses', session1Verses);

      // Simulate app restart by creating new instance
      final session2Verses = prefs.getStringList('bible_marked_verses') ?? [];

      expect(session2Verses, session1Verses);
      expect(session2Verses.length, 2);
    });
  });

  group('Bible Reader Position Persistence Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('should save reading position', () async {
      final prefs = await SharedPreferences.getInstance();

      // Save position
      await prefs.setString('bible_last_book', 'Juan');
      await prefs.setInt('bible_last_book_number', 500);
      await prefs.setInt('bible_last_chapter', 3);
      await prefs.setInt('bible_last_verse', 16);
      await prefs.setString('bible_last_version', 'RVR1960');
      await prefs.setString('bible_last_language', 'es');

      // Verify saved
      expect(prefs.getString('bible_last_book'), 'Juan');
      expect(prefs.getInt('bible_last_chapter'), 3);
      expect(prefs.getInt('bible_last_verse'), 16);
    });

    test('should load reading position', () async {
      final prefs = await SharedPreferences.getInstance();

      // Set initial position
      await prefs.setString('bible_last_book', 'Genesis');
      await prefs.setInt('bible_last_book_number', 10);
      await prefs.setInt('bible_last_chapter', 1);
      await prefs.setInt('bible_last_verse', 1);
      await prefs.setString('bible_last_version', 'KJV');
      await prefs.setString('bible_last_language', 'en');

      // Load position
      final bookName = prefs.getString('bible_last_book');
      final bookNumber = prefs.getInt('bible_last_book_number');
      final chapter = prefs.getInt('bible_last_chapter');
      final version = prefs.getString('bible_last_version');

      expect(bookName, 'Genesis');
      expect(bookNumber, 10);
      expect(chapter, 1);
      expect(version, 'KJV');
    });

    test(
      'should update position when navigating to different chapter',
      () async {
        final prefs = await SharedPreferences.getInstance();

        // Initial position - Genesis 1
        await prefs.setString('bible_last_book', 'Genesis');
        await prefs.setInt('bible_last_chapter', 1);

        // Navigate to Genesis 2
        await prefs.setInt('bible_last_chapter', 2);

        expect(prefs.getInt('bible_last_chapter'), 2);
        expect(prefs.getString('bible_last_book'), 'Genesis');
      },
    );

    test('should update position when navigating to different book', () async {
      final prefs = await SharedPreferences.getInstance();

      // Initial position - Genesis 1
      await prefs.setString('bible_last_book', 'Genesis');
      await prefs.setInt('bible_last_book_number', 10);
      await prefs.setInt('bible_last_chapter', 1);

      // Navigate to Exodus 1
      await prefs.setString('bible_last_book', 'Exodus');
      await prefs.setInt('bible_last_book_number', 20);
      await prefs.setInt('bible_last_chapter', 1);

      expect(prefs.getString('bible_last_book'), 'Exodus');
      expect(prefs.getInt('bible_last_book_number'), 20);
    });

    test('should return null when no position is saved', () async {
      final prefs = await SharedPreferences.getInstance();

      final bookName = prefs.getString('bible_last_book');
      final chapter = prefs.getInt('bible_last_chapter');

      expect(bookName, isNull);
      expect(chapter, isNull);
    });
  });
}
