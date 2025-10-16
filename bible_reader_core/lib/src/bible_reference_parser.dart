/// Helper class to parse Bible references like "Juan 3:16", "Genesis 1:1", etc.
class BibleReferenceParser {
  /// Parses a Bible reference string and returns book name, chapter, and optional verse
  /// Returns null if the input doesn't match a Bible reference pattern
  static Map<String, dynamic>? parse(String input) {
    final trimmed = input.trim();

    // Pattern 1: "Book Chapter:Verse" (e.g., "Juan 3:16", "Genesis 1:1")
    // Pattern 2: "Book Chapter" (e.g., "Juan 3", "Genesis 1")
    // Supports book names with numbers (e.g., "1 Juan", "2 Corintios")
    // Supports book names with spaces and accents

    // Match patterns like: "1 Juan 3:16" or "Juan 3:16" or "Genesis 1:1"
    final regexWithVerse = RegExp(
      r'^(\d+\s+)?([a-záéíóúñü\s\.]+?)\s+(\d+):(\d+)$',
      caseSensitive: false,
      unicode: true,
    );

    // Match patterns like: "1 Juan 3" or "Juan 3" or "Genesis 1"
    final regexWithoutVerse = RegExp(
      r'^(\d+\s+)?([a-záéíóúñü\s\.]+?)\s+(\d+)$',
      caseSensitive: false,
      unicode: true,
    );

    // Try with verse first
    var match = regexWithVerse.firstMatch(trimmed);
    if (match != null) {
      final bookPrefix = match.group(1)?.trim() ?? '';
      final bookName = match.group(2)!.trim();
      final chapter = int.tryParse(match.group(3)!);
      final verse = int.tryParse(match.group(4)!);

      if (chapter != null && verse != null) {
        final fullBookName =
            bookPrefix.isEmpty ? bookName : '$bookPrefix $bookName';
        return {
          'bookName': fullBookName,
          'chapter': chapter,
          'verse': verse,
        };
      }
    }

    // Try without verse
    match = regexWithoutVerse.firstMatch(trimmed);
    if (match != null) {
      final bookPrefix = match.group(1)?.trim() ?? '';
      final bookName = match.group(2)!.trim();
      final chapter = int.tryParse(match.group(3)!);

      if (chapter != null) {
        final fullBookName =
            bookPrefix.isEmpty ? bookName : '$bookPrefix $bookName';
        return {
          'bookName': fullBookName,
          'chapter': chapter,
        };
      }
    }

    return null;
  }
}
