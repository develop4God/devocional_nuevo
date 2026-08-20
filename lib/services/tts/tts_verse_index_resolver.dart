/// Maps a TTS playback signal onto the verse being read.
///
/// Built from the *character* length each verse contributes to the spoken text
/// (plus a header), because both signals it consumes are character-based:
///  * the word-accurate progress offset from the TTS engine, and
///  * a proportional fraction fallback (position estimate).
///
/// Character ranges honour real content distribution, so a long verse occupies
/// proportionally more of the timeline than a short one — a flat
/// `fraction * verseCount` mapping desyncs badly on real chapters.
///
/// The spoken text is a header followed by every verse concatenated (see
/// `BibleReaderTtsTextBuilder.build`).
class TtsVerseIndexResolver {
  /// Cumulative character count at the END of each verse, header included.
  final List<int> _cumulative;
  final int _headerChars;
  final int _totalChars;

  TtsVerseIndexResolver._(
    this._cumulative,
    this._headerChars,
    this._totalChars,
  );

  /// Build from the ordered [verseCharCounts] (one per verse, display order)
  /// and the [headerChars] spoken before verse 1.
  factory TtsVerseIndexResolver.fromCharCounts(
    List<int> verseCharCounts, {
    required int headerChars,
  }) {
    final cumulative = <int>[];
    int running = headerChars;
    for (final c in verseCharCounts) {
      running += c;
      cumulative.add(running);
    }
    return TtsVerseIndexResolver._(cumulative, headerChars, running);
  }

  int get length => _cumulative.length;

  /// Total character span (header + all items), for continuous fraction mapping.
  int get totalChars => _totalChars;

  /// Verse index for a global [charOffset] (from the TTS progress handler),
  /// or null when there are no verses. Clamped to the verse range.
  int? indexForCharOffset(int charOffset) {
    if (_cumulative.isEmpty) return null;
    if (charOffset < _headerChars) return 0;
    for (int i = 0; i < _cumulative.length; i++) {
      if (charOffset < _cumulative[i]) return i;
    }
    return _cumulative.length - 1;
  }

  /// Verse index for a playback [fraction] (0.0..1.0) — the estimated fallback
  /// used when no word-accurate offset is available. Maps the fraction across
  /// the same character span so it stays consistent with the offset path.
  int? indexForFraction(double fraction) {
    if (_cumulative.isEmpty || _totalChars <= 0) return null;
    final charOffset = (fraction.clamp(0.0, 1.0) * _totalChars).round();
    return indexForCharOffset(charOffset);
  }

  /// Character length of [text] after trimming. Returns 0 for null/blank.
  static int charCount(String? text) => text?.trim().length ?? 0;
}
