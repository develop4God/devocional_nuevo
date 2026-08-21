@Tags(['unit', 'services'])
library;

import 'package:devocional_nuevo/services/sound/audio_player_handle.dart';
import 'package:devocional_nuevo/services/sound/sound_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

class FakeAudioPlayerHandle implements AudioPlayerHandle {
  String? lastUrl;
  LoopMode? lastLoopMode;
  bool playCalled = false;
  bool stopCalled = false;
  bool disposeCalled = false;
  bool throwOnSetUrl = false;

  @override
  Future<void> setUrl(String url) async {
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
    stopCalled = true;
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
      expect(fake.stopCalled, isTrue);
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
