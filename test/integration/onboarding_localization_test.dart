import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Onboarding Localization Integration Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LocalizationService.instance.initialize();
    });

    test('should properly translate onboarding keys', () {
      final localizationService = LocalizationService.instance;
      
      // Test key translation with proper hierarchy
      final welcomeTitle = localizationService.translate('onboarding.onboarding_welcome_title');
      final themeTitle = localizationService.translate('onboarding.onboarding_theme_title');
      final backupTitle = localizationService.translate('onboarding.onboarding_backup_title');
      
      // Should not return the key itself (which means translation failed)
      expect(welcomeTitle, isNot(equals('onboarding.onboarding_welcome_title')));
      expect(themeTitle, isNot(equals('onboarding.onboarding_theme_title')));
      expect(backupTitle, isNot(equals('onboarding.onboarding_backup_title')));
      
      // Should contain actual text
      expect(welcomeTitle.isNotEmpty, isTrue);
      expect(themeTitle.isNotEmpty, isTrue);
      expect(backupTitle.isNotEmpty, isTrue);
    });

    test('should handle connection and timeout messages', () {
      final localizationService = LocalizationService.instance;
      
      final connecting = localizationService.translate('onboarding.onboarding_connecting');
      final timeout = localizationService.translate('onboarding.onboarding_connection_timeout');
      
      // Should not return raw keys
      expect(connecting, isNot(equals('onboarding.onboarding_connecting')));
      expect(timeout, isNot(equals('onboarding.onboarding_connection_timeout')));
      
      // Should be meaningful text
      expect(connecting.isNotEmpty, isTrue);
      expect(timeout.isNotEmpty, isTrue);
    });

    test('should support all navigation and action keys', () {
      final localizationService = LocalizationService.instance;
      
      final keys = [
        'onboarding.onboarding_next',
        'onboarding.onboarding_back',
        'onboarding.onboarding_skip',
        'onboarding.onboarding_skip_for_now',
        'onboarding.onboarding_configure_later',
        'onboarding.onboarding_start_app',
      ];
      
      for (final key in keys) {
        final translation = localizationService.translate(key);
        expect(translation, isNot(equals(key)), reason: 'Key $key should be translated');
        expect(translation.isNotEmpty, isTrue, reason: 'Translation for $key should not be empty');
      }
    });

    test('should support multilingual onboarding', () async {
      // Test Spanish (default)
      await LocalizationService.instance.changeLocale(const Locale('es'));
      var welcomeTitle = LocalizationService.instance.translate('onboarding.onboarding_welcome_title');
      expect(welcomeTitle.isNotEmpty, isTrue);
      
      // Test English
      await LocalizationService.instance.changeLocale(const Locale('en'));
      welcomeTitle = LocalizationService.instance.translate('onboarding.onboarding_welcome_title');
      expect(welcomeTitle.isNotEmpty, isTrue);
      
      // Test Portuguese
      await LocalizationService.instance.changeLocale(const Locale('pt'));
      welcomeTitle = LocalizationService.instance.translate('onboarding.onboarding_welcome_title');
      expect(welcomeTitle.isNotEmpty, isTrue);
      
      // Test French
      await LocalizationService.instance.changeLocale(const Locale('fr'));
      welcomeTitle = LocalizationService.instance.translate('onboarding.onboarding_welcome_title');
      expect(welcomeTitle.isNotEmpty, isTrue);
    });
  });
}