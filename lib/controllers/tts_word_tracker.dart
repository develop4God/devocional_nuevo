import 'package:flutter/foundation.dart';

/// Tracks which word the TTS engine is currently speaking and publishes its
/// character offset within the *full* text.
///
/// Single responsibility: translate the engine's per-utterance progress events
/// (offsets relative to the current `speak()` call) into a global offset
/// against the full text. It knows nothing about playback control, verses, or
/// scrolling — consumers listen to [spokenCharOffset] and map it however they
/// like. Decoupled from [TtsAudioController] so it is reusable and testable in
/// isolation.
///
/// [spokenCharOffset] is -1 when the current word is unknown: before playback,
/// after [reset], or on engines that emit no progress events (e.g. some iOS
/// voices). Consumers treat -1 as "no word-accurate signal — fall back".
class TtsWordTracker {
  /// Global character offset of the word currently being spoken, or -1.
  final ValueNotifier<int> spokenCharOffset = ValueNotifier<int>(-1);

  /// Offset of the current utterance segment within the full text. The engine
  /// reports progress relative to the segment passed to `speak()`, so the
  /// global offset is [_segmentBase] + the reported start.
  int _segmentBase = 0;
  bool _disposed = false;

  /// Set the base offset of the segment about to be (or being) spoken.
  ///
  /// Pass 0 for a fresh start from the beginning, or the length of the skipped
  /// prefix when resuming from pause / after a seek, so reported offsets remain
  /// global.
  void beginSegment(int base) {
    _segmentBase = base < 0 ? 0 : base;
  }

  /// Feed a raw progress event. [startInSegment] is the character offset of the
  /// spoken word relative to the current `speak()` call.
  void onProgress(int startInSegment) {
    if (_disposed) return;
    final global = _segmentBase + (startInSegment < 0 ? 0 : startInSegment);
    spokenCharOffset.value = global;
  }

  /// Clear the tracked word (e.g. on stop/completion) so consumers fall back to
  /// the estimated position.
  void reset() {
    if (_disposed) return;
    _segmentBase = 0;
    spokenCharOffset.value = -1;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    spokenCharOffset.dispose();
  }
}
