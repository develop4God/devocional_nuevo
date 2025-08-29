import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/services/tts_text_normalizer_service.dart';

void main() {
  group('TTS Comprehensive Language Tests', () {
    late TtsTextNormalizerService textNormalizer;

    setUp(() {
      textNormalizer = TtsTextNormalizerService();
    });

    test('Spanish: Complete functionality test', () async {
      SharedPreferences.setMockInitialValues({'tts_language': 'es-US'});

      // Test ordinals
      final ordinals = await textNormalizer.normalizeTtsText('1º 2º 3º lugar');
      expect(ordinals, equals('primero segundo tercero lugar'));

      // Test Bible versions  
      final bibleVersions = await textNormalizer.normalizeTtsText('RVR1960 y NVI son traducciones');
      expect(bibleVersions, contains('Reina Valera mil novecientos sesenta'));
      expect(bibleVersions, contains('Nueva Versión Internacional'));

      // Test Bible book formatting
      final bibleBook = textNormalizer.formatBibleBook('1 Corintios 13:1', 'es');
      expect(bibleBook, equals('Primera de Corintios 13:1'));

      // Test abbreviations
      final abbreviations = await textNormalizer.normalizeTtsText('vs. 1 y vv. 2-3 del cap. 1');
      expect(abbreviations, contains('versículo 1'));
      expect(abbreviations, contains('versículos 2-3'));
      expect(abbreviations, contains('capítulo 1'));
    });

    test('English: Complete functionality test', () async {
      SharedPreferences.setMockInitialValues({'tts_language': 'en-US'});

      // Test ordinals
      final ordinals = await textNormalizer.normalizeTtsText('1º 2º 3º place');
      expect(ordinals, equals('first second third place'));

      // Test Bible versions
      final bibleVersions = await textNormalizer.normalizeTtsText('KJV and NIV are translations');
      expect(bibleVersions, contains('King James Version'));
      expect(bibleVersions, contains('New International Version'));

      // Test Bible book formatting
      final bibleBook = textNormalizer.formatBibleBook('1 Corinthians 13:1', 'en');
      expect(bibleBook, equals('First Corinthians 13:1'));

      // Test abbreviations
      final abbreviations = await textNormalizer.normalizeTtsText('vs. 1 and vv. 2-3 of ch. 1');
      expect(abbreviations, contains('verse 1'));
      expect(abbreviations, contains('verses 2-3'));
      expect(abbreviations, contains('chapter 1'));
    });

    test('French: Complete functionality test', () async {
      SharedPreferences.setMockInitialValues({'tts_language': 'fr-FR'});

      // Test ordinals
      final ordinals = await textNormalizer.normalizeTtsText('1º 2º 3º place');
      expect(ordinals, equals('premier deuxième troisième place'));

      // Test Bible versions
      final bibleVersions = await textNormalizer.normalizeTtsText('LSG et NEG sont des traductions');
      expect(bibleVersions, contains('Louis Segond'));
      expect(bibleVersions, contains('Nouvelle Edition de Genève'));

      // Test Bible book formatting  
      final bibleBook = textNormalizer.formatBibleBook('1 Corinthiens 13:1', 'fr');
      expect(bibleBook, equals('Premier Corinthiens 13:1'));

      // Test abbreviations
      final abbreviations = await textNormalizer.normalizeTtsText('vs. 1 et vv. 2-3 du ch. 1');
      expect(abbreviations, contains('verset 1'));
      expect(abbreviations, contains('versets 2-3'));
      expect(abbreviations, contains('chapitre 1'));
    });

    test('Portuguese: Complete functionality test', () async {
      SharedPreferences.setMockInitialValues({'tts_language': 'pt-BR'});

      // Test ordinals
      final ordinals = await textNormalizer.normalizeTtsText('1º 2º 3º lugar');
      expect(ordinals, equals('primeiro segundo terceiro lugar'));

      // Test Bible versions
      final bibleVersions = await textNormalizer.normalizeTtsText('ARC e NVI são traduções');
      expect(bibleVersions, contains('Almeida Revista e Corrigida'));
      expect(bibleVersions, contains('Nova Versão Internacional'));

      // Test Bible book formatting
      final bibleBook = textNormalizer.formatBibleBook('1 Coríntios 13:1', 'pt');
      expect(bibleBook, equals('Primeiro Coríntios 13:1'));

      // Test abbreviations
      final abbreviations = await textNormalizer.normalizeTtsText('vs. 1 e vv. 2-3 do cap. 1');
      expect(abbreviations, contains('versículo 1'));
      expect(abbreviations, contains('versículos 2-3'));
      expect(abbreviations, contains('capítulo 1'));
    });

    test('Backwards compatibility: Unknown language defaults to Spanish', () async {
      SharedPreferences.setMockInitialValues({'tts_language': 'unknown-XX'});

      // Should default to Spanish behavior
      final result = await textNormalizer.normalizeTtsText('1º lugar RVR1960');
      expect(result, contains('primero lugar'));
      expect(result, contains('Reina Valera mil novecientos sesenta'));
    });

    test('Mixed content: Multiple features in one text', () async {
      SharedPreferences.setMockInitialValues({'tts_language': 'en-US'});

      final complexText = await textNormalizer.normalizeTtsText(
        '1º verse KJV 2º edition vs. 3º chapter'
      );
      
      expect(complexText, contains('first verse'));
      expect(complexText, contains('King James Version'));
      expect(complexText, contains('second edition'));
      expect(complexText, contains('verse'));
      expect(complexText, contains('third chapter'));
    });
  });
}