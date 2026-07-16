@Tags(['unit', 'repositories'])
library;

import 'dart:convert';

import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/repositories/encounter_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockHttpClient;
  late EncounterRepository repository;

  setUp(() {
    mockHttpClient = MockHttpClient();
    repository = EncounterRepository(httpClient: mockHttpClient);
    SharedPreferences.setMockInitialValues({});
  });

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('EncounterRepository - clearCache', () {
    const studyId = 'peter_water_001';
    const lang = 'en';
    const version1 = '1.0';

    final index = {
      'encounters': [
        {'id': studyId, 'version': version1, 'files': {}, 'titles': {}},
      ],
    };

    final studyJson = {
      'id': studyId,
      'titles': {'en': 'Peter Walks on Water'},
    };

    test(
      'removes index and study cache, forcing fresh network fetch',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('encounter_index_cache', jsonEncode(index));
        await prefs.setString(
          'encounter_cache_${studyId}_$lang',
          jsonEncode(studyJson),
        );
        await prefs.setString(
          'encounter_cache_${studyId}_${lang}_version',
          version1,
        );

        await repository.clearCache();

        expect(prefs.getString('encounter_index_cache'), isNull);
        expect(prefs.getString('encounter_cache_${studyId}_$lang'), isNull);
        expect(
          prefs.getString('encounter_cache_${studyId}_${lang}_version'),
          isNull,
        );

        when(() => mockHttpClient.get(any())).thenAnswer((invocation) async {
          final uri = invocation.positionalArguments[0] as Uri;
          if (uri.toString().contains('index.json')) {
            return http.Response(jsonEncode(index), 200);
          }
          return http.Response(jsonEncode(studyJson), 200);
        });

        final entries = await repository.fetchIndex();
        expect(entries, hasLength(1));
        expect(entries.first.id, equals(studyId));

        final study = await repository.fetchStudy(
          studyId,
          lang,
          entry: const EncounterIndexEntry(
            id: studyId,
            version: version1,
            files: {},
            titles: {},
            subtitles: {},
            scriptureReference: {},
            estimatedReadingMinutes: {},
          ),
        );
        expect(study.id, equals(studyId));

        verify(() => mockHttpClient.get(any())).called(2);
      },
    );
  });
}
