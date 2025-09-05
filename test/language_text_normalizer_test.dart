import 'package:devocional_nuevo/services/tts/language_text_normalizer_backup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Language Text Normalizer Tests', () {
    test('should return correct ordinals for Spanish', () {
      expect(LanguageTextNormalizer.getOrdinal(1, 'es'), equals('primero'));
      expect(LanguageTextNormalizer.getOrdinal(2, 'es'), equals('segundo'));
      expect(LanguageTextNormalizer.getOrdinal(3, 'es'), equals('tercero'));
      expect(LanguageTextNormalizer.getOrdinal(4, 'es'), equals('cuarto'));
      expect(LanguageTextNormalizer.getOrdinal(5, 'es'), equals('quinto'));
      expect(LanguageTextNormalizer.getOrdinal(10, 'es'), equals('número 10'));
    });

    test('should return correct ordinals for English', () {
      expect(LanguageTextNormalizer.getOrdinal(1, 'en'), equals('first'));
      expect(LanguageTextNormalizer.getOrdinal(2, 'en'), equals('second'));
      expect(LanguageTextNormalizer.getOrdinal(3, 'en'), equals('third'));
      expect(LanguageTextNormalizer.getOrdinal(4, 'en'), equals('fourth'));
      expect(LanguageTextNormalizer.getOrdinal(5, 'en'), equals('fifth'));
      expect(LanguageTextNormalizer.getOrdinal(10, 'en'), equals('number 10'));
    });

    test('should return correct ordinals for Portuguese', () {
      expect(LanguageTextNormalizer.getOrdinal(1, 'pt'), equals('primeiro'));
      expect(LanguageTextNormalizer.getOrdinal(2, 'pt'), equals('segundo'));
      expect(LanguageTextNormalizer.getOrdinal(3, 'pt'), equals('terceiro'));
      expect(LanguageTextNormalizer.getOrdinal(4, 'pt'), equals('quarto'));
      expect(LanguageTextNormalizer.getOrdinal(5, 'pt'), equals('quinto'));
      expect(LanguageTextNormalizer.getOrdinal(10, 'pt'), equals('número 10'));
    });

    test('should return correct ordinals for French', () {
      expect(LanguageTextNormalizer.getOrdinal(1, 'fr'), equals('premier'));
      expect(LanguageTextNormalizer.getOrdinal(2, 'fr'), equals('deuxième'));
      expect(LanguageTextNormalizer.getOrdinal(3, 'fr'), equals('troisième'));
      expect(LanguageTextNormalizer.getOrdinal(4, 'fr'), equals('quatrième'));
      expect(LanguageTextNormalizer.getOrdinal(5, 'fr'), equals('cinquième'));
      expect(LanguageTextNormalizer.getOrdinal(10, 'fr'), equals('numéro 10'));
    });

    test('should format ordinal numbers in text', () {
      expect(
          LanguageTextNormalizer.formatOrdinalNumbers('El 1º capítulo', 'es'),
          equals('El primero capítulo'));
      expect(
          LanguageTextNormalizer.formatOrdinalNumbers('The 1° chapter', 'en'),
          equals('The first chapter'));
      expect(LanguageTextNormalizer.formatOrdinalNumbers('O 1ª capítulo', 'pt'),
          equals('O primeiro capítulo'));
      expect(
          LanguageTextNormalizer.formatOrdinalNumbers('Le 1° chapitre', 'fr'),
          equals('Le premier chapitre'));
    });

    test('should apply language-specific normalizations for English', () {
      final result = LanguageTextNormalizer.applyLanguageSpecificNormalizations(
          'versiculo: reflexion: vs. vv.', 'en');
      expect(result, contains('Verse:'));
      expect(result, contains('Reflection:'));
      expect(result, contains('verse'));
      expect(result, contains('verses'));
    });

    test('should apply language-specific normalizations for Portuguese', () {
      final result = LanguageTextNormalizer.applyLanguageSpecificNormalizations(
          'vs. vv. cap. caps.', 'pt');
      expect(result, contains('versículo'));
      expect(result, contains('versículos'));
      expect(result, contains('capítulo'));
      expect(result, contains('capítulos'));
    });

    test('should apply language-specific normalizations for French', () {
      final result = LanguageTextNormalizer.applyLanguageSpecificNormalizations(
          'vs. vv. ch. chs.', 'fr');
      expect(result, contains('verset'));
      expect(result, contains('versets'));
      expect(result, contains('chapitre'));
      expect(result, contains('chapitres'));
    });

    test('should apply abbreviations correctly for each language', () {
      // Test Spanish abbreviations
      String result = LanguageTextNormalizer.applyAbbreviations(
          'vs. vv. etc. p.ej. a.C. d.C.', 'es');
      expect(result, contains('versículo'));
      expect(result, contains('versículos'));
      expect(result, contains('etcétera'));
      expect(result, contains('por ejemplo'));
      expect(result, contains('antes de Cristo'));
      expect(result, contains('después de Cristo'));

      // Test English abbreviations
      result = LanguageTextNormalizer.applyAbbreviations(
          'vs. vv. etc. e.g. B.C. A.D.', 'en');
      expect(result, contains('verse'));
      expect(result, contains('verses'));
      expect(result, contains('et cetera'));
      expect(result, contains('for example'));
      expect(result, contains('before Christ'));
      expect(result, contains('anno domini'));
    });

    test('should default to Spanish for unknown languages', () {
      expect(
          LanguageTextNormalizer.getOrdinal(1, 'unknown'), equals('primero'));

      final result =
          LanguageTextNormalizer.applyAbbreviations('etc. p.ej.', 'unknown');
      expect(result, contains('etcétera'));
      expect(result, contains('por ejemplo'));
    });
  });
}
