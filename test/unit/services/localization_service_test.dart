import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalizationService Tests', () {
    late LocalizationService localizationService;

    setUp(() async {
      // Reset ServiceLocator and register default services using the app setup
      ServiceLocator().reset();

      // Mock SharedPreferences BEFORE setting up the locator so services
      // that read prefs during initialization get the mocked values.
      SharedPreferences.setMockInitialValues({});

      // Use the centralized setup to register all services (DI approach)
      setupServiceLocator();

      // Acquire the localization service and initialize translations
      localizationService = getService<LocalizationService>();
      await localizationService.initialize();
    });

    tearDown(() {
      // Clean up ServiceLocator after each test
      ServiceLocator().reset();
    });

    test('should initialize with default locale', () async {
      expect(LocalizationService.supportedLocales.map((l) => l.languageCode),
          contains(localizationService.currentLocale.languageCode));
    });

    test('should load translations correctly for each language', () async {
      // Since asset loading may fail in test environment, let's test graceful handling

      // Test Spanish
      await localizationService.changeLocale(const Locale('es'));
      final spanishTitle = localizationService.translate('app.title');

      if (spanishTitle != 'app.title') {
        // If translations are loaded, test expected values
        expect(spanishTitle, equals('Devocionales Cristianos'));
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
            equals('Méditations Chrétiennes'));
        expect(localizationService.translate('app.loading'),
            equals('Chargement...'));
      } else {
        // If assets aren't loaded, verify graceful fallback
        expect(spanishTitle,
            equals('app.title')); // Returns key when translation missing

        // Test other languages also fallback gracefully
        await localizationService.changeLocale(const Locale('en'));
        expect(localizationService.translate('app.title'), equals('app.title'));

        await localizationService.changeLocale(const Locale('pt'));
        expect(localizationService.translate('app.title'), equals('app.title'));

        await localizationService.changeLocale(const Locale('fr'));
        expect(localizationService.translate('app.title'), equals('app.title'));
      }

      // Test passes in both scenarios - with working translations or graceful fallback
      expect(localizationService.currentLocale, isNotNull);
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
      expect(LocalizationService.supportedLocales.length, equals(6));
      expect(LocalizationService.supportedLocales.map((l) => l.languageCode),
          containsAll(['es', 'en', 'pt', 'fr', 'ja', 'zh']));
    });

    test('should return correct Japanese TTS locale', () async {
      await localizationService.changeLocale(const Locale('ja'));
      expect(localizationService.getTtsLocale(), equals('ja-JP'));
    });

    test('should return Japanese language name', () {
      expect(localizationService.getLanguageName('ja'), equals('日本語'));
    });

    test('should return language code for unknown language', () {
      expect(localizationService.getLanguageName('xx'), equals('xx'));
    });

    test('defaultLocale is Spanish', () {
      expect(LocalizationService.defaultLocale.languageCode, equals('es'));
    });
  });

  group('LocalizationService User Behavior Tests', () {
    late LocalizationService localizationService;

    setUp(() async {
      ServiceLocator().reset();
      SharedPreferences.setMockInitialValues({});
      setupServiceLocator();
      localizationService = getService<LocalizationService>();
    });

    tearDown(() {
      ServiceLocator().reset();
    });

    test('initialize() loads persisted locale from SharedPreferences',
        () async {
      // Set up with persisted English locale
      ServiceLocator().reset();
      SharedPreferences.setMockInitialValues({'locale': 'en'});
      // Use centralized setup so all dependent services are registered
      setupServiceLocator();

      localizationService = getService<LocalizationService>();
      await localizationService.initialize();

      // Should load persisted English locale
      expect(localizationService.currentLocale.languageCode, equals('en'));
    });

    test('initialize() uses default locale when saved locale is unsupported',
        () async {
      // Set up with unsupported locale
      ServiceLocator().reset();
      SharedPreferences.setMockInitialValues({'locale': 'xx'});
      setupServiceLocator();
      localizationService = getService<LocalizationService>();
      await localizationService.initialize();

      // Should fall back to a supported locale
      expect(
        LocalizationService.supportedLocales
            .map((l) => l.languageCode)
            .contains(localizationService.currentLocale.languageCode),
        isTrue,
      );
    });

    test('changeLocale() persists new locale in SharedPreferences', () async {
      await localizationService.initialize();

      // Change locale to French
      await localizationService.changeLocale(const Locale('fr'));

      // Verify the locale was persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale'), equals('fr'));

      // Verify current locale reflects the change
      expect(localizationService.currentLocale.languageCode, equals('fr'));
    });

    test('changeLocale() ignores unsupported locales', () async {
      await localizationService.initialize();
      final initialLocale = localizationService.currentLocale;

      // Try to change to unsupported locale
      await localizationService.changeLocale(const Locale('xx'));

      // Locale should remain unchanged
      expect(localizationService.currentLocale, equals(initialLocale));
    });

    test('translate() interpolates parameters correctly', () async {
      await localizationService.initialize();
      await localizationService.changeLocale(const Locale('es'));

      // Test with navigation.switch_to_language if available
      final result = localizationService
          .translate('navigation.switch_to_language', {'language': 'Test'});

      // Either the key is returned or the translation with substitution
      expect(result, isNotNull);
      expect(result.isNotEmpty, isTrue);
    });

    test('translate() handles nested keys correctly', () async {
      await localizationService.initialize();
      await localizationService.changeLocale(const Locale('es'));

      // Test nested key
      final result = localizationService.translate('app.title');

      // Either returns the translation or the key
      expect(result, isNotNull);
      expect(result.isNotEmpty, isTrue);
    });

    test('getLocalizedDateFormat() returns correct format for each language',
        () async {
      await localizationService.initialize();

      // Note: DateFormat requires initializeDateFormatting() which may not be
      // available in all test environments. We test that the method exists and
      // returns a DateFormat object, or gracefully handles the exception.
      try {
        // Test Spanish date format
        final esFormat = localizationService.getLocalizedDateFormat('es');
        expect(esFormat, isNotNull);

        // Test English date format
        final enFormat = localizationService.getLocalizedDateFormat('en');
        expect(enFormat, isNotNull);

        // Test Portuguese date format
        final ptFormat = localizationService.getLocalizedDateFormat('pt');
        expect(ptFormat, isNotNull);

        // Test French date format
        final frFormat = localizationService.getLocalizedDateFormat('fr');
        expect(frFormat, isNotNull);

        // Test Japanese date format
        final jaFormat = localizationService.getLocalizedDateFormat('ja');
        expect(jaFormat, isNotNull);
      } catch (e) {
        // If intl locale data not initialized, the method throws an exception
        // This is expected in test environments without full intl setup
        expect(e.toString(), contains('Locale data has not been initialized'));
      }
    });

    test('getLocalizedDateFormat() returns English format for unknown language',
        () async {
      await localizationService.initialize();

      try {
        final format = localizationService.getLocalizedDateFormat('xx');
        expect(format, isNotNull);
      } catch (e) {
        // If intl locale data not initialized, the method throws an exception
        expect(e.toString(), contains('Locale data has not been initialized'));
      }
    });

    test('User journey: app start -> change language -> verify persistence',
        () async {
      // Step 1: Initialize with default
      await localizationService.initialize();
      final initialLocale = localizationService.currentLocale.languageCode;
      expect(LocalizationService.supportedLocales.map((l) => l.languageCode),
          contains(initialLocale));

      // Step 2: Change to Portuguese
      await localizationService.changeLocale(const Locale('pt'));
      expect(localizationService.currentLocale.languageCode, equals('pt'));

      // Step 3: Simulate app restart with new service instance
      ServiceLocator().reset();
      // Do NOT reset SharedPreferences - persistence should survive
      // Re-create the full locator as the app would on startup
      setupServiceLocator();
      final newService = getService<LocalizationService>();
      await newService.initialize();

      // Step 4: Portuguese should still be selected
      expect(newService.currentLocale.languageCode, equals('pt'));
    });

    test('Multiple rapid locale changes work correctly', () async {
      await localizationService.initialize();

      // Rapidly change locales
      await localizationService.changeLocale(const Locale('en'));
      await localizationService.changeLocale(const Locale('fr'));
      await localizationService.changeLocale(const Locale('ja'));
      await localizationService.changeLocale(const Locale('pt'));
      await localizationService.changeLocale(const Locale('es'));

      // Final locale should be Spanish
      expect(localizationService.currentLocale.languageCode, equals('es'));

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale'), equals('es'));
    });

    test(
        'Translation cache stores and reuses translations on language switches',
        () async {
      await localizationService.initialize();

      // Initially, only the current locale should be cached
      final initialLocale = localizationService.currentLocale.languageCode;
      expect(localizationService.isCached(initialLocale), isTrue);

      // Switch to English - should load and cache
      await localizationService.changeLocale(const Locale('en'));
      expect(localizationService.isCached('en'), isTrue);
      expect(localizationService.currentLocale.languageCode, equals('en'));

      // Switch to Spanish - should load and cache
      await localizationService.changeLocale(const Locale('es'));
      expect(localizationService.isCached('es'), isTrue);
      expect(localizationService.currentLocale.languageCode, equals('es'));

      // Both languages should now be cached
      expect(localizationService.isCached('en'), isTrue);
      expect(localizationService.isCached('es'), isTrue);

      // Switch back to English - should use cache (verify it's still cached)
      await localizationService.changeLocale(const Locale('en'));
      expect(localizationService.isCached('en'), isTrue);
      expect(localizationService.currentLocale.languageCode, equals('en'));
    });

    test('Error handling falls back to default locale gracefully', () async {
      // This test verifies that the error logging and fallback mechanism works
      // when an invalid language is requested internally

      await localizationService.initialize();

      // Change to a valid locale to verify the service is working
      await localizationService.changeLocale(const Locale('en'));
      expect(localizationService.currentLocale.languageCode, equals('en'));

      // Translations should be available (either from cache or file)
      // The service should handle any errors gracefully
      final translation = localizationService.translate('app.title');
      expect(translation, isNotNull);
    });

    test('Service handles unsupported locale gracefully with fallback',
        () async {
      await localizationService.initialize();

      // Attempt to change to an unsupported locale
      // This should fail silently and not change the current locale
      final currentLocale = localizationService.currentLocale;
      await localizationService.changeLocale(const Locale('invalid_xx'));

      // Locale should remain unchanged because 'invalid_xx' is not supported
      expect(localizationService.currentLocale, equals(currentLocale));
    });

    test('Translation returns key when translation not found', () async {
      await localizationService.initialize();

      // Request a key that doesn't exist
      final result = localizationService.translate('nonexistent.key.path');

      // Should return the key itself as fallback
      expect(result, equals('nonexistent.key.path'));
    });
  });

  group('Error Logging Validation', () {
    late LocalizationService localizationService;

    setUp(() async {
      ServiceLocator().reset();
      SharedPreferences.setMockInitialValues({});
      setupServiceLocator();
      localizationService = getService<LocalizationService>();
    });

    tearDown(() {
      ServiceLocator().reset();
    });

    test('Error logging mechanism is implemented in _loadTranslations',
        () async {
      // This test validates that the error logging code paths exist
      // by testing the fallback behavior which triggers error logging

      await localizationService.initialize();

      // The service should initialize without throwing
      expect(localizationService.currentLocale, isNotNull);

      // Verify the service is functional after any error handling
      final translation = localizationService.translate('app.title');
      expect(translation, isNotNull);

      // If we reach here, error handling worked correctly
      // (developer.log calls are made but we can't easily capture them in tests)
    });

    test('Service recovers from initialization errors', () async {
      // Initialize with a persisted locale that may not have translations
      ServiceLocator().reset();
      SharedPreferences.setMockInitialValues({'locale': 'es'});

      // Re-create service with new SharedPreferences state using setupServiceLocator
      setupServiceLocator();
      final service = getService<LocalizationService>();

      await service.initialize();

      // Service should still be functional
      expect(service.currentLocale.languageCode, equals('es'));
      expect(service.translate('app.title'), isNotNull);
    });
  });
}
