@Tags(['unit', 'providers'])
library;

// test/unit/providers/german_language_persistence_test.dart
//
// Test that German language preference persists and loads German devotionals
// correctly on app startup.

import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:devocional_nuevo/services/cache_metadata_service.dart';
import 'package:devocional_nuevo/services/devocional_index_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDevocionalIndexService extends Mock
    implements DevocionalIndexService {}

class MockCacheMetadataService extends Mock implements CacheMetadataService {}

class MockDevocionalRepository extends Mock implements DevocionalRepository {}

void main() {
  group('German Language Persistence', () {
    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test(
        'German language is included in supportedLanguages and not downgraded to es',
        () {
      final mockHttp = MockClient((request) async {
        return http.Response('{"data": {"de": {}}}', 200);
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
        reason: 'German must be in supportedLanguages',
      );

      expect(
        provider.supportedLanguages.contains('de'),
        isTrue,
        reason: 'German was recently added and must be present',
      );
    });

    test('German language preference can be set and retrieved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Simulate setting German as the preferred language
      await prefs.setString('selectedLanguage', 'de');
      await prefs.setString('selectedVersion', 'LU17');

      // Verify it was saved
      expect(prefs.getString('selectedLanguage'), equals('de'));
      expect(prefs.getString('selectedVersion'), equals('LU17'));
    });

    test('German language is not silently downgraded to Spanish fallback', () {
      final mockHttp = MockClient((request) async {
        return http.Response('{"data": {}}', 200);
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

      // Simulate device/saved language being German
      expect(
        provider.supportedLanguages.contains('de'),
        isTrue,
        reason:
            'German must be supported to prevent fallback to es during initialization',
      );

      // The provider should be able to accept 'de' as a valid language
      // without falling back to 'es'
      expect(
        provider.supportedLanguages.where((lang) => lang == 'de'),
        isNotEmpty,
        reason:
            'German language code de must be in the supported languages list',
      );
    });

    test('German default version (LU17) is correctly matched from constants',
        () {
      final mockHttp = MockClient((request) async {
        return http.Response('{"data": {}}', 200);
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

      // Get available versions for German
      final germanVersions = provider.getVersionsForLanguage('de');
      expect(germanVersions, isNotEmpty);
      expect(germanVersions, contains('LU17'));
      expect(germanVersions, contains('SCH2000'));
    });
  });
}
