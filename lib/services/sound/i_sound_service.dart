// lib/services/sound/i_sound_service.dart

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

  /// Pauses playback if currently playing, keeping the loaded cue so
  /// [resume] can continue without re-fetching. No-op otherwise. Intended
  /// for app-lifecycle transitions (background/minimize) — mirrors TTS's
  /// pause-on-background behavior.
  Future<void> pause();

  /// Resumes playback if currently paused via [pause]. No-op otherwise.
  Future<void> resume();

  bool get isPlaying;

  /// True if playback is paused via [pause] and can be continued with
  /// [resume].
  bool get isPaused;

  Future<void> dispose();
}
