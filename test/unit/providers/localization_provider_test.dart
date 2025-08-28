import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('LocalizationProvider Tests', () {
    late LocalizationProvider localizationProvider;

    setUp(() async {
      // Reset singleton instance for clean test state
      LocalizationService.resetInstance();
      
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      localizationProvider = LocalizationProvider();
    });

    test('should initialize successfully', () async {
      await localizationProvider.initialize();

      // Should initialize to some supported locale
      expect(LocalizationService.supportedLocales.map((l) => l.languageCode), 
             contains(localizationProvider.currentLocale.languageCode));
      expect(localizationProvider.supportedLocales.length, equals(4));
    });

    test('should change language and notify listeners', () async {
      await localizationProvider.initialize();

      bool notified = false;
      localizationProvider.addListener(() {
        notified = true;
      });

      await localizationProvider.changeLanguage('en');

      expect(localizationProvider.currentLocale.languageCode, equals('en'));
      expect(notified, isTrue);
    });

    test('should translate text correctly', () async {
      await localizationProvider.initialize();

      // Get the initial translation
      final initialTitle = localizationProvider.translate('app.title');
      expect(initialTitle, isNotEmpty);
      expect(initialTitle, isNot(equals('app.title')));

      await localizationProvider.changeLanguage('en');
      expect(
          localizationProvider.translate('app.title'), equals('Christian Devotionals'));
    });

    test('should return correct TTS locale', () async {
      await localizationProvider.initialize();

      // Get initial TTS locale - should be one of the supported ones
      final initialTtsLocale = localizationProvider.getTtsLocale();
      expect(['es-ES', 'en-US', 'pt-BR', 'fr-FR'], contains(initialTtsLocale));

      await localizationProvider.changeLanguage('en');
      expect(localizationProvider.getTtsLocale(), equals('en-US'));

      await localizationProvider.changeLanguage('pt');
      expect(localizationProvider.getTtsLocale(), equals('pt-BR'));

      await localizationProvider.changeLanguage('fr');
      expect(localizationProvider.getTtsLocale(), equals('fr-FR'));
    });

    test('should return available languages with native names', () async {
      await localizationProvider.initialize();

      final availableLanguages = localizationProvider.getAvailableLanguages();
      expect(availableLanguages.keys, containsAll(['es', 'en', 'pt', 'fr']));
      expect(availableLanguages['es'], equals('Español'));
      expect(availableLanguages['en'], equals('English'));
      expect(availableLanguages['pt'], equals('Português'));
      expect(availableLanguages['fr'], equals('Français'));
    });

    test('should return correct language names', () async {
      await localizationProvider.initialize();

      expect(localizationProvider.getLanguageName('es'), equals('Español'));
      expect(localizationProvider.getLanguageName('en'), equals('English'));
      expect(localizationProvider.getLanguageName('pt'), equals('Português'));
      expect(localizationProvider.getLanguageName('fr'), equals('Français'));
    });

    test('should handle all supported locales', () async {
      await localizationProvider.initialize();

      for (final locale in LocalizationService.supportedLocales) {
        await localizationProvider.changeLanguage(locale.languageCode);
        expect(localizationProvider.currentLocale.languageCode, 
               equals(locale.languageCode));
      }
    });
  });
}