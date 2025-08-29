import 'dart:ui';

import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Translation Validation Tests', () {
    late LocalizationService localizationService;

    setUp(() async {
      // Reset singleton instance for clean test state
      LocalizationService.resetInstance();

      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Get fresh instance and initialize with real assets
      localizationService = LocalizationService.instance;
      await localizationService.initialize();
    });

    group('App-wide Translation Keys', () {
      test('should translate basic app keys across all languages', () async {
        // Test Spanish
        await localizationService.changeLocale(const Locale('es'));
        expect(localizationService.translate('app.title'),
            equals('Devocionales Cristianos'));
        expect(localizationService.translate('app.loading'),
            equals('Cargando...'));

        // Test English
        await localizationService.changeLocale(const Locale('en'));
        expect(localizationService.translate('app.title'),
            equals('Christian Devotionals'));
        expect(
            localizationService.translate('app.loading'), equals('Loading...'));

        // Test Portuguese
        await localizationService.changeLocale(const Locale('pt'));
        expect(localizationService.translate('app.title'),
            equals('Devocionais Cristãos'));
        expect(localizationService.translate('app.loading'),
            equals('Carregando...'));

        // Test French
        await localizationService.changeLocale(const Locale('fr'));
        expect(localizationService.translate('app.title'),
            equals('Dévotionnels Chrétiens'));
        expect(localizationService.translate('app.loading'),
            equals('Chargement...'));
      });
    });

    group('Basic Translation Structure', () {
      test('should have working translation keys', () async {
        // Test Spanish defaults
        await localizationService.changeLocale(const Locale('es'));

        // Basic app keys
        expect(localizationService.translate('app.title'), isNotEmpty);
        expect(localizationService.translate('app.loading'), isNotEmpty);
        expect(localizationService.translate('app.preparing'), isNotEmpty);

        // Should not return the key itself
        expect(localizationService.translate('app.title'),
            isNot(equals('app.title')));
      });

      test('should handle missing translation keys gracefully', () async {
        await localizationService.changeLocale(const Locale('es'));

        // Non-existent key should return the key itself
        expect(localizationService.translate('non.existent.key'),
            equals('non.existent.key'));
      });
    });

    group('Language Switching Tests', () {
      test('should successfully switch between all supported languages',
          () async {
        for (final locale in LocalizationService.supportedLocales) {
          await localizationService.changeLocale(locale);
          expect(localizationService.currentLocale, equals(locale));

          // Verify translation works after language switch
          final title = localizationService.translate('app.title');
          expect(title, isNotEmpty);
          expect(title, isNot(equals('app.title')));
        }
      });
    });
  });
}
