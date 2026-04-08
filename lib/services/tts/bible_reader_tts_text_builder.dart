import 'package:bible_reader_core/bible_reader_core.dart';

/// Builds formatted TTS text from Bible Reader state for voice playback.
///
/// Follows Single Responsibility Principle: only responsible for
/// converting Bible chapter content into TTS-ready text format.
/// Uses [BibleTextNormalizer] for cleaning verse text.
class BibleReaderTtsTextBuilder {
  const BibleReaderTtsTextBuilder._();

  /// Build a TTS-ready string from the current Bible reader [state].
  ///
  /// Produces a natural reading of the current chapter including the book
  /// name, chapter number, and all verse texts cleaned of markup.
  static String build(BibleReaderState state) {
    if (state.verses.isEmpty) return '';

    final StringBuffer ttsBuffer = StringBuffer();

    // Add book and chapter header for context
    final bookName = _resolveBookLongName(state);
    final chapter = state.selectedChapter ?? 1;
    if (bookName.isNotEmpty) {
      ttsBuffer.write('$bookName $chapter.\n');
    }

    // Append each verse as clean text
    for (final verse in state.verses) {
      final text = BibleTextNormalizer.clean(verse['text']?.toString());
      if (text.isNotEmpty) {
        ttsBuffer.write('$text\n');
      }
    }

    return ttsBuffer.toString().trim();
  }

  /// Build TTS text for a subset of selected verse keys.
  ///
  /// Useful when the user selects specific verses for reading aloud.
  static String buildFromSelectedVerses(
    BibleReaderState state,
    Set<String> selectedVerseKeys,
  ) {
    if (selectedVerseKeys.isEmpty || state.verses.isEmpty) return '';

    final StringBuffer ttsBuffer = StringBuffer();

    // Add book and chapter header
    final bookName = _resolveBookLongName(state);
    final chapter = state.selectedChapter ?? 1;
    if (bookName.isNotEmpty) {
      ttsBuffer.write('$bookName $chapter.\n');
    }

    // Only include verses whose key matches the selection
    for (final verse in state.verses) {
      final verseNumber = verse['verse'];
      final key =
          '${state.selectedBookName}|${state.selectedChapter}|$verseNumber';
      if (selectedVerseKeys.contains(key)) {
        final text = BibleTextNormalizer.clean(verse['text']?.toString());
        if (text.isNotEmpty) {
          ttsBuffer.write('$text\n');
        }
      }
    }

    return ttsBuffer.toString().trim();
  }

  /// Resolve the long book name from state.books using selectedBookName.
  static String _resolveBookLongName(BibleReaderState state) {
    if (state.selectedBookName == null || state.books.isEmpty) return '';
    try {
      final book = state.books.firstWhere(
        (b) => b['short_name'] == state.selectedBookName,
      );
      return book['long_name']?.toString() ?? state.selectedBookName ?? '';
    } catch (_) {
      return state.selectedBookName ?? '';
    }
  }
}
