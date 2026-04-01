@Tags(['unit', 'repositories'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:devocional_nuevo/constants/devocional_years.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/repositories/devocional_repository_impl.dart';
import 'package:devocional_nuevo/services/cache_metadata_service.dart';
import 'package:devocional_nuevo/services/devocional_index_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockDevocionalIndexService extends Mock
    implements DevocionalIndexService {}

class MockCacheMetadataService extends Mock implements CacheMetadataService {}

class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      '/tmp/test_devocional_repo';
}

/// Builds a minimal valid API response JSON for [language]/[version].
Map<String, dynamic> _buildApiResponse({
  String language = 'es',
  String version = 'RVR1960',
  int year = 2025,
  int count = 2,
}) {
  final Map<String, dynamic> dateEntries = {};
  for (int i = 1; i <= count; i++) {
    final date = '$year-01-0$i';
    dateEntries[date] = [
      {
        'id': 'dev_${year}_${i}_$language',
        'versiculo': 'Test verse $i',
        'reflexion': 'Test reflection $i',
        'para_meditar': <dynamic>[],
        'oracion': 'Test prayer $i',
        'date': date,
        'version': version,
        'language': language,
      },
    ];
  }
  return {
    'data': {language: dateEntries},
  };
}

void main() {
  late MockHttpClient mockHttpClient;
  late MockDevocionalIndexService mockIndexService;
  late MockCacheMetadataService mockMetadataService;
  late DevocionalRepositoryImpl repository;

  const testDir = '/tmp/test_devocional_repo';

  setUpAll(() {
    registerFallbackValue(Uri());
    TestWidgetsFlutterBinding.ensureInitialized();
    PathProviderPlatform.instance = MockPathProviderPlatform();

    // Ensure test directory exists
    Directory('$testDir/devocionales').createSync(recursive: true);
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockIndexService = MockDevocionalIndexService();
    mockMetadataService = MockCacheMetadataService();

    // Default stubs: index unreachable (offline), no sidecar
    when(() => mockIndexService.fetchIndex()).thenAnswer((_) async => null);
    when(() => mockIndexService.getFileDate(any(), any(), any(), any()))
        .thenReturn(null);
    when(() => mockIndexService.extractAvailableYears(any())).thenReturn([]);
    when(() => mockMetadataService.readManifestDate(any()))
        .thenAnswer((_) async => null);
    when(() => mockMetadataService.writeMetadata(any(), any()))
        .thenAnswer((_) async {});

    repository = DevocionalRepositoryImpl(
      httpClient: mockHttpClient,
      devocionalIndexService: mockIndexService,
      cacheMetadataService: mockMetadataService,
    );
  });

  tearDown(() {
    // Clean up test files
    final dir = Directory('$testDir/devocionales');
    if (dir.existsSync()) {
      for (final f in dir.listSync()) {
        if (f is File) f.deleteSync();
      }
    }
  });

  // ---------------------------------------------------------------------------
  // fetchAll
  // ---------------------------------------------------------------------------

  group('fetchAll — HTTP 200', () {
    test('returns parsed List<Devocional> from HTTP 200 response', () async {
      final responseBody =
          json.encode(_buildApiResponse(language: 'es', version: 'RVR1960'));

      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response.bytes(
          utf8.encode(responseBody),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );

      final result = await repository.fetchAll(2025, 'es', 'RVR1960');

      expect(result, isNotEmpty);
      expect(result.length, 2);
      expect(result.every((d) => d.language == 'es'), isTrue);
      expect(result.every((d) => d.version == 'RVR1960'), isTrue);
    });
  });

  group('fetchAll — HTTP failure', () {
    test('falls back to local storage when HTTP throws', () async {
      // Write a local file first
      final file = File('$testDir/devocionales/devocional_2025_es.json');
      final localContent =
          json.encode(_buildApiResponse(language: 'es', version: 'RVR1960'));
      await file.writeAsString(localContent);

      when(() => mockHttpClient.get(any()))
          .thenThrow(Exception('Network error'));

      final result = await repository.fetchAll(2025, 'es', 'RVR1960');

      expect(result, isNotEmpty);
      expect(result.first.language, 'es');
    });

    test('returns empty list when both HTTP and local storage fail', () async {
      when(() => mockHttpClient.get(any()))
          .thenThrow(Exception('Network error'));

      // No local file exists — using a year that won't have a cached file
      final result = await repository.fetchAll(2099, 'es', 'RVR1960');

      expect(result, isEmpty);
    });

    test('returns empty list on HTTP non-200 with no local cache', () async {
      when(() => mockHttpClient.get(any()))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      final result = await repository.fetchAll(2099, 'en', 'NIV');

      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // filterByVersion
  // ---------------------------------------------------------------------------

  group('filterByVersion', () {
    late List<Devocional> devocionales;

    setUp(() {
      devocionales = [
        Devocional(
          id: 'dev1',
          versiculo: 'verse',
          reflexion: 'reflection',
          paraMeditar: [],
          oracion: 'prayer',
          date: DateTime(2025, 1, 1),
          version: 'RVR1960',
        ),
        Devocional(
          id: 'dev2',
          versiculo: 'verse',
          reflexion: 'reflection',
          paraMeditar: [],
          oracion: 'prayer',
          date: DateTime(2025, 1, 2),
          version: 'RVR1960',
        ),
        Devocional(
          id: 'dev3',
          versiculo: 'verse',
          reflexion: 'reflection',
          paraMeditar: [],
          oracion: 'prayer',
          date: DateTime(2025, 1, 3),
          version: 'NVI',
        ),
      ];
    });

    test('returns only matching version devotionals', () {
      final result = repository.filterByVersion(devocionales, 'RVR1960');

      expect(result.length, 2);
      expect(result.every((d) => d.version == 'RVR1960'), isTrue);
    });

    test('returns all when version is empty', () {
      final result = repository.filterByVersion(devocionales, '');

      expect(result.length, 3);
    });

    test('returns empty list when no devotionals match version', () {
      final result = repository.filterByVersion(devocionales, 'LBLA');

      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // hasLocalData
  // ---------------------------------------------------------------------------

  group('hasLocalData', () {
    test('returns true when file exists', () async {
      final file = File('$testDir/devocionales/devocional_2025_es.json');
      await file.writeAsString('{}');

      final result = await repository.hasLocalData(2025, 'es', 'RVR1960');

      expect(result, isTrue);
    });

    test('returns false when file does not exist', () async {
      final result = await repository.hasLocalData(2099, 'es', 'RVR1960');

      expect(result, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // downloadAndStoreDevocionales
  // ---------------------------------------------------------------------------

  group('downloadAndStoreDevocionales', () {
    test('saves file to local storage on HTTP 200 success', () async {
      final responseBody =
          json.encode(_buildApiResponse(language: 'es', version: 'RVR1960'));

      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response.bytes(
          utf8.encode(responseBody),
          200,
        ),
      );

      final result =
          await repository.downloadAndStoreDevocionales(2025, 'es', 'RVR1960');

      expect(result, isTrue);

      final file = File('$testDir/devocionales/devocional_2025_es.json');
      expect(await file.exists(), isTrue);
    });

    test('returns false and does not write on HTTP 404', () async {
      when(() => mockHttpClient.get(any()))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      final result =
          await repository.downloadAndStoreDevocionales(2099, 'es', 'RVR1960');

      expect(result, isFalse);
    });

    test('returns false on HTTP 500 error', () async {
      when(() => mockHttpClient.get(any()))
          .thenAnswer((_) async => http.Response('Server Error', 500));

      final result =
          await repository.downloadAndStoreDevocionales(2099, 'es', 'RVR1960');

      expect(result, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // wasLastFetchOffline / resetIndexCache
  // ---------------------------------------------------------------------------

  group('wasLastFetchOffline', () {
    test('is false before any fetch', () {
      expect(repository.wasLastFetchOffline, isFalse);
    });

    test('is true after fetchAll when index is unreachable', () async {
      when(() => mockIndexService.fetchIndex()).thenAnswer((_) async => null);
      when(() => mockHttpClient.get(any()))
          .thenThrow(Exception('Network error'));

      await repository.fetchAll(2099, 'es', 'RVR1960');

      expect(repository.wasLastFetchOffline, isTrue);
    });

    test('is false after resetCache', () async {
      when(() => mockIndexService.fetchIndex()).thenAnswer((_) async => null);
      when(() => mockHttpClient.get(any()))
          .thenThrow(Exception('Network error'));

      await repository.fetchAll(2099, 'es', 'RVR1960');
      repository.resetCache();

      expect(repository.wasLastFetchOffline, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // findFirstUnreadDevocionalIndex
  // ---------------------------------------------------------------------------

  group('findFirstUnreadDevocionalIndex', () {
    test('returns 0 for empty list', () {
      expect(
        repository.findFirstUnreadDevocionalIndex([], ['id1']),
        0,
      );
    });

    test('returns index of first unread devotional', () {
      final devocionales = [
        Devocional(
          id: 'dev1',
          versiculo: 'v',
          reflexion: 'r',
          paraMeditar: [],
          oracion: 'o',
          date: DateTime(2025, 1, 1),
        ),
        Devocional(
          id: 'dev2',
          versiculo: 'v',
          reflexion: 'r',
          paraMeditar: [],
          oracion: 'o',
          date: DateTime(2025, 1, 2),
        ),
        Devocional(
          id: 'dev3',
          versiculo: 'v',
          reflexion: 'r',
          paraMeditar: [],
          oracion: 'o',
          date: DateTime(2025, 1, 3),
        ),
      ];
      final readIds = ['dev1', 'dev2'];

      expect(
        repository.findFirstUnreadDevocionalIndex(devocionales, readIds),
        2,
      );
    });

    test('returns 0 when all devotionals are read', () {
      final devocionales = [
        Devocional(
          id: 'dev1',
          versiculo: 'v',
          reflexion: 'r',
          paraMeditar: [],
          oracion: 'o',
          date: DateTime(2025, 1, 1),
        ),
        Devocional(
          id: 'dev2',
          versiculo: 'v',
          reflexion: 'r',
          paraMeditar: [],
          oracion: 'o',
          date: DateTime(2025, 1, 2),
        ),
      ];
      final readIds = ['dev1', 'dev2'];

      expect(
        repository.findFirstUnreadDevocionalIndex(devocionales, readIds),
        0,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getAvailableYears
  // ---------------------------------------------------------------------------

  group('getAvailableYears', () {
    test('returns years extracted from index when online', () async {
      final index = {
        'schema_version': 1,
        'files': {
          'es': {
            'RVR1960': {'2025': '2026-01-01', '2026': '2026-01-01'},
          },
          'en': {
            'KJV': {'2025': '2026-01-01', '2027': '2026-01-01'},
          },
        },
      };

      when(() => mockIndexService.fetchIndex()).thenAnswer((_) async => index);
      when(() => mockIndexService.extractAvailableYears(any()))
          .thenReturn([2025, 2026, 2027]);

      // Reset cache so the new stub is used
      repository.resetCache();
      final result = await repository.getAvailableYears();

      expect(result, [2025, 2026, 2027]);
    });

    test('falls back to DevocionalYears.availableYears when index is null',
        () async {
      when(() => mockIndexService.fetchIndex()).thenAnswer((_) async => null);
      when(() => mockIndexService.extractAvailableYears(any())).thenReturn([]);

      repository.resetCache();
      final result = await repository.getAvailableYears();

      expect(result, DevocionalYears.availableYears);
    });

    test('falls back when index returns empty year list', () async {
      final index = {'schema_version': 1, 'files': <String, dynamic>{}};

      when(() => mockIndexService.fetchIndex()).thenAnswer((_) async => index);
      when(() => mockIndexService.extractAvailableYears(any())).thenReturn([]);

      repository.resetCache();
      final result = await repository.getAvailableYears();

      expect(result, DevocionalYears.availableYears);
    });

    test('result is sorted ascending', () async {
      final index = {
        'schema_version': 1,
        'files': {
          'es': {
            'RVR1960': {'2026': '2026-01-01', '2025': '2026-01-01'},
          },
        },
      };

      when(() => mockIndexService.fetchIndex()).thenAnswer((_) async => index);
      when(() => mockIndexService.extractAvailableYears(any()))
          .thenReturn([2025, 2026]);

      repository.resetCache();
      final result = await repository.getAvailableYears();

      expect(result, [2025, 2026]);
      for (int i = 0; i < result.length - 1; i++) {
        expect(result[i] < result[i + 1], isTrue);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // All tests use mocked http.Client — no real network calls
  // ---------------------------------------------------------------------------

  group('All tests use mocked http.Client', () {
    test('no real network calls are made', () async {
      when(() => mockHttpClient.get(any()))
          .thenAnswer((_) async => http.Response('{"data":{}}', 200));

      // Force an API fetch (no local file for year 2099)
      await repository.fetchAll(2099, 'es', 'RVR1960');

      // Verify the mock was called (not real network)
      verify(() => mockHttpClient.get(any())).called(1);
    });
  });
}
