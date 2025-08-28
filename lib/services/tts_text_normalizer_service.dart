import 'tts_localization_service.dart';

/// Service for normalizing text for TTS across multiple languages
class TtsTextNormalizerService {
  static final TtsTextNormalizerService _instance =
      TtsTextNormalizerService._internal();

  factory TtsTextNormalizerService() => _instance;

  TtsTextNormalizerService._internal();

  final TtsLocalizationService _localizationService = TtsLocalizationService();

  /// Main text normalization method that handles all language-specific transformations
  Future<String> normalizeTtsText(String text) async {
    String normalized = text;

    final currentLanguage = await _localizationService.getCurrentLanguage();
    final languageCode = _localizationService.getLanguageCode(currentLanguage);

    // Get language-specific maps
    final bibleVersions =
        _localizationService.getBibleVersionsMap(languageCode);
    final abbreviations =
        _localizationService.getAbbreviationsMap(languageCode);
    final ordinals = _localizationService.getOrdinalsMap(languageCode);

    // Apply Bible version expansions
    bibleVersions.forEach((version, expansion) {
      if (normalized.contains(version)) {
        normalized = normalized.replaceAll(version, expansion);
      }
    });

    // Format Bible book ordinals
    normalized = formatBibleBook(normalized, languageCode);

    // Handle year formatting (currently Spanish-specific, could be expanded)
    normalized = _normalizeYears(normalized, languageCode);

    // Handle Bible references
    normalized = _normalizeBibleReferences(normalized, languageCode);

    // Handle time expressions
    normalized = _normalizeTimeExpressions(normalized, languageCode);

    // Handle ratios and numeric expressions
    normalized = _normalizeNumericExpressions(normalized, languageCode);

    // Apply abbreviation expansions with word boundaries to prevent partial matches
    abbreviations.forEach((abbrev, expansion) {
      // Use word boundaries for abbreviations that could be part of other words
      if (abbrev == 'am' || abbrev == 'pm') {
        // Only match am/pm when they're standalone or with common punctuation
        normalized = normalized.replaceAllMapped(
          RegExp(r'\b' + RegExp.escape(abbrev) + r'\b(?=\s|$|[.,;!?])',
              caseSensitive: false),
          (match) => expansion,
        );
      } else {
        if (normalized.contains(abbrev)) {
          normalized = normalized.replaceAll(abbrev, expansion);
        }
      }
    });

    // Handle ordinal number replacement
    normalized = normalized.replaceAllMapped(
      RegExp(r'(\d+)([º°ª])'),
      (match) {
        final number = int.tryParse(match.group(1)!) ?? 0;
        return ordinals[number] ?? 'número $number';
      },
    );

    // Clean up extra whitespace
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }

  /// Format Bible book references with language-specific ordinals
  String formatBibleBook(String reference, String languageCode) {
    final exp =
        RegExp(r'^([123])\s+([A-Za-záéíóúÁÉÍÓÚñÑ]+)', caseSensitive: false);
    final match = exp.firstMatch(reference.trim());

    if (match != null) {
      final number = match.group(1)!;
      final book = match.group(2)!;

      final bookOrdinals =
          _localizationService.getBookOrdinalsMap(languageCode);
      final ordinal = bookOrdinals[number] ?? '';

      if (ordinal.isNotEmpty) {
        return reference.replaceFirst(exp, '$ordinal $book');
      }
    }
    return reference;
  }

  /// Normalize year expressions (currently Spanish-focused, can be expanded)
  String _normalizeYears(String text, String languageCode) {
    // For now, keeping the Spanish year logic as it's complex
    // This could be expanded for other languages in the future
    if (languageCode != 'es') {
      return text; // Skip year normalization for non-Spanish languages
    }

    return text.replaceAllMapped(
      RegExp(r'\b(19\d{2}|20\d{2})\b'),
      (match) {
        final year = match.group(1)!;
        final yearInt = int.parse(year);
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
          result = year;
        }

        return result;
      },
    );
  }

  /// Normalize Bible reference patterns
  String _normalizeBibleReferences(String text, String languageCode) {
    // Get language-specific words for biblical references
    Map<String, String> bibleWords = _getBibleReferenceWords(languageCode);

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

        String result =
            '$book ${bibleWords['chapter']} $chapter ${bibleWords['verse']} $verseStart';

        if (verseEnd != null) {
          result += ' ${bibleWords['to']} $verseEnd';
        }
        if (secondVerse != null) {
          result += ' ${bibleWords['verse']} $secondVerse';
        }

        return result;
      },
    );
  }

  /// Get language-specific words for Bible references
  Map<String, String> _getBibleReferenceWords(String languageCode) {
    switch (languageCode) {
      case 'en':
        return {
          'chapter': 'chapter',
          'verse': 'verse',
          'to': 'to',
        };
      case 'fr':
        return {
          'chapter': 'chapitre',
          'verse': 'verset',
          'to': 'à',
        };
      case 'pt':
        return {
          'chapter': 'capítulo',
          'verse': 'versículo',
          'to': 'ao',
        };
      case 'es':
      default:
        return {
          'chapter': 'capítulo',
          'verse': 'versículo',
          'to': 'al',
        };
    }
  }

  /// Normalize time expressions
  String _normalizeTimeExpressions(String text, String languageCode) {
    // For now, keeping Spanish time logic as it's complex
    // This could be expanded for other languages in the future
    if (languageCode != 'es') {
      return text; // Skip time normalization for non-Spanish languages
    }

    return text.replaceAllMapped(
      RegExp(
          r'\b(\d{1,2}):(\d{2})\s*(am|pm|a\.m\.|p\.m\.|de la mañana|de la tarde|de la noche)\b',
          caseSensitive: false),
      (match) {
        final hour = match.group(1)!;
        final minute = match.group(2)!;
        final period = match.group(3)!;

        String result;
        if (minute == '00') {
          result = '$hour en punto $period';
        } else {
          result = '$hour y $minute $period';
        }

        return result;
      },
    );
  }

  /// Normalize numeric expressions and ratios
  String _normalizeNumericExpressions(String text, String languageCode) {
    // Get language-specific connector word
    String connector = _getNumericConnector(languageCode);

    return text.replaceAllMapped(
      RegExp(
          r'\b(\d+):(\d+)\b(?!\s*(am|pm|a\.m\.|p\.m\.|de la|capítulo|versículo|chapter|verse|chapitre|verset))'),
      (match) {
        final first = match.group(1)!;
        final second = match.group(2)!;
        return '$first $connector $second';
      },
    );
  }

  /// Get language-specific numeric connector (e.g., "to", "a", "à")
  String _getNumericConnector(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'to';
      case 'fr':
        return 'à';
      case 'pt':
        return 'a';
      case 'es':
      default:
        return 'a';
    }
  }
}
