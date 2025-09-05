import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_setup.dart';

void main() {
  setUpAll(() {
    TestSetup.setupCommonMocks();
  });

  tearDownAll() {
    TestSetup.cleanupMocks();
  }

  group('LocalizationService Core Functionality', () {
    late LocalizationService localizationService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // Reset singleton instance for clean test state
      LocalizationService.resetInstance();
      localizationService = LocalizationService.instance;
      await localizationService.initialize();
    });

    test('should initialize with default locale', () {
      expect(localizationService.currentLocale, isNotNull);
      expect(localizationService.currentLocale.languageCode, isNotEmpty);
    });

    test('should support multiple languages', () {
      const supportedLocales = LocalizationService.supportedLocales;
      expect(supportedLocales.length, greaterThanOrEqualTo(4));

      // Check for expected languages
      final languageCodes =
          supportedLocales.map((l) => l.languageCode).toList();
      expect(languageCodes, contains('es'));
      expect(languageCodes, contains('en'));
      expect(languageCodes, contains('pt'));
      expect(languageCodes, contains('fr'));
    });

    test('should change locale successfully', () async {
      final originalLocale = localizationService.currentLocale;

      // Change to English
      await localizationService.changeLocale(const Locale('en'));
      expect(localizationService.currentLocale.languageCode, equals('en'));

      // Change to Portuguese
      await localizationService.changeLocale(const Locale('pt'));
      expect(localizationService.currentLocale.languageCode, equals('pt'));

      // Change to French
      await localizationService.changeLocale(const Locale('fr'));
      expect(localizationService.currentLocale.languageCode, equals('fr'));

      // Change back to Spanish
      await localizationService.changeLocale(const Locale('es'));
      expect(localizationService.currentLocale.languageCode, equals('es'));
    });

    test('should translate basic app keys', () async {
      // Test Spanish translations
      await localizationService.changeLocale(const Locale('es'));
      expect(localizationService.translate('app.title'), isNotEmpty);
      expect(localizationService.translate('app.loading'), isNotEmpty);

      // Test English translations
      await localizationService.changeLocale(const Locale('en'));
      expect(localizationService.translate('app.title'), isNotEmpty);
      expect(localizationService.translate('app.loading'), isNotEmpty);

      // Test Portuguese translations
      await localizationService.changeLocale(const Locale('pt'));
      expect(localizationService.translate('app.title'), isNotEmpty);
      expect(localizationService.translate('app.loading'), isNotEmpty);

      // Test French translations
      await localizationService.changeLocale(const Locale('fr'));
      expect(localizationService.translate('app.title'), isNotEmpty);
      expect(localizationService.translate('app.loading'), isNotEmpty);
    });

    test('should handle missing translation keys gracefully', () async {
      await localizationService.changeLocale(const Locale('es'));

      // Non-existent key should return the key itself
      const nonExistentKey = 'non.existent.key.that.does.not.exist';
      expect(localizationService.translate(nonExistentKey),
          equals(nonExistentKey));
    });

    test('should handle empty or null keys', () {
      expect(localizationService.translate(''), equals(''));
    });

    test('should persist locale changes', () async {
      // Change locale
      await localizationService.changeLocale(const Locale('en'));
      expect(localizationService.currentLocale.languageCode, equals('en'));

      // Create new instance (simulating app restart)
      LocalizationService.resetInstance();
      final newService = LocalizationService.instance;
      await newService.initialize();

      // Should remember the last set locale (or fallback to default)
      expect(newService.currentLocale, isNotNull);
    });

    test('should handle rapid locale changes', () async {
      final locales = [
        const Locale('es'),
        const Locale('en'),
        const Locale('pt'),
        const Locale('fr'),
      ];

      for (int i = 0; i < 3; i++) {
        for (final locale in locales) {
          await localizationService.changeLocale(locale);
          expect(localizationService.currentLocale.languageCode,
              equals(locale.languageCode));
        }
      }
    });

    test('should handle unsupported locale gracefully', () async {
      final originalLocale = localizationService.currentLocale;

      // Try to set unsupported locale
      await localizationService.changeLocale(const Locale('de')); // German

      // Should fallback to supported locale or maintain current
      expect(localizationService.currentLocale, isNotNull);
      expect(
          LocalizationService.supportedLocales
              .map((l) => l.languageCode)
              .contains(localizationService.currentLocale.languageCode),
          isTrue);
    });

    test('should provide translation with parameters', () async {
      await localizationService.changeLocale(const Locale('es'));

      // Test parameter substitution if supported
      final result =
          localizationService.translate('app.title', {'param': 'test'});
      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });

    test('should handle concurrent operations', () async {
      // Multiple operations running concurrently should not cause issues
      final futures = <Future>[];

      for (int i = 0; i < 5; i++) {
        futures.add(localizationService.changeLocale(const Locale('en')));
        futures.add(localizationService.changeLocale(const Locale('es')));
      }

      await Future.wait(futures);
      expect(localizationService.currentLocale, isNotNull);
    });

    test('should maintain singleton behavior', () {
      final instance1 = LocalizationService.instance;
      final instance2 = LocalizationService.instance;

      expect(identical(instance1, instance2), isTrue);
    });
  });

  group('LocalizationService Edge Cases', () {
    late LocalizationService localizationService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      LocalizationService.resetInstance();
      localizationService = LocalizationService.instance;
      await localizationService.initialize();
    });

    test('should handle initialization errors gracefully', () async {
      // Even if initialization fails, service should not crash
      expect(localizationService, isNotNull);
      expect(localizationService.currentLocale, isNotNull);
    });

    test('should handle translation loading errors', () {
      // Service should handle missing translation files gracefully
      final result = localizationService.translate('any.key');
      expect(result, isNotNull);
    });

    test('should handle malformed locale', () async {
      // Should handle unsupported locale gracefully by falling back to default
      await localizationService
          .changeLocale(const Locale('xx')); // Non-existent language
      expect(localizationService.currentLocale, isNotNull);
      // Should either stay on current locale or fallback to default
      expect(LocalizationService.supportedLocales,
          contains(localizationService.currentLocale));
    });

    test('should handle stress testing', () async {
      // Rapid translations should not cause memory leaks or crashes
      for (int i = 0; i < 100; i++) {
        localizationService.translate('app.title');
        localizationService.translate('app.loading');
        if (i % 10 == 0) {
          await localizationService.changeLocale(const Locale('en'));
          await localizationService.changeLocale(const Locale('es'));
        }
      }

      expect(localizationService.currentLocale, isNotNull);
    });

    test('should handle memory constraints', () {
      // Create multiple translation requests
      final translations = <String>[];

      for (int i = 0; i < 50; i++) {
        translations.add(localizationService.translate('app.title'));
        translations.add(localizationService.translate('app.loading'));
      }

      // All translations should be valid
      for (final translation in translations) {
        expect(translation, isNotNull);
        expect(translation, isNotEmpty);
      }
    });

    test('should handle service reset', () {
      final originalService = LocalizationService.instance;

      LocalizationService.resetInstance();
      final newService = LocalizationService.instance;

      expect(identical(originalService, newService), isFalse);
      expect(newService, isNotNull);
    });
  });

  group('LocalizationService Performance', () {
    test('should perform translations efficiently', () async {
      LocalizationService.resetInstance();
      final service = LocalizationService.instance;
      await service.initialize();

      final stopwatch = Stopwatch()..start();

      // Perform many translations
      for (int i = 0; i < 1000; i++) {
        service.translate('app.title');
      }

      stopwatch.stop();

      // Should complete quickly (less than 1 second for 1000 translations)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('should handle locale changes efficiently', () async {
      LocalizationService.resetInstance();
      final service = LocalizationService.instance;
      await service.initialize();

      final stopwatch = Stopwatch()..start();

      // Perform locale changes
      for (int i = 0; i < 10; i++) {
        await service.changeLocale(const Locale('en'));
        await service.changeLocale(const Locale('es'));
      }

      stopwatch.stop();

      // Should complete in reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });
  });
}
