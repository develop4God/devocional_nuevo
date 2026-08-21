// lib/services/sound/i_sound_service.dart

/// Ambient sound playback state, mirroring the real player rather than a
/// hand-tracked flag — same modeling as TtsState in tts_service.dart.
enum SoundState {
  idle,
  playing,

  /// The last toggle()/stop() call failed at the platform layer.
  error,
}

abstract class ISoundService {
  /// Toggles ambient sound playback for [cueKey] within [encounterId].
  ///
  /// If not currently playing, resolves the cue to a URL and starts a
  /// gapless loop. If already playing, stops playback.
  ///
  /// [version] — optional cache-busting query param, forwarded to
  /// Constants.getEncounterAudioUrl (e.g. EncounterIndexEntry.soundVersion).
  Future<void> toggle(
    String cueKey, {
    required String encounterId,
    String? version,
  });

  /// Stops playback if currently playing. No-op otherwise. Unlike [toggle],
  /// this never starts playback — safe to call unconditionally from
  /// teardown paths (e.g. widget dispose) without risking a restart.
  Future<void> stop();

  /// Current playback state, read from the real player — never a value
  /// tracked by hand, so it can't drift from what's actually playing.
  SoundState get state;

  /// Convenience for `state == SoundState.playing`.
  bool get isPlaying;

  Future<void> dispose();
}
