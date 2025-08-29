import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';

void main() {
  group('Bible Text Formatter Tests', () {
    test('should format Spanish Bible books correctly', () {
      expect(BibleTextFormatter.formatBibleBook('1 Juan', 'es'), contains('Primera de Juan'));
      expect(BibleTextFormatter.formatBibleBook('2 Corintios', 'es'), contains('Segunda de Corintios'));
      expect(BibleTextFormatter.formatBibleBook('3 Juan', 'es'), contains('Tercera de Juan'));
      expect(BibleTextFormatter.formatBibleBook('Génesis', 'es'), equals('Génesis'));
    });

    test('should format English Bible books correctly', () {
      expect(BibleTextFormatter.formatBibleBook('1 John', 'en'), contains('First John'));
      expect(BibleTextFormatter.formatBibleBook('2 Corinthians', 'en'), contains('Second Corinthians'));
      expect(BibleTextFormatter.formatBibleBook('3 John', 'en'), contains('Third John'));
      expect(BibleTextFormatter.formatBibleBook('Genesis', 'en'), equals('Genesis'));
    });

    test('should format Portuguese Bible books correctly', () {
      expect(BibleTextFormatter.formatBibleBook('1 João', 'pt'), contains('Primeiro João'));
      expect(BibleTextFormatter.formatBibleBook('2 Coríntios', 'pt'), contains('Segundo Coríntios'));
      expect(BibleTextFormatter.formatBibleBook('3 João', 'pt'), contains('Terceiro João'));
      expect(BibleTextFormatter.formatBibleBook('Gênesis', 'pt'), equals('Gênesis'));
    });

    test('should format French Bible books correctly', () {
      expect(BibleTextFormatter.formatBibleBook('1 Jean', 'fr'), contains('Premier Jean'));
      expect(BibleTextFormatter.formatBibleBook('2 Corinthiens', 'fr'), contains('Deuxième Corinthiens'));
      expect(BibleTextFormatter.formatBibleBook('3 Jean', 'fr'), contains('Troisième Jean'));
      expect(BibleTextFormatter.formatBibleBook('Genèse', 'fr'), equals('Genèse'));
    });

    test('should return Spanish Bible version expansions', () {
      final expansions = BibleTextFormatter.getBibleVersionExpansions('es');
      expect(expansions['RVR1960'], equals('Reina Valera mil novecientos sesenta'));
      expect(expansions['NVI'], equals('Nueva Versión Internacional'));
      expect(expansions['TLA'], equals('Traducción en Lenguaje Actual'));
    });

    test('should return English Bible version expansions', () {
      final expansions = BibleTextFormatter.getBibleVersionExpansions('en');
      expect(expansions['KJV'], equals('King James Version'));
      expect(expansions['NIV'], equals('New International Version'));
    });

    test('should return Portuguese Bible version expansions', () {
      final expansions = BibleTextFormatter.getBibleVersionExpansions('pt');
      expect(expansions['ARC'], equals('Almeida Revista e Corrigida'));
      expect(expansions['NVI'], equals('Nova Versão Internacional'));
    });

    test('should return French Bible version expansions', () {
      final expansions = BibleTextFormatter.getBibleVersionExpansions('fr');
      expect(expansions['LSG1910'], equals('Louis Segond mil nove cento e dez'));
      expect(expansions['TOB'], equals('Traduction Oecuménique de la Bible'));
    });

    test('should default to Spanish for unknown languages', () {
      expect(BibleTextFormatter.formatBibleBook('1 Juan', 'unknown'), contains('Primera de Juan'));
      final expansions = BibleTextFormatter.getBibleVersionExpansions('unknown');
      expect(expansions['RVR1960'], equals('Reina Valera mil novecientos sesenta'));
    });
  });
}