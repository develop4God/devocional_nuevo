/// SRP: owns all Hindi-specific TTS pre-processing.
/// Called by BibleTextFormatter before any shared normalization steps.
class HindiTtsNormalizer {
  /// Devanagari digit → ASCII digit map
  static const Map<String, String> _devanagariDigits = {
    '०': '0',
    '१': '1',
    '२': '2',
    '३': '3',
    '४': '4',
    '५': '5',
    '६': '6',
    '७': '7',
    '८': '8',
    '९': '9',
  };

  /// Convert Devanagari digits to ASCII so regex \d+ matches correctly
  static String convertDevanagariDigits(String text) {
    String result = text;
    _devanagariDigits.forEach((deva, ascii) {
      result = result.replaceAll(deva, ascii);
    });
    return result;
  }

  /// Replace Devanagari danda and double danda with period + space
  /// Prevents TTS from reading '।' as a symbol or skipping pauses entirely
  static String normalizeDanda(String text) {
    return text
        .replaceAll('॥', '. ') // double danda
        .replaceAll('।', '. '); // single danda
  }

  /// Expand Hindi Bible version abbreviations not covered by shared map
  static String expandVersionAbbreviations(String text) {
    const Map<String, String> extraKeys = {
      'ओ.वी.': 'पवित्र बाइबिल पुराना संस्करण',
      'HIOV_hi.SQLite3': 'पवित्र बाइबिल पुराना संस्करण',
      'HERV_hi.SQLite3': 'पवित्र बाइबिल हिंदी आसान पठन संस्करण',
    };
    String result = text;
    extraKeys.forEach((key, expansion) {
      result = result.replaceAll(key, expansion);
    });
    return result;
  }

  /// Single entry point — apply all Hindi pre-processing in order
  static String preProcess(String text) {
    String result = convertDevanagariDigits(text);
    result = normalizeDanda(result);
    result = expandVersionAbbreviations(result);
    return result;
  }
}
