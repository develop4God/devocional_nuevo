@Tags(['unit', 'services'])
library;

import 'package:devocional_nuevo/services/tts/tts_verse_index_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('long verse occupies proportionally more of the timeline', () {
    // Header 3 words + verses of 2, 90, 8 words → total 103 words.
    // Verse ranges (cumulative words): v0 [4..5], v1 [6..95], v2 [96..103].
    final resolver = TtsVerseIndexResolver.fromWordCounts(
      [2, 90, 8],
      headerWords: 3,
    );

    // Early on (still header / v0).
    expect(resolver.indexForFraction(0.0), 0);
    // Middle of the long verse must map to verse 1, not verse 1.5-by-count.
    expect(resolver.indexForFraction(0.5), 1);
    // Near the end → last verse.
    expect(resolver.indexForFraction(0.99), 2);
  });

  test('flat mapping would desync where word-mapping stays correct', () {
    // 3 verses, but verse 1 is huge. Flat fraction*3 at f=0.5 => index 1 too,
    // but at f=0.34 flat says index 1 while words say still in the header/v0.
    final resolver = TtsVerseIndexResolver.fromWordCounts(
      [1, 100, 1],
      headerWords: 0,
    );
    // 34% of 102 words = ~34.7 → inside verse 1's [2..101] range → index 1.
    expect(resolver.indexForFraction(0.34), 1);
    // 1% of 102 words = ~1.0 → verse 0 ends at word 1 → index 0.
    expect(resolver.indexForFraction(0.005), 0);
  });

  test('returns null for empty verses', () {
    final resolver = TtsVerseIndexResolver.fromWordCounts([], headerWords: 3);
    expect(resolver.indexForFraction(0.5), isNull);
  });

  test('wordCount splits on whitespace and handles blanks', () {
    expect(TtsVerseIndexResolver.wordCount('one two three'), 3);
    expect(TtsVerseIndexResolver.wordCount('  spaced   out  '), 2);
    expect(TtsVerseIndexResolver.wordCount(''), 0);
    expect(TtsVerseIndexResolver.wordCount(null), 0);
  });
}
