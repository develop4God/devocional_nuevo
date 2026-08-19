@Tags(['unit', 'services'])
library;

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
}
