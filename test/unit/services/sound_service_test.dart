@Tags(['unit', 'services'])
library;

import 'dart:async';

import 'package:devocional_nuevo/services/sound/audio_player_handle.dart';
import 'package:devocional_nuevo/services/sound/sound_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

class FakeAudioPlayerHandle implements AudioPlayerHandle {
  String? lastUrl;
  LoopMode? lastLoopMode;
  bool playCalled = false;
  int stopCallCount = 0;
  bool disposeCalled = false;
  bool throwOnSetUrl = false;
  bool throwOnStop = false;

  /// When set, [setUrl] doesn't complete until this completer resolves —
  /// simulates the real device's slow network + codec setup, so tests can
  /// fire a second toggle() while the first is still mid-flight.
  Completer<void>? setUrlGate;

  @override
  Future<void> setUrl(String url) async {
    if (setUrlGate != null) {
      await setUrlGate!.future;
    }
    if (throwOnSetUrl) {
      throw Exception('network error');
    }
    lastUrl = url;
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

void main() {
  group('SoundService.toggle', () {
    test('starts gapless loop playback on first toggle', () async {
      final fake = FakeAudioPlayerHandle();
      final service = SoundService(player: fake);

      await service.toggle('storm_waves', encounterId: 'peter_water_001');

      expect(service.isPlaying, isTrue);
      expect(fake.lastUrl, contains('storm_waves'));
      expect(fake.lastUrl, contains('peter_water_001'));
      expect(fake.lastLoopMode, LoopMode.one);
      expect(fake.playCalled, isTrue);
    });

    test('stops playback on second toggle', () async {
      final fake = FakeAudioPlayerHandle();
      final service = SoundService(player: fake);

      await service.toggle('storm_waves', encounterId: 'peter_water_001');
      await service.toggle('storm_waves', encounterId: 'peter_water_001');

      expect(service.isPlaying, isFalse);
      expect(fake.stopCallCount, 1);
    });

    test('version is forwarded to the resolved URL', () async {
      final fake = FakeAudioPlayerHandle();
      final service = SoundService(player: fake);

      await service.toggle(
        'storm_waves',
        encounterId: 'peter_water_001',
        version: '2.0',
      );

      expect(fake.lastUrl, contains('v=2.0'));
    });

    test('unreachable URL does not throw and leaves isPlaying false', () async {
      final fake = FakeAudioPlayerHandle()..throwOnSetUrl = true;
      final service = SoundService(player: fake);

      await expectLater(
        service.toggle('storm_waves', encounterId: 'peter_water_001'),
        completes,
      );
      expect(service.isPlaying, isFalse);
      expect(fake.playCalled, isFalse);
    });
  });

  group('SoundService.toggle concurrency', () {
    test(
        'a second toggle() landing while the first is still loading '
        'stops instead of starting a duplicate playback', () async {
      final fake = FakeAudioPlayerHandle()..setUrlGate = Completer<void>();
      final service = SoundService(player: fake);

      // First call: starts loading, blocked on setUrlGate (simulates the
      // real device's in-flight network + codec setup).
      final firstToggle = service.toggle(
        'storm_waves',
        encounterId: 'peter_water_001',
      );

      // Second call lands before the first has flipped isPlaying — must
      // wait for the first to finish rather than also starting playback.
      final secondToggle = service.toggle(
        'storm_waves',
        encounterId: 'peter_water_001',
      );

      // Let the first call's setUrl complete.
      fake.setUrlGate!.complete();
      await firstToggle;
      await secondToggle;

      // The first call played; the second, seeing it now playing, stopped
      // it — net result is stopped, not a duplicate/relaunched playback.
      expect(fake.stopCallCount, 1);
      expect(service.isPlaying, isFalse);
    });

    test('stop() landing while toggle() is still loading waits, then stops',
        () async {
      final fake = FakeAudioPlayerHandle()..setUrlGate = Completer<void>();
      final service = SoundService(player: fake);

      final toggleCall = service.toggle(
        'storm_waves',
        encounterId: 'peter_water_001',
      );
      final stopCall = service.stop();

      fake.setUrlGate!.complete();
      await toggleCall;
      await stopCall;

      expect(fake.playCalled, isTrue);
      expect(fake.stopCallCount, 1);
      expect(service.isPlaying, isFalse);
    });
  });

  group('SoundService.stop', () {
    test('no-op when not playing — never calls the player', () async {
      final fake = FakeAudioPlayerHandle();
      final service = SoundService(player: fake);

      await service.stop();

      expect(fake.stopCallCount, 0);
      expect(service.isPlaying, isFalse);
    });

    test('stops the player and resets isPlaying when playing', () async {
      final fake = FakeAudioPlayerHandle();
      final service = SoundService(player: fake);
      await service.toggle('storm_waves', encounterId: 'peter_water_001');

      await service.stop();

      expect(fake.stopCallCount, 1);
      expect(service.isPlaying, isFalse);
    });

    test(
        'a platform error during stop does not throw and still resets isPlaying',
        () async {
      final fake = FakeAudioPlayerHandle()..throwOnStop = true;
      final service = SoundService(player: fake);
      await service.toggle('storm_waves', encounterId: 'peter_water_001');

      await expectLater(service.stop(), completes);

      expect(service.isPlaying, isFalse);
    });

    test('calling stop() repeatedly never restarts playback', () async {
      final fake = FakeAudioPlayerHandle();
      final service = SoundService(player: fake);
      await service.toggle('storm_waves', encounterId: 'peter_water_001');

      await service.stop();
      await service.stop();
      await service.stop();

      expect(fake.playCalled, isTrue); // only from the initial toggle
      expect(fake.stopCallCount, 1); // subsequent stops are no-ops
      expect(service.isPlaying, isFalse);
    });
  });

  group('SoundService.dispose', () {
    test('releases the underlying player and resets isPlaying', () async {
      final fake = FakeAudioPlayerHandle();
      final service = SoundService(player: fake);
      await service.toggle('storm_waves', encounterId: 'peter_water_001');

      await service.dispose();

      expect(fake.disposeCalled, isTrue);
      expect(service.isPlaying, isFalse);
    });
  });
}
