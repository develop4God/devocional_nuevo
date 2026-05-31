@Tags(['integration'])
library;

// test/unit/german_language_integration_test.dart

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
  group('German language support', () {
    test(
        'Provider includes German (de) in supportedLanguages — '
        'setSelectedLanguage("de") must NOT fall back to "es"', () {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': {
              'de': {
                '2025-01-01': [
                  {
                    'id': 'dev_de_2025_01_01',
                    'date': '2025-01-01',
                    'versiculo': 'Johannes 1:1',
                    'texto': 'Im Anfang war das Wort',
                    'language': 'de',
                    'version': 'LU17',
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
        contains('de'),
        reason: 'German must be a supported language in DevocionalProvider',
      );
    });

    test('Constants defines German versions and default', () {
      expect(
        Constants.bibleVersionsByLanguage.containsKey('de'),
        isTrue,
        reason: 'Constants.bibleVersionsByLanguage must contain "de"',
      );
      expect(
        Constants.defaultVersionByLanguage.containsKey('de'),
        isTrue,
        reason: 'Constants.defaultVersionByLanguage must contain "de"',
      );
      final germanVersions = Constants.bibleVersionsByLanguage['de']!;
      final defaultGerman = Constants.defaultVersionByLanguage['de']!;
      expect(
        germanVersions.contains(defaultGerman),
        isTrue,
        reason:
            'German default version "$defaultGerman" must be in its versions list',
      );
    });

    test('getDevocionalesApiUrlMultilingual generates correct German URL', () {
      const year = 2025;
      final url = Constants.getDevocionalesApiUrlMultilingual(
        year,
        'de',
        'LU17',
      );
      expect(
        url,
        equals(
          'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_${year}_de_LU17.json',
        ),
        reason: 'German URL must follow the multilingual naming convention',
      );
    });
  });
}
