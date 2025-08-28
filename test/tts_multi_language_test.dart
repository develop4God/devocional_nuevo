import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/services/tts_localization_service.dart';
import 'package:devocional_nuevo/services/tts_text_normalizer_service.dart';

void main() {
  group('TTS Multi-language Support Tests', () {
    late TtsLocalizationService localizationService;
    late TtsTextNormalizerService textNormalizerService;

    setUp(() {
      localizationService = TtsLocalizationService();
      textNormalizerService = TtsTextNormalizerService();
      // Set up mock shared preferences for testing
      SharedPreferences.setMockInitialValues({});
    });

    group('TtsLocalizationService', () {
      test('should get correct language code from full language identifier', () {
        expect(localizationService.getLanguageCode('es-US'), equals('es'));
        expect(localizationService.getLanguageCode('en-US'), equals('en'));
        expect(localizationService.getLanguageCode('fr-FR'), equals('fr'));
        expect(localizationService.getLanguageCode('pt-BR'), equals('pt'));
      });

      test('should return correct ordinals for Spanish', () {
        final ordinals = localizationService.getOrdinalsMap('es');
        expect(ordinals[1], equals('primero'));
        expect(ordinals[2], equals('segundo'));
        expect(ordinals[3], equals('tercero'));
      });

      test('should return correct ordinals for English', () {
        final ordinals = localizationService.getOrdinalsMap('en');
        expect(ordinals[1], equals('first'));
        expect(ordinals[2], equals('second'));
        expect(ordinals[3], equals('third'));
      });

      test('should return correct ordinals for French', () {
        final ordinals = localizationService.getOrdinalsMap('fr');
        expect(ordinals[1], equals('premier'));
        expect(ordinals[2], equals('deuxième'));
        expect(ordinals[3], equals('troisième'));
      });

      test('should return correct ordinals for Portuguese', () {
        final ordinals = localizationService.getOrdinalsMap('pt');
        expect(ordinals[1], equals('primeiro'));
        expect(ordinals[2], equals('segundo'));
        expect(ordinals[3], equals('terceiro'));
      });

      test('should return correct Bible book ordinals for Spanish', () {
        final bookOrdinals = localizationService.getBookOrdinalsMap('es');
        expect(bookOrdinals['1'], equals('Primera de'));
        expect(bookOrdinals['2'], equals('Segunda de'));
        expect(bookOrdinals['3'], equals('Tercera de'));
      });

      test('should return correct Bible book ordinals for English', () {
        final bookOrdinals = localizationService.getBookOrdinalsMap('en');
        expect(bookOrdinals['1'], equals('First'));
        expect(bookOrdinals['2'], equals('Second'));
        expect(bookOrdinals['3'], equals('Third'));
      });

      test('should return correct Bible versions for Spanish', () {
        final bibleVersions = localizationService.getBibleVersionsMap('es');
        expect(bibleVersions['RVR1960'], equals('Reina Valera mil novecientos sesenta'));
        expect(bibleVersions['NVI'], equals('Nueva Versión Internacional'));
      });

      test('should return correct Bible versions for English', () {
        final bibleVersions = localizationService.getBibleVersionsMap('en');
        expect(bibleVersions['KJV'], equals('King James Version'));
        expect(bibleVersions['NIV'], equals('New International Version'));
      });

      test('should return correct Bible versions for French', () {
        final bibleVersions = localizationService.getBibleVersionsMap('fr');
        expect(bibleVersions['LSG'], equals('Louis Segond'));
        expect(bibleVersions['NEG'], equals('Nouvelle Edition de Genève'));
      });

      test('should return correct Bible versions for Portuguese', () {
        final bibleVersions = localizationService.getBibleVersionsMap('pt');
        expect(bibleVersions['ARC'], equals('Almeida Revista e Corrigida'));
        expect(bibleVersions['NVI'], equals('Nova Versão Internacional'));
      });
    });

    group('TtsTextNormalizerService', () {
      test('should format Bible book ordinals correctly for Spanish', () {
        final result = textNormalizerService.formatBibleBook('1 Juan', 'es');
        expect(result, equals('Primera de Juan'));
      });

      test('should format Bible book ordinals correctly for English', () {
        final result = textNormalizerService.formatBibleBook('1 John', 'en');
        expect(result, equals('First John'));
      });

      test('should format Bible book ordinals correctly for French', () {
        final result = textNormalizerService.formatBibleBook('1 Jean', 'fr');
        expect(result, equals('Premier Jean'));
      });

      test('should format Bible book ordinals correctly for Portuguese', () {
        final result = textNormalizerService.formatBibleBook('1 João', 'pt');
        expect(result, equals('Primeiro João'));
      });

      test('should not modify books without ordinals', () {
        expect(textNormalizerService.formatBibleBook('Genesis', 'en'), equals('Genesis'));
        expect(textNormalizerService.formatBibleBook('Génesis', 'es'), equals('Génesis'));
      });

      test('should preserve Spanish functionality', () async {
        // Test that Spanish normalization still works as before
        SharedPreferences.setMockInitialValues({'tts_language': 'es-US'});
        
        final result = await textNormalizerService.normalizeTtsText('1º 2º 3º');
        expect(result, contains('primero'));
        expect(result, contains('segundo'));
        expect(result, contains('tercero'));
      });

      test('should handle English ordinals', () async {
        SharedPreferences.setMockInitialValues({'tts_language': 'en-US'});
        
        final result = await textNormalizerService.normalizeTtsText('1º 2º 3º');
        expect(result, contains('first'));
        expect(result, contains('second'));
        expect(result, contains('third'));
      });
    });

    group('Integration Tests', () {
      test('should preserve existing Spanish functionality completely', () async {
        SharedPreferences.setMockInitialValues({'tts_language': 'es-US'});
        
        // Test Bible versions expansion
        final result1 = await textNormalizerService.normalizeTtsText('RVR1960 y NVI');
        expect(result1, contains('Reina Valera mil novecientos sesenta'));
        expect(result1, contains('Nueva Versión Internacional'));

        // Test ordinals
        final result2 = await textNormalizerService.normalizeTtsText('1º lugar');
        expect(result2, contains('primero lugar'));
        
        // Test Bible book formatting
        final result3 = textNormalizerService.formatBibleBook('1 Corintios', 'es');
        expect(result3, equals('Primera de Corintios'));
      });

      test('should work correctly for English language', () async {
        SharedPreferences.setMockInitialValues({'tts_language': 'en-US'});
        
        // Test Bible versions expansion
        final result1 = await textNormalizerService.normalizeTtsText('KJV and NIV');
        expect(result1, contains('King James Version'));
        expect(result1, contains('New International Version'));

        // Test ordinals
        final result2 = await textNormalizerService.normalizeTtsText('1º place');
        expect(result2, contains('first place'));
        
        // Test Bible book formatting
        final result3 = textNormalizerService.formatBibleBook('1 Corinthians', 'en');
        expect(result3, equals('First Corinthians'));
      });
    });
  });
}