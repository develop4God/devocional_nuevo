/// Specialized text normalization utilities for TTS
/// Handles years, times, Bible references, and other complex formatting
class SpecializedTextNormalizer {
  /// Format years with language-specific number words
  static String formatYears(String text, String language) {
    return text.replaceAllMapped(
      RegExp(r'\b(19\d{2}|20\d{2})\b'),
      (match) {
        final year = match.group(1)!;
        final yearInt = int.parse(year);

        switch (language) {
          case 'en':
            return _formatYearEnglish(yearInt);
          case 'pt':
            return _formatYearPortuguese(yearInt);
          case 'fr':
            return _formatYearFrench(yearInt);
          default: // Spanish
            return _formatYearSpanish(yearInt);
        }
      },
    );
  }

  /// Format years in Spanish
  static String _formatYearSpanish(int yearInt) {
    String result;
    if (yearInt >= 1900 && yearInt < 2000) {
      final lastTwo = yearInt - 1900;
      if (lastTwo < 10) {
        result = 'mil novecientos cero $lastTwo';
      } else {
        result = 'mil novecientos $lastTwo';
      }
    } else if (yearInt >= 2000 && yearInt < 2100) {
      final lastTwo = yearInt - 2000;
      if (lastTwo == 0) {
        result = 'dos mil';
      } else if (lastTwo < 10) {
        result = 'dos mil $lastTwo';
      } else {
        result = 'dos mil $lastTwo';
      }
    } else {
      result = yearInt.toString();
    }
    return result;
  }

  /// Format years in English
  static String _formatYearEnglish(int yearInt) {
    String result;
    if (yearInt >= 1900 && yearInt < 2000) {
      final lastTwo = yearInt - 1900;
      if (lastTwo < 10) {
        result = 'nineteen oh $lastTwo';
      } else {
        result = 'nineteen $lastTwo';
      }
    } else if (yearInt >= 2000 && yearInt < 2100) {
      final lastTwo = yearInt - 2000;
      if (lastTwo == 0) {
        result = 'two thousand';
      } else if (lastTwo < 10) {
        result = 'two thousand $lastTwo';
      } else {
        result = 'two thousand $lastTwo';
      }
    } else {
      result = yearInt.toString();
    }
    return result;
  }

  /// Format years in Portuguese
  static String _formatYearPortuguese(int yearInt) {
    String result;
    if (yearInt >= 1900 && yearInt < 2000) {
      final lastTwo = yearInt - 1900;
      if (lastTwo < 10) {
        result = 'mil novecentos e zero $lastTwo';
      } else {
        result = 'mil novecentos e $lastTwo';
      }
    } else if (yearInt >= 2000 && yearInt < 2100) {
      final lastTwo = yearInt - 2000;
      if (lastTwo == 0) {
        result = 'dois mil';
      } else if (lastTwo < 10) {
        result = 'dois mil e $lastTwo';
      } else {
        result = 'dois mil e $lastTwo';
      }
    } else {
      result = yearInt.toString();
    }
    return result;
  }

  /// Format years in French
  static String _formatYearFrench(int yearInt) {
    String result;
    if (yearInt >= 1900 && yearInt < 2000) {
      final lastTwo = yearInt - 1900;
      if (lastTwo < 10) {
        result = 'mille neuf cent zéro $lastTwo';
      } else {
        result = 'mille neuf cent $lastTwo';
      }
    } else if (yearInt >= 2000 && yearInt < 2100) {
      final lastTwo = yearInt - 2000;
      if (lastTwo == 0) {
        result = 'deux mille';
      } else if (lastTwo < 10) {
        result = 'deux mille $lastTwo';
      } else {
        result = 'deux mille $lastTwo';
      }
    } else {
      result = yearInt.toString();
    }
    return result;
  }

  /// Format Bible references with language-specific terms
  static String formatBibleReferences(String text, String language) {
    return text.replaceAllMapped(
      RegExp(
          r'(\b(?:\d+\s+)?[A-Za-záéíóúÁÉÍÓÚñÑ]+)\s+(\d+):(\d+)(?:-(\d+))?(?::(\d+))?',
          caseSensitive: false),
      (match) {
        final book = match.group(1)!;
        final chapter = match.group(2)!;
        final verseStart = match.group(3)!;
        final verseEnd = match.group(4);
        final secondVerse = match.group(5);

        switch (language) {
          case 'en':
            return _formatBibleReferenceEnglish(
                book, chapter, verseStart, verseEnd, secondVerse);
          case 'pt':
            return _formatBibleReferencePortuguese(
                book, chapter, verseStart, verseEnd, secondVerse);
          case 'fr':
            return _formatBibleReferenceFrench(
                book, chapter, verseStart, verseEnd, secondVerse);
          default: // Spanish
            return _formatBibleReferenceSpanish(
                book, chapter, verseStart, verseEnd, secondVerse);
        }
      },
    );
  }

  /// Format Bible reference in Spanish
  static String _formatBibleReferenceSpanish(String book, String chapter,
      String verseStart, String? verseEnd, String? secondVerse) {
    String result = '$book capítulo $chapter versículo $verseStart';
    if (verseEnd != null) {
      result += ' al $verseEnd';
    }
    if (secondVerse != null) {
      result += ' versículo $secondVerse';
    }
    return result;
  }

  /// Format Bible reference in English
  static String _formatBibleReferenceEnglish(String book, String chapter,
      String verseStart, String? verseEnd, String? secondVerse) {
    String result = '$book chapter $chapter verse $verseStart';
    if (verseEnd != null) {
      result += ' to $verseEnd';
    }
    if (secondVerse != null) {
      result += ' verse $secondVerse';
    }
    return result;
  }

  /// Format Bible reference in Portuguese
  static String _formatBibleReferencePortuguese(String book, String chapter,
      String verseStart, String? verseEnd, String? secondVerse) {
    String result = '$book capítulo $chapter versículo $verseStart';
    if (verseEnd != null) {
      result += ' ao $verseEnd';
    }
    if (secondVerse != null) {
      result += ' versículo $secondVerse';
    }
    return result;
  }

  /// Format Bible reference in French
  static String _formatBibleReferenceFrench(String book, String chapter,
      String verseStart, String? verseEnd, String? secondVerse) {
    String result = '$book chapitre $chapter verset $verseStart';
    if (verseEnd != null) {
      result += ' au $verseEnd';
    }
    if (secondVerse != null) {
      result += ' verset $secondVerse';
    }
    return result;
  }

  /// Format times and ratios
  static String formatTimesAndRatios(String text, String language) {
    // Format time expressions
    text = text.replaceAllMapped(
      RegExp(
          r'\b(\d{1,2}):(\d{2})\s*(am|pm|a\.m\.|p\.m\.|de la mañana|de la tarde|de la noche)\b',
          caseSensitive: false),
      (match) {
        final hour = match.group(1)!;
        final minute = match.group(2)!;
        final period = match.group(3)!;

        switch (language) {
          case 'en':
            if (minute == '00') {
              return '$hour o\'clock $period';
            } else {
              return '$hour $minute $period';
            }
          case 'pt':
            if (minute == '00') {
              return '$hour em ponto $period';
            } else {
              return '$hour e $minute $period';
            }
          case 'fr':
            if (minute == '00') {
              return '$hour heures $period';
            } else {
              return '$hour heures $minute $period';
            }
          default: // Spanish
            if (minute == '00') {
              return '$hour en punto $period';
            } else {
              return '$hour y $minute $period';
            }
        }
      },
    );

    // Format ratios (excluding times and Bible references)
    text = text.replaceAllMapped(
      RegExp(
          r'\b(\d+):(\d+)\b(?!\s*(am|pm|a\.m\.|p\.m\.|de la|capítulo|versículo))'),
      (match) {
        final first = match.group(1)!;
        final second = match.group(2)!;

        switch (language) {
          case 'en':
            return '$first to $second';
          case 'pt':
            return '$first para $second';
          case 'fr':
            return '$first à $second';
          default: // Spanish
            return '$first a $second';
        }
      },
    );

    return text;
  }
}
