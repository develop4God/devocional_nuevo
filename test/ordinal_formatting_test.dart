import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bible Text Formatter Tests', () {
    test('should format Spanish ordinals correctly', () {
      expect(BibleTextFormatter.formatBibleBook('1 Juan', 'es'), contains('Primera de Juan'));
      expect(BibleTextFormatter.formatBibleBook('2 Corintios', 'es'),
          contains('Segunda de Corintios'));
      expect(BibleTextFormatter.formatBibleBook('3 Juan', 'es'), contains('Tercera de Juan'));
      expect(BibleTextFormatter.formatBibleBook('Génesis', 'es'),
          equals('Génesis')); // No ordinal change
    });

    test('should format English ordinals correctly', () {
      expect(BibleTextFormatter.formatBibleBook('1 John', 'en'), contains('First John'));
      expect(BibleTextFormatter.formatBibleBook('2 Corinthians', 'en'),
          contains('Second Corinthians'));
      expect(BibleTextFormatter.formatBibleBook('3 John', 'en'), contains('Third John'));
      expect(BibleTextFormatter.formatBibleBook('Genesis', 'en'),
          equals('Genesis')); // No ordinal change
    });

    test('should format Portuguese ordinals correctly', () {
      expect(BibleTextFormatter.formatBibleBook('1 João', 'pt'), contains('Primeiro João'));
      expect(BibleTextFormatter.formatBibleBook('2 Coríntios', 'pt'),
          contains('Segundo Coríntios'));
      expect(BibleTextFormatter.formatBibleBook('3 João', 'pt'), contains('Terceiro João'));
      expect(BibleTextFormatter.formatBibleBook('Gênesis', 'pt'),
          equals('Gênesis')); // No ordinal change
    });

    test('should format French ordinals correctly', () {
      expect(BibleTextFormatter.formatBibleBook('1 Jean', 'fr'),
          contains('Premier'));
      expect(BibleTextFormatter.formatBibleBook('2 Corinthiens', 'fr'),
          contains('Deuxième'));
      expect(BibleTextFormatter.formatBibleBook('3 Jean', 'fr'),
          contains('Troisième'));
      expect(BibleTextFormatter.formatBibleBook('Genèse', 'fr'),
          equals('Genèse')); // No ordinal change
    });

    test('should handle edge cases and invalid input gracefully', () {
      // Empty string
      expect(BibleTextFormatter.formatBibleBook('', 'es'), equals(''));

      // Numbers without proper format
      expect(BibleTextFormatter.formatBibleBook('4 Juan', 'es'), equals('4 Juan'));

      // Non-existing books (should still apply ordinal format)
      expect(BibleTextFormatter.formatBibleBook('1 Invented', 'es'), contains('Primera de'));

      // Whitespace handling
      expect(BibleTextFormatter.formatBibleBook('  1 Juan  ', 'es'),
          equals('  1 Juan  ')); // Leading/trailing whitespace should be preserved if pattern doesn't match at start
    });

    test('should default to Spanish for unknown languages', () {
      expect(BibleTextFormatter.formatBibleBook('1 Juan', 'xx'), contains('Primera de Juan'));
    });
  });
}