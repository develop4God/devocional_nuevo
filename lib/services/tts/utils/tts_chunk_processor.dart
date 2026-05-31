// lib/services/tts/utils/tts_chunk_processor.dart

import 'package:flutter/foundation.dart';

/// Encapsulates the text-chunking strategy for the Android TTS engine.
///
/// Android's TTS engine hard-rejects input >= 4096 chars (ERROR_OUTPUT -8).
/// This class is responsible for:
///  1. Splitting long texts at safe word boundaries ([splitIntoChunks]).
///  2. Computing per-chunk speak() timeouts that scale with text length and
///     engine speed so hung engines are detected reliably ([chunkTimeout]).
///
/// The class is stateless and dependency-free, making it trivially testable
/// in isolation (black-box) and injectable into any consumer.
///
/// Register via the Service Locator:
/// ```dart
/// locator.registerLazySingleton<TtsChunkProcessor>(() => TtsChunkProcessor());
/// ```
class TtsChunkProcessor {
  // ── Constants ──────────────────────────────────────────────────────────────

  /// Android TTS engine hard-rejects input >= 4096 chars (ERROR_OUTPUT -8).
  /// 3 500 gives a 596-char safety margin below that hard limit.
  static const int kMaxChunkLength = 3500;

  /// Approximate chars/second at flutter_tts settings-rate 0.5 (normal speed).
  /// Deliberately conservative at 12.0 rather than the theoretical 13.75
  /// (150 wpm × 5.5 chars/word ÷ 60 s) to account for TTS engine warm-up,
  /// inter-sentence pauses, and device variance.  A lower baseline produces
  /// longer timeouts — the safe direction for a hang-detection safety net.
  static const double kBaselineCharsPerSec = 12.0;

  /// Safety multiplier applied to the estimated speaking time.
  /// 2× means the timeout fires only if TTS takes twice as long as expected,
  /// which in practice means the engine silently hung.
  static const double kTimeoutSafetyMultiplier = 2.0;

  /// Floor: even very short chunks or very fast rates get at least this.
  static const int kMinChunkTimeoutSec = 60;

  /// Ceiling: hard cap so a hung engine never freezes the app for more than
  /// 20 minutes regardless of chapter length or playback speed.
  static const int kMaxChunkTimeoutSec = 1200; // 20 min

  /// Timeout for single-chunk (fire-and-forget) mode.
  /// In this mode speak() resolves when the utterance is *queued*, not when
  /// it finishes speaking, so 10 s is ample to detect a non-responsive engine.
  static const int kQueueTimeoutSec = 10;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Splits [text] into chunks of at most [maxLength] characters, breaking
  /// only at word boundaries to avoid mid-word cuts.
  ///
  /// Returns a list with a single element when [text.length <= maxLength].
  List<String> splitIntoChunks(String text, {int maxLength = kMaxChunkLength}) {
    if (text.length <= maxLength) return [text];

    final chunks = <String>[];
    int start = 0;
    while (start < text.length) {
      int end = (start + maxLength).clamp(0, text.length);
      if (end < text.length) {
        // Walk back to the last space to avoid a mid-word cut.
        final lastSpace = text.lastIndexOf(' ', end);
        if (lastSpace > start) end = lastSpace;
      }
      chunks.add(text.substring(start, end).trim());
      start = end;
      // Skip leading whitespace for the next chunk.
      while (start < text.length && text[start] == ' ') {
        start++;
      }
    }

    debugPrint(
      '📝 [TtsChunkProcessor] Text split into ${chunks.length} chunks '
      '(max $maxLength chars each)',
    );
    return chunks;
  }

  /// Computes a per-chunk speak() timeout based on [charCount] and the TTS
  /// engine [settingsRate] (0.25 = half speed, 0.5 = normal, 0.75 = 1.5×).
  ///
  /// When [awaitSpeakCompletion] is `true` the Future returned by speak()
  /// blocks until the utterance actually *finishes speaking* (which can be
  /// several minutes for a long chunk at slow speed).  A fixed timeout is
  /// too short at 0.5× speed and unnecessarily large at 1.5×.  This method
  /// scales the timeout to the actual workload with a 2× safety margin.
  ///
  /// Floor  : [kMinChunkTimeoutSec] (60 s)  — short chunks / fast rates.
  /// Ceiling: [kMaxChunkTimeoutSec] (1200 s) — even the longest Bible chapter
  ///          at the slowest speed completes well within 20 min per chunk.
  Duration chunkTimeout(int charCount, {required double settingsRate}) {
    // Debug-time assertions to catch callers passing invalid values early.
    assert(settingsRate > 0, 'settingsRate must be > 0, got $settingsRate');
    assert(charCount >= 0, 'charCount must be >= 0, got $charCount');

    // Production-safe guards (asserts are stripped in release builds).
    // settingsRate ≤ 0 causes adjustedCharsPerSec = 0, then
    //   charCount / 0.0 = double.infinity, and infinity.ceil() throws
    //   "Unsupported operation: Not a finite number" at runtime.
    // charCount < 0 produces a negative estimated time before clamp, which
    //   clamp() recovers from, but the intent is clearly wrong.
    final double safeRate = settingsRate > 0 ? settingsRate : 0.5;
    final int safeCharCount = charCount >= 0 ? charCount : 0;

    // Scale baseline chars/sec linearly with the engine rate.
    // settingsRate=0.5 is normal speed; 0.25 is half speed → half chars/sec.
    final double adjustedCharsPerSec = kBaselineCharsPerSec * (safeRate / 0.5);

    final int estimated =
        (safeCharCount / adjustedCharsPerSec * kTimeoutSafetyMultiplier).ceil();

    final int clamped = estimated.clamp(
      kMinChunkTimeoutSec,
      kMaxChunkTimeoutSec,
    );

    debugPrint(
      '⏱️ [TtsChunkProcessor] chunkTimeout: $charCount chars, '
      'settingsRate=$settingsRate → est=${estimated}s → timeout=${clamped}s',
    );
    return Duration(seconds: clamped);
  }
}
