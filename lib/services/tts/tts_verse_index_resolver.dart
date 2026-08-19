/// Maps a TTS playback fraction (0.0..1.0) onto the verse being read, using
/// cumulative word counts so long verses occupy proportionally more of the
/// timeline than short ones.
///
/// The TTS position estimate is word-based (see `TtsDurationEstimator`), and the
/// spoken text is a header followed by every verse concatenated (see
/// `BibleReaderTtsTextBuilder.build`). A flat `fraction * verseCount` mapping
/// assumes equal words per verse and desyncs badly on real chapters. This
/// resolver aligns the highlight to the same word unit the estimate advances in.
class TtsVerseIndexResolver {
  /// Cumulative word count at the END of each verse, in verse order.
  /// `_cumulative[i]` = words spoken once verse `i` finishes (header included).
  final List<int> _cumulative;

  /// Words spoken before the first verse (the "BookName N." header).
  final int _headerWords;

  final int _totalWords;

  TtsVerseIndexResolver._(
    this._cumulative,
    this._headerWords,
    this._totalWords,
  );

  /// Build a resolver from the ordered [verseWordCounts] (one entry per verse,
  /// in display order) and the [headerWords] spoken before verse 1.
  factory TtsVerseIndexResolver.fromWordCounts(
    List<int> verseWordCounts, {
    required int headerWords,
  }) {
    final cumulative = <int>[];
    int running = headerWords;
    for (final w in verseWordCounts) {
      running += w;
      cumulative.add(running);
    }
    return TtsVerseIndexResolver._(cumulative, headerWords, running);
  }

  /// Number of verses this resolver covers.
  int get verseCount => _cumulative.length;

  /// Returns the 0-based index of the verse being read at [fraction], or null
  /// when there are no verses. The result is clamped to the verse range.
  int? indexForFraction(double fraction) {
    if (_cumulative.isEmpty || _totalWords <= 0) return null;

    final f = fraction.clamp(0.0, 1.0);
    final wordPos = f * _totalWords;

    // Still inside the header → first verse.
    if (wordPos <= _headerWords) return 0;

    // Find the first verse whose cumulative end is past the current word.
    for (int i = 0; i < _cumulative.length; i++) {
      if (wordPos <= _cumulative[i]) return i;
    }
    return _cumulative.length - 1;
  }

  /// Counts words in [text] the same way the duration estimator does
  /// (whitespace-split). Returns 0 for null/blank.
  static int wordCount(String? text) {
    if (text == null) return 0;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }
}
