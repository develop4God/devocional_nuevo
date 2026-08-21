// lib/services/sound/audio_player_handle.dart

import 'package:just_audio/just_audio.dart';

/// Thin seam over [AudioPlayer] exposing only what [SoundService] needs,
/// so the service depends on an abstraction rather than the concrete
/// just_audio player (DIP) and can be unit-tested without platform channels.
abstract class AudioPlayerHandle {
  Future<void> setUrl(String url);
  Future<void> setLoopMode(LoopMode mode);
  Future<void> play();
  Future<void> stop();
  Future<void> dispose();
}

class JustAudioPlayerHandle implements AudioPlayerHandle {
  JustAudioPlayerHandle() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> setUrl(String url) async {
    await _player.setUrl(url);
  }

  @override
  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
