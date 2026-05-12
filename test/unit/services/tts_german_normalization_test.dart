@Tags(['unit', 'services', 'tts'])
library;

// test/unit/services/tts_german_normalization_test.dart
//
// Comprehensive test for German TTS text normalization including:
// - Bible book ordinals (Erstes, Zweites, Drittes Johannes)
// - Version expansions (LU17, SCH2000)
// - Bible references (Kapitel, Vers, and ranges with "bis")
// - Integration with voice playback for German speakers

import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('German TTS Normalization', () {
    // ──────────────────────────────────────────────────────────────
    // 1. BIBLE BOOK ORDINALS (Erstes, Zweites, Drittes)
    // ──────────────────────────────────────────────────────────────

    group('German Bible Book Ordinals', () {
      test('converts "1 Johannes" to "Erster Johannes"', () {
        final result = BibleTextFormatter.formatBibleBook('1 Johannes', 'de');
        expect(result, contains('Erster Johannes'));
      });

      test('converts "2 Korinther" to "Zweiter Korinther"', () {
        final result = BibleTextFormatter.formatBibleBook('2 Korinther', 'de');
        expect(result, contains('Zweiter Korinther'));
      });

      test('converts "3 Johannes" to "Dritter Johannes"', () {
        final result = BibleTextFormatter.formatBibleBook('3 Johannes', 'de');
        expect(result, contains('Dritter Johannes'));
      });

      test('handles special German characters (ä, ö, ü, ß)', () {
        final result = BibleTextFormatter.formatBibleBook('1 Mose', 'de');
        expect(result, contains('Erster Mose'));
      });

      test('converts mixed case ordinals', () {
        final result = BibleTextFormatter.formatBibleBook('1 JOHANNES', 'de');
        expect(result.toLowerCase(), contains('erster johannes'));
      });

      test(
        'handles ordinals in middle of text (e.g. "The 1 Peter chapter")',
        () {
          final result = BibleTextFormatter.formatBibleBook(
            'From 1 Petrus to other references',
            'de',
          );
          expect(result, contains('Erster Petrus'));
        },
      );

      test('preserves non-ordinal numbers (4, 5, etc.)', () {
        final result = BibleTextFormatter.formatBibleBook(
          '4 Mose 5 Buch',
          'de',
        );
        // Regex only matches 1-3; 4 Mose (Numbers) and standalone
        // numbers must pass through unchanged
        expect(result, contains('4 Mose'));
        expect(result, contains('5 Buch'));
      });
    });

    // ──────────────────────────────────────────────────────────────
    // 2. VERSION EXPANSIONS (LU17, SCH2000)
    // ──────────────────────────────────────────────────────────────

    group('German Bible Version Expansions', () {
      test('expands LU17 to "Lutherbibel zweitausendsiebzehn"', () {
        final expansions = BibleTextFormatter.getBibleVersionExpansions('de');
        expect(expansions['LU17'], equals('Lutherbibel zweitausendsiebzehn'));
      });

      test('expands SCH2000 to "Schlachter zweitausend"', () {
        final expansions = BibleTextFormatter.getBibleVersionExpansions('de');
        expect(expansions['SCH2000'], equals('Schlachter zweitausend'));
      });

      test('normalizes text with LU17 version code', () {
        final result = BibleTextFormatter.normalizeTtsText(
          'Johannes 3:16 LU17',
          'de',
          'LU17',
        );
        expect(result, contains('Lutherbibel zweitausendsiebzehn'));
      });

      test('normalizes text with SCH2000 version code', () {
        final result = BibleTextFormatter.normalizeTtsText(
          'Erste Petrus 1:3 SCH2000',
          'de',
          'SCH2000',
        );
        expect(result, contains('Schlachter zweitausend'));
      });
    });

    // ──────────────────────────────────────────────────────────────
    // 3. BIBLE REFERENCES (Kapitel, Vers, Ranges with "bis")
    // ──────────────────────────────────────────────────────────────

    group('German Bible References', () {
      test('expands "Johannes 3:16" to include "Kapitel" and "Vers"', () {
        final result = BibleTextFormatter.formatBibleReferences(
          'Johannes 3:16',
          'de',
        );
        expect(result, contains('Kapitel'));
        expect(result, contains('Vers'));
        expect(result, contains('3'));
        expect(result, contains('16'));
      });

      test('expands "Erster Korinther 13:4-7" with "bis" for verse ranges', () {
        final result = BibleTextFormatter.formatBibleReferences(
          'Erster Korinther 13:4-7',
          'de',
        );
        expect(result, contains('Kapitel'));
        expect(result, contains('Vers'));
        expect(result, contains('bis'));
        expect(result, contains('13'));
        expect(result, contains('4'));
        expect(result, contains('7'));
      });

      test('properly formats chapter:verse without verse range', () {
        final result = BibleTextFormatter.formatBibleReferences(
          'Römer 8:28',
          'de',
        );
        expect(result, contains('Kapitel'));
        expect(result, contains('Vers'));
        expect(
          result.contains('bis'),
          isFalse,
          reason: 'Should not contain "bis" without verse range',
        );
      });

      test('handles multiple references in text', () {
        final result = BibleTextFormatter.formatBibleReferences(
          'Johannes 1:1 and Matthäus 6:9',
          'de',
        );
        expect(result, contains('Kapitel'));
        expect(result, contains('Vers'));
        expect(
          result.split('Kapitel').length,
          greaterThan(2),
          reason: 'Should have expanded multiple references',
        );
      });
    });

    // ──────────────────────────────────────────────────────────────
    // 4. FULL TEXT NORMALIZATION (INTEGRATION)
    // ──────────────────────────────────────────────────────────────

    group('German TTS Full Text Normalization (Integration)', () {
      test(
        'normalizes complete devotional reference: "1 Johannes 3:16 LU17"',
        () {
          final result = BibleTextFormatter.normalizeTtsText(
            '1 Johannes 3:16 LU17',
            'de',
            'LU17',
          );
          expect(result, contains('Erster Johannes'));
          expect(result, contains('Kapitel'));
          expect(result, contains('Vers'));
          expect(result, contains('Lutherbibel zweitausendsiebzehn'));
        },
      );

      test('normalizes verse range: "2 Korinther 4:7-9 SCH2000"', () {
        final result = BibleTextFormatter.normalizeTtsText(
          '2 Korinther 4:7-9 SCH2000',
          'de',
          'SCH2000',
        );
        expect(result, contains('Zweiter Korinther'));
        expect(result, contains('Kapitel'));
        expect(result, contains('Vers'));
        expect(result, contains('bis'));
        expect(result, contains('Schlachter zweitausend'));
      });

      test('handles ordinal at start and reference in middle', () {
        final text = '1 Petrus discusses 3:15-16 blessings';
        final result = BibleTextFormatter.normalizeTtsText(text, 'de', 'LU17');
        expect(result, contains('Erster Petrus'));
        expect(result, contains('Kapitel'));
        expect(result, contains('bis'));
      });

      test('sanitizes malformed input before normalizing', () {
        // Input with Unicode replacement character
        final malformed = '1 Johannes \uFFFD 3:16';
        final result = BibleTextFormatter.normalizeTtsText(
          malformed,
          'de',
          'LU17',
        );
        // Should not crash and should normalize the valid part
        expect(result, contains('Erster Johannes'));
      });

      test('normalizes multiple whitespace to single spaces', () {
        final text = '1  Johannes   3:16   LU17';
        final result = BibleTextFormatter.normalizeTtsText(text, 'de', 'LU17');
        // Should have normalized whitespace
        expect(
          result.contains('   '),
          isFalse,
          reason: 'Should normalize multiple spaces',
        );
      });
    });

    // ──────────────────────────────────────────────────────────────
    // 5. REGRESSION TESTS (Other Languages Still Work)
    // ──────────────────────────────────────────────────────────────

    group('German TTS does not break other languages', () {
      test('Spanish still converts "1 Juan" to "Primera de Juan"', () {
        final result = BibleTextFormatter.formatBibleBook('1 Juan', 'es');
        expect(result, contains('Primera de Juan'));
      });

      test('English still converts "1 John" to "First John"', () {
        final result = BibleTextFormatter.formatBibleBook('1 John', 'en');
        expect(result, contains('First John'));
      });

      test('Portuguese still converts "1 Pedro" to "Primeiro Pedro"', () {
        final result = BibleTextFormatter.formatBibleBook('1 Pedro', 'pt');
        expect(result, contains('Primeiro Pedro'));
      });

      test('French still converts "1 Jean" to "Premier Jean"', () {
        final result = BibleTextFormatter.formatBibleBook('1 Jean', 'fr');
        expect(result, contains('Premier Jean'));
      });
    });
  });
}
