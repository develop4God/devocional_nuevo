import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('String Extensions Tests', () {
    late LocalizationService localizationService;

    setUp(() {
      localizationService = LocalizationService.instance;

      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Mock asset loading
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString') {
            return '''
            {
              "app": {
                "title": "Devocionales",
                "welcome": "Bienvenido {name}!"
              },
              "devotionals": {
                "app_title": "Devocionales Diarios"
              }
            }
            ''';
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

    test('should translate simple keys', () async {
      await localizationService.initialize();

      expect('app.title'.tr(), equals('Devocionales'));
      expect('devotionals.app_title'.tr(), equals('Devocionales Diarios'));
    });

    test('should translate with parameters', () async {
      await localizationService.initialize();

      expect('app.welcome'.tr({'name': 'Juan'}), equals('Bienvenido Juan!'));
    });

    test('should return key when translation not found', () async {
      await localizationService.initialize();

      expect('nonexistent.key'.tr(), equals('nonexistent.key'));
    });

    test('should handle nested keys', () async {
      await localizationService.initialize();

      expect('app.title'.tr(), equals('Devocionales'));
      expect('devotionals.app_title'.tr(), equals('Devocionales Diarios'));
    });

    test('should work with empty string', () async {
      await localizationService.initialize();

      expect(''.tr(), equals(''));
    });

    test('should work with single word keys', () async {
      // Mock single word translation
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString') {
            return '''
            {
              "hello": "Hola"
            }
            ''';
          }
          return null;
        },
      );

      await localizationService.initialize();

      expect('hello'.tr(), equals('Hola'));
    });
  });
}
