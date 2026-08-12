/// Matches MyBible-style inline Strong's number tags, e.g. `<S>1234</S>`,
/// used by Bible databases such as RV'09+ (Reina-Valera 1909 con números de
/// Strong).
final RegExp _strongTagPattern = RegExp(r'<S>(\d+)</S>');

/// Matches a run of letters/digits/hyphens, used to locate word tokens that
/// may have a Hebrew/Greek morphology code glued onto their end (see
/// [BibleTextNormalizer.stripGluedMorphologyCodes]).
final RegExp _wordRunPattern = RegExp(r'[\p{L}\p{N}-]+', unicode: true);

class BibleTextNormalizer {
  /// Removes Strong's number tags (`<S>1234</S>`) as a single unit, so the
  /// wrapped digits aren't left behind as stray text. Kept separate from
  /// [clean]'s generic tag stripper since it targets a specific tag shape.
  static String stripStrongTags(String text) {
    return text.replaceAll(_strongTagPattern, '');
  }

  /// Cleans Bible text by removing tags like `<pb/>`, `<f>`, `<S>1234</S>`
  /// (Strong's numbers), angle-bracketed tags, references like [1], [a],
  /// [36†], Unicode inline footnote markers (circled letters/numbers:
  /// ⓐ–ⓩ, Ⓐ–Ⓩ, ①–⑳, U+2460–U+24FF) used by Bible databases such as MBB05,
  /// and unescaped `&quot;` entities left over from LBLA download text.
  /// Applies to all Bible versions universally.
  static String clean(String? text) {
    if (text == null) return '';
    String cleaned = stripStrongTags(text); // Remove <S>1234</S> as a unit
    // Decode the literal &quot; entity left unescaped in LBLA download text
    // into a straight double quote.
    cleaned = cleaned.replaceAll('&quot;', '"');
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
    // Remove stray bullet markers (\u2022) with surrounding whitespace, collapsing
    // to a single space so words don't get glued together (seen in LBLA
    // download text, e.g. `la \u2022 tarde`).
    cleaned = cleaned.replaceAll(RegExp(r'\s*\u2022\s*'), ' ');
    cleaned = stripGluedMorphologyCodes(cleaned);
    return cleaned.trim();
  }

  /// Strips Hebrew/Greek morphology codes glued directly onto words with no
  /// delimiter, as seen in some LBLA download modules (Genesis 1:1-2
  /// example: `EnP el principioNCFSA cre\u00F3VaP3MS DiosNCMPAPO... YC la...`).
  /// Within each word/digit/hyphen run, the code always starts at the first
  /// uppercase letter found after the first character (covering both a
  /// lowercase-to-uppercase transition like `principioNCFSA`, and a
  /// single-letter capitalized word like `Y` glued straight to an uppercase
  /// code as in `YC`); everything from that point on is dropped.
  static String stripGluedMorphologyCodes(String text) {
    return text.replaceAllMapped(_wordRunPattern, (match) {
      final token = match.group(0)!;
      for (var i = 1; i < token.length; i++) {
        final char = token[i];
        if (char != char.toLowerCase() && char == char.toUpperCase()) {
          return token.substring(0, i);
        }
      }
      return token;
    });
  }
}
