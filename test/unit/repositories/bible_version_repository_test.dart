@Tags(['unit', 'repositories'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/repositories/bible_version_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeStreamedRequest extends Fake implements http.BaseRequest {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHttpClient mockHttpClient;
  late BibleVersionRepository repository;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(FakeStreamedRequest());
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    repository = BibleVersionRepository(httpClient: mockHttpClient);
    SharedPreferences.setMockInitialValues({});
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  tearDown(() {
    // Clean up any test-installed .SQLite3 files from systemTemp so
    // downloadVersion tests don't leak files across test runs.
    for (final name in [
      'PROGRESS_xx.SQLite3',
      'INDET_xx.SQLite3',
    ]) {
      final f = File('${Directory.systemTemp.path}/$name');
      if (f.existsSync()) f.deleteSync();
    }
  });

  // Full index covering languages/versions actually asserted on below.
  final fullIndex = {
    'meta': {'version': '1.0.0'},
    'languages': {
      'en': {
        'primary_version': 'KJV',
        'versions': {
          'KJV': {
            'name': 'King James Version',
            'file': 'KJV_en.SQLite3.gz',
            'url': 'https://raw.githubusercontent.com/develop4God/'
                'bible_versions/main/en/KJV_en.SQLite3.gz',
          },
          'NIV': {
            'name': 'New International Version',
            'file': 'NIV_en.SQLite3.gz',
            'url': 'https://raw.githubusercontent.com/develop4God/'
                'bible_versions/main/en/NIV_en.SQLite3.gz',
          },
          'ESV': {
            'name': 'English Standard Version',
            'file': 'ESV_en.SQLite3.gz',
            'url': 'https://raw.githubusercontent.com/develop4God/'
                'bible_versions/main/en/ESV_en.SQLite3.gz',
          },
        },
      },
      'fr': {
        'primary_version': 'LSG1910',
        'versions': {
          'LSG1910': {
            'name': 'Louis Segond 1910',
            'file': 'LSG1910_fr.SQLite3.gz',
            'url': 'https://raw.githubusercontent.com/develop4God/'
                'bible_versions/main/fr/LSG1910_fr.SQLite3.gz',
          },
          'BDS': {
            'name': 'Bible du Semeur',
            'file': 'BDS_fr.SQLite3.gz',
            'url': 'https://raw.githubusercontent.com/develop4God/'
                'bible_versions/main/fr/BDS_fr.SQLite3.gz',
          },
        },
      },
    },
  };

  group('fetchRemoteVersions', () {
    test('parses index and returns allowlisted, non-bundled versions',
        () async {
      when(() => mockHttpClient.get(any()))
          .thenAnswer((_) async => http.Response(jsonEncode(fullIndex), 200));

      // 'en' bundled versions are KJV/NIV/ESV (see BibleVersionRegistry) —
      // all three are bundled, so nothing should be eligible for 'en'.
      final enResult = await repository.fetchRemoteVersions('en');
      expect(enResult, isEmpty);
    });

    test('excludes versions already bundled as app assets', () async {
      when(() => mockHttpClient.get(any()))
          .thenAnswer((_) async => http.Response(jsonEncode(fullIndex), 200));

      // 'fr' bundled versions are LSG1910/BDS — both bundled, so the
      // fr result should also exclude them despite LSG1910 being
      // allowlisted (bundled wins).
      final frResult = await repository.fetchRemoteVersions('fr');
      expect(
        frResult.any((v) => v.dbFileName.startsWith('LSG1910')),
        isFalse,
      );
    });

    test('filters remote versions through the allowlist', () async {
      final index = {
        'languages': {
          'de': {
            'versions': {
              // Not bundled for 'de' (bundled are LU17/SCH2000) and NOT on
              // the allowlist — must be excluded.
              'NOTALLOWED': {
                'name': 'Not Allowed Version',
                'file': 'NOTALLOWED_de.SQLite3.gz',
                'url': 'https://example.com/NOTALLOWED_de.SQLite3.gz',
              },
            },
          },
        },
      };
      when(() => mockHttpClient.get(any()))
          .thenAnswer((_) async => http.Response(jsonEncode(index), 200));

      final result = await repository.fetchRemoteVersions('de');
      expect(result, isEmpty);
    });

    test('includes an allowlisted, non-bundled version with remoteUrl set',
        () async {
      // Every allowlisted code (KJV, LSG1910, CUV1919, SVDA, HIOV) is
      // already bundled for its real language in BibleVersionRegistry, so
      // to exercise the genuinely-eligible path (allowlisted AND not
      // bundled) this uses a language code with no bundled versions at
      // all — the version is still on the allowlist by code ('KJV').
      final index = {
        'languages': {
          'xx': {
            'versions': {
              'KJV': {
                'name': 'King James Version (test lang)',
                'file': 'KJV_xx.SQLite3.gz',
                'url': 'https://raw.githubusercontent.com/develop4God/'
                    'bible_versions/main/xx/KJV_xx.SQLite3.gz',
              },
            },
          },
        },
      };
      when(() => mockHttpClient.get(any()))
          .thenAnswer((_) async => http.Response(jsonEncode(index), 200));

      final result = await repository.fetchRemoteVersions('xx');

      expect(result, hasLength(1));
      expect(result.first.dbFileName, 'KJV_xx.SQLite3');
      expect(result.first.isRemote, isTrue);
      expect(
        result.first.remoteUrl,
        'https://raw.githubusercontent.com/develop4God/'
        'bible_versions/main/xx/KJV_xx.SQLite3.gz',
      );
    });

    test('session cache avoids a second network call', () async {
      when(() => mockHttpClient.get(any()))
          .thenAnswer((_) async => http.Response(jsonEncode(fullIndex), 200));

      await repository.fetchRemoteVersions('en');
      await repository.fetchRemoteVersions('fr');

      verify(() => mockHttpClient.get(any())).called(1);
    });

    test('falls back to stale cache on network failure', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'bible_versions_index_cache_main',
        jsonEncode(fullIndex),
      );

      when(() => mockHttpClient.get(any()))
          .thenThrow(Exception('network down'));

      // Should not throw — falls back to the stale cache above.
      final result = await repository.fetchRemoteVersions('en');
      expect(result, isEmpty); // en is fully bundled per fullIndex
    });
  });

  group('downloadVersion', () {
    BibleVersion remoteVersion(String dbFileName, String url) {
      return BibleVersion(
        name: 'Test Version',
        language: 'Test',
        languageCode: 'xx',
        assetPath: '',
        dbFileName: dbFileName,
        isDownloaded: false,
        remoteUrl: url,
      );
    }

    test('non-200 response throws a network exception', () async {
      when(() => mockHttpClient.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(const Stream.empty(), 404),
      );

      await expectLater(
        repository.downloadVersion(
          remoteVersion('FAIL_xx.SQLite3', 'https://example.com/fail.gz'),
        ),
        throwsA(
          isA<BibleVersionDownloadException>().having(
            (e) => e.kind,
            'kind',
            BibleVersionDownloadErrorKind.network,
          ),
        ),
      );
    });

    test('corrupt gzip body throws a corrupt exception', () async {
      when(() => mockHttpClient.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value([1, 2, 3, 4]),
          200,
          contentLength: 4,
        ),
      );

      await expectLater(
        repository.downloadVersion(
          remoteVersion(
            'CORRUPT_xx.SQLite3',
            'https://example.com/corrupt.gz',
          ),
        ),
        throwsA(
          isA<BibleVersionDownloadException>().having(
            (e) => e.kind,
            'kind',
            BibleVersionDownloadErrorKind.corrupt,
          ),
        ),
      );
    });

    test('progress callback sequence reaches 1.0 for known contentLength',
        () async {
      final gzipBytes = _validGzipBytes();
      when(() => mockHttpClient.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value(gzipBytes),
          200,
          contentLength: gzipBytes.length,
        ),
      );

      final progressValues = <double?>[];
      await repository.downloadVersion(
        remoteVersion('PROGRESS_xx.SQLite3', 'https://example.com/ok.gz'),
        onProgress: progressValues.add,
      );

      expect(progressValues, isNotEmpty);
      expect(progressValues.last, 1.0);
    });

    test('null contentLength keeps progress indeterminate (null only)',
        () async {
      final gzipBytes = _validGzipBytes();
      when(() => mockHttpClient.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value(gzipBytes),
          200,
        ),
      );

      final progressValues = <double?>[];
      await repository.downloadVersion(
        remoteVersion('INDET_xx.SQLite3', 'https://example.com/ok2.gz'),
        onProgress: progressValues.add,
      );

      expect(progressValues, isNotEmpty);
      expect(progressValues.every((p) => p == null), isTrue);
    });
  });
}

/// A minimal valid gzip payload (gzip of an empty byte list), sufficient
/// for GZipDecoder to decode successfully without a real SQLite file.
List<int> _validGzipBytes() {
  // gzip header + empty deflate stream + crc32/size trailer for zero bytes.
  return [
    0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, //
    0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  ];
}
