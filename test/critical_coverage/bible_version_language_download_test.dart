import 'dart:async';
import 'dart:convert';

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock HTTP client for testing Bible version downloads by language.
class MockHttpClient implements HttpClient {
  final Map<String, MockHttpResponse> _responses = {};
  final Map<String, List<int>> _downloadData = {};

  void givenGitHubApiResponse(
      String language, List<Map<String, dynamic>> files) {
    final url =
        'https://api.github.com/repos/develop4God/bible_versions/contents/$language';
    _responses[url] = MockHttpResponse(
      statusCode: 200,
      body: jsonEncode(files),
    );
  }

  void givenDownloadData(String url, List<int> data) {
    _downloadData[url] = data;
  }

  void givenNetworkError(String urlPattern) {
    _responses[urlPattern] = MockHttpResponse(statusCode: 500, body: '');
  }

  @override
  Future<HttpResponse> get(String url) async {
    final downloadBytes = _downloadData[url];
    if (downloadBytes != null) {
      return HttpResponse(
        statusCode: 200,
        body: '',
        bodyBytes: downloadBytes,
        headers: {},
      );
    }

    final response = _responses[url];
    if (response != null) {
      return HttpResponse(
        statusCode: response.statusCode,
        body: response.body,
        headers: {},
      );
    }
    return const HttpResponse(statusCode: 404, body: '', headers: {});
  }

  @override
  Stream<HttpDownloadProgress> downloadStream(String url) async* {
    final data = _downloadData[url];
    if (data == null) {
      throw NetworkException('No download data for: $url');
    }

    // Simulate chunked download
    final chunkSize = (data.length / 10).ceil();
    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize > data.length) ? data.length : i + chunkSize;
      final chunk = data.sublist(i, end);
      yield HttpDownloadProgress(
        downloaded: end,
        total: data.length,
        data: chunk,
      );
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }
}

class MockHttpResponse {
  final int statusCode;
  final String body;

  MockHttpResponse({required this.statusCode, required this.body});
}

/// Mock storage for testing.
class MockStorage implements BibleVersionStorage {
  final Map<String, List<int>> _files = {};
  final Set<String> _directories = {};
  List<String> _downloadedVersions = [];
  int _availableSpace = 1000000000; // 1GB

  void setAvailableSpace(int bytes) {
    _availableSpace = bytes;
  }

  @override
  Future<String> getBiblesDirectory() async => '/test/bibles';

  @override
  Future<void> createDirectory(String path) async {
    _directories.add(path);
  }

  @override
  Future<void> deleteDirectory(String path) async {
    _directories.remove(path);
    _files.removeWhere((key, _) => key.startsWith(path));
  }

  @override
  Future<bool> directoryExists(String path) async {
    return _directories.contains(path);
  }

  @override
  Future<List<String>> listFiles(String directoryPath) async {
    return _files.keys
        .where((f) => f.startsWith(directoryPath))
        .map((f) => f.split('/').last)
        .toList();
  }

  @override
  Future<void> deleteFile(String path) async {
    _files.remove(path);
  }

  @override
  Future<bool> fileExists(String path) async => _files.containsKey(path);

  @override
  Future<int> getAvailableSpace() async => _availableSpace;

  @override
  Future<List<String>> getDownloadedVersions() async => _downloadedVersions;

  @override
  Future<List<int>> readFile(String path) async {
    final data = _files[path];
    if (data == null) throw Exception('File not found: $path');
    return data;
  }

  @override
  Future<void> saveDownloadedVersions(List<String> versionIds) async {
    _downloadedVersions = versionIds;
  }

  @override
  Future<void> writeFile(String path, List<int> bytes) async {
    _files[path] = bytes;
  }
}

/// Creates a valid SQLite database header for testing.
List<int> createValidSqliteData() {
  // SQLite format 3 header (16 bytes)
  return [
    0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66,
    0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00,
    // Additional padding
    ...List.filled(100, 0),
  ];
}

void main() {
  group('Bible Version Download by Language - Real User Behavior', () {
    late MockHttpClient mockHttp;
    late MockStorage mockStorage;
    late BibleVersionRepository repository;

    setUp(() {
      mockHttp = MockHttpClient();
      mockStorage = MockStorage();
      repository = BibleVersionRepository(
        httpClient: mockHttp,
        storage: mockStorage,
      );
    });

    tearDown(() {
      repository.dispose();
    });

    group('Spanish (es) - User Downloads', () {
      test('user browses Spanish Bible versions from GitHub', () async {
        // Given: GitHub API returns Spanish versions
        mockHttp.givenGitHubApiResponse('es', [
          {
            'name': 'NVI_es.SQLite3',
            'size': 6356992,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/es/NVI_es.SQLite3',
          },
          {
            'name': 'RVR1960_es.SQLite3',
            'size': 2,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/es/RVR1960_es.SQLite3',
          },
        ]);

        // When: User fetches versions for Spanish
        final versions = await repository.fetchVersionsByLanguage('es');

        // Then: User sees Spanish versions
        expect(versions, hasLength(2));
        expect(versions.any((v) => v.id == 'es-NVI'), true);
        expect(versions.any((v) => v.id == 'es-RVR1960'), true);
        expect(versions.first.language, 'es');
        expect(versions.first.languageName, 'Español');
      });

      test('user downloads NVI Spanish Bible', () async {
        // Given: Spanish version is available
        mockHttp.givenGitHubApiResponse('es', [
          {
            'name': 'NVI_es.SQLite3',
            'size': 6356992,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/es/NVI_es.SQLite3',
          },
        ]);
        mockHttp.givenDownloadData(
          'https://raw.githubusercontent.com/develop4God/bible_versions/main/es/NVI_es.SQLite3',
          createValidSqliteData(),
        );

        // When: User downloads NVI
        final progressValues = <double>[];
        repository.downloadProgress('es-NVI').listen(progressValues.add);
        await repository.downloadVersion('es-NVI');

        // Then: Download completes with progress updates
        expect(progressValues.isNotEmpty, true);
        expect(progressValues.last, 1.0);
        expect(repository.isVersionDownloaded('es-NVI'), true);

        // And: Database path uses original filename
        final dbPath = await repository.getVersionDatabasePath('es-NVI');
        expect(dbPath, contains('NVI_es.SQLite3'));
      });
    });

    group('English (en) - User Downloads', () {
      test('user browses English Bible versions from GitHub', () async {
        // Given: GitHub API returns English versions
        mockHttp.givenGitHubApiResponse('en', [
          {
            'name': 'KJV_en.SQLite3',
            'size': 2,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/en/KJV_en.SQLite3',
          },
          {
            'name': 'NIV_en.SQLite3',
            'size': 2,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/en/NIV_en.SQLite3',
          },
        ]);

        // When: User fetches versions for English
        final versions = await repository.fetchVersionsByLanguage('en');

        // Then: User sees English versions with display names
        expect(versions, hasLength(2));
        expect(versions.any((v) => v.id == 'en-KJV'), true);
        expect(versions.any((v) => v.id == 'en-NIV'), true);

        final kjv = versions.firstWhere((v) => v.id == 'en-KJV');
        expect(kjv.name,
            'KJV'); // Short code for matching in BibleSelectedVersionProvider
        expect(kjv.description,
            'King James Version'); // Display name in description
        expect(kjv.language, 'en');
        expect(kjv.languageName, 'English');
      });

      test('user downloads KJV English Bible', () async {
        // Given: English version is available
        mockHttp.givenGitHubApiResponse('en', [
          {
            'name': 'KJV_en.SQLite3',
            'size': 5000000,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/en/KJV_en.SQLite3',
          },
        ]);
        mockHttp.givenDownloadData(
          'https://raw.githubusercontent.com/develop4God/bible_versions/main/en/KJV_en.SQLite3',
          createValidSqliteData(),
        );

        // When: User downloads KJV
        await repository.downloadVersion('en-KJV');

        // Then: Version is downloaded
        expect(repository.isVersionDownloaded('en-KJV'), true);
      });
    });

    group('Japanese (ja) - User Downloads', () {
      test('user browses Japanese Bible versions from GitHub', () async {
        // Given: GitHub API returns Japanese versions
        mockHttp.givenGitHubApiResponse('ja', [
          {
            'name': 'リビングバイブル_ja.SQLite3',
            'size': 6193152,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/ja/リビングバイブル_ja.SQLite3',
          },
          {
            'name': '新改訳2003_ja.SQLite3',
            'size': 2,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/ja/新改訳2003_ja.SQLite3',
          },
        ]);

        // When: User fetches versions for Japanese
        final versions = await repository.fetchVersionsByLanguage('ja');

        // Then: User sees Japanese versions
        expect(versions, hasLength(2));
        expect(versions.any((v) => v.id == 'ja-リビングバイブル'), true);
        expect(versions.any((v) => v.id == 'ja-新改訳2003'), true);
        expect(versions.first.languageName, '\u65e5\u672c\u8a9e');
      });

      test('user downloads リビングバイブル Japanese Bible', () async {
        // Given: Japanese version is available
        mockHttp.givenGitHubApiResponse('ja', [
          {
            'name': 'リビングバイブル_ja.SQLite3',
            'size': 6193152,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/ja/リビングバイブル_ja.SQLite3',
          },
        ]);
        mockHttp.givenDownloadData(
          'https://raw.githubusercontent.com/develop4God/bible_versions/main/ja/リビングバイブル_ja.SQLite3',
          createValidSqliteData(),
        );

        // When: User downloads JCB
        await repository.downloadVersion('ja-リビングバイブル');

        // Then: Version is downloaded
        expect(repository.isVersionDownloaded('ja-リビングバイブル'), true);
      });
    });

    group('French (fr) - User Downloads', () {
      test('user browses French Bible versions from GitHub', () async {
        // Given: GitHub API returns French versions
        mockHttp.givenGitHubApiResponse('fr', [
          {
            'name': 'LSG1910_fr.SQLite3',
            'size': 2,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/fr/LSG1910_fr.SQLite3',
          },
        ]);

        // When: User fetches versions for French
        final versions = await repository.fetchVersionsByLanguage('fr');

        // Then: User sees French versions
        expect(versions, hasLength(1));
        expect(versions.first.id, 'fr-LSG1910');
        expect(versions.first.name, 'LSG1910'); // Short code
        expect(versions.first.description, 'Louis Segond 1910'); // Display name
        expect(versions.first.languageName, 'Français');
      });
    });

    group('Portuguese (pt) - User Downloads', () {
      test('user browses Portuguese Bible versions from GitHub', () async {
        // Given: GitHub API returns Portuguese versions
        mockHttp.givenGitHubApiResponse('pt', [
          {
            'name': 'ARC_pt.SQLite3',
            'size': 5636096,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/pt/ARC_pt.SQLite3',
          },
          {
            'name': 'NVI_pt.SQLite3',
            'size': 2,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/pt/NVI_pt.SQLite3',
          },
        ]);

        // When: User fetches versions for Portuguese
        final versions = await repository.fetchVersionsByLanguage('pt');

        // Then: User sees Portuguese versions
        expect(versions, hasLength(2));
        expect(versions.any((v) => v.id == 'pt-ARC'), true);
        expect(versions.any((v) => v.id == 'pt-NVI'), true);
        expect(versions.first.languageName, 'Português');
      });

      test('user downloads ARC Portuguese Bible', () async {
        // Given: Portuguese version is available
        mockHttp.givenGitHubApiResponse('pt', [
          {
            'name': 'ARC_pt.SQLite3',
            'size': 5636096,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/pt/ARC_pt.SQLite3',
          },
        ]);
        mockHttp.givenDownloadData(
          'https://raw.githubusercontent.com/develop4God/bible_versions/main/pt/ARC_pt.SQLite3',
          createValidSqliteData(),
        );

        // When: User downloads ARC
        await repository.downloadVersion('pt-ARC');

        // Then: Version is downloaded
        expect(repository.isVersionDownloaded('pt-ARC'), true);
      });
    });

    group('Multi-language User Flow', () {
      test('user downloads versions from multiple languages', () async {
        // Given: All languages are available
        mockHttp.givenGitHubApiResponse('es', [
          {
            'name': 'NVI_es.SQLite3',
            'size': 1000,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/es/NVI_es.SQLite3'
          },
        ]);
        mockHttp.givenGitHubApiResponse('en', [
          {
            'name': 'KJV_en.SQLite3',
            'size': 1000,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/en/KJV_en.SQLite3'
          },
        ]);
        mockHttp.givenGitHubApiResponse('ja', [
          {
            'name': 'リビングバイブル_ja.SQLite3',
            'size': 1000,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/ja/リビングバイブル_ja.SQLite3'
          },
        ]);
        mockHttp.givenGitHubApiResponse('fr', []);
        mockHttp.givenGitHubApiResponse('pt', []);

        mockHttp.givenDownloadData(
            'https://raw.githubusercontent.com/develop4God/bible_versions/main/es/NVI_es.SQLite3',
            createValidSqliteData());
        mockHttp.givenDownloadData(
            'https://raw.githubusercontent.com/develop4God/bible_versions/main/en/KJV_en.SQLite3',
            createValidSqliteData());
        mockHttp.givenDownloadData(
            'https://raw.githubusercontent.com/develop4God/bible_versions/main/ja/リビングバイブル_ja.SQLite3',
            createValidSqliteData());

        // When: User downloads versions from different languages
        await repository.downloadVersion('es-NVI');
        await repository.downloadVersion('en-KJV');
        await repository.downloadVersion('ja-リビングバイブル');

        // Then: All versions are downloaded
        expect(repository.isVersionDownloaded('es-NVI'), true);
        expect(repository.isVersionDownloaded('en-KJV'), true);
        expect(repository.isVersionDownloaded('ja-リビングバイブル'), true);

        // And: User can list all downloaded versions
        final downloaded = await repository.getDownloadedVersionIds();
        expect(downloaded, containsAll(['es-NVI', 'en-KJV', 'ja-リビングバイブル']));
      });

      test('user fetches all available versions across languages', () async {
        // Given: All language folders have versions
        mockHttp.givenGitHubApiResponse('en', [
          {
            'name': 'KJV_en.SQLite3',
            'size': 1000,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/en/KJV_en.SQLite3'
          },
        ]);
        mockHttp.givenGitHubApiResponse('es', [
          {
            'name': 'NVI_es.SQLite3',
            'size': 1000,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/es/NVI_es.SQLite3'
          },
        ]);
        mockHttp.givenGitHubApiResponse('fr', [
          {
            'name': 'LSG1910_fr.SQLite3',
            'size': 1000,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/fr/LSG1910_fr.SQLite3'
          },
        ]);
        mockHttp.givenGitHubApiResponse('ja', [
          {
            'name': 'リビングバイブル_ja.SQLite3',
            'size': 1000,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/ja/リビングバイブル_ja.SQLite3'
          },
        ]);
        mockHttp.givenGitHubApiResponse('pt', [
          {
            'name': 'ARC_pt.SQLite3',
            'size': 1000,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/pt/ARC_pt.SQLite3'
          },
        ]);

        // When: User fetches all versions
        final allVersions = await repository.fetchAvailableVersions();

        // Then: Versions from all languages are returned
        expect(allVersions.length, greaterThanOrEqualTo(5));
        expect(allVersions.any((v) => v.language == 'en'), true);
        expect(allVersions.any((v) => v.language == 'es'), true);
        expect(allVersions.any((v) => v.language == 'fr'), true);
        expect(allVersions.any((v) => v.language == 'ja'), true);
        expect(allVersions.any((v) => v.language == 'pt'), true);
      });
    });

    group('Error Handling by Language', () {
      test('handles network error for specific language gracefully', () async {
        // Given: One language folder is unavailable
        mockHttp.givenGitHubApiResponse('en', [
          {
            'name': 'KJV_en.SQLite3',
            'size': 1000,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/en/KJV_en.SQLite3'
          },
        ]);
        mockHttp.givenGitHubApiResponse('es', [
          {
            'name': 'NVI_es.SQLite3',
            'size': 1000,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/es/NVI_es.SQLite3'
          },
        ]);
        // fr, ja, pt return 404

        // When: User fetches all versions
        final versions = await repository.fetchAvailableVersions();

        // Then: Available languages are still returned
        expect(versions.any((v) => v.language == 'en'), true);
        expect(versions.any((v) => v.language == 'es'), true);
      });

      test('throws error when all language fetches fail', () async {
        // Given: No language folders respond
        // All return 404 by default

        // When/Then: Fetching versions throws
        expect(
          () => repository.fetchAvailableVersions(),
          throwsA(isA<NetworkException>()),
        );
      });

      test('handles download failure for specific version', () async {
        // Given: Version exists but download fails
        mockHttp.givenGitHubApiResponse('es', [
          {
            'name': 'NVI_es.SQLite3',
            'size': 1000,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/es/NVI_es.SQLite3'
          },
        ]);
        // No download data provided - will fail

        // When/Then: Download throws after retries
        expect(
          () => repository.downloadVersion('es-NVI'),
          throwsA(isA<MaxRetriesExceededException>()),
        );
      });
    });

    group('Repository Architecture Validation', () {
      test('repository uses dependency injection (not singleton)', () {
        // Given/When: Creating multiple repository instances
        final repo1 = BibleVersionRepository(
          httpClient: mockHttp,
          storage: mockStorage,
        );
        final repo2 = BibleVersionRepository(
          httpClient: mockHttp,
          storage: mockStorage,
        );

        // Then: They are independent instances
        expect(identical(repo1, repo2), false);

        repo1.dispose();
        repo2.dispose();
      });

      test('repository is framework-agnostic (uses callbacks/streams)',
          () async {
        // Given: Repository with callbacks
        mockHttp.givenGitHubApiResponse('es', [
          {
            'name': 'NVI_es.SQLite3',
            'size': 1000,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/es/NVI_es.SQLite3'
          },
        ]);
        mockHttp.givenDownloadData(
          'https://raw.githubusercontent.com/develop4God/bible_versions/main/es/NVI_es.SQLite3',
          createValidSqliteData(),
        );

        // When: Using stream-based progress
        final progressUpdates = <double>[];
        final subscription = repository.downloadProgress('es-NVI').listen(
              progressUpdates.add,
            );

        await repository.downloadVersion('es-NVI');
        await subscription.cancel();

        // Then: Progress was reported via stream (framework-agnostic)
        expect(progressUpdates.isNotEmpty, true);
      });

      test('supported languages constant is available', () {
        // Then: Static constant lists supported languages
        expect(BibleVersionRepository.supportedLanguages,
            containsAll(['en', 'es', 'fr', 'ja', 'pt']));
        expect(BibleVersionRepository.languageNames['es'], 'Español');
        expect(BibleVersionRepository.languageNames['ja'], '日本語');
      });
    });

    group('Delete Downloaded Version', () {
      test('user deletes Spanish version to free space', () async {
        // Given: User has downloaded a Spanish version
        mockHttp.givenGitHubApiResponse('es', [
          {
            'name': 'NVI_es.SQLite3',
            'size': 1000,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/es/NVI_es.SQLite3'
          },
        ]);
        mockHttp.givenDownloadData(
          'https://raw.githubusercontent.com/develop4God/bible_versions/main/es/NVI_es.SQLite3',
          createValidSqliteData(),
        );
        await repository.downloadVersion('es-NVI');
        expect(repository.isVersionDownloaded('es-NVI'), true);

        // When: User deletes the version
        await repository.deleteVersion('es-NVI');

        // Then: Version is no longer downloaded
        expect(repository.isVersionDownloaded('es-NVI'), false);
        final downloaded = await repository.getDownloadedVersionIds();
        expect(downloaded.contains('es-NVI'), false);
      });
    });
  });
}
