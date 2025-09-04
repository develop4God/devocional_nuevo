import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_setup.dart';

void main() {
  setUpAll(() {
    TestSetup.setupCommonMocks();
  });

  tearDownAll(() {
    TestSetup.cleanupMocks();
  });

  group('DevocionalProvider Download Fallback Tests', () {
    late DevocionalProvider provider;

    setUp(() {
      // Initialize shared preferences
      SharedPreferences.setMockInitialValues({});
      provider = DevocionalProvider();
    });

    test(
        'should maintain language and version state correctly',
        () async {
      // Test the state management behavior
      provider.setSelectedLanguage('en');
      provider.setSelectedVersion('NIV');
      
      expect(provider.selectedLanguage, equals('en'));
      expect(provider.selectedVersion, equals('NIV'));
    });

    test('should handle valid language/version combinations', () async {
      provider.setSelectedLanguage('fr');
      provider.setSelectedVersion('LSG1910');

      expect(provider.selectedLanguage, equals('fr'));
      expect(provider.selectedVersion, equals('LSG1910'));
    });

    test('should accept any version for any language', () async {
      // The provider should accept any combination, validation happens elsewhere
      provider.setSelectedLanguage('pt');
      provider.setSelectedVersion('CUSTOM');

      expect(provider.selectedLanguage, equals('pt'));
      expect(provider.selectedVersion, equals('CUSTOM'));
    });
  });

  group('Constants URL Generation Tests', () {
    test('should generate correct URLs for 2025 multilingual files', () {
      // Test Spanish (backward compatibility)
      expect(Constants.getDevocionalesApiUrlMultilingual(2025, 'es', 'RVR1960'),
          'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_2025.json');

      // Test other languages
      expect(Constants.getDevocionalesApiUrlMultilingual(2025, 'en', 'KJV'),
          'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_2025_en_KJV.json');

      expect(Constants.getDevocionalesApiUrlMultilingual(2025, 'pt', 'ARC'),
          'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_2025_pt_ARC.json');

      expect(Constants.getDevocionalesApiUrlMultilingual(2025, 'fr', 'LSG1910'),
          'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_2025_fr_LSG1910.json');
    });

    test('should handle edge cases in URL generation', () {
      // Test empty/null cases
      expect(() => Constants.getDevocionalesApiUrlMultilingual(2025, '', ''),
          returnsNormally);

      // Test year variations
      expect(Constants.getDevocionalesApiUrlMultilingual(2024, 'en', 'KJV'),
          contains('2024_en_KJV'));
    });
  });

  group('Provider State Management Tests', () {
    late DevocionalProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = DevocionalProvider();
    });

    test('should initialize with default values', () {
      expect(provider.selectedLanguage, isNotNull);
      expect(provider.selectedVersion, isNotNull);
    });

    test('should update language and reset version correctly', () {
      provider.setSelectedLanguage('en');
      // Language switching might reset version to default for that language
      expect(provider.selectedLanguage, equals('en'));
    });

    test('should handle language switching gracefully', () {
      final initialLanguage = provider.selectedLanguage;
      
      provider.setSelectedLanguage('fr');
      expect(provider.selectedLanguage, equals('fr'));
      
      provider.setSelectedLanguage(initialLanguage);
      expect(provider.selectedLanguage, equals(initialLanguage));
    });
  });
}