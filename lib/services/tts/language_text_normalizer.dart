/// Language-specific text normalization for TTS
/// Handles ordinal numbers, abbreviations, and other language-specific formatting
class LanguageTextNormalizer {
  /// Get ordinal word for a number based on language
  static String getOrdinal(int number, String language) {
    switch (language) {
      case 'en':
        return _getEnglishOrdinal(number);
      case 'pt':
        return _getPortugueseOrdinal(number);
      case 'fr':
        return _getFrenchOrdinal(number);
      default: // Spanish
        return _getSpanishOrdinal(number);
    }
  }

  /// Spanish ordinal numbers
  static String _getSpanishOrdinal(int number) {
    switch (number) {
      case 1:
        return 'primero';
      case 2:
        return 'segundo';
      case 3:
        return 'tercero';
      case 4:
        return 'cuarto';
      case 5:
        return 'quinto';
      default:
        return 'número $number';
    }
  }

  /// English ordinal numbers
  static String _getEnglishOrdinal(int number) {
    switch (number) {
      case 1:
        return 'first';
      case 2:
        return 'second';
      case 3:
        return 'third';
      case 4:
        return 'fourth';
      case 5:
        return 'fifth';
      default:
        return 'number $number';
    }
  }

  /// Portuguese ordinal numbers
  static String _getPortugueseOrdinal(int number) {
    switch (number) {
      case 1:
        return 'primeiro';
      case 2:
        return 'segundo';
      case 3:
        return 'terceiro';
      case 4:
        return 'quarto';
      case 5:
        return 'quinto';
      default:
        return 'número $number';
    }
  }

  /// French ordinal numbers
  static String _getFrenchOrdinal(int number) {
    switch (number) {
      case 1:
        return 'premier';
      case 2:
        return 'deuxième';
      case 3:
        return 'troisième';
      case 4:
        return 'quatrième';
      case 5:
        return 'cinquième';
      default:
        return 'numéro $number';
    }
  }

  /// Format ordinal numbers with language-specific words
  static String formatOrdinalNumbers(String text, String language) {
    // Replace ordinal indicators after numbers
    String result = text;
    
    // Look for patterns like "1º", "2ª", "3°" etc.
    final regex = RegExp(r'(\d+)([º°ª])');
    result = result.replaceAllMapped(regex, (match) {
      final number = int.tryParse(match.group(1)!) ?? 0;
      return getOrdinal(number, language);
    });
    
    return result;
  }

  /// Apply language-specific normalizations
  static String applyLanguageSpecificNormalizations(
      String text, String language) {
    switch (language) {
      case 'en':
        return text
            .replaceAll('versiculo:', 'Verse:')
            .replaceAll('reflexion:', 'Reflection:')
            .replaceAll('capitulo:', 'chapter:')
            .replaceAll('para_meditar:', 'To Meditate:')
            .replaceAll('Oracion:', 'Prayer:')
            .replaceAll('vs.', 'verse')
            .replaceAll('vv.', 'verses')
            .replaceAll('ch.', 'chapter')
            .replaceAll('chs.', 'chapters');
      case 'pt':
        return text
            .replaceAll('vs.', 'versículo')
            .replaceAll('vv.', 'versículos')
            .replaceAll('cap.', 'capítulo')
            .replaceAll('caps.', 'capítulos');
      case 'fr':
        return text
            .replaceAll('vs.', 'verset')
            .replaceAll('vv.', 'versets')
            .replaceAll('ch.', 'chapitre')
            .replaceAll('chs.', 'chapitres');
      default: // Spanish
        return text;
    }
  }

  /// Apply language-specific abbreviations
  static String applyAbbreviations(String text, String language) {
    Map<String, String> abbreviations;

    switch (language) {
      case 'en':
        abbreviations = {
          'vs.': 'verse',
          'vv.': 'verses',
          'ch.': 'chapter',
          'chs.': 'chapters',
          'cf.': 'compare',
          'etc.': 'et cetera',
          'e.g.': 'for example',
          'i.e.': 'that is',
          'B.C.': 'before Christ',
          'A.D.': 'anno domini',
          'a.m.': 'in the morning',
          'p.m.': 'in the afternoon',
        };
        break;
      case 'pt':
        abbreviations = {
          'vs.': 'versículo',
          'vv.': 'versículos',
          'cap.': 'capítulo',
          'caps.': 'capítulos',
          'cf.': 'compare',
          'etc.': 'etcétera',
          'p.ex.': 'por exemplo',
          'i.e.': 'isto é',
          'a.C.': 'antes de Cristo',
          'd.C.': 'depois de Cristo',
          'a.m.': 'da manhã',
          'p.m.': 'da tarde',
        };
        break;
      case 'fr':
        abbreviations = {
          'vs.': 'verset',
          'vv.': 'versets',
          'ch.': 'chapitre',
          'chs.': 'chapitres',
          'cf.': 'comparer',
          'etc.': 'et cetera',
          'p.ex.': 'par exemple',
          'i.e.': 'c\'est-à-dire',
          'av. J.-C.': 'avant Jésus-Christ',
          'ap. J.-C.': 'après Jésus-Christ',
          'a.m.': 'du matin',
          'p.m.': 'de l\'après-midi',
        };
        break;
      default: // Spanish
        abbreviations = {
          'vs.': 'versículo',
          'vv.': 'versículos',
          'cap.': 'capítulo',
          'caps.': 'capítulos',
          'cf.': 'compárese',
          'etc.': 'etcétera',
          'p.ej.': 'por ejemplo',
          'i.e.': 'es decir',
          'a.C.': 'antes de Cristo',
          'd.C.': 'después de Cristo',
          'a.m.': 'de la mañana',
          'p.m.': 'de la tarde',
        };
    }

    abbreviations.forEach((abbrev, expansion) {
      if (text.contains(abbrev)) {
        text = text.replaceAll(abbrev, expansion);
      }
    });

    return text;
  }
}
