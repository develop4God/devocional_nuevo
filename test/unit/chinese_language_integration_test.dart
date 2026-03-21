@Tags(['integration'])
library;

// test/unit/chinese_language_integration_test.dart

import 'dart:convert';

import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/cache_metadata_service.dart';
import 'package:devocional_nuevo/services/devocional_index_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';

// Mock implementations
class MockDevocionalIndexService extends Mock
    implements DevocionalIndexService {}

class MockCacheMetadataService extends Mock implements CacheMetadataService {}

void main() {
  test(
      'Provider supports Chinese language (zh) and exposes it in supportedLanguages',
      () {
    final mockHttp = MockClient((request) async {
      // Minimal valid payload so provider parsing won't fail if used later
      return http.Response(
          jsonEncode({
            'data': {
              'zh': {
                '2025-01-01': [
                  {
                    'id': 'dev_zh_2025_01_01',
                    'date': '2025-01-01',
                    'versiculo': '约翰 1:1',
                    'texto': '测试文本',
                    'language': 'zh',
                    'version': 'KJV'
                  }
                ]
              }
            }
          }),
          200);
    });

    // Create mock services to bypass service locator dependency
    final mockIndexService = MockDevocionalIndexService();
    final mockCacheService = MockCacheMetadataService();

    final provider = DevocionalProvider(
      httpClient: mockHttp,
      enableAudio: false,
      devocionalIndexService: mockIndexService,
      cacheMetadataService: mockCacheService,
    );

    expect(provider.supportedLanguages, contains('zh'));
  });
}
