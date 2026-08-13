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

  /// Stubs the conditional-GET flow used by _fetchIndex: httpClient.send()
  /// returning a StreamedResponse built from [body]/[statusCode]/[headers].
  void stubIndexResponse(
    String body, {
    int statusCode = 200,
    Map<String, String> headers = const {},
  }) {
    when(() => mockHttpClient.send(any())).thenAnswer(
      (_) async => http.StreamedResponse(
        Stream.value(utf8.encode(body)),
        statusCode,
        headers: {
          'content-type': 'application/json; charset=utf-8',
          ...headers
        },
      ),
    );
  }

  group('fetchRemoteVersions', () {
    test('excludes versions already bundled as app assets', () async {
      stubIndexResponse(jsonEncode(fullIndex));

      // 'en' bundled versions are KJV/NIV/ESV (see BibleVersionRegistry) —
      // all three are bundled, so nothing should be eligible for 'en'.
      final enResult = await repository.fetchRemoteVersions('en');
      expect(enResult, isEmpty);

      // 'fr' bundled versions are LSG1910/BDS — both bundled, so the fr
      // result should exclude them too.
      final frResult = await repository.fetchRemoteVersions('fr');
      expect(
        frResult.any((v) => v.dbFileName.startsWith('LSG1910')),
        isFalse,
      );
    });

    test('includes a non-bundled version from the index with remoteUrl set',
        () async {
      final index = {
        'languages': {
          'de': {
            'versions': {
              // Not bundled for 'de' (bundled are LU17/SCH2000) — must be
              // offered for download regardless of version code.
              'NGU': {
                'name': 'Neue Genfer Übersetzung',
                'file': 'NGU_de.SQLite3.gz',
                'url': 'https://raw.githubusercontent.com/develop4God/'
                    'bible_versions/main/de/NGU_de.SQLite3.gz',
              },
            },
          },
        },
      };
      stubIndexResponse(jsonEncode(index));

      final result = await repository.fetchRemoteVersions('de');

      expect(result, hasLength(1));
      expect(result.first.dbFileName, 'NGU_de.SQLite3');
      expect(result.first.isRemote, isTrue);
      expect(
        result.first.remoteUrl,
        'https://raw.githubusercontent.com/develop4God/'
        'bible_versions/main/de/NGU_de.SQLite3.gz',
      );
    });

    test('parses disclaimer when present on the index entry', () async {
      final index = {
        'languages': {
          'es': {
            'versions': {
              'RVR1909': {
                'name': 'Reina-Valera 1909 (con Números Strong)',
                'file': 'RVR1909_es.SQLite3.gz',
                'url': 'https://raw.githubusercontent.com/develop4God/'
                    'bible_versions/main/es/RVR1909_es.SQLite3.gz',
                'disclaimer': 'Texto de dominio público (Reina-Valera 1909).',
              },
            },
          },
        },
      };
      stubIndexResponse(jsonEncode(index));

      final result = await repository.fetchRemoteVersions('es');

      expect(result, hasLength(1));
      expect(
        result.first.disclaimer,
        'Texto de dominio público (Reina-Valera 1909).',
      );
    });

    test('leaves disclaimer null when absent on the index entry', () async {
      final index = {
        'languages': {
          'de': {
            'versions': {
              // Not bundled for 'de' (bundled are LU17/SCH2000).
              'NGU': {
                'name': 'Neue Genfer Übersetzung',
                'file': 'NGU_de.SQLite3.gz',
                'url': 'https://raw.githubusercontent.com/develop4God/'
                    'bible_versions/main/de/NGU_de.SQLite3.gz',
              },
            },
          },
        },
      };
      stubIndexResponse(jsonEncode(index));

      final result = await repository.fetchRemoteVersions('de');

      expect(result, isNotEmpty);
      expect(result.every((v) => v.disclaimer == null), isTrue);
    });

    test(
        'a fresh 200 is fetched on every call — a same-session cache must '
        'never suppress a newer index', () async {
      stubIndexResponse(jsonEncode(fullIndex));

      await repository.fetchRemoteVersions('en');
      await repository.fetchRemoteVersions('fr');

      // Two calls, not deduped by a same-session flag — see _fetchIndex's
      // doc comment for why a stale cache must never win silently.
      verify(() => mockHttpClient.send(any())).called(2);
    });

    test(
        'sends If-None-Match with the cached ETag and reuses the cached '
        'body on 304', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'bible_versions_index_cache_main',
        jsonEncode(fullIndex),
      );
      await prefs.setString('bible_versions_index_etag_main', '"abc123"');

      when(() => mockHttpClient.send(any())).thenAnswer((invocation) async {
        final request = invocation.positionalArguments[0] as http.Request;
        expect(request.headers['If-None-Match'], '"abc123"');
        return http.StreamedResponse(const Stream.empty(), 304);
      });

      final result = await repository.fetchRemoteVersions('en');
      expect(result, isEmpty); // en is fully bundled per fullIndex
    });

    test('a 200 response with a new ETag overwrites the cached ETag and body',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bible_versions_index_etag_main', '"old-etag"');

      stubIndexResponse(
        jsonEncode(fullIndex),
        headers: {'etag': '"new-etag"'},
      );

      await repository.fetchRemoteVersions('en');

      expect(prefs.getString('bible_versions_index_etag_main'), '"new-etag"');
      expect(
        prefs.getString('bible_versions_index_cache_main'),
        jsonEncode(fullIndex),
      );
    });

    test('falls back to stale cache on network failure', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'bible_versions_index_cache_main',
        jsonEncode(fullIndex),
      );

      when(() => mockHttpClient.send(any()))
          .thenThrow(Exception('network down'));

      // Should not throw — falls back to the stale cache above.
      final result = await repository.fetchRemoteVersions('en');
      expect(result, isEmpty); // en is fully bundled per fullIndex
    });

    test(
        'surfaces an already-downloaded remote version with hasUpdate when '
        'the index hash differs from the stored hash', () async {
      final file = File('${Directory.systemTemp.path}/NGU_de.SQLite3');
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });
      await file.writeAsBytes([1, 2, 3]);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'bible_remote_version_names',
        jsonEncode({
          'NGU_de.SQLite3': {'name': 'Neue Genfer Übersetzung', 'hash': 'old'},
        }),
      );

      stubIndexResponse(jsonEncode({
        'languages': {
          'de': {
            'versions': {
              'NGU': {
                'name': 'Neue Genfer Übersetzung',
                'file': 'NGU_de.SQLite3.gz',
                'url': 'https://raw.githubusercontent.com/develop4God/'
                    'bible_versions/main/de/NGU_de.SQLite3.gz',
                'hash': 'new',
              },
            },
          },
        },
      }));

      final result = await repository.fetchRemoteVersions('de');

      expect(result, hasLength(1));
      expect(result.first.dbFileName, 'NGU_de.SQLite3');
      expect(result.first.hasUpdate, isTrue);
      expect(result.first.isDownloaded, isTrue);
    });

    test(
        'omits an already-downloaded remote version when the index hash '
        'matches the stored hash', () async {
      final file = File('${Directory.systemTemp.path}/NGU_de.SQLite3');
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });
      await file.writeAsBytes([1, 2, 3]);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'bible_remote_version_names',
        jsonEncode({
          'NGU_de.SQLite3': {'name': 'Neue Genfer Übersetzung', 'hash': 'same'},
        }),
      );

      stubIndexResponse(jsonEncode({
        'languages': {
          'de': {
            'versions': {
              'NGU': {
                'name': 'Neue Genfer Übersetzung',
                'file': 'NGU_de.SQLite3.gz',
                'url': 'https://raw.githubusercontent.com/develop4God/'
                    'bible_versions/main/de/NGU_de.SQLite3.gz',
                'hash': 'same',
              },
            },
          },
        },
      }));

      final result = await repository.fetchRemoteVersions('de');

      expect(result, isEmpty);
    });

    test(
        'omits an already-downloaded remote version when neither stored '
        'nor index hash is present (pre-fingerprint data)', () async {
      final file = File('${Directory.systemTemp.path}/NGU_de.SQLite3');
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });
      await file.writeAsBytes([1, 2, 3]);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'bible_remote_version_names',
        jsonEncode({'NGU_de.SQLite3': 'Neue Genfer Übersetzung'}),
      );

      stubIndexResponse(jsonEncode({
        'languages': {
          'de': {
            'versions': {
              'NGU': {
                'name': 'Neue Genfer Übersetzung',
                'file': 'NGU_de.SQLite3.gz',
                'url': 'https://raw.githubusercontent.com/develop4God/'
                    'bible_versions/main/de/NGU_de.SQLite3.gz',
              },
            },
          },
        },
      }));

      final result = await repository.fetchRemoteVersions('de');

      expect(result, isEmpty);
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

    test('persists the disclaimer alongside the name on successful download',
        () async {
      final gzipBytes = _validGzipBytes();
      when(() => mockHttpClient.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value(gzipBytes),
          200,
          contentLength: gzipBytes.length,
        ),
      );

      final version = BibleVersion(
        name: 'Reina-Valera 1909 (con Números Strong)',
        language: 'Español',
        languageCode: 'es',
        assetPath: '',
        dbFileName: 'DISCLAIM_xx.SQLite3',
        isDownloaded: false,
        remoteUrl: 'https://example.com/rvr1909.gz',
        disclaimer: 'Texto de dominio público (Reina-Valera 1909).',
      );

      await repository.downloadVersion(version);

      final prefs = await SharedPreferences.getInstance();
      final stored = jsonDecode(prefs.getString('bible_remote_version_names')!)
          as Map<String, dynamic>;

      expect(
        stored['DISCLAIM_xx.SQLite3'],
        {
          'name': 'Reina-Valera 1909 (con Números Strong)',
          'disclaimer': 'Texto de dominio público (Reina-Valera 1909).',
        },
      );

      final installedFile =
          File('${Directory.systemTemp.path}/DISCLAIM_xx.SQLite3');
      if (installedFile.existsSync()) installedFile.deleteSync();
    });

    test('persists the remote hash alongside the name on successful download',
        () async {
      final gzipBytes = _validGzipBytes();
      when(() => mockHttpClient.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value(gzipBytes),
          200,
          contentLength: gzipBytes.length,
        ),
      );

      final version = BibleVersion(
        name: 'Neue Genfer Übersetzung',
        language: 'Deutsch',
        languageCode: 'de',
        assetPath: '',
        dbFileName: 'HASH_xx.SQLite3',
        isDownloaded: false,
        remoteUrl: 'https://example.com/ngu.gz',
        remoteHash: 'abc123def456',
      );

      await repository.downloadVersion(version);

      final prefs = await SharedPreferences.getInstance();
      final stored = jsonDecode(prefs.getString('bible_remote_version_names')!)
          as Map<String, dynamic>;

      expect(
        stored['HASH_xx.SQLite3'],
        {'name': 'Neue Genfer Übersetzung', 'hash': 'abc123def456'},
      );

      final installedFile =
          File('${Directory.systemTemp.path}/HASH_xx.SQLite3');
      if (installedFile.existsSync()) installedFile.deleteSync();
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
