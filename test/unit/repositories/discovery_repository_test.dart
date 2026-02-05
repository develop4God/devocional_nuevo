@Tags(['unit', 'repositories'])
library;

import 'dart:convert';

import 'package:devocional_nuevo/repositories/discovery_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockHttpClient;
  late DiscoveryRepository repository;

  setUp(() {
    mockHttpClient = MockHttpClient();
    repository = DiscoveryRepository(httpClient: mockHttpClient);
    SharedPreferences.setMockInitialValues({});
  });

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('DiscoveryRepository - Smart Cache with Version', () {
    const studyId = 'morning_star_001';
    const languageCode = 'es';
    const version1 = '1.0';
    const version2 = '1.1';

    final indexV1 = {
      'studies': [
        {
          'id': studyId,
          'version': version1,
          'files': {'es': 'morning_star_es_001.json'},
        },
      ],
    };

    final indexV2 = {
      'studies': [
        {
          'id': studyId,
          'version': version2,
          'files': {'es': 'morning_star_es_001.json'},
        },
      ],
    };

    final studyJsonV1 = {
      'id': studyId,
      'type': 'discovery',
      'date': '2026-01-15',
      'title': 'Study Version 1.0',
      'key_verse': {
        'reference': '2 Pedro 1:19',
        'text': 'Test verse',
      },
      'cards': [
        {
          'order': 1,
          'type': 'natural_revelation',
          'title': 'Card 1',
        },
      ],
    };

    final studyJsonV2 = {
      'id': studyId,
      'type': 'discovery',
      'date': '2026-01-15',
      'title': 'Study Version 1.1 - Updated',
      'key_verse': {
        'reference': '2 Pedro 1:19',
        'text': 'Test verse',
      },
      'cards': [
        {
          'order': 1,
          'type': 'natural_revelation',
          'title': 'Card 1 Updated',
        },
      ],
    };

    test('should fetch and cache study on first request', () async {
      when(() => mockHttpClient.get(any())).thenAnswer((invocation) async {
        final uri = invocation.positionalArguments[0] as Uri;
        if (uri.toString().contains('index.json')) {
          return http.Response(jsonEncode(indexV1), 200);
        } else {
          return http.Response(jsonEncode(studyJsonV1), 200);
        }
      });

      final study = await repository.fetchDiscoveryStudy(studyId, languageCode);

      expect(study.id, equals(studyId));
      expect(study.reflexion, equals('Study Version 1.0'));
      expect(study.cards, hasLength(1));

      final prefs = await SharedPreferences.getInstance();
      // Cache key now includes branch (tests run with kDebugMode=false, so always 'main')
      final cached =
          prefs.getString('discovery_cache_${studyId}_${languageCode}_main');
      final cachedVersion = prefs
          .getString('discovery_cache_${studyId}_${languageCode}_main_version');

      expect(cached, isNotNull);
      expect(cachedVersion, equals(version1));
    });

    test('should use cache when version matches', () async {
      final prefs = await SharedPreferences.getInstance();
      // Cache key now includes branch (tests run with kDebugMode=false, so always 'main')
      await prefs.setString(
        'discovery_cache_${studyId}_${languageCode}_main',
        jsonEncode(studyJsonV1),
      );
      await prefs.setString(
        'discovery_cache_${studyId}_${languageCode}_main_version',
        version1,
      );

      when(() => mockHttpClient.get(any())).thenAnswer((invocation) async {
        final uri = invocation.positionalArguments[0] as Uri;
        if (uri.toString().contains('index.json')) {
          return http.Response(jsonEncode(indexV1), 200);
        }
        throw Exception('Should not fetch study from network');
      });

      final study = await repository.fetchDiscoveryStudy(studyId, languageCode);

      expect(study.reflexion, equals('Study Version 1.0'));
      verify(() => mockHttpClient.get(any())).called(1);
    });

    test('should invalidate cache and fetch new version when version changes',
        () async {
      final prefs = await SharedPreferences.getInstance();
      // Cache key now includes branch (tests run with kDebugMode=false, so always 'main')
      await prefs.setString(
        'discovery_cache_${studyId}_${languageCode}_main',
        jsonEncode(studyJsonV1),
      );
      await prefs.setString(
        'discovery_cache_${studyId}_${languageCode}_main_version',
        version1,
      );

      when(() => mockHttpClient.get(any())).thenAnswer((invocation) async {
        final uri = invocation.positionalArguments[0] as Uri;
        if (uri.toString().contains('index.json')) {
          return http.Response(jsonEncode(indexV2), 200);
        } else {
          return http.Response(jsonEncode(studyJsonV2), 200);
        }
      });

      final study = await repository.fetchDiscoveryStudy(studyId, languageCode);

      expect(study.reflexion, equals('Study Version 1.1 - Updated'));
      expect(study.cards[0].title, equals('Card 1 Updated'));

      final cachedVersion = prefs
          .getString('discovery_cache_${studyId}_${languageCode}_main_version');
      expect(cachedVersion, equals(version2));

      verify(() => mockHttpClient.get(any())).called(2);
    });
  });
}
