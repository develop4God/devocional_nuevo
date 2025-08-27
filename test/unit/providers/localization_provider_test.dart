import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('LocalizationProvider Tests', () {
    late LocalizationProvider localizationProvider;

    setUp(() {
      localizationProvider = LocalizationProvider();

      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Mock asset loading
      const Map<String, String> mockTranslations = {
        'assets/translations/es.json': '''
        {
          "app": {
            "title": "Devocionales"
          }
        }
        ''',
        'assets/translations/en.json': '''
        {
          "app": {
            "title": "Devotionals"
          }
        }
        ''',
        'assets/translations/pt.json': '''
        {
          "app": {
            "title": "Devocionais"
          }
        }
        ''',
        'assets/translations/fr.json': '''
        {
          "app": {
            "title": "Dévotionnels"
          }
        }
        '''
      };

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString') {
            final String key = methodCall.arguments as String;
            return mockTranslations[key];
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        null,
      );
    });

    test('should initialize successfully', () async {
      await localizationProvider.initialize();

      expect(localizationProvider.currentLocale.languageCode, equals('es'));
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

      expect(
          localizationProvider.translate('app.title'), equals('Devocionales'));

      await localizationProvider.changeLanguage('en');
      expect(
          localizationProvider.translate('app.title'), equals('Devotionals'));
    });

    test('should return correct TTS locale', () async {
      await localizationProvider.initialize();

      expect(localizationProvider.getTtsLocale(), equals('es-ES'));

      await localizationProvider.changeLanguage('en');
      expect(localizationProvider.getTtsLocale(), equals('en-US'));

      await localizationProvider.changeLanguage('pt');
      expect(localizationProvider.getTtsLocale(), equals('pt-BR'));

      await localizationProvider.changeLanguage('fr');
      expect(localizationProvider.getTtsLocale(), equals('fr-FR'));
    });

    test('should return available languages with native names', () {
      final languages = localizationProvider.getAvailableLanguages();

      expect(languages['es'], equals('Español'));
      expect(languages['en'], equals('English'));
      expect(languages['pt'], equals('Português'));
      expect(languages['fr'], equals('Français'));
    });

    test('should return correct language names', () {
      expect(localizationProvider.getLanguageName('es'), equals('Español'));
      expect(localizationProvider.getLanguageName('en'), equals('English'));
      expect(localizationProvider.getLanguageName('pt'), equals('Português'));
      expect(localizationProvider.getLanguageName('fr'), equals('Français'));
    });

    test('should handle all supported locales', () {
      final supportedLocales = localizationProvider.supportedLocales;
      final languageCodes =
          supportedLocales.map((l) => l.languageCode).toList();

      expect(languageCodes, containsAll(['es', 'en', 'pt', 'fr']));
      expect(supportedLocales.length, equals(4));
    });
  });
}
