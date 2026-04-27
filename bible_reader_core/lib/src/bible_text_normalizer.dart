class BibleTextNormalizer {
  /// Cleans Bible text by removing tags like `<pb/>`, `<f>`, angle-bracketed tags,
  /// references like [1], [a], [36†], and Unicode inline footnote markers
  /// (circled letters/numbers: ⓐ–ⓩ, Ⓐ–Ⓩ, ①–⑳, U+2460–U+24FF) used by
  /// Bible databases such as MBB05. Applies to all Bible versions universally.
  static String clean(String? text) {
    if (text == null) return '';
    String cleaned = text.replaceAll(
      RegExp(r'<[^>]+>'),
      '',
    ); // Remove all <...> tags
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
