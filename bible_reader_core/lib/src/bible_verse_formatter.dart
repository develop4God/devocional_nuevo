/// Utility for formatting Bible verses with full book name and version.
/// PURE Dart (no Flutter imports).
library;

class BibleVerseFormatter {
  /// Formats selected verses for sharing/copy, using full book name and version.
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
    final List<String> lines = [];
    final sortedVerses = selectedVerseKeys.toList()..sort();

    for (final key in sortedVerses) {
      final parts = key.split('|');
      if (parts.length != 3) continue;
      final bookAbbrev = parts[0];
      final chapter = parts[1];
      final verseNum = int.tryParse(parts[2]);
      if (verseNum == null) continue;

      final longBookName = books.firstWhere(
        (b) => b['short_name'] == bookAbbrev,
        orElse: () => {'long_name': bookAbbrev},
      )['long_name'];

      final verse = verses.firstWhere(
        (v) => v['verse'] == verseNum,
        orElse: () => {},
      );

      if (verse.isNotEmpty) {
        lines.add(
          '$longBookName $chapter:$verseNum ($versionName) - ${cleanText(verse['text'])}',
        );
      }
    }

    return lines.join('\n\n');
  }
}
