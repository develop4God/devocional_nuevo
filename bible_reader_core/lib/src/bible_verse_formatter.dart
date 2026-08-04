/// Utility for formatting Bible verses with full book name and version.
/// PURE Dart (no Flutter imports).
library;

class BibleVerseFormatter {
  /// Resolves the full book name for [shortName] from [books].
  ///
  /// [books]: List of maps, each {'short_name': ..., 'long_name': ...}
  /// Falls back to [shortName] itself when no match is found.
  static String resolveBookName(
    List<Map<String, dynamic>> books,
    String shortName,
  ) {
    return books.firstWhere(
      (b) => b['short_name'] == shortName,
      orElse: () => {'long_name': shortName},
    )['long_name'] as String;
  }

  /// Formats selected verses for sharing/copy, using full book name and version.
  ///
  /// A single selected verse is returned as one line:
  /// `Book chapter:verse (version) - text`.
  ///
  /// Multiple selected verses (always within the same book/chapter, per
  /// [BibleReaderController]'s selection reset on navigation) are combined
  /// into one block: a `Book chapter:verses (version)` header — where
  /// `verses` collapses consecutive runs into ranges (e.g. `16-18, 23, 26`)
  /// — followed by each verse as `[verse] text`, one per line.
  ///
  /// [selectedVerseKeys]: e.g. ["Jn|3|16"]
  /// [verses]: List of maps, each {'verse': int, 'text': ...}
  /// [books]: List of maps, each {'short_name': ..., 'long_name': ...}
  /// [versionName]: e.g. "RVR1960"
  /// [cleanText]: function to clean/normalize the verse text
  static String formatVerses({
    required Iterable<String> selectedVerseKeys,
    required List<Map<String, dynamic>> verses,
    required List<Map<String, dynamic>> books,
    required String versionName,
    required String Function(dynamic text) cleanText,
  }) {
    final List<({String bookAbbrev, String chapter, int verseNum, String text})>
        entries = [];
    for (final key in selectedVerseKeys) {
      final parts = key.split('|');
      if (parts.length != 3) continue;
      final verseNum = int.tryParse(parts[2]);
      if (verseNum == null) continue;

      final verse = verses.firstWhere(
        (v) => v['verse'] == verseNum,
        orElse: () => {},
      );
      if (verse.isEmpty) continue;

      entries.add((
        bookAbbrev: parts[0],
        chapter: parts[1],
        verseNum: verseNum,
        text: cleanText(verse['text']),
      ));
    }

    entries.sort((a, b) => a.verseNum.compareTo(b.verseNum));

    if (entries.isEmpty) return '';

    if (entries.length == 1) {
      final entry = entries.first;
      final longBookName = resolveBookName(books, entry.bookAbbrev);
      return '$longBookName ${entry.chapter}:${entry.verseNum} ($versionName) - ${entry.text}';
    }

    final first = entries.first;
    final longBookName = resolveBookName(books, first.bookAbbrev);
    final verseRanges = _collapseToRanges(entries.map((e) => e.verseNum));
    final header = '$longBookName ${first.chapter}:$verseRanges ($versionName)';
    final verseLines = entries.map((e) => '[${e.verseNum}] ${e.text}');

    return ([header, ...verseLines]).join('\n');
  }

  /// Collapses a sorted sequence of verse numbers into a comma-separated
  /// summary, combining consecutive runs into ranges.
  ///
  /// e.g. [16, 17, 18, 23, 26] -> "16-18, 23, 26"
  static String _collapseToRanges(Iterable<int> verseNums) {
    final nums = verseNums.toList();
    final List<String> parts = [];
    int runStart = nums.first;
    int runEnd = nums.first;

    void closeRun() {
      parts.add(runStart == runEnd ? '$runStart' : '$runStart-$runEnd');
    }

    for (final num in nums.skip(1)) {
      if (num == runEnd + 1) {
        runEnd = num;
      } else {
        closeRun();
        runStart = num;
        runEnd = num;
      }
    }
    closeRun();

    return parts.join(', ');
  }
}
