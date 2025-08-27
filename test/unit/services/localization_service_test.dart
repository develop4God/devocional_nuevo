import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalizationService Tests', () {
    late LocalizationService localizationService;

    setUp(() {
      localizationService = LocalizationService.instance;

      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Mock asset loading
      const Map<String, String> mockTranslations = {
        'assets/translations/es.json': '''
        {
          "app": {
            "title": "Devocionales",
            "loading": "Cargando..."
          },
          "devotionals": {
            "app_title": "Devocionales Diarios"
          }
        }
        ''',
        'assets/translations/en.json': '''
        {
          "app": {
            "title": "Devotionals",
            "loading": "Loading..."
          },
          "devotionals": {
            "app_title": "Daily Devotionals"
          }
        }
        ''',
        'assets/translations/pt.json': '''
        {
          "app": {
            "title": "Devocionais",
            "loading": "Carregando..."
          },
          "devotionals": {
            "app_title": "Devocionais Diários"
          }
        }
        ''',
        'assets/translations/fr.json': '''
        {
          "app": {
            "title": "Dévotionnels",
            "loading": "Chargement..."
          },
          "devotionals": {
            "app_title": "Dévotionnels Quotidiens"
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

    test('should initialize with default locale', () async {
      await localizationService.initialize();
      // The service might detect device locale or fall back to default
      expect(
          ['es', 'en'].contains(localizationService.currentLocale.languageCode),
          isTrue);
    });

    test('should load Spanish translations correctly', () async {
      await localizationService.initialize();

      // Force Spanish locale if not already set
      if (localizationService.currentLocale.languageCode != 'es') {
        await localizationService.changeLocale(const Locale('es'));
      }

      expect(
          localizationService.translate('app.title'), equals('Devocionales'));
      expect(
          localizationService.translate('app.loading'), equals('Cargando...'));
      expect(localizationService.translate('devotionals.app_title'),
          equals('Devocionales Diarios'));
    });

    test('should change locale and load new translations', () async {
      await localizationService.initialize();

      // Change to English
      await localizationService.changeLocale(const Locale('en'));

      expect(localizationService.currentLocale.languageCode, equals('en'));
      expect(localizationService.translate('app.title'), equals('Devotionals'));
      expect(
          localizationService.translate('app.loading'), equals('Loading...'));
      expect(localizationService.translate('devotionals.app_title'),
          equals('Daily Devotionals'));
    });

    test('should return correct TTS locale mappings', () async {
      await localizationService.initialize();

      // Test Spanish - force locale first
      await localizationService.changeLocale(const Locale('es'));
      expect(localizationService.getTtsLocale(), equals('es-ES'));

      // Test English
      await localizationService.changeLocale(const Locale('en'));
      expect(localizationService.getTtsLocale(), equals('en-US'));

      // Test Portuguese
      await localizationService.changeLocale(const Locale('pt'));
      expect(localizationService.getTtsLocale(), equals('pt-BR'));

      // Test French
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
      await localizationService.initialize();

      expect(localizationService.translate('nonexistent.key'),
          equals('nonexistent.key'));
      expect(localizationService.translate('app.nonexistent'),
          equals('app.nonexistent'));
    });

    test('should handle parameters in translations', () async {
      // Mock translation with parameters
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString' &&
              methodCall.arguments == 'assets/translations/es.json') {
            return '''
            {
              "messages": {
                "welcome": "Bienvenido {name}!"
              }
            }
            ''';
          }
          return null;
        },
      );

      await localizationService.changeLocale(const Locale('es'));

      final result =
          localizationService.translate('messages.welcome', {'name': 'Juan'});
      expect(result, equals('Bienvenido Juan!'));
    });

    test('should support all required locales', () {
      const supportedLocales = LocalizationService.supportedLocales;

      expect(supportedLocales.length, equals(4));
      expect(supportedLocales.map((l) => l.languageCode).toList(),
          containsAll(['es', 'en', 'pt', 'fr']));
    });

    test('should handle failed translation loading gracefully', () async {
      // Mock failed asset loading
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString') {
            throw Exception('Asset not found');
          }
          return null;
        },
      );

      await localizationService.initialize();

      // Should not throw and should return key when translation fails
      expect(localizationService.translate('app.title'), equals('app.title'));
    });
  });
}
