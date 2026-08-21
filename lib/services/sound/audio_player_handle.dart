// lib/services/sound/audio_player_handle.dart

import 'package:just_audio/just_audio.dart';

/// Thin seam over [AudioPlayer] exposing only what [SoundService] needs,
/// so the service depends on an abstraction rather than the concrete
/// just_audio player (DIP) and can be unit-tested without platform channels.
abstract class AudioPlayerHandle {
  Future<void> setUrl(String url);
  Future<void> setFilePath(String path);
  Future<void> setLoopMode(LoopMode mode);
  Future<void> play();
  Future<void> stop();
  Future<void> dispose();

  /// The real, platform-reported playing state — not a value tracked by
  /// hand, so it can never drift from what the player is actually doing.
  bool get isPlaying;
}

class JustAudioPlayerHandle implements AudioPlayerHandle {
  JustAudioPlayerHandle() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  bool get isPlaying => _player.playing;

  @override
  Future<void> setUrl(String url) async {
    await _player.setUrl(url);
  }

  @override
  Future<void> setFilePath(String path) async {
    await _player.setFilePath(path);
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
