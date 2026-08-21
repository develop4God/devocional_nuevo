// lib/services/sound/i_sound_service.dart

abstract class ISoundService {
  /// Toggles ambient sound playback for [cueKey] within [encounterId].
  ///
  /// If not currently playing, resolves the cue to a URL and starts a
  /// gapless loop. If already playing, stops playback.
  Future<void> toggle(String cueKey, {required String encounterId});

  bool get isPlaying;

  Future<void> dispose();
}
