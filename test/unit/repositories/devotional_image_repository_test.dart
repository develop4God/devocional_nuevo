@Tags(['unit', 'repositories'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:devocional_nuevo/repositories/devotional_image_repository.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockBaseCacheManager extends Mock implements BaseCacheManager {}

class MockFileInfo extends Mock implements FileInfo {}

/// Always returns index 0 — deterministic for assertions.
class ZeroRandom implements Random {
  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  late MockHttpClient mockHttpClient;
  late MockBaseCacheManager mockCacheManager;
  late DevotionalImageRepository repository;

  const indexJson = {
    'generatedAt': '2026-07-25T04:50:52Z',
    'files': ['blue_mountains.avif', 'desert_dune.avif'],
  };

  http.Response okResponse() => http.Response(jsonEncode(indexJson), 200);

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockCacheManager = MockBaseCacheManager();
    SharedPreferences.setMockInitialValues({});

    when(() => mockCacheManager.downloadFile(any()))
        .thenAnswer((_) async => MockFileInfo());

    repository = DevotionalImageRepository(
      httpClient: mockHttpClient,
      cacheManager: mockCacheManager,
      random: ZeroRandom(),
    );
  });

  group('fetchIndex', () {
    test('parses filenames without extension from network', () async {
      when(() => mockHttpClient.get(any()))
          .thenAnswer((_) async => okResponse());

      final files = await repository.fetchIndex();

      expect(files, ['blue_mountains', 'desert_dune']);
    });

    test('returns empty list on network failure with no cache', () async {
      when(() => mockHttpClient.get(any())).thenThrow(Exception('offline'));

      final files = await repository.fetchIndex();

      expect(files, isEmpty);
    });

    test('falls back to cached index on network failure', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'devotional_image_index_cache',
        jsonEncode(indexJson),
      );

      when(() => mockHttpClient.get(any())).thenThrow(Exception('offline'));

      final files = await repository.fetchIndex();

      expect(files, ['blue_mountains', 'desert_dune']);
    });
  });

  group('prepareInitial', () {
    test('sets currentImageUrl and warms it via the cache manager', () async {
      when(() => mockHttpClient.get(any()))
          .thenAnswer((_) async => okResponse());

      await repository.prepareInitial();

      expect(repository.currentImageUrl, isNotNull);
      expect(repository.currentImageUrl, contains('blue_mountains'));
      verify(() => mockCacheManager.downloadFile(any())).called(2);
    });

    test('leaves currentImageUrl null when the pool is empty', () async {
      when(() => mockHttpClient.get(any())).thenThrow(Exception('offline'));

      await repository.prepareInitial();

      expect(repository.currentImageUrl, isNull);
    });

    test('leaves currentImageUrl null when the image download fails', () async {
      when(() => mockHttpClient.get(any()))
          .thenAnswer((_) async => okResponse());
      when(() => mockCacheManager.downloadFile(any()))
          .thenThrow(Exception('image unavailable'));

      await repository.prepareInitial();

      expect(repository.currentImageUrl, isNull);
      verify(() => mockCacheManager.downloadFile(any())).called(2);
    });
  });

  group('advance', () {
    test(
      'promotes the pre-fetched image instantly, no new download wait',
      () async {
        when(() => mockHttpClient.get(any()))
            .thenAnswer((_) async => okResponse());
        await repository.prepareInitial();
        clearInteractions(mockCacheManager);

        final result = await repository.advance();

        expect(result, repository.currentImageUrl);
        expect(result, isNotNull);
      },
    );

    test(
      'returns null when nothing was pre-fetched and nothing was shown',
      () async {
        final result = await repository.advance();

        expect(result, isNull);
      },
    );

    test(
      'keeps the currently shown image when nothing was pre-fetched',
      () async {
        when(() => mockHttpClient.get(any()))
            .thenAnswer((_) async => okResponse());
        await repository.prepareInitial();
        final shownBefore = repository.currentImageUrl;
        expect(shownBefore, isNotNull);

        // Simulate the prefetch-ahead having failed/not landed yet.
        await repository.advance();
        final afterFirstAdvance = repository.currentImageUrl;

        // Second advance with nothing freshly pre-fetched must not blank
        // the view — it keeps whatever is currently shown.
        when(() => mockHttpClient.get(any())).thenThrow(Exception('offline'));
        final result = await repository.advance();

        expect(result, afterFirstAdvance);
        expect(result, isNotNull);
      },
    );

    test(
      'does not promote a URL when forward-navigation prefetch fails',
      () async {
        final prefetchAttempted = Completer<void>();
        when(() => mockHttpClient.get(any()))
            .thenAnswer((_) async => okResponse());
        when(() => mockCacheManager.downloadFile(any())).thenAnswer((_) {
          if (!prefetchAttempted.isCompleted) {
            prefetchAttempted.complete();
          }
          throw Exception('image unavailable');
        });

        // The first advance starts an asynchronous prefetch while there is no
        // current or pre-fetched image. Wait until that prefetch has failed.
        await repository.advance();
        await prefetchAttempted.future;
        await Future<void>.delayed(Duration.zero);

        // If the failed URL had been stored, this second advance would
        // incorrectly promote it. It must remain null instead.
        final result = await repository.advance();

        expect(result, isNull);
        expect(repository.currentImageUrl, isNull);
      },
    );
  });

  group('pickFresh', () {
    test('returns a URL from the pool and updates currentImageUrl', () async {
      when(() => mockHttpClient.get(any()))
          .thenAnswer((_) async => okResponse());

      final result = await repository.pickFresh();

      expect(result, isNotNull);
      expect(repository.currentImageUrl, result);
    });

    test(
      'returns null when the pool is empty and nothing was shown yet',
      () async {
        when(() => mockHttpClient.get(any())).thenThrow(Exception('offline'));

        final result = await repository.pickFresh();

        expect(result, isNull);
      },
    );

    test(
      'keeps the currently shown image when the pool comes back empty',
      () async {
        when(() => mockHttpClient.get(any()))
            .thenAnswer((_) async => okResponse());
        final shownBefore = await repository.pickFresh();
        expect(shownBefore, isNotNull);

        // An index that parses successfully but lists no files — pickFresh
        // must not blank out what's already showing.
        when(() => mockHttpClient.get(any())).thenAnswer(
          (_) async => http.Response(
            jsonEncode({'generatedAt': 'now', 'files': <String>[]}),
            200,
          ),
        );
        final result = await repository.pickFresh(forceRefresh: true);

        expect(result, shownBefore);
      },
    );

    test('keeps the shown URL when a fresh image download fails', () async {
      when(() => mockHttpClient.get(any()))
          .thenAnswer((_) async => okResponse());
      final shownBefore = await repository.pickFresh();
      expect(shownBefore, isNotNull);

      when(() => mockCacheManager.downloadFile(any()))
          .thenThrow(Exception('image unavailable'));

      final result = await repository.pickFresh(forceRefresh: true);

      expect(result, shownBefore);
      expect(repository.currentImageUrl, shownBefore);
    });
  });

  group('rapid navigation (rapid-tap regression)', () {
    test(
      'skips duplicate prefetches while one is in flight and resumes afterwards',
      () async {
        // Hold the first post-initial download open. This makes the in-flight
        // state deterministic without relying on arbitrary delays.
        final prefetchBlocker = Completer<FileInfo>();
        final firstPrefetchStarted = Completer<void>();
        final secondPrefetchStarted = Completer<void>();
        var blockPostInitialDownloads = false;
        var postInitialDownloadCount = 0;

        when(() => mockCacheManager.downloadFile(any())).thenAnswer((_) async {
          if (!blockPostInitialDownloads) {
            return MockFileInfo();
          }

          postInitialDownloadCount++;
          if (postInitialDownloadCount == 1) {
            firstPrefetchStarted.complete();
            return prefetchBlocker.future;
          }
          if (postInitialDownloadCount == 2) {
            secondPrefetchStarted.complete();
          }
          return MockFileInfo();
        });

        when(() => mockHttpClient.get(any()))
            .thenAnswer((_) async => okResponse());

        // Initialization warms the current and next images normally.
        await repository.prepareInitial();
        blockPostInitialDownloads = true;

        // The first advance starts a prefetch and returns immediately. Wait
        // until its download handler confirms it is genuinely in flight.
        await repository.advance();
        await firstPrefetchStarted.future;

        // A rapid second advance must not start another download.
        await repository.advance();
        expect(postInitialDownloadCount, 1,
            reason:
                'second advance() must not start a duplicate in-flight prefetch');

        // Once the first prefetch finishes, the guard must reset so a later
        // advance can prepare the following image.
        prefetchBlocker.complete(MockFileInfo());
        await Future<void>.delayed(Duration.zero);
        await repository.advance();
        await secondPrefetchStarted.future.timeout(const Duration(seconds: 1));
        expect(postInitialDownloadCount, 2);
      },
    );
  });
}
