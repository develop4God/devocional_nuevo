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

    test('getDevocionalesApiUrl generates correct URLs', () {
      const int testYear = 2025;

      // Test Spanish (backward compatibility) - should use original URL format
      final spanishUrl =
          Constants.getDevocionalesApiUrl(testYear, 'es', 'RVR1960');
      expect(
        spanishUrl,
        equals(
            'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$testYear.json'),
        reason: 'Spanish URL should maintain backward compatibility',
      );

      // Test Spanish without explicit language/version
      final defaultUrl = Constants.getDevocionalesApiUrl(testYear);
      expect(
        defaultUrl,
        equals(spanishUrl),
        reason:
            'Default URL should be same as Spanish URL for backward compatibility',
      );

      // Test English with KJV
      final englishKjvUrl =
          Constants.getDevocionalesApiUrl(testYear, 'en', 'KJV');
      expect(
        englishKjvUrl,
        equals(
            'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$testYear._EN_KJV.json'),
        reason: 'English KJV URL should use new format',
      );

      // Test English with NIV
      final englishNivUrl =
          Constants.getDevocionalesApiUrl(testYear, 'en', 'NIV');
      expect(
        englishNivUrl,
        equals(
            'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$testYear._EN_NIV.json'),
        reason: 'English NIV URL should use new format',
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

    test('URL generation handles edge cases', () {
      const int testYear = 2025;

      // Test null language with version
      final nullLanguageUrl =
          Constants.getDevocionalesApiUrl(testYear, null, 'NIV');
      expect(
        nullLanguageUrl,
        equals(
            'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$testYear.json'),
        reason: 'Null language should default to Spanish format',
      );

      // Test language without version
      final noVersionUrl = Constants.getDevocionalesApiUrl(testYear, 'en');
      expect(
        noVersionUrl,
        equals(
            'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$testYear._EN_.json'),
        reason: 'Missing version should result in empty version code',
      );

      // Test case sensitivity
      final lowerCaseUrl =
          Constants.getDevocionalesApiUrl(testYear, 'en', 'kjv');
      expect(
        lowerCaseUrl,
        equals(
            'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$testYear._EN_KJV.json'),
        reason: 'Language and version codes should be converted to uppercase',
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
