import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bible Verse Scroll Precision Tests', () {
    test('should calculate accurate scroll position based on text length', () {
      final fontSize = 18.0;
      final lineHeight = fontSize * 1.6;
      
      // Simulate short verse
      final shortText = 'In the beginning God created the heavens and the earth.';
      final shortLines = (shortText.length / 40).ceil();
      final shortHeight = (shortLines * lineHeight) + 16;
      
      expect(shortLines, 2); // ~56 chars = 2 lines
      expect(shortHeight, greaterThan(40));
      expect(shortHeight, lessThan(100));
    });

    test('should calculate accurate scroll position for long verse (Psalm 119)', () {
      final fontSize = 18.0;
      final lineHeight = fontSize * 1.6;
      
      // Simulate long verse from Psalm 119
      final longText = 'Your word is a lamp for my feet, a light on my path. I have taken an oath and confirmed it, that I will follow your righteous laws.';
      final longLines = (longText.length / 40).ceil();
      final longHeight = (longLines * lineHeight) + 16;
      
      expect(longLines, greaterThanOrEqualTo(3)); // ~130 chars = 4+ lines
      expect(longHeight, greaterThan(80));
    });

    test('should accumulate height correctly for multiple verses', () {
      final fontSize = 18.0;
      final lineHeight = fontSize * 1.6;
      
      final verses = [
        'Verse 1 text here.',
        'Verse 2 is longer with more words to say.',
        'Verse 3 text.',
      ];
      
      double totalHeight = 0;
      for (final text in verses) {
        final lines = (text.length / 40).ceil();
        final height = (lines * lineHeight) + 16;
        totalHeight += height;
      }
      
      expect(totalHeight, greaterThan(0));
      expect(totalHeight, lessThan(500)); // Reasonable for 3 verses
    });

    test('should handle Psalm 119 navigation (176 verses)', () {
      final fontSize = 18.0;
      final lineHeight = fontSize * 1.6;
      
      // Simulate navigating to verse 100 in Psalm 119
      final targetVerseIndex = 99; // 0-indexed
      
      double estimatedHeight = 0;
      for (int i = 0; i < targetVerseIndex; i++) {
        // Assume average verse length of 80 characters
        final avgText = 'A' * 80;
        final lines = (avgText.length / 40).ceil();
        final height = (lines * lineHeight) + 16;
        estimatedHeight += height;
      }
      
      expect(estimatedHeight, greaterThan(1000)); // Should be substantial
      expect(estimatedHeight, lessThan(10000)); // But reasonable
    });

    test('should clamp scroll position to max scroll extent', () {
      final estimatedHeight = 15000.0;
      final maxScrollExtent = 10000.0;
      final screenHeight = 800.0;
      final centerOffset = screenHeight * 0.25;
      
      final scrollPosition = (estimatedHeight - centerOffset).clamp(0.0, maxScrollExtent);
      
      expect(scrollPosition, equals(maxScrollExtent));
      expect(scrollPosition, lessThanOrEqualTo(maxScrollExtent));
    });

    test('should not scroll below 0', () {
      final estimatedHeight = 50.0;
      final maxScrollExtent = 10000.0;
      final screenHeight = 800.0;
      final centerOffset = screenHeight * 0.25;
      
      final scrollPosition = (estimatedHeight - centerOffset).clamp(0.0, maxScrollExtent);
      
      expect(scrollPosition, equals(0.0));
      expect(scrollPosition, greaterThanOrEqualTo(0.0));
    });

    test('should center verse on screen with offset', () {
      final screenHeight = 800.0;
      final centerOffset = screenHeight * 0.25; // 200 pixels
      
      expect(centerOffset, equals(200.0));
      
      // For a verse at height 500, scroll position should be 300
      final verseHeight = 500.0;
      final scrollPosition = verseHeight - centerOffset;
      
      expect(scrollPosition, equals(300.0));
    });

    test('should handle different font sizes', () {
      final smallFont = 12.0;
      final largeFont = 30.0;
      
      final text = 'A' * 80;
      
      final smallLines = (text.length / 40).ceil();
      final smallHeight = (smallLines * (smallFont * 1.6)) + 16;
      
      final largeLines = (text.length / 40).ceil();
      final largeHeight = (largeLines * (largeFont * 1.6)) + 16;
      
      expect(largeHeight, greaterThan(smallHeight));
      expect(largeHeight / smallHeight, closeTo(largeFont / smallFont, 0.5));
    });

    test('should handle verse 1 (first verse)', () {
      final verseNumber = 1;
      final verses = List.generate(50, (i) => {'verse': i + 1, 'text': 'Verse ${i + 1}'});
      
      final verseIndex = verses.indexWhere((v) => v['verse'] == verseNumber);
      
      expect(verseIndex, equals(0));
      
      // Height before first verse should be 0
      double estimatedHeight = 0;
      for (int i = 0; i < verseIndex; i++) {
        estimatedHeight += 50; // dummy height
      }
      
      expect(estimatedHeight, equals(0.0));
    });

    test('should find correct verse index for verse 119 in Psalm 119', () {
      // Simulate Psalm 119 with 176 verses
      final verses = List.generate(176, (i) => {'verse': i + 1, 'text': 'Psalm 119 verse ${i + 1}'});
      
      final targetVerse = 119;
      final verseIndex = verses.indexWhere((v) => v['verse'] == targetVerse);
      
      expect(verseIndex, equals(118)); // 0-indexed
      expect(verseIndex, greaterThan(0));
      expect(verseIndex, lessThan(verses.length));
    });

    test('should handle mid-chapter verse navigation', () {
      final verses = List.generate(31, (i) => {'verse': i + 1, 'text': 'Genesis 1:${i + 1}'});
      
      final targetVerse = 15;
      final verseIndex = verses.indexWhere((v) => v['verse'] == targetVerse);
      
      expect(verseIndex, equals(14)); // 0-indexed
      expect(verseIndex, greaterThan(0));
      expect(verseIndex, lessThan(verses.length));
    });
  });

  group('Bottom Sheet Modal Tests', () {
    test('should format single verse reference correctly', () {
      final selectedVerses = {'Juan|3|16'};
      final sorted = selectedVerses.toList()..sort();
      final parts = sorted.first.split('|');
      
      final book = parts[0];
      final chapter = parts[1];
      final verse = parts[2];
      
      final reference = '$book $chapter:$verse';
      
      expect(reference, equals('Juan 3:16'));
    });

    test('should format verse range reference correctly', () {
      final selectedVerses = {
        'Juan|3|16',
        'Juan|3|17',
        'Juan|3|18',
      };
      final sorted = selectedVerses.toList()..sort();
      final first = sorted.first.split('|');
      final last = sorted.last.split('|');
      
      final book = first[0];
      final chapter = first[1];
      final firstVerse = int.parse(first[2]);
      final lastVerse = int.parse(last[2]);
      
      final reference = '$book $chapter:$firstVerse-$lastVerse';
      
      expect(reference, equals('Juan 3:16-18'));
    });

    test('should handle non-contiguous verses', () {
      final selectedVerses = {
        'Juan|3|16',
        'Juan|3|19',
        'Juan|3|20',
      };
      final sorted = selectedVerses.toList()..sort();
      
      expect(sorted.length, equals(3));
      expect(sorted.first, equals('Juan|3|16'));
      expect(sorted.last, equals('Juan|3|20'));
    });
  });
}
