/// Matches MyBible-style inline Strong's number tags, e.g. `<S>1234</S>`,
/// used by Bible databases such as RV'09+ (Reina-Valera 1909 con números de
/// Strong).
final RegExp _strongTagPattern = RegExp(r'<S>(\d+)</S>');

/// Matches MyBible-style inline morphology code tags, e.g. `<m>NCFSA</m>`,
/// used by Bible databases such as LBLA (La Biblia de las Américas). Must be
/// stripped as a unit (tag + content together) so the wrapped code isn't
/// left behind as stray text — the generic `<...>` tag stripper in [clean]
/// only removes the angle-bracket delimiters, not the text between an
/// opening and closing tag pair.
final RegExp _morphTagPattern = RegExp(r'<m>[^<]*</m>');

class BibleTextNormalizer {
  /// Removes Strong's number tags (`<S>1234</S>`) as a single unit, so the
  /// wrapped digits aren't left behind as stray text. Kept separate from
  /// [clean]'s generic tag stripper since it targets a specific tag shape.
  static String stripStrongTags(String text) {
    return text.replaceAll(_strongTagPattern, '');
  }

  /// Removes morphology code tags (`<m>NCFSA</m>`) as a single unit, so the
  /// wrapped code isn't left behind as stray text. Kept separate from
  /// [clean]'s generic tag stripper for the same reason as [stripStrongTags].
  static String stripMorphTags(String text) {
    return text.replaceAll(_morphTagPattern, '');
  }

  /// Cleans Bible text by removing tags like `<pb/>`, `<f>`, `<S>1234</S>`
  /// (Strong's numbers), `<m>NCFSA</m>` (morphology codes), angle-bracketed
  /// tags, references like [1], [a], [36†], Unicode inline footnote markers
  /// (circled letters/numbers: ⓐ–ⓩ, Ⓐ–Ⓩ, ①–⑳, U+2460–U+24FF) used by Bible
  /// databases such as MBB05, and unescaped `&quot;` entities left over from
  /// LBLA download text.
  /// Applies to all Bible versions universally.
  static String clean(String? text) {
    if (text == null) return '';
    String cleaned = stripStrongTags(text); // Remove <S>1234</S> as a unit
    cleaned = stripMorphTags(cleaned); // Remove <m>NCFSA</m> as a unit
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
    cleaned = cleaned.replaceAll(RegExp(r'[①-⓿]'), '');
    // Remove stray bullet markers (•) with surrounding whitespace, collapsing
    // to a single space so words don't get glued together (seen in LBLA
    // download text, e.g. `la • tarde`).
    cleaned = cleaned.replaceAll(RegExp(r'\s*•\s*'), ' ');
    return cleaned.trim();
  }
}
