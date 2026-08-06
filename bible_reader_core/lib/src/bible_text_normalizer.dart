/// Matches MyBible-style inline Strong's number tags, e.g. `<S>1234</S>`,
/// used by Bible databases such as RV'09+ (Reina-Valera 1909 con números de
/// Strong).
final RegExp _strongTagPattern = RegExp(r'<S>(\d+)</S>');

class BibleTextNormalizer {
  /// Removes Strong's number tags (`<S>1234</S>`) as a single unit, so the
  /// wrapped digits aren't left behind as stray text. Kept separate from
  /// [clean]'s generic tag stripper since it targets a specific tag shape.
  static String stripStrongTags(String text) {
    return text.replaceAll(_strongTagPattern, '');
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
