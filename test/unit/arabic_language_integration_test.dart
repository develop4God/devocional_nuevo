@Tags(['integration'])
library;

// test/unit/arabic_language_integration_test.dart

import 'dart:convert';

import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:devocional_nuevo/services/cache_metadata_service.dart';
import 'package:devocional_nuevo/services/devocional_index_service.dart';
import 'package:devocional_nuevo/utils/constants/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';

class MockDevocionalIndexService extends Mock
    implements DevocionalIndexService {}

class MockCacheMetadataService extends Mock implements CacheMetadataService {}

class MockDevocionalRepository extends Mock implements DevocionalRepository {}

void main() {
  group('Arabic language support', () {
    test(
        'Provider includes Arabic (ar) in supportedLanguages — '
        'setSelectedLanguage("ar") must NOT fall back to "es"', () {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': {
              'ar': {
                '2025-01-01': [
                  {
                    'id': 'dev_ar_2025_01_01',
                    'date': '2025-01-01',
                    'versiculo': 'يوحنا 1:1',
                    'texto': 'فِي الْبَدْءِ كَانَ الْكَلِمَةُ',
                    'language': 'ar',
                    'version': 'NAV',
                  },
                ],
              },
            },
          }),
          200,
        );
      });

      final mockIndexService = MockDevocionalIndexService();
      final mockCacheService = MockCacheMetadataService();
      final mockRepository = MockDevocionalRepository();

      final provider = DevocionalProvider(
        httpClient: mockHttp,
        enableAudio: false,
        devocionalIndexService: mockIndexService,
        cacheMetadataService: mockCacheService,
        devocionalRepository: mockRepository,
      );

      expect(
        provider.supportedLanguages,
        contains('ar'),
        reason: 'Arabic must be a supported language in DevocionalProvider',
      );
    });

    test('Constants defines Arabic versions and default', () {
      expect(
        Constants.bibleVersionsByLanguage.containsKey('ar'),
        isTrue,
        reason: 'Constants.bibleVersionsByLanguage must contain "ar"',
      );
      expect(
        Constants.defaultVersionByLanguage.containsKey('ar'),
        isTrue,
        reason: 'Constants.defaultVersionByLanguage must contain "ar"',
      );
      final arabicVersions = Constants.bibleVersionsByLanguage['ar']!;
      final defaultArabic = Constants.defaultVersionByLanguage['ar']!;
      expect(
        arabicVersions.contains(defaultArabic),
        isTrue,
        reason:
            'Arabic default version "$defaultArabic" must be in its versions list',
      );
      expect(
        arabicVersions,
        containsAll(['NAV', 'SVDA']),
        reason: 'Arabic must have NAV and SVDA versions',
      );
    });

    test('getDevocionalesApiUrlMultilingual generates correct Arabic URL', () {
      const year = 2025;
      final url = Constants.getDevocionalesApiUrlMultilingual(
        year,
        'ar',
        'NAV',
      );
      expect(
        url,
        equals(
          'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_${year}_ar_NAV.json',
        ),
        reason: 'Arabic URL must follow the multilingual naming convention',
      );
    });

    test('Arabic language flag is registered', () {
      expect(
        Constants.languageFlags.containsKey('ar'),
        isTrue,
        reason: 'Constants.languageFlags must contain "ar"',
      );
      expect(
        Constants.getLanguageFlag('ar'),
        equals('🇸🇦'),
        reason: 'Arabic flag must be Saudi Arabia flag emoji',
      );
    });

    test('Arabic is in supportedLanguages map', () {
      expect(
        Constants.supportedLanguages.containsKey('ar'),
        isTrue,
        reason: 'Constants.supportedLanguages must contain "ar"',
      );
      expect(
        Constants.supportedLanguages['ar'],
        equals('العربية'),
        reason: 'Arabic display name must be العربية',
      );
    });
  });
}
