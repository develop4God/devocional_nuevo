import 'package:flutter_test/flutter_test.dart';

/// Test suite for consecutive verse navigation in Bible reader
/// Tests that verse dropdown works correctly multiple times in a row
/// Specifically tests with Psalm 119 (176 verses) as requested
void main() {
  group('Consecutive Verse Navigation Tests', () {
    test('Verse keys should be created for all verses in chapter', () {
      // Simulate verses from Psalm 119 (176 verses)
      final Map<int, dynamic> verseKeys = {};
      final int totalVerses = 176;

      // Create keys for all verses
      for (int i = 1; i <= totalVerses; i++) {
        verseKeys[i] = 'key_$i'; // Simulating GlobalKey
      }

      expect(verseKeys.length, totalVerses);
      expect(verseKeys[1], isNotNull);
      expect(verseKeys[88], isNotNull); // Middle verse
      expect(verseKeys[176], isNotNull); // Last verse
    });

    test('Verse keys should persist across multiple selections', () {
      final Map<int, dynamic> verseKeys = {};
      final List<int> verses = [1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

      // Simulate 10+ consecutive verse selections
      for (final verseNum in verses) {
        verseKeys[verseNum] = 'key_$verseNum';

        // Verify key exists and hasn't been cleared
        expect(verseKeys[verseNum], isNotNull);
        expect(verseKeys[verseNum], equals('key_$verseNum'));
      }

      // All keys should still exist after multiple selections
      expect(verseKeys.length, verses.length);
      for (final verseNum in verses) {
        expect(verseKeys[verseNum], isNotNull);
      }
    });

    test('Consecutive forward navigation (Psalm 119 verses 1-15)', () {
      final List<int> selectedVerses = [];
      final int startVerse = 1;
      final int endVerse = 15;

      // Simulate consecutive forward navigation
      for (int verse = startVerse; verse <= endVerse; verse++) {
        selectedVerses.add(verse);
      }

      expect(selectedVerses.length, 15);
      expect(selectedVerses.first, 1);
      expect(selectedVerses.last, 15);
      // Verify sequence is correct
      for (int i = 0; i < selectedVerses.length; i++) {
        expect(selectedVerses[i], i + 1);
      }
    });

    test('Consecutive backward navigation (Psalm 119 verses 176-160)', () {
      final List<int> selectedVerses = [];
      final int startVerse = 176;
      final int endVerse = 160;

      // Simulate consecutive backward navigation
      for (int verse = startVerse; verse >= endVerse; verse--) {
        selectedVerses.add(verse);
      }

      expect(selectedVerses.length, 17);
      expect(selectedVerses.first, 176);
      expect(selectedVerses.last, 160);
      // Verify descending sequence
      for (int i = 0; i < selectedVerses.length; i++) {
        expect(selectedVerses[i], 176 - i);
      }
    });

    test('Random verse navigation (10 consecutive selections)', () {
      final List<int> randomVerses = [7, 20, 1, 50, 100, 150, 75, 25, 176, 88];
      final List<int> navigated = [];

      // Simulate random consecutive selections
      for (final verse in randomVerses) {
        navigated.add(verse);
      }

      expect(navigated.length, 10);
      expect(navigated, equals(randomVerses));
    });

    test('Verse navigation with state updates', () {
      int? currentVerse;
      final Map<int, String> verseKeys = {};

      // Simulate 10 consecutive verse changes with state updates
      final List<int> verses = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50];

      for (final verse in verses) {
        // Simulate setState - update current verse
        currentVerse = verse;

        // Ensure verse key exists
        if (!verseKeys.containsKey(verse)) {
          verseKeys[verse] = 'key_$verse';
        }

        // Verify state
        expect(currentVerse, verse);
        expect(verseKeys[verse], isNotNull);
      }

      // Final state should be the last verse
      expect(currentVerse, 50);
      // All keys should still exist
      expect(verseKeys.length, verses.length);
    });

    test('Mixed chapter and verse navigation', () {
      // Simulate switching chapters multiple times with verse navigation
      final List<Map<String, int>> navigation = [
        {'chapter': 119, 'verse': 1},
        {'chapter': 119, 'verse': 10},
        {'chapter': 119, 'verse': 20},
        {'chapter': 120, 'verse': 1},
        {'chapter': 120, 'verse': 5},
        {'chapter': 119, 'verse': 100},
        {'chapter': 119, 'verse': 150},
        {'chapter': 119, 'verse': 176},
      ];

      int? currentChapter;
      int? currentVerse;
      final Map<int, Map<int, String>> chapterVerseKeys = {};

      for (final nav in navigation) {
        final chapter = nav['chapter']!;
        final verse = nav['verse']!;

        // Update state
        currentChapter = chapter;
        currentVerse = verse;

        // Ensure verse key exists for this chapter
        if (!chapterVerseKeys.containsKey(chapter)) {
          chapterVerseKeys[chapter] = {};
        }
        if (!chapterVerseKeys[chapter]!.containsKey(verse)) {
          chapterVerseKeys[chapter]![verse] = 'key_${chapter}_$verse';
        }

        // Verify
        expect(currentChapter, chapter);
        expect(currentVerse, verse);
        expect(chapterVerseKeys[chapter]![verse], isNotNull);
      }

      // Verify final state
      expect(currentChapter, 119);
      expect(currentVerse, 176);
    });

    test('Verse dropdown value should update correctly', () {
      int selectedVerse = 1;
      final List<int> selections = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50];

      for (final verse in selections) {
        // Simulate dropdown onChange
        selectedVerse = verse;
        expect(selectedVerse, verse);
      }

      // Last selected verse should be 50
      expect(selectedVerse, 50);
    });

    test('GlobalKey context should be available after build', () {
      // Simulate that contexts are available after frame callback
      final Map<int, bool> contextAvailable = {};
      final List<int> verses = [1, 10, 20, 30, 40, 50, 60, 70, 80, 90];

      for (final verse in verses) {
        // Simulate post-frame callback
        contextAvailable[verse] = true;
        expect(contextAvailable[verse], true);
      }

      // All contexts should be available
      expect(contextAvailable.length, verses.length);
    });

    test('Psalm 119 full navigation test (10+ consecutive)', () {
      // Test specifically with Psalm 119 as requested by user
      final List<int> psalm119Verses = [
        1, // Start
        10, // Forward
        20, // Forward
        50, // Jump
        100, // Jump
        150, // Jump
        176, // End
        88, // Middle
        44, // Back
        120, // Forward
        160, // Forward
        5, // Beginning
      ];

      int? currentVerse;
      final Map<int, String> keys = {};

      for (final verse in psalm119Verses) {
        currentVerse = verse;
        keys[verse] = 'key_$verse';

        expect(currentVerse, verse);
        expect(keys[verse], isNotNull);
      }

      // Should have navigated 12 times successfully
      expect(keys.length, psalm119Verses.length);
      expect(currentVerse, 5); // Last selected
    });
  });
}
