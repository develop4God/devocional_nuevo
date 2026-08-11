/// Matches MyBible-style inline Strong's number tags, e.g. `<S>1234</S>`,
/// used by Bible databases such as RV'09+ (Reina-Valera 1909 con números de
/// Strong).
final RegExp _strongTagPattern = RegExp(r'<S>(\d+)</S>');

/// Matches Hebrew/Greek morphology codes glued directly onto the end of a
/// word with no delimiter, as found in some LBLA ("La Biblia de las
/// Américas") download modules, e.g. `principioNCFSA`, `creóVaP3MS`. The
/// codes always begin with an uppercase letter immediately following the
/// lowercase letter that ends the real word, so that transition is used as
/// the split point.
final RegExp _gluedMorphologyCodePattern = RegExp(
  r'\p{Ll}\p{Lu}[\p{L}\p{N}-]*',
  unicode: true,
);

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
    cleaned = stripGluedMorphologyCodes(cleaned);
    return cleaned.trim();
  }

  /// Strips Hebrew/Greek morphology codes glued directly onto words with no
  /// delimiter, as seen in some LBLA download modules (Genesis 1:1 example:
  /// `EnP el principioNCFSA cre\u00F3VaP3MS DiosNCMPAPO...`). The word/code
  /// boundary is detected as a lowercase-to-uppercase letter transition
  /// within the same run of characters.
  static String stripGluedMorphologyCodes(String text) {
    return text.replaceAllMapped(
      _gluedMorphologyCodePattern,
      (match) => match.group(0)![0],
    );
  }
}
