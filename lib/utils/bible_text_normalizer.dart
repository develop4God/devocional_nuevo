class BibleTextNormalizer {
  /// Cleans Bible text by removing tags like <pb/>, <f>, <...>, and references like [1], [a], etc.
  static String clean(String? text) {
    if (text == null) return '';
    String cleaned =
        text.replaceAll(RegExp(r'<[^>]+>'), ''); // Remove all <...> tags
    cleaned =
        cleaned.replaceAll(RegExp(r'\[\w+\]'), ''); // Remove [1], [a], etc.
    return cleaned.trim();
  }
}
