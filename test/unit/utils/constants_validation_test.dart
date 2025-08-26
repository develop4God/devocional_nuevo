import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/utils/constants.dart';

void main() {
  group('Constants Configuration Validation', () {
    test('all supported languages have default versions', () {
      // Verify every key in supportedLanguages exists in defaultVersionByLanguage
      for (final languageCode in Constants.supportedLanguages.keys) {
        expect(
          Constants.defaultVersionByLanguage.containsKey(languageCode),
          isTrue,
          reason: 'Language $languageCode should have a default version',
        );
      }
    });

    test('all supported languages have Bible versions', () {
      // Verify every key in supportedLanguages exists in bibleVersionsByLanguage
      for (final languageCode in Constants.supportedLanguages.keys) {
        expect(
          Constants.bibleVersionsByLanguage.containsKey(languageCode),
          isTrue,
          reason: 'Language $languageCode should have available Bible versions',
        );

        final versions = Constants.bibleVersionsByLanguage[languageCode]!;
        expect(
          versions.isNotEmpty,
          isTrue,
          reason:
              'Language $languageCode should have at least one Bible version',
        );
      }
    });

    test('default versions exist in available versions', () {
      // Verify defaultVersionByLanguage values exist in bibleVersionsByLanguage
      for (final entry in Constants.defaultVersionByLanguage.entries) {
        final languageCode = entry.key;
        final defaultVersion = entry.value;

        final availableVersions =
            Constants.bibleVersionsByLanguage[languageCode];
        expect(
          availableVersions,
          isNotNull,
          reason: 'Language $languageCode should have available versions',
        );

        expect(
          availableVersions!.contains(defaultVersion),
          isTrue,
          reason:
              'Default version $defaultVersion for $languageCode should exist in available versions: $availableVersions',
        );
      }
    });

    test('should maintain backward compatibility - original method unchanged',
        () {
      const int testYear = 2025;

      // Test original method for backward compatibility
      final originalUrl = Constants.getDevocionalesApiUrl(testYear);
      expect(
        originalUrl,
        equals(
            'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$testYear.json'),
        reason: 'Original method should maintain exact backward compatibility',
      );
    });

    test('getDevocionalesApiUrlMultilingual generates correct URLs', () {
      const int testYear = 2025;

      // Test Spanish (backward compatibility) - should use original URL format
      final spanishUrl = Constants.getDevocionalesApiUrlMultilingual(
          testYear, 'es', 'RVR1960');
      expect(
        spanishUrl,
        equals(
            'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$testYear.json'),
        reason: 'Spanish RVR1960 should maintain backward compatibility',
      );

      // Test Spanish with NVI - should use new format
      final spanishNviUrl =
          Constants.getDevocionalesApiUrlMultilingual(testYear, 'es', 'NVI');
      expect(
        spanishNviUrl,
        equals(
            'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_${testYear}_es_NVI.json'),
        reason: 'Spanish NVI URL should use new format',
      );

      // Test English with KJV
      final englishKjvUrl =
          Constants.getDevocionalesApiUrlMultilingual(testYear, 'en', 'KJV');
      expect(
        englishKjvUrl,
        equals(
            'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_${testYear}_en_KJV.json'),
        reason: 'English KJV URL should use new format',
      );

      // Test English with NIV
      final englishNivUrl =
          Constants.getDevocionalesApiUrlMultilingual(testYear, 'en', 'NIV');
      expect(
        englishNivUrl,
        equals(
            'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_${testYear}_en_NIV.json'),
        reason: 'English NIV URL should use new format',
      );

      // Test Portuguese with ARC
      final portugueseArcUrl =
          Constants.getDevocionalesApiUrlMultilingual(testYear, 'pt', 'ARC');
      expect(
        portugueseArcUrl,
        equals(
            'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_${testYear}_pt_ARC.json'),
        reason: 'Portuguese ARC URL should use new format',
      );

      // Test French with LSG
      final frenchLsgUrl =
          Constants.getDevocionalesApiUrlMultilingual(testYear, 'fr', 'LSG');
      expect(
        frenchLsgUrl,
        equals(
            'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_${testYear}_fr_LSG.json'),
        reason: 'French LSG URL should use new format',
      );
    });

    test('constants data consistency', () {
      // Verify no orphaned or missing mappings between constants maps
      final supportedLanguageKeys = Constants.supportedLanguages.keys.toSet();
      final bibleVersionsKeys = Constants.bibleVersionsByLanguage.keys.toSet();
      final defaultVersionKeys =
          Constants.defaultVersionByLanguage.keys.toSet();

      expect(
        supportedLanguageKeys,
        equals(bibleVersionsKeys),
        reason: 'Supported languages and bible versions should have same keys',
      );

      expect(
        supportedLanguageKeys,
        equals(defaultVersionKeys),
        reason:
            'Supported languages and default versions should have same keys',
      );

      // Verify Spanish is always present (backward compatibility)
      expect(
        supportedLanguageKeys.contains('es'),
        isTrue,
        reason:
            'Spanish language support is required for backward compatibility',
      );

      expect(
        Constants.defaultVersionByLanguage['es'],
        equals('RVR1960'),
        reason:
            'Spanish default version should be RVR1960 for backward compatibility',
      );
    });

    test('multilingual URL generation handles edge cases', () {
      const int testYear = 2025;

      // Test case sensitivity - language and version codes should be used as-is
      final lowerCaseUrl =
          Constants.getDevocionalesApiUrlMultilingual(testYear, 'en', 'kjv');
      expect(
        lowerCaseUrl,
        equals(
            'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_${testYear}_en_kjv.json'),
        reason:
            'Language and version codes should be used as-is (no case conversion)',
      );

      // Test different year
      final differentYearUrl =
          Constants.getDevocionalesApiUrlMultilingual(2026, 'en', 'NIV');
      expect(
        differentYearUrl,
        equals(
            'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_2026_en_NIV.json'),
        reason: 'URL should work with different years',
      );
    });

    test('supported languages structure is valid', () {
      // Verify supported languages map has proper structure
      expect(
        Constants.supportedLanguages.isNotEmpty,
        isTrue,
        reason: 'Should have at least one supported language',
      );

      for (final entry in Constants.supportedLanguages.entries) {
        expect(
          entry.key.isNotEmpty,
          isTrue,
          reason: 'Language code should not be empty',
        );

        expect(
          entry.value.isNotEmpty,
          isTrue,
          reason: 'Language name should not be empty',
        );

        expect(
          entry.key.length,
          equals(2),
          reason: 'Language code should be 2 characters (ISO 639-1)',
        );
      }
    });

    test('Bible versions structure is valid', () {
      // Verify Bible versions map has proper structure
      for (final entry in Constants.bibleVersionsByLanguage.entries) {
        expect(
          entry.value.isNotEmpty,
          isTrue,
          reason:
              'Language ${entry.key} should have at least one Bible version',
        );

        for (final version in entry.value) {
          expect(
            version.isNotEmpty,
            isTrue,
            reason: 'Bible version code should not be empty',
          );

          expect(
            RegExp(r'^[A-Z0-9]+$').hasMatch(version),
            isTrue,
            reason:
                'Bible version $version should only contain uppercase letters and numbers',
          );
        }
      }
    });
  });
}
