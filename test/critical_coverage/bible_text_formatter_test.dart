@Tags(['critical', 'bloc'])
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

    test('handles number at end of text', () {
      final result = BibleTextFormatter.formatBibleBook('Libro número 1', 'es');
      expect(result, 'Libro número 1');
    });
  });
}
