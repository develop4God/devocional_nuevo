import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bible Text Formatter Tests', () {
    test('should format Bible books correctly for all supported languages', () {
      // Test Spanish
      expect(BibleTextFormatter.formatBibleBook('1 Juan', 'es'),
          contains('Primera de Juan'));
      expect(BibleTextFormatter.formatBibleBook('2 Corintios', 'es'),
          contains('Segunda de Corintios'));
      expect(BibleTextFormatter.formatBibleBook('3 Juan', 'es'),
          contains('Tercera de Juan'));
      expect(BibleTextFormatter.formatBibleBook('Génesis', 'es'),
          equals('Génesis'));

      // Test English
      expect(BibleTextFormatter.formatBibleBook('1 John', 'en'),
          contains('First John'));
      expect(BibleTextFormatter.formatBibleBook('2 Corinthians', 'en'),
          contains('Second Corinthians'));
      expect(BibleTextFormatter.formatBibleBook('3 John', 'en'),
          contains('Third John'));
      expect(BibleTextFormatter.formatBibleBook('Genesis', 'en'),
          equals('Genesis'));

      // Test Portuguese
      expect(BibleTextFormatter.formatBibleBook('1 João', 'pt'),
          contains('Primeiro João'));
      expect(BibleTextFormatter.formatBibleBook('2 Coríntios', 'pt'),
          contains('Segundo Coríntios'));
      expect(BibleTextFormatter.formatBibleBook('3 João', 'pt'),
          contains('Terceiro João'));
      expect(BibleTextFormatter.formatBibleBook('Gênesis', 'pt'),
          equals('Gênesis'));

      // Test French
      expect(BibleTextFormatter.formatBibleBook('1 Jean', 'fr'),
          contains('Premier Jean'));
      expect(BibleTextFormatter.formatBibleBook('2 Corinthiens', 'fr'),
          contains('Deuxième Corinthiens'));
      expect(BibleTextFormatter.formatBibleBook('3 Jean', 'fr'),
          contains('Troisième Jean'));
      expect(
          BibleTextFormatter.formatBibleBook('Genèse', 'fr'), equals('Genèse'));
    });

    test('should return Bible version expansions for all languages', () {
      // Test Spanish expansions
      final spanishExpansions =
          BibleTextFormatter.getBibleVersionExpansions('es');
      expect(spanishExpansions['RVR1960'],
          equals('Reina Valera mil novecientos sesenta'));
      expect(spanishExpansions['NVI'], equals('Nueva Versión Internacional'));

      // Test English expansions
      final englishExpansions =
          BibleTextFormatter.getBibleVersionExpansions('en');
      expect(englishExpansions['KJV'], equals('King James Version'));
      expect(englishExpansions['NIV'], equals('New International Version'));

      // Test Portuguese expansions
      final portugueseExpansions =
          BibleTextFormatter.getBibleVersionExpansions('pt');
      expect(
          portugueseExpansions['ARC'], equals('Almeida Revista e Corrigida'));
      expect(portugueseExpansions['NVI'], equals('Nova Versão Internacional'));

      // Test French expansions
      final frenchExpansions =
          BibleTextFormatter.getBibleVersionExpansions('fr');
      expect(frenchExpansions['LSG1910'],
          equals('Louis Segond mille neuf cent dix'));
      expect(frenchExpansions['TOB'],
          equals('Traduction Oecuménique de la Bible'));
    });

    test('should default to Spanish for unknown languages', () {
      expect(BibleTextFormatter.formatBibleBook('1 Juan', 'unknown'),
          contains('Primera de Juan'));
      final expansions =
          BibleTextFormatter.getBibleVersionExpansions('unknown');
      expect(expansions['RVR1960'],
          equals('Reina Valera mil novecientos sesenta'));
    });
  });
}
