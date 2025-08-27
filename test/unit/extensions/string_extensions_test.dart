import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('String Extensions Tests', () {
    late LocalizationService localizationService;

    setUp(() async {
      // Reset singleton instance for clean test state
      LocalizationService.resetInstance();

      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Mock asset loading with proper JSON structure
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString') {
            if (methodCall.arguments == 'assets/translations/es.json') {
              return '''
              {
                "app": {
                  "title": "Devocionales",
                  "welcome": "Bienvenido {name}!"
                },
                "devotionals": {
                  "app_title": "Devocionales Diarios"
                },
                "hello": "Hola"
              }
              ''';
            }
          }
          return null;
        },
      );

      // Get fresh instance and initialize
      localizationService = LocalizationService.instance;
      await localizationService.initialize();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        null,
      );
    });

    test('should translate simple keys', () async {
      // Force Spanish locale
      await localizationService.changeLocale(const Locale('es'));

      expect('app.title'.tr(), equals('Devocionales'));
      expect('devotionals.app_title'.tr(), equals('Devocionales Diarios'));
    });

    test('should translate with parameters', () async {
      // Force Spanish locale
      await localizationService.changeLocale(const Locale('es'));

      expect('app.welcome'.tr({'name': 'Juan'}), equals('Bienvenido Juan!'));
    });

    test('should return key when translation not found', () async {
      expect('nonexistent.key'.tr(), equals('nonexistent.key'));
    });

    test('should handle nested keys', () async {
      // Force Spanish locale
      await localizationService.changeLocale(const Locale('es'));

      expect('app.title'.tr(), equals('Devocionales'));
      expect('devotionals.app_title'.tr(), equals('Devocionales Diarios'));
    });

    test('should work with empty string', () async {
      expect(''.tr(), equals(''));
    });

    test('should work with single word keys', () async {
      // Force Spanish locale
      await localizationService.changeLocale(const Locale('es'));

      expect('hello'.tr(), equals('Hola'));
    });
  });
}
