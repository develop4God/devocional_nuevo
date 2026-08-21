@Tags(['unit', 'services'])
library;

import 'package:devocional_nuevo/services/sound/audio_player_handle.dart';
import 'package:devocional_nuevo/services/sound/sound_service.dart';
import 'package:file/memory.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

class FakeAudioPlayerHandle implements AudioPlayerHandle {
  String? lastUrl;
  String? lastFilePath;
  LoopMode? lastLoopMode;
  bool playCalled = false;
  int stopCallCount = 0;
  bool disposeCalled = false;
  bool throwOnSetUrl = false;
  bool throwOnSetFilePath = false;
  bool throwOnStop = false;

  @override
  Future<void> setUrl(String url) async {
    if (throwOnSetUrl) {
      throw Exception('network error');
    }
    lastUrl = url;
  }

  @override
  Future<void> setFilePath(String path) async {
    if (throwOnSetFilePath) {
      throw Exception('file error');
    }
    lastFilePath = path;
  }

  @override
  Future<void> setLoopMode(LoopMode mode) async {
    lastLoopMode = mode;
  }

  @override
  Future<void> play() async {
    playCalled = true;
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
    if (throwOnStop) {
      throw Exception('platform error');
    }
  }

  @override
  Future<void> dispose() async {
    disposeCalled = true;
  }
}

/// Minimal fake covering only what [SoundService] actually calls
/// (getFileFromCache, downloadFile) — BaseCacheManager is an infrastructure
/// boundary (disk/network), so a partial fake is appropriate; the unused
/// members are never exercised by SoundService and throw if ever called.
class FakeCacheManager implements BaseCacheManager {
  FakeCacheManager({this.cachedPath});

  /// When set, getFileFromCache returns a FileInfo pointing at this local
  /// path — simulates the file already being prefetched to disk.
  String? cachedPath;

  int downloadFileCallCount = 0;
  bool throwOnDownload = false;
  String? lastGetFileFromCacheKey;
  String? lastDownloadFileKey;

  final _fs = MemoryFileSystem();

  @override
  Future<FileInfo?> getFileFromCache(String key,
      {bool ignoreMemCache = false}) async {
    lastGetFileFromCacheKey = key;
    if (cachedPath == null) return null;
    return FileInfo(
      _fs.file(cachedPath!),
      FileSource.Cache,
      DateTime.now().add(const Duration(days: 30)),
      key,
    );
  }

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) async {
    downloadFileCallCount++;
    lastDownloadFileKey = key;
    if (throwOnDownload) {
      throw Exception('download failed');
    }
    return FileInfo(
      _fs.file('/cache/downloaded'),
      FileSource.Online,
      DateTime.now().add(const Duration(days: 30)),
      key ?? url,
    );
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError(
      '${invocation.memberName} not used by SoundService');
}

void main() {
  group('SoundService.toggle — cache hit (local file already prefetched)', () {
    test('plays from the cached local file path, no network setUrl', () async {
      final fake = FakeAudioPlayerHandle();
      final cache = FakeCacheManager(cachedPath: '/cache/storm_waves.m4a');
      final service = SoundService(cacheManager: cache, player: fake);

      await service.toggle('storm_waves', encounterId: 'peter_water_001');

      expect(service.isPlaying, isTrue);
      expect(fake.lastFilePath, '/cache/storm_waves.m4a');
      expect(fake.lastUrl, isNull);
      expect(cache.downloadFileCallCount, 0);
      expect(fake.lastLoopMode, LoopMode.one);
      expect(fake.playCalled, isTrue);
    });

    test(
        'looks up the cache with an explicit, namespaced key — never the '
        'raw URL — so it can never resolve to an unrelated cached file '
        '(reproduces a real-device bug: the shared BaseCacheManager store '
        'returned an image cache entry for a URL-defaulted audio lookup)',
        () async {
      final fake = FakeAudioPlayerHandle();
      final cache = FakeCacheManager(cachedPath: '/cache/storm_waves.m4a');
      final service = SoundService(cacheManager: cache, player: fake);

      await service.toggle(
        'storm_waves',
        encounterId: 'peter_water_001',
        version: '2.0',
      );

      expect(cache.lastGetFileFromCacheKey, isNotNull);
      expect(cache.lastGetFileFromCacheKey, isNot(contains('http')));
      expect(cache.lastGetFileFromCacheKey, contains('peter_water_001'));
      expect(cache.lastGetFileFromCacheKey, contains('storm_waves'));
      expect(cache.lastGetFileFromCacheKey, contains('2.0'));
    });
  });

  group('SoundService.toggle — cache miss (falls back to network)', () {
    test('streams from the network URL and warms the cache in the background',
        () async {
      final fake = FakeAudioPlayerHandle();
      final cache = FakeCacheManager();
      final service = SoundService(cacheManager: cache, player: fake);

      await service.toggle('storm_waves', encounterId: 'peter_water_001');

      expect(service.isPlaying, isTrue);
      expect(fake.lastUrl, contains('storm_waves'));
      expect(fake.lastUrl, contains('peter_water_001'));
      expect(fake.lastFilePath, isNull);
      expect(fake.playCalled, isTrue);

      // Background cache warm is fire-and-forget — give it a beat to run.
      await Future<void>.delayed(Duration.zero);
      expect(cache.downloadFileCallCount, 1);
      // Warmed under the same namespaced key toggle() looks up by — not
      // the raw URL — so a subsequent cache hit finds it.
      expect(cache.lastDownloadFileKey, cache.lastGetFileFromCacheKey);
      expect(cache.lastDownloadFileKey, isNot(contains('http')));
    });

    test('version is forwarded to the resolved URL', () async {
      final fake = FakeAudioPlayerHandle();
      final cache = FakeCacheManager();
      final service = SoundService(cacheManager: cache, player: fake);

      await service.toggle(
        'storm_waves',
        encounterId: 'peter_water_001',
        version: '2.0',
      );

      expect(fake.lastUrl, contains('v=2.0'));
    });

    test('unreachable URL does not throw and leaves isPlaying false', () async {
      final fake = FakeAudioPlayerHandle()..throwOnSetUrl = true;
      final cache = FakeCacheManager();
      final service = SoundService(cacheManager: cache, player: fake);

      await expectLater(
        service.toggle('storm_waves', encounterId: 'peter_water_001'),
        completes,
      );
      expect(service.isPlaying, isFalse);
      expect(fake.playCalled, isFalse);
    });
  });

  group('SoundService.toggle', () {
    test('stops playback on second toggle', () async {
      final fake = FakeAudioPlayerHandle();
      final cache = FakeCacheManager(cachedPath: '/cache/storm_waves.m4a');
      final service = SoundService(cacheManager: cache, player: fake);

      await service.toggle('storm_waves', encounterId: 'peter_water_001');
      await service.toggle('storm_waves', encounterId: 'peter_water_001');

      expect(service.isPlaying, isFalse);
      expect(fake.stopCallCount, 1);
    });
  });

  group('SoundService.stop — hard, unconditional brake', () {
    test('always calls the player directly, no conditions, same as TTS stop',
        () async {
      final fake = FakeAudioPlayerHandle();
      final cache = FakeCacheManager();
      final service = SoundService(cacheManager: cache, player: fake);

      // Called with nothing playing — still reaches the player, matching
      // TtsAudioController.stop()'s unconditional flutterTts.stop() call.
      await service.stop();

      expect(fake.stopCallCount, 1);
      expect(service.isPlaying, isFalse);
    });

    test('stops the player and resets isPlaying when playing', () async {
      final fake = FakeAudioPlayerHandle();
      final cache = FakeCacheManager(cachedPath: '/cache/storm_waves.m4a');
      final service = SoundService(cacheManager: cache, player: fake);
      await service.toggle('storm_waves', encounterId: 'peter_water_001');

      await service.stop();

      expect(fake.stopCallCount, 1);
      expect(service.isPlaying, isFalse);
    });

    test(
        'a platform error during stop does not throw and still resets isPlaying',
        () async {
      final fake = FakeAudioPlayerHandle()..throwOnStop = true;
      final cache = FakeCacheManager(cachedPath: '/cache/storm_waves.m4a');
      final service = SoundService(cacheManager: cache, player: fake);
      await service.toggle('storm_waves', encounterId: 'peter_water_001');

      await expectLater(service.stop(), completes);

      expect(service.isPlaying, isFalse);
    });

    test('completes immediately — never awaits or is gated by any flag',
        () async {
      final fake = FakeAudioPlayerHandle();
      final cache = FakeCacheManager(cachedPath: '/cache/storm_waves.m4a');
      final service = SoundService(cacheManager: cache, player: fake);

      await service.stop().timeout(const Duration(milliseconds: 200));

      expect(service.isPlaying, isFalse);
    });
  });

  group('SoundService.dispose', () {
    test('releases the underlying player and resets isPlaying', () async {
      final fake = FakeAudioPlayerHandle();
      final cache = FakeCacheManager(cachedPath: '/cache/storm_waves.m4a');
      final service = SoundService(cacheManager: cache, player: fake);
      await service.toggle('storm_waves', encounterId: 'peter_water_001');

      await service.dispose();

      expect(fake.disposeCalled, isTrue);
      expect(service.isPlaying, isFalse);
    });
  });
}
