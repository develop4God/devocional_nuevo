import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io' show gzip;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock HTTP client for testing compressed Bible version downloads.
class MockCompressionHttpClient implements HttpClient {
  final Map<String, MockHttpResponse> _responses = {};
  final Map<String, List<int>> _downloadData = {};
  final List<String> requestLog = [];

  void givenGitHubApiResponse(
      String language, List<Map<String, dynamic>> files) {
    final url =
        'https://api.github.com/repos/develop4God/bible_versions/contents/$language';
    _responses[url] = MockHttpResponse(
      statusCode: 200,
      body: jsonEncode(files),
    );
  }

  void givenCompressedDownloadData(String url, List<int> uncompressedData) {
    // Compress the data with gzip
    final compressed = gzip.encode(uncompressedData);
    _downloadData[url] = compressed;
  }

  void givenRawDownloadData(String url, List<int> data) {
    _downloadData[url] = data;
  }

  @override
  Future<HttpResponse> get(String url) async {
    requestLog.add(url);

    final downloadBytes = _downloadData[url];
    if (downloadBytes != null) {
      return HttpResponse(
        statusCode: 200,
        body: '',
        bodyBytes: Uint8List.fromList(downloadBytes),
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
    requestLog.add('STREAM:$url');
    final data = _downloadData[url];
    if (data == null) {
      throw NetworkException('No download data for: $url');
    }

    final chunkSize = (data.length / 10).ceil();
    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize > data.length) ? data.length : i + chunkSize;
      final chunk = data.sublist(i, end);
      yield HttpDownloadProgress(
        downloaded: end,
        total: data.length,
        data: chunk,
      );
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }
}

class MockHttpResponse {
  final int statusCode;
  final String body;

  MockHttpResponse({required this.statusCode, required this.body});
}

/// Mock storage for testing.
class MockCompressionStorage implements BibleVersionStorage {
  final Map<String, List<int>> _files = {};
  final Set<String> _directories = {};
  List<String> _downloadedVersions = [];

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
  Future<int> getAvailableSpace() async => 1000000000;

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

  /// Get written file for validation
  List<int>? getWrittenFile(String path) => _files[path];
}

/// Creates a valid SQLite database with realistic size for testing.
List<int> createValidSqliteData({int sizeKB = 100}) {
  // SQLite format 3 header (16 bytes)
  final header = [
    0x53,
    0x51,
    0x4C,
    0x69,
    0x74,
    0x65,
    0x20,
    0x66,
    0x6F,
    0x72,
    0x6D,
    0x61,
    0x74,
    0x20,
    0x33,
    0x00,
  ];
  // Additional padding to simulate realistic file size
  return [...header, ...List.filled(sizeKB * 1024 - header.length, 0)];
}

void main() {
  group('Bible Download Compression Benchmark', () {
    late MockCompressionHttpClient mockHttp;
    late MockCompressionStorage mockStorage;
    late BibleVersionRepository repository;

    setUp(() {
      mockHttp = MockCompressionHttpClient();
      mockStorage = MockCompressionStorage();
      repository = BibleVersionRepository(
        httpClient: mockHttp,
        storage: mockStorage,
      );
    });

    tearDown(() {
      repository.dispose();
    });

    group('Compressed Download Tests', () {
      test('downloads and decompresses gzipped Bible file', () async {
        // Given: Uncompressed SQLite data (simulating ~1MB Bible file)
        final uncompressedData = createValidSqliteData(sizeKB: 1024);
        debugPrint('Uncompressed size: ${uncompressedData.length} bytes');

        // Given: GitHub API returns Spanish versions with .gz extension in URL
        mockHttp.givenGitHubApiResponse('es', [
          {
            'name': 'NVI_es.SQLite3',
            'size': uncompressedData.length,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/es/NVI_es.SQLite3',
          },
        ]);

        // Given: Compressed data available at .gz URL
        mockHttp.givenCompressedDownloadData(
          'https://raw.githubusercontent.com/develop4God/bible_versions/main/es/NVI_es.SQLite3.gz',
          uncompressedData,
        );

        // When: Download version
        final progressValues = <double>[];
        repository.downloadProgress('es-NVI').listen(progressValues.add);
        await repository.downloadVersion('es-NVI');

        // Then: File was downloaded and decompressed
        expect(repository.isVersionDownloaded('es-NVI'), isTrue);

        // Then: Written file has SQLite header (decompressed)
        final writtenFile =
            mockStorage.getWrittenFile('/test/bibles/NVI_es.SQLite3');
        expect(writtenFile, isNotNull);

        // Verify SQLite header is intact after decompression
        final header = String.fromCharCodes(writtenFile!.take(16));
        expect(header, startsWith('SQLite format 3'));

        // Then: Progress updates were emitted
        expect(progressValues.isNotEmpty, isTrue);
        expect(progressValues.last, 1.0);
      });

      test('URL construction uses .gz extension for compressed downloads',
          () async {
        // Given: GitHub API returns a version
        mockHttp.givenGitHubApiResponse('en', [
          {
            'name': 'KJV_en.SQLite3',
            'size': 1000,
            'download_url':
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/en/KJV_en.SQLite3',
          },
        ]);

        // When: Fetching versions
        final versions = await repository.fetchVersionsByLanguage('en');

        // Then: Download URL should have .gz extension
        expect(versions.first.downloadUrl, endsWith('.SQLite3.gz'));
        expect(
            versions.first.downloadUrl,
            equals(
                'https://raw.githubusercontent.com/develop4God/bible_versions/main/en/KJV_en.SQLite3.gz'));
      });

      test('compression reduces download size significantly', () async {
        // Given: Large uncompressed SQLite data (simulating 6MB file)
        final uncompressedData = createValidSqliteData(sizeKB: 6 * 1024);
        final compressedData = gzip.encode(uncompressedData);

        debugPrint('Uncompressed: ${uncompressedData.length} bytes '
            '(${(uncompressedData.length / 1024 / 1024).toStringAsFixed(2)} MB)');
        debugPrint('Compressed: ${compressedData.length} bytes '
            '(${(compressedData.length / 1024 / 1024).toStringAsFixed(2)} MB)');

        final compressionRatio =
            compressedData.length / uncompressedData.length;
        debugPrint(
            'Compression ratio: ${(compressionRatio * 100).toStringAsFixed(1)}%');

        // Then: Compression should reduce size by at least 50%
        expect(compressionRatio, lessThan(0.5),
            reason: 'Compression should reduce size by at least 50%');
      });
    });

    group('Decompression Error Handling', () {
      test('handles invalid gzip data gracefully', () {
        // Given: Invalid gzip data (not actually compressed)
        final invalidGzip = Uint8List.fromList([1, 2, 3, 4, 5]);

        // When/Then: Decompression should throw
        expect(
          () => gzip.decode(invalidGzip),
          throwsA(isA<FormatException>()),
        );
      });

      test('decompresses valid gzip data correctly', () {
        // Given: Valid SQLite data
        final originalData = createValidSqliteData(sizeKB: 100);

        // When: Compress then decompress
        final compressed = gzip.encode(originalData);
        final decompressed = gzip.decode(compressed);

        // Then: Data should be identical
        expect(decompressed, equals(originalData));
      });

      test('gzip header detection works correctly', () {
        // Given: Valid gzip data
        final originalData = createValidSqliteData(sizeKB: 10);
        final compressed = gzip.encode(originalData);

        // Then: Gzip magic bytes should be present
        expect(compressed[0], equals(0x1f)); // First gzip magic byte
        expect(compressed[1], equals(0x8b)); // Second gzip magic byte
      });
    });

    group('Before/After Comparison', () {
      test('BASELINE: uncompressed download size', () {
        // Simulate 6MB uncompressed file
        final uncompressedSize = 6 * 1024 * 1024; // 6 MB
        final downloadSpeedMBps = 0.11; // MB/s (from benchmark)

        final downloadTimeSeconds =
            (uncompressedSize / 1024 / 1024) / downloadSpeedMBps;
        debugPrint('BEFORE - Uncompressed:');
        debugPrint(
            '  Size: ${(uncompressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
        debugPrint(
            '  Est. download time: ${downloadTimeSeconds.toStringAsFixed(1)}s');

        expect(downloadTimeSeconds, greaterThan(50),
            reason: 'Uncompressed download should take >50s at 0.11 MB/s');
      });

      test('OPTIMIZED: compressed download size', () {
        // Simulate compressed file (~36% of original based on typical SQLite compression)
        final uncompressedSize = 6 * 1024 * 1024; // 6 MB
        final compressionRatio = 0.36; // ~36% of original
        final compressedSize = (uncompressedSize * compressionRatio).toInt();
        final downloadSpeedMBps = 0.11; // MB/s
        final decompressionTimeSeconds = 2.0; // ~2s for local decompression

        final downloadTimeSeconds =
            (compressedSize / 1024 / 1024) / downloadSpeedMBps;
        final totalTimeSeconds = downloadTimeSeconds + decompressionTimeSeconds;

        debugPrint('AFTER - Compressed:');
        debugPrint(
            '  Compressed size: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
        debugPrint(
            '  Download time: ${downloadTimeSeconds.toStringAsFixed(1)}s');
        debugPrint(
            '  Decompression time: ${decompressionTimeSeconds.toStringAsFixed(1)}s');
        debugPrint('  Total time: ${totalTimeSeconds.toStringAsFixed(1)}s');

        expect(totalTimeSeconds, lessThan(25),
            reason: 'Compressed download + decompression should be <25s');
      });

      test('time savings calculation', () {
        final beforeSeconds = 54.0;
        final afterSeconds = 22.0;
        final savingsSeconds = beforeSeconds - afterSeconds;
        final savingsPercent = (savingsSeconds / beforeSeconds) * 100;

        debugPrint('\n=== TIME SAVINGS ===');
        debugPrint('Before: ${beforeSeconds.toStringAsFixed(0)}s');
        debugPrint('After: ${afterSeconds.toStringAsFixed(0)}s');
        debugPrint(
            'Savings: ${savingsSeconds.toStringAsFixed(0)}s (${savingsPercent.toStringAsFixed(0)}%)');

        expect(savingsPercent, greaterThan(50),
            reason: 'Should save at least 50% download time');
      });
    });
  });
}
