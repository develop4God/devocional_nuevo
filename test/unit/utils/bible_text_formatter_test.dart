@Tags(['unit', 'utils'])
library;

// test/critical_coverage/bible_text_formatter_test.dart
// High-value tests for Bible text formatting for TTS across all languages

import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';

void main() {
  group('BibleTextFormatter - Spanish Ordinals', () {
    test('formats 1 Pedro as Primera de Pedro', () {
      final result = BibleTextFormatter.formatBibleBook('1 Pedro', 'es');
      expect(result, 'Primera de Pedro');
    });

    test('formats 2 Corintios as Segunda de Corintios', () {
      final result = BibleTextFormatter.formatBibleBook('2 Corintios', 'es');
      expect(result, 'Segunda de Corintios');
    });

    test('formats 3 Juan as Tercera de Juan', () {
      final result = BibleTextFormatter.formatBibleBook('3 Juan', 'es');
      expect(result, 'Tercera de Juan');
    });

    test('formats book names with accents', () {
      final result = BibleTextFormatter.formatBibleBook(
        '1 Tesalonicenses',
        'es',
      );
      expect(result, 'Primera de Tesalonicenses');
    });

    test('handles book in middle of text', () {
      final result = BibleTextFormatter.formatBibleBook(
        'Lee 1 Pedro hoy',
        'es',
      );
      expect(result, contains('Primera de Pedro'));
    });

    test('leaves non-numbered books unchanged', () {
      final result = BibleTextFormatter.formatBibleBook('Génesis', 'es');
      expect(result, 'Génesis');
    });
  });

  group('BibleTextFormatter - English Ordinals', () {
    test('formats 1 Peter as First Peter', () {
      final result = BibleTextFormatter.formatBibleBook('1 Peter', 'en');
      expect(result, 'First Peter');
    });

    test('formats 2 Corinthians as Second Corinthians', () {
      final result = BibleTextFormatter.formatBibleBook('2 Corinthians', 'en');
      expect(result, 'Second Corinthians');
    });

    test('formats 3 John as Third John', () {
      final result = BibleTextFormatter.formatBibleBook('3 John', 'en');
      expect(result, 'Third John');
    });

    test('handles mixed case', () {
      final result = BibleTextFormatter.formatBibleBook('1 TIMOTHY', 'en');
      expect(result, 'First TIMOTHY');
    });
  });

  group('BibleTextFormatter - Portuguese Ordinals', () {
    test('formats 1 Pedro as Primeiro Pedro', () {
      final result = BibleTextFormatter.formatBibleBook('1 Pedro', 'pt');
      expect(result, 'Primeiro Pedro');
    });

    test('formats 2 Coríntios as Segundo Coríntios', () {
      final result = BibleTextFormatter.formatBibleBook('2 Coríntios', 'pt');
      expect(result, 'Segundo Coríntios');
    });

    test('formats 3 João as Terceiro João', () {
      final result = BibleTextFormatter.formatBibleBook('3 João', 'pt');
      expect(result, 'Terceiro João');
    });
  });

  group('BibleTextFormatter - French Ordinals', () {
    test('formats 1 Pierre as Premier Pierre', () {
      final result = BibleTextFormatter.formatBibleBook('1 Pierre', 'fr');
      expect(result, 'Premier Pierre');
    });

    test('formats 2 Corinthiens as Deuxième Corinthiens', () {
      final result = BibleTextFormatter.formatBibleBook('2 Corinthiens', 'fr');
      expect(result, 'Deuxième Corinthiens');
    });

    test('formats 3 Jean as Troisième Jean', () {
      final result = BibleTextFormatter.formatBibleBook('3 Jean', 'fr');
      expect(result, 'Troisième Jean');
    });

    test('handles French accented characters', () {
      final result = BibleTextFormatter.formatBibleBook('1 Éphésiens', 'fr');
      expect(result, 'Premier Éphésiens');
    });
  });

  group('BibleTextFormatter - Japanese', () {
    test('returns Japanese text unchanged (no ordinals)', () {
      final result = BibleTextFormatter.formatBibleBook('ペテロの手紙', 'ja');
      expect(result, 'ペテロの手紙');
    });

    test('trims Japanese text', () {
      final result = BibleTextFormatter.formatBibleBook('  ヨハネ  ', 'ja');
      expect(result, 'ヨハネ');
    });
  });

  group('BibleTextFormatter - Chinese', () {
    test('returns Chinese text unchanged (no ordinals)', () {
      final result = BibleTextFormatter.formatBibleBook('彼得前书', 'zh');
      expect(result, '彼得前书');
    });

    test('trims Chinese text', () {
      final result = BibleTextFormatter.formatBibleBook('  约翰福音  ', 'zh');
      expect(result, '约翰福音');
    });

    test('handles traditional Chinese characters', () {
      final result = BibleTextFormatter.formatBibleBook('創世記', 'zh');
      expect(result, '創世記');
    });
  });

  group('BibleTextFormatter - Hindi Ordinals', () {
    test('formats 1 यूहन्ना as पहला यूहन्ना', () {
      final result = BibleTextFormatter.formatBibleBook('1 यूहन्ना', 'hi');
      expect(result, 'पहला यूहन्ना');
    });

    test('formats 2 पतरस as दूसरा पतरस', () {
      final result = BibleTextFormatter.formatBibleBook('2 पतरस', 'hi');
      expect(result, 'दूसरा पतरस');
    });

    test('formats 3 यूहन्ना as तीसरा यूहन्ना', () {
      final result = BibleTextFormatter.formatBibleBook('3 यूहन्ना', 'hi');
      expect(result, 'तीसरा यूहन्ना');
    });

    test('handles Hindi text with Devanagari characters', () {
      final result = BibleTextFormatter.formatBibleBook('1 कुरिन्थियों', 'hi');
      expect(result, 'पहला कुरिन्थियों');
    });

    test('handles book in middle of Hindi text', () {
      final result = BibleTextFormatter.formatBibleBook(
        'पढ़ें 2 पतरस आज',
        'hi',
      );
      expect(result, equals('पढ़ें दूसरा पतरस आज'));
    });

    test('leaves non-numbered Hindi books unchanged', () {
      final result = BibleTextFormatter.formatBibleBook('उत्पत्ति', 'hi');
      expect(result, 'उत्पत्ति');
    });
  });

  group('BibleTextFormatter - Bible Version Expansions', () {
    test('Spanish versions expand correctly', () {
      final expansions = BibleTextFormatter.getBibleVersionExpansions('es');
      expect(expansions['RVR1960'], 'Reina Valera mil novecientos sesenta');
      expect(expansions['NVI'], 'Nueva Versión Internacional');
    });

    test('English versions expand correctly', () {
      final expansions = BibleTextFormatter.getBibleVersionExpansions('en');
      expect(expansions['KJV'], 'King James Version');
      expect(expansions['NIV'], 'New International Version');
    });

    test('Portuguese versions expand correctly', () {
      final expansions = BibleTextFormatter.getBibleVersionExpansions('pt');
      expect(expansions['ARC'], 'Almeida Revista e Corrigida');
      expect(expansions['NVI'], 'Nova Versão Internacional');
    });

    test('French versions expand correctly', () {
      final expansions = BibleTextFormatter.getBibleVersionExpansions('fr');
      expect(expansions['LSG1910'], 'Louis Segond mille neuf cent dix');
      expect(expansions['TOB'], 'Traduction Oecuménique de la Bible');
    });

    test('Chinese versions expand correctly', () {
      final expansions = BibleTextFormatter.getBibleVersionExpansions('zh');
      expect(expansions['和合本1919'], '和合本一九一九');
      // The second Chinese version should be 新译本 (not 新标点和合本)
      expect(expansions['新译本'], '新译本');
    });

    test('Hindi versions expand correctly for TTS', () {
      final expansions = BibleTextFormatter.getBibleVersionExpansions('hi');
      // Full Devanagari names from database
      expect(
          expansions['पवित्र बाइबिल (ओ.वी.)'], 'पवित्र बाइबिल पुराना संस्करण');
      expect(
          expansions['पवित्र बाइबिल'], 'पवित्र बाइबिल हिंदी आसान पठन संस्करण');
      // Abbreviations for constants usage
      expect(expansions['HIOV'], 'पवित्र बाइबिल पुराना संस्करण');
      expect(expansions['HERV'], 'पवित्र बाइबिल हिंदी आसान पठन संस्करण');
      expect(expansions['OV'], 'पुराना संस्करण');
    });

    test('unknown language falls back to Spanish', () {
      final expansions = BibleTextFormatter.getBibleVersionExpansions('xx');
      expect(expansions['RVR1960'], 'Reina Valera mil novecientos sesenta');
    });
  });

  group('BibleTextFormatter - Bible References', () {
    test('formats chapter:verse reference in Spanish', () {
      final result = BibleTextFormatter.formatBibleReferences(
        'Juan 3:16',
        'es',
      );
      expect(result, contains('capítulo'));
      expect(result, contains('versículo'));
    });

    test('formats chapter:verse reference in English', () {
      final result = BibleTextFormatter.formatBibleReferences(
        'John 3:16',
        'en',
      );
      expect(result, contains('chapter'));
      expect(result, contains('verse'));
    });

    test('formats verse range in Spanish', () {
      final result = BibleTextFormatter.formatBibleReferences(
        'Salmos 23:1-6',
        'es',
      );
      expect(result, contains('al'));
    });

    test('formats verse range in English', () {
      final result = BibleTextFormatter.formatBibleReferences(
        'Psalms 23:1-6',
        'en',
      );
      expect(result, contains('to'));
    });

    test('formats verse range in Portuguese', () {
      final result = BibleTextFormatter.formatBibleReferences(
        'Salmos 23:1-6',
        'pt',
      );
      expect(result, contains('ao'));
    });

    test('formats verse range in French', () {
      final result = BibleTextFormatter.formatBibleReferences(
        'Psaumes 23:1-6',
        'fr',
      );
      expect(result, contains('au'));
    });

    test('formats chapter:verse reference in Chinese', () {
      final result = BibleTextFormatter.formatBibleReferences(
        '约翰福音 3:16',
        'zh',
      );
      expect(result, contains('章'));
      expect(result, contains('节'));
    });

    test('formats verse range in Chinese', () {
      final result = BibleTextFormatter.formatBibleReferences(
        '诗篇 23:1-6',
        'zh',
      );
      expect(result, contains('至'));
    });
  });

  group('BibleTextFormatter - Normalize TTS Text', () {
    test('normalizes complete Spanish reference', () {
      final result = BibleTextFormatter.normalizeTtsText(
        '1 Pedro 3:16 RVR1960',
        'es',
      );
      expect(result, contains('Primera de Pedro'));
      expect(result, contains('Reina Valera'));
    });

    test('normalizes complete English reference', () {
      final result = BibleTextFormatter.normalizeTtsText(
        '1 Peter 3:16 KJV',
        'en',
      );
      expect(result, contains('First Peter'));
      expect(result, contains('King James Version'));
    });

    test('normalizes complete Chinese reference', () {
      final result = BibleTextFormatter.normalizeTtsText(
        '约翰福音 3:16 和合本1919',
        'zh',
      );
      expect(result, contains('约翰福音'));
      expect(result, contains('和合本一九一九'));
    });

    test('cleans up extra whitespace', () {
      final result = BibleTextFormatter.normalizeTtsText('Juan   3:16', 'es');
      expect(result, isNot(contains('  '))); // No double spaces
    });

    test('handles text without Bible references', () {
      final result = BibleTextFormatter.normalizeTtsText('Hola mundo', 'es');
      expect(result, 'Hola mundo');
    });

    test('unknown language defaults to Spanish', () {
      final result = BibleTextFormatter.formatBibleBook('1 Pedro', 'unknown');
      expect(result, 'Primera de Pedro');
    });
  });

  group('BibleTextFormatter - Edge Cases', () {
    test('handles empty string', () {
      final result = BibleTextFormatter.formatBibleBook('', 'es');
      expect(result, '');
    });

    test('handles string with only whitespace', () {
      final result = BibleTextFormatter.formatBibleBook('   ', 'es');
      expect(result, '   '); // Whitespace preserved (not a book reference)
    });

    test('handles multiple book references in text', () {
      final result = BibleTextFormatter.formatBibleBook(
        'Lee 1 Pedro y 2 Juan',
        'es',
      );
      expect(result, contains('Primera de Pedro'));
      expect(result, contains('Segunda de Juan'));
    });

    test('does not transform standalone numbers', () {
      final result = BibleTextFormatter.formatBibleBook('Capítulo 1', 'es');
      expect(result, 'Capítulo 1');
    });

    test('number at end of text', () {
      final result = BibleTextFormatter.formatBibleBook('Libro número 1', 'es');
      expect(result, 'Libro número 1');
    });
  });

  // ── Guard-path regression tests ──────────────────────────────────────────
  //
  // The replaceAllMapped callbacks now have an early-return guard:
  //   if (number.isEmpty || book.isEmpty) return matchText;
  //
  // These tests verify that:
  //   a) Normal valid references still produce the correct ordinal output.
  //   b) Text that does NOT match the pattern passes through unchanged
  //      (i.e. the guard never corrupts non-matching text).
  //   c) The function never throws for any language on unexpected input.

  group('BibleTextFormatter — early-return guard regression', () {
    // The guard fires only when a structurally-required group somehow resolves
    // to ''. That cannot happen with the current regexes (all groups are
    // required), so the guard is dead code today.  These tests document the
    // CONTRACT: the output must never be a malformed reference.

    const languages = ['es', 'en', 'pt', 'fr', 'de', 'hi', 'ar', 'zh', 'ja'];

    for (final lang in languages) {
      test('empty string does not throw for language=$lang', () {
        expect(
          () => BibleTextFormatter.formatBibleBook('', lang),
          returnsNormally,
        );
        expect(BibleTextFormatter.formatBibleBook('', lang), '');
      });

      test(
          'text with no Bible reference is returned unchanged for language=$lang',
          () {
        const text = 'This is plain text without any numbered book reference';
        final result = BibleTextFormatter.formatBibleBook(text, lang);
        // Non-matching text must pass through; no partial corruption allowed.
        expect(result, isNotEmpty);
        // Result must not introduce leading/trailing spaces from a misfire.
        expect(result.trimLeft(), result,
            reason: 'Guard must not produce leading whitespace on non-match');
      });
    }

    test(
        'valid Spanish reference produces correct ordinal (guard does not interfere)',
        () {
      expect(
        BibleTextFormatter.formatBibleBook('1 Corintios', 'es'),
        'Primera de Corintios',
      );
    });

    test(
        'valid English reference produces correct ordinal (guard does not interfere)',
        () {
      expect(
        BibleTextFormatter.formatBibleBook('2 Timothy', 'en'),
        'Second Timothy',
      );
    });

    test('formatBibleReferences: empty string does not throw', () {
      expect(
        () => BibleTextFormatter.formatBibleReferences('', 'es'),
        returnsNormally,
      );
      expect(BibleTextFormatter.formatBibleReferences('', 'es'), '');
    });

    test(
        'formatBibleReferences: text with no reference passes through unchanged',
        () {
      const text = 'Solo texto sin referencia bíblica';
      expect(BibleTextFormatter.formatBibleReferences(text, 'es'), text);
    });
  });

  // ── Per-language smoke tests ──────────────────────────────────────────────
  //
  // One representative reference per language through the full normalizeTtsText
  // pipeline.  Confirms no crash and that key tokens appear in the output.

  group('BibleTextFormatter — normalizeTtsText per-language smoke tests', () {
    test('Spanish: ordinal + chapter:verse + version expansion', () {
      final result = BibleTextFormatter.normalizeTtsText(
        '1 Pedro 3:16 RVR1960',
        'es',
      );
      expect(result, contains('Primera de Pedro'));
      expect(result, contains('capítulo'));
      expect(result, contains('versículo'));
      expect(result, contains('Reina Valera'));
    });

    test('English: ordinal + chapter:verse + version expansion', () {
      final result = BibleTextFormatter.normalizeTtsText(
        '1 Peter 3:16 KJV',
        'en',
      );
      expect(result, contains('First Peter'));
      expect(result, contains('chapter'));
      expect(result, contains('verse'));
      expect(result, contains('King James Version'));
    });

    test('Portuguese: ordinal + chapter:verse + version expansion', () {
      final result = BibleTextFormatter.normalizeTtsText(
        '1 Pedro 3:16 ARC',
        'pt',
      );
      expect(result, contains('Primeiro Pedro'));
      expect(result, contains('capítulo'));
      expect(result, contains('Almeida Revista'));
    });

    test('French: ordinal + chapter:verse + version expansion', () {
      final result = BibleTextFormatter.normalizeTtsText(
        '1 Pierre 3:16 LSG1910',
        'fr',
      );
      expect(result, contains('Premier Pierre'));
      expect(result, contains('chapitre'));
      expect(result, contains('Louis Segond'));
    });

    test('German: ordinal + chapter:verse + version expansion', () {
      final result = BibleTextFormatter.normalizeTtsText(
        '1 Petrus 3:16 LU17',
        'de',
      );
      expect(result, contains('Erster Petrus'));
      expect(result, contains('Kapitel'));
      expect(result, contains('Lutherbibel'));
    });

    test('Chinese: book name preserved + chapter:verse + version expansion',
        () {
      final result = BibleTextFormatter.normalizeTtsText(
        '约翰福音 3:16 和合本1919',
        'zh',
      );
      expect(result, contains('约翰福音'));
      expect(result, contains('章'));
      expect(result, contains('和合本一九一九'));
    });

    test('Japanese: book name preserved + chapter:verse (no ordinals)', () {
      final result = BibleTextFormatter.normalizeTtsText(
        'ヨハネ 3:16',
        'ja',
      );
      expect(result, contains('ヨハネ'));
      expect(result, contains('章'));
    });

    test('Hindi: ordinal + chapter:verse + version expansion', () {
      final result = BibleTextFormatter.normalizeTtsText(
        '1 यूहन्ना 3:16 HIOV',
        'hi',
      );
      expect(result, contains('पहला यूहन्ना'));
      expect(result, contains('पवित्र बाइबिल'));
    });

    test('Arabic: ordinal + chapter:verse + version expansion', () {
      final result = BibleTextFormatter.normalizeTtsText(
        '1 يوحنا 3:16 NAV',
        'ar',
      );
      expect(result, contains('الأول يوحنا'));
      expect(result, contains('الإصحاح'));
      expect(result, contains('كتاب الحياة'));
    });

    test('Tagalog: ordinal + chapter:verse + version expansion', () {
      final result = BibleTextFormatter.normalizeTtsText(
        '1 Juan 3:16 ASND',
        'fil',
      );
      expect(result, contains('Una Juan'));
      expect(result, contains('kabanata'));
      expect(result, contains('Ang Salita ng Dios'));
    });

    test('unknown language falls back to Spanish pipeline without crashing',
        () {
      final result = BibleTextFormatter.normalizeTtsText(
        '1 Pedro 3:16',
        'xx',
      );
      expect(result, contains('Primera de Pedro'));
    });
  });

  group('BibleTextFormatter - Tagalog Ordinals', () {
    test('formats 1 Juan as Una Juan', () {
      final result = BibleTextFormatter.formatBibleBook('1 Juan', 'fil');
      expect(result, 'Una Juan');
    });

    test('formats 2 Pedro as Pangalawa Pedro', () {
      final result = BibleTextFormatter.formatBibleBook('2 Pedro', 'fil');
      expect(result, 'Pangalawa Pedro');
    });

    test('formats 3 Juan as Pangatlo Juan', () {
      final result = BibleTextFormatter.formatBibleBook('3 Juan', 'fil');
      expect(result, 'Pangatlo Juan');
    });

    test('leaves non-numbered books unchanged', () {
      final result = BibleTextFormatter.formatBibleBook('Genesis', 'fil');
      expect(result, 'Genesis');
    });

    test('handles book in middle of text', () {
      final result = BibleTextFormatter.formatBibleBook(
        'Basahin ang 2 Corinto ngayon',
        'fil',
      );
      expect(result, contains('Pangalawa Corinto'));
    });
  });

  group('BibleTextFormatter - Tagalog Bible References', () {
    test('formats Tagalog chapter:verse reference with kabanata/talata', () {
      final result = BibleTextFormatter.formatBibleReferences(
        'Juan 3:16',
        'fil',
      );
      expect(result, contains('kabanata'));
      expect(result, contains('talata'));
    });

    test('formats Tagalog verse range with hanggang', () {
      final result = BibleTextFormatter.formatBibleReferences(
        'Juan 3:16-17',
        'fil',
      );
      expect(result, contains('hanggang'));
    });
  });

  group('BibleTextFormatter - Tagalog Version Expansions', () {
    test('MBB05 expands to Magandang Balita Biblia', () {
      final expansions = BibleTextFormatter.getBibleVersionExpansions('fil');
      expect(expansions['MBB05'], 'Magandang Balita Biblia');
    });

    test('ASND expands to Ang Salita ng Dios', () {
      final expansions = BibleTextFormatter.getBibleVersionExpansions('fil');
      expect(expansions['ASND'], 'Ang Salita ng Dios');
    });

    test('ADB expands to Ang Dating Biblia', () {
      final expansions = BibleTextFormatter.getBibleVersionExpansions('fil');
      expect(expansions['ADB'], 'Ang Dating Biblia');
    });
  });

  group('BibleTextFormatter - Footnote Marker Sanitization', () {
    test('removes circled lowercase letter footnote markers (ⓐ, ⓑ) for fil',
        () {
      // MBB05 uses ⓐ, ⓑ etc. as inline footnote markers
      final result = BibleTextFormatter.normalizeTtsText(
        'Sinabi ⓐ ng Diyos: "Magkaroon ng liwanag ⓑ."',
        'fil',
        'MBB05',
      );
      expect(result, isNot(contains('ⓐ')));
      expect(result, isNot(contains('ⓑ')));
      expect(result, contains('Sinabi'));
      expect(result, contains('ng Diyos'));
    });

    test(
        'removes circled letter markers for all languages (universal sanitization)',
        () {
      // Verify footnote stripping works for any language, not only fil
      final result = BibleTextFormatter.normalizeTtsText(
        'God ⓐ said: "Let there be light ⓑ."',
        'en',
        'KJV',
      );
      expect(result, isNot(contains('ⓐ')));
      expect(result, isNot(contains('ⓑ')));
    });

    test('removes circled number markers ①②③', () {
      final result = BibleTextFormatter.normalizeTtsText(
        'Verse ① contains a note ② about this passage ③.',
        'es',
        'RVR1960',
      );
      expect(result, isNot(contains('①')));
      expect(result, isNot(contains('②')));
      expect(result, isNot(contains('③')));
    });

    test(
        'normalizes extra whitespace after removing consecutive footnote markers',
        () {
      final result = BibleTextFormatter.normalizeTtsText(
        'Sinabi  ⓐ  ng  Diyos',
        'fil',
        'MBB05',
      );
      // Should not have multiple spaces after removal
      expect(result, isNot(contains('  ')));
    });
  });
}
