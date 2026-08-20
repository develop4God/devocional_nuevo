@Tags(['unit', 'services'])
library;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/services/tts/bible_reader_tts_text_builder.dart';
import 'package:devocional_nuevo/services/tts/tts_verse_index_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Header 10 chars + verses of 5, 200, 20 chars → total 235.
  // Ranges: header [0..10), v0 [10..15), v1 [15..215), v2 [215..235).
  TtsVerseIndexResolver build() => TtsVerseIndexResolver.fromCharCounts(
        [5, 200, 20],
        headerChars: 10,
      );

  group('indexForCharOffset (word-accurate)', () {
    test('maps offset inside the header to the first verse', () {
      expect(build().indexForCharOffset(3), 0);
    });

    test('maps offset inside the long verse to that verse', () {
      // 100 is inside v1's [15..215) range.
      expect(build().indexForCharOffset(100), 1);
    });

    test('clamps past-end offset to the last verse', () {
      expect(build().indexForCharOffset(999), 2);
    });
  });

  group('indexForFraction (estimated fallback)', () {
    test('long verse occupies proportionally more of the timeline', () {
      final r = build();
      // 0.5 * 235 = ~117 → inside the long verse (index 1).
      expect(r.indexForFraction(0.5), 1);
      expect(r.indexForFraction(0.0), 0);
      expect(r.indexForFraction(0.99), 2);
    });
  });

  test('returns null for empty verses', () {
    final r = TtsVerseIndexResolver.fromCharCounts([], headerChars: 10);
    expect(r.indexForCharOffset(3), isNull);
    expect(r.indexForFraction(0.5), isNull);
  });

  test('charCount trims and handles blanks', () {
    expect(TtsVerseIndexResolver.charCount('abc'), 3);
    expect(TtsVerseIndexResolver.charCount('  ab  '), 2);
    expect(TtsVerseIndexResolver.charCount(''), 0);
    expect(TtsVerseIndexResolver.charCount(null), 0);
  });

  group('totalChars matches BibleReaderTtsTextBuilder.build (regression)', () {
    // Reproduces bible_reader_page.dart's _verseIndexResolver char-count
    // logic exactly, so a regression here means the resolver and the real
    // spoken text (which the TTS progress handler's offsets are measured
    // against) have drifted apart.
    int resolverTotalChars(BibleReaderState state) {
      final bookName = state.selectedBookName != null && state.books.isNotEmpty
          ? BibleVerseFormatter.resolveBookName(
              state.books,
              state.selectedBookName!,
            )
          : '';
      final chapter = state.selectedChapter ?? 1;
      final headerChars = bookName.isEmpty ? 0 : '$bookName $chapter.\n'.length;

      final verseCharCounts = state.verses.map((v) {
        final text = BibleTextNormalizer.clean(v['text']?.toString());
        return text.isEmpty ? 0 : text.length + 1;
      }).toList();
      final lastNonEmpty = verseCharCounts.lastIndexWhere((c) => c > 0);
      if (lastNonEmpty != -1) {
        verseCharCounts[lastNonEmpty] -= 1;
      }

      return TtsVerseIndexResolver.fromCharCounts(
        verseCharCounts,
        headerChars: headerChars,
      ).totalChars;
    }

    test('single-verse chapter: resolver total equals real spoken length', () {
      final state = BibleReaderState(
        books: [
          {'name': 'Genesis', 'longName': 'Genesis'},
        ],
        selectedBookName: 'Genesis',
        selectedChapter: 1,
        verses: [
          {'verse': 1, 'text': 'In the beginning'},
        ],
      );

      final spokenText = BibleReaderTtsTextBuilder.build(state);

      expect(resolverTotalChars(state), spokenText.length);
    });

    test('multi-verse chapter: resolver total equals real spoken length', () {
      final state = BibleReaderState(
        books: [
          {'name': 'Genesis', 'longName': 'Genesis'},
        ],
        selectedBookName: 'Genesis',
        selectedChapter: 1,
        verses: [
          {'verse': 1, 'text': 'In the beginning God created the heavens'},
          {'verse': 2, 'text': 'and the earth was without form'},
          {'verse': 3, 'text': 'and God said let there be light'},
        ],
      );

      final spokenText = BibleReaderTtsTextBuilder.build(state);

      expect(resolverTotalChars(state), spokenText.length);
    });
  });
}
