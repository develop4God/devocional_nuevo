import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

@Tags(['unit', 'extensions'])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('String Extensions Tests', () {
    late LocalizationService localizationService;

    setUp(() async {
      ServiceLocator().reset();
      SharedPreferences.setMockInitialValues({});
      setupServiceLocator();

      localizationService = getService<LocalizationService>();
      await localizationService.initialize();
    });

    tearDown(() {
      // Clean up ServiceLocator after each test
      ServiceLocator().reset();
    });

    test('should translate simple keys', () async {
      // Force Spanish locale
      await localizationService.changeLocale(const Locale('es'));

      expect('app.title'.tr(), equals('Devocionales Cristianos'));
      expect('devotionals.app_title'.tr(), equals('Devocionales Diarios'));
    });

    test('should translate with parameters', () async {
      // Force Spanish locale
      await localizationService.changeLocale(const Locale('es'));

      // Test with a key that has parameters in the real translations
      final result = 'navigation.switch_to_language'.tr({
        'language': 'English',
      });
      expect(result, isNotEmpty);
    });

    test('should return key when translation not found', () async {
      expect('nonexistent.key'.tr(), equals('nonexistent.key'));
    });

    test('should handle nested keys', () async {
      // Force Spanish locale
      await localizationService.changeLocale(const Locale('es'));

      expect('app.title'.tr(), equals('Devocionales Cristianos'));
      expect('devotionals.app_title'.tr(), equals('Devocionales Diarios'));
    });

    test('should work with empty string', () async {
      expect(''.tr(), equals(''));
    });

    test('should work across different languages', () async {
      // Test Spanish
      await localizationService.changeLocale(const Locale('es'));
      expect('app.loading'.tr(), equals('Cargando...'));

      // Test English
      await localizationService.changeLocale(const Locale('en'));
      expect('app.loading'.tr(), equals('Loading...'));

      // Test Portuguese
      await localizationService.changeLocale(const Locale('pt'));
      expect('app.loading'.tr(), equals('Carregando...'));

      // Test French
      await localizationService.changeLocale(const Locale('fr'));
      expect('app.loading'.tr(), equals('Chargement...'));
    });
  });
}
