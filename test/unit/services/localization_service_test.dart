import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalizationService Tests', () {
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

    test('should initialize with default locale', () async {
      expect(LocalizationService.supportedLocales.map((l) => l.languageCode),
          contains(localizationService.currentLocale.languageCode));
    });

    test('should load translations correctly for each language', () async {
      // Test Spanish
      await localizationService.changeLocale(const Locale('es'));
      expect(
          localizationService.translate('app.title'), equals('Devocionales Cristianos'));
      expect(
          localizationService.translate('app.loading'), equals('Cargando...'));

      // Test English
      await localizationService.changeLocale(const Locale('en'));
      expect(
          localizationService.translate('app.title'), equals('Christian Devotionals'));
      expect(
          localizationService.translate('app.loading'), equals('Loading...'));

      // Test Portuguese
      await localizationService.changeLocale(const Locale('pt'));
      expect(
          localizationService.translate('app.title'), equals('Devocionais Cristãos'));
      expect(
          localizationService.translate('app.loading'), equals('Carregando...'));

      // Test French
      await localizationService.changeLocale(const Locale('fr'));
      expect(
          localizationService.translate('app.title'), equals('Dévotionnels Chrétiens'));
      expect(
          localizationService.translate('app.loading'), equals('Chargement...'));
    });

    test('should return correct TTS locale mappings', () async {
      await localizationService.initialize();

      // Test each language
      await localizationService.changeLocale(const Locale('es'));
      expect(localizationService.getTtsLocale(), equals('es-ES'));

      await localizationService.changeLocale(const Locale('en'));
      expect(localizationService.getTtsLocale(), equals('en-US'));

      await localizationService.changeLocale(const Locale('pt'));
      expect(localizationService.getTtsLocale(), equals('pt-BR'));

      await localizationService.changeLocale(const Locale('fr'));
      expect(localizationService.getTtsLocale(), equals('fr-FR'));
    });

    test('should return correct native language names', () {
      expect(localizationService.getLanguageName('es'), equals('Español'));
      expect(localizationService.getLanguageName('en'), equals('English'));
      expect(localizationService.getLanguageName('pt'), equals('Português'));
      expect(localizationService.getLanguageName('fr'), equals('Français'));
    });

    test('should return key when translation not found', () async {
      await localizationService.changeLocale(const Locale('es'));
      expect(localizationService.translate('nonexistent.key'),
          equals('nonexistent.key'));
    });

    test('should support all required locales', () {
      expect(LocalizationService.supportedLocales.length, equals(4));
      expect(LocalizationService.supportedLocales.map((l) => l.languageCode),
          containsAll(['es', 'en', 'pt', 'fr']));
    });
  });
}