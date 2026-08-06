/// Matches MyBible-style inline Strong's number tags, e.g. `<S>1234</S>`,
/// used by Bible databases such as RV'09+ (Reina-Valera 1909 con números de
/// Strong). Captures the number so callers can parse it, not just discard it.
final RegExp _strongTagPattern = RegExp(r'<S>(\d+)</S>');

/// One Strong's number found in a verse, with its position in the
/// already-cleaned (Strong's-tag-free) text it was extracted from.
class StrongTagMatch {
  /// Offset into the cleaned text immediately after which this Strong's
  /// number applies (i.e. the index the tag occupied before removal).
  final int offset;

  /// The bare Strong's number, e.g. `'1234'` (no G/H prefix — the tag alone
  /// doesn't encode Hebrew vs. Greek).
  final String number;

  StrongTagMatch({required this.offset, required this.number});
}

class BibleTextNormalizer {
  /// Removes Strong's number tags (`<S>1234</S>`) as a single unit, so the
  /// wrapped digits aren't left behind as stray text. Kept separate from
  /// [clean]'s generic tag stripper so this can be reused by a future
  /// Strong's lookup feature without re-deriving the tag pattern.
  static String stripStrongTags(String text) {
    return text.replaceAll(_strongTagPattern, '');
  }

  /// Parses Strong's number tags out of [text], returning the cleaned text
  /// (tags removed) alongside the list of numbers found, in order. Intended
  /// for a future Strong's dictionary/lookup feature — not currently called
  /// by [clean], which discards Strong's tags outright via [stripStrongTags].
  static (String cleanedText, List<StrongTagMatch> matches) parseStrongTags(
    String text,
  ) {
    final matches = <StrongTagMatch>[];
    final buffer = StringBuffer();
    int lastEnd = 0;
    for (final match in _strongTagPattern.allMatches(text)) {
      buffer.write(text.substring(lastEnd, match.start));
      matches.add(
        StrongTagMatch(offset: buffer.length, number: match.group(1)!),
      );
      lastEnd = match.end;
    }
    buffer.write(text.substring(lastEnd));
    return (buffer.toString(), matches);
  }

  /// Cleans Bible text by removing tags like `<pb/>`, `<f>`, `<S>1234</S>`
  /// (Strong's numbers), angle-bracketed tags, references like [1], [a],
  /// [36†], and Unicode inline footnote markers (circled letters/numbers:
  /// ⓐ–ⓩ, Ⓐ–Ⓩ, ①–⑳, U+2460–U+24FF) used by Bible databases such as MBB05.
  /// Applies to all Bible versions universally.
  static String clean(String? text) {
    if (text == null) return '';
    String cleaned = stripStrongTags(text); // Remove <S>1234</S> as a unit
    cleaned = cleaned.replaceAll(
      RegExp(r'<[^>]+>'),
      '',
    ); // Remove all remaining <...> tags
    cleaned = cleaned.replaceAll(
      RegExp(r'\[[^\]]+\]'),
      '',
    ); // Remove all [bracketed] content
    // Remove Unicode "Enclosed Alphanumerics" (U+2460–U+24FF): circled numbers
    // (①②③…), circled uppercase (Ⓐ–Ⓩ), and circled lowercase (ⓐ–ⓩ) footnote markers.
    cleaned = cleaned.replaceAll(RegExp(r'[\u2460-\u24FF]'), '');
    return cleaned.trim();
  }
}
