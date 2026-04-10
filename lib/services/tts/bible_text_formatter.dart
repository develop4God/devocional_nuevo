import 'package:flutter/foundation.dart';
import 'package:devocional_nuevo/services/tts/hindi_tts_normalizer.dart';

/// Bible text formatting utilities for TTS
/// Handles ordinal formatting and Bible version expansions across multiple languages
class BibleTextFormatter {
  /// Helper to check if a match starts with whitespace
  static bool _startsWithWhitespace(String text) {
    return text.isNotEmpty && text[0].trim().isEmpty;
  }

  /// Remove problematic control characters and Unicode replacement chars
  /// This helps tests and TTS normalization when source strings include
  /// malformed bytes or invisible control characters (e.g. U+FFFD).
  static String _sanitizeInput(String input) {
    if (input.isEmpty) return input;
    // Remove Unicode replacement character U+FFFD which appears when decoding
    // with wrong encoding or malformed bytes.
    String out = input.replaceAll('\uFFFD', '');

    // Remove C0 control characters except common whitespace (tab/newline/carriage)
    out = out.replaceAll(RegExp(r"[\x00-\x08\x0B\x0C\x0E-\x1F]"), '');

    // Also trim and normalize multiple whitespace to single spaces for stable matching
    out = out.replaceAll(RegExp(r"\s+"), ' ').trim();
    return out;
  }

  /// Formats Bible book names with ordinals based on the specified language
  static String formatBibleBook(String reference, String language) {
    final maxLogLength = 80;
    final logText = reference.length > maxLogLength
        ? '${reference.substring(0, maxLogLength)}...'
        : reference;
    debugPrint(
      '[BibleTextFormatter] formatBibleBook called with reference="$logText", language="$language"',
    );
    switch (language) {
      case 'es':
        return _formatBibleBookSpanish(reference);
      case 'en':
        return _formatBibleBookEnglish(reference);
      case 'pt':
        return _formatBibleBookPortuguese(reference);
      case 'fr':
        return _formatBibleBookFrench(reference);
      case 'de':
        return _formatBibleBookGerman(reference);
      case 'ja':
        return _formatBibleBookJapanese(reference);
      case 'zh':
        return _formatBibleBookChinese(reference);
      case 'hi':
        return _formatBibleBookHindi(reference);
      case 'ar':
        return _formatBibleBookArabic(reference);
      default:
        debugPrint(
          '[BibleTextFormatter] Unknown language "$language", using Spanish as default',
        );
        return _formatBibleBookSpanish(reference);
    }
  }

  /// Formats Spanish Bible book ordinals (Primera de, Segunda de, Tercera de)
  /// Now uses replaceAllMapped to work anywhere in text, not just at beginning
  static String _formatBibleBookSpanish(String reference) {
    // Use word boundary (\b) or start of string to match Bible book references anywhere
    final exp = RegExp(
      r'(?:^|\s)([123])\s+([A-Za-záéíóúÁÉÍÓÚñÑ]+)',
      caseSensitive: false,
    );

    return reference.replaceAllMapped(exp, (match) {
      final matchText = match.group(0) ?? '';
      final prefix = _startsWithWhitespace(matchText) ? ' ' : '';
      final number = match.group(1) ?? '';
      final book = match.group(2) ?? '';
      String ordinal;
      switch (number) {
        case '1':
          ordinal = 'Primera de';
          break;
        case '2':
          ordinal = 'Segunda de';
          break;
        case '3':
          ordinal = 'Tercera de';
          break;
        default:
          ordinal = '';
      }
      return '$prefix$ordinal $book';
    });
  }

  /// Formats English Bible book ordinals (First, Second, Third)
  /// Now uses replaceAllMapped to work anywhere in text, not just at beginning
  static String _formatBibleBookEnglish(String reference) {
    final exp = RegExp(r'(?:^|\s)([123])\s+([A-Za-z]+)', caseSensitive: false);
    final ordinals = {'1': 'First', '2': 'Second', '3': 'Third'};

    return reference.replaceAllMapped(exp, (match) {
      final matchText = match.group(0) ?? '';
      final prefix = _startsWithWhitespace(matchText) ? ' ' : '';
      final number = match.group(1) ?? '';
      final bookName = match.group(2) ?? '';
      final ordinal = ordinals[number] ?? number;
      return '$prefix$ordinal $bookName';
    });
  }

  /// Formats Portuguese Bible book ordinals (Primeiro, Segundo, Terceiro)
  /// Now uses replaceAllMapped to work anywhere in text, not just at beginning
  static String _formatBibleBookPortuguese(String reference) {
    final exp = RegExp(
      r'(?:^|\s)([123])\s+([A-Za-záéíóúâêîôûãõç]+)',
      caseSensitive: false,
    );
    final ordinals = {'1': 'Primeiro', '2': 'Segundo', '3': 'Terceiro'};

    return reference.replaceAllMapped(exp, (match) {
      final matchText = match.group(0) ?? '';
      final prefix = _startsWithWhitespace(matchText) ? ' ' : '';
      final number = match.group(1) ?? '';
      final bookName = match.group(2) ?? '';
      final ordinal = ordinals[number] ?? number;
      return '$prefix$ordinal $bookName';
    });
  }

  /// Formats French Bible book ordinals (Premier, Deuxième, Troisième)
  /// Now uses replaceAllMapped to work anywhere in text, not just at beginning
  static String _formatBibleBookFrench(String reference) {
    final exp = RegExp(
      r'(?:^|\s)([123])\s+([A-Za-zéèêëàâäùûüôîïç]+)',
      caseSensitive: false,
    );
    final ordinals = {'1': 'Premier', '2': 'Deuxième', '3': 'Troisième'};

    return reference.replaceAllMapped(exp, (match) {
      final matchText = match.group(0) ?? '';
      final prefix = _startsWithWhitespace(matchText) ? ' ' : '';
      final number = match.group(1) ?? '';
      final bookName = match.group(2) ?? '';
      final ordinal = ordinals[number] ?? number;
      return '$prefix$ordinal $bookName';
    });
  }

  /// Formats German Bible book ordinals (Erster, Zweiter, Dritter)
  /// Now uses replaceAllMapped to work anywhere in text, not just at beginning
  static String _formatBibleBookGerman(String reference) {
    final exp = RegExp(
      r'(?:^|\s)([123])\s+([A-Za-zäöüßÄÖÜ]+)',
      caseSensitive: false,
    );
    final ordinals = {'1': 'Erster', '2': 'Zweiter', '3': 'Dritter'};

    return reference.replaceAllMapped(exp, (match) {
      final matchText = match.group(0) ?? '';
      final prefix = _startsWithWhitespace(matchText) ? ' ' : '';
      final number = match.group(1) ?? '';
      final bookName = match.group(2) ?? '';
      final ordinal = ordinals[number] ?? number;
      return '$prefix$ordinal $bookName';
    });
  }

  /// Formato para libros bíblicos en japonés (sin ordinales, solo limpieza básica)
  static String _formatBibleBookJapanese(String reference) {
    // En japonés, los libros bíblicos no usan ordinales, solo se devuelve el texto tal cual
    return reference.trim();
  }

  /// Formato para libros bíblicos en chino (sin ordinales, solo limpieza básica)
  static String _formatBibleBookChinese(String reference) {
    // En chino, los libros bíblicos no usan ordinales, solo se devuelve el texto tal cual
    return reference.trim();
  }

  /// Formato para libros bíblicos en hindi (con ordinales para 1, 2, 3)
  static String _formatBibleBookHindi(String reference) {
    // Hindi uses ordinales for numbered books (1 Juan -> पहला यूहन्ना)
    // Pattern to match numbered books in Hindi text
    final exp = RegExp(
      r'(^|\s)([123])\s+([\u0900-\u097F]+)',
      caseSensitive: false,
    );
    final ordinals = {
      '1': 'पहला', // First (pahlā)
      '2': 'दूसरा', // Second (dūsrā)
      '3': 'तीसरा', // Third (tīsrā)
    };

    return reference.replaceAllMapped(exp, (match) {
      final separator = match.group(1) ?? '';
      final number = match.group(2) ?? '';
      final bookName = match.group(3) ?? '';
      final ordinal = ordinals[number] ?? number;
      return '$separator$ordinal $bookName';
    });
  }

  /// Formato para libros bíblicos en árabe (con ordinales para 1, 2, 3)
  static String _formatBibleBookArabic(String reference) {
    // Arabic uses ordinals for numbered books (1 يوحنا -> الأول يوحنا)
    // Pattern to match digit + Arabic book name (Unicode range \u0600-\u06FF)
    final exp = RegExp(
      r'(^|\s)([123])\s+([\u0600-\u06FF]+)',
      caseSensitive: false,
    );
    final ordinals = {
      '1': 'الأول', // First (al-awwal)
      '2': 'الثاني', // Second (al-thānī)
      '3': 'الثالث', // Third (al-thālith)
    };

    return reference.replaceAllMapped(exp, (match) {
      final separator = match.group(1) ?? '';
      final number = match.group(2) ?? '';
      final bookName = match.group(3) ?? '';
      final ordinal = ordinals[number] ?? number;
      return '$separator$ordinal $bookName';
    });
  }

  /// Get Bible version expansions based on language
  static Map<String, String> getBibleVersionExpansions(String language) {
    switch (language) {
      case 'es':
        return {
          'RVR1960': 'Reina Valera mil novecientos sesenta',
          'NVI': 'Nueva Versión Internacional',
        };
      case 'en':
        return {
          'KJV': 'King James Version',
          'NIV': 'New International Version',
        };
      case 'pt':
        return {
          'ARC': 'Almeida Revista e Corrigida',
          'NVI': 'Nova Versão Internacional',
        };
      case 'fr':
        return {
          'LSG1910': 'Louis Segond mille neuf cent dix',
          'TOB': 'Traduction Oecuménique de la Bible',
        };
      case 'de':
        return {
          'LU17': 'Lutherbibel zweitausendsiebzehn',
          'SCH2000': 'Schlachter zweitausend',
        };
      case 'zh':
        return {'和合本1919': '和合本一九一九', '新译本': '新译本'};
      case 'hi':
        return {
          // Full Devanagari names (from database)
          'पवित्र बाइबिल (ओ.वी.)': 'पवित्र बाइबिल पुराना संस्करण',
          'पवित्र बाइबिल': 'पवित्र बाइबिल हिंदी आसान पठन संस्करण',
          // Abbreviations (for constants usage)
          'HIOV': 'पवित्र बाइबिल पुराना संस्करण',
          'HERV': 'पवित्र बाइबिल हिंदी आसान पठन संस्करण',
          'OV': 'पुराना संस्करण',
        };
      case 'ar':
        return {
          'NAV': 'كتاب الحياة',
          'SVDA': 'الكتاب المقدس — فان دايك',
        };
      default:
        return {'RVR1960': 'Reina Valera mil novecientos sesenta'};
    }
  }

  /// Normaliza y arma el texto para TTS (capítulo, versículo, ordinales, versión bíblica)
  static String normalizeTtsText(
    String text,
    String language, [
    String? version,
  ]) {
    // Sanitize early to remove any malformed or invisible characters that
    // could break subsequent regex-based formatting.
    String normalized = _sanitizeInput(text);
    // 0. Hindi-specific pre-processing (SRP: delegated to HindiTtsNormalizer)
    if (language == 'hi') {
      normalized = HindiTtsNormalizer.preProcess(normalized);
    }
    // 1. Formatear libros bíblicos PRIMERO (con RegExp corregido)
    normalized = formatBibleBook(normalized, language);
    // 2. Expandir versiones bíblicas
    final bibleVersions = getBibleVersionExpansions(language);
    bibleVersions.forEach((versionKey, expansion) {
      if (normalized.contains(versionKey)) {
        normalized = normalized.replaceAll(versionKey, expansion);
      }
    });
    // 3. Formatear referencias bíblicas básicas (capítulo:versículo)
    normalized = formatBibleReferences(normalized, language);
    // Clean up whitespace
    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Formatea referencias bíblicas básicas (capítulo:versículo)
  static String formatBibleReferences(String text, String language) {
    final Map<String, String> referenceWords = {
      'es': 'capítulo|versículo',
      'en': 'chapter|verse',
      'pt': 'capítulo|versículo',
      'fr': 'chapitre|verset',
      'de': 'Kapitel|Vers',
      'ja': '章|節',
      // Japonés: capítulo=章, versículo=節
      'zh': '章|节',
      // Chino: capítulo=章, versículo=节
      'hi': 'अध्याय|पद',
      // Hindi: capítulo=अध्याय (adhyāya), versículo=पद (pada)
      'ar': 'الإصحاح|الآية',
      // Arabic: capítulo=الإصحاح (chapter), versículo=الآية (verse)
    };

    final words = referenceWords[language] ?? 'capítulo|versículo';
    final chapterWord = words.split('|')[0];
    final verseWord = words.split('|')[1];

    // Different regex pattern for CJK languages (Chinese, Japanese, Korean)
    // to avoid word boundary issues with non-ASCII characters
    final isCJK = language == 'zh' || language == 'ja';
    final isDevanagari = language == 'hi';
    final isArabic = language == 'ar';
    final pattern = isCJK
        ? RegExp(
            r'((?:\d+\s+)?[一-龯ぁ-んァ-ン]+)\s+(\d+):(\d+)(?:-(\d+))?',
            caseSensitive: false,
          )
        : isDevanagari
            ? RegExp(
                r'((?:पहला|दूसरा|तीसरा)?\s*[\u0900-\u097F]+)\s+(\d+):(\d+)(?:-(\d+))?',
                caseSensitive: false,
              )
            : isArabic
                ? RegExp(
                    r'((?:الأول|الثاني|الثالث)?\s*[\u0600-\u06FF]+)\s+(\d+):(\d+)(?:-(\d+))?',
                    caseSensitive: false,
                  )
                : RegExp(
                    r'(\b(?:\d+\s+)?[A-Za-záéíóúÁÉÍÓÚñÑäöüßÄÖÜ]+)\s+(\d+):(\d+)(?:-(\d+))?',
                    caseSensitive: false,
                  );

    return text.replaceAllMapped(pattern, (match) {
      final book = match.group(1) ?? '';
      final chapter = match.group(2) ?? '';
      final verseStart = match.group(3) ?? '';
      final verseEnd = match.group(4);

      String result = '$book $chapterWord $chapter $verseWord $verseStart';
      if (verseEnd != null) {
        final toWord = language == 'en'
            ? 'to'
            : language == 'pt'
                ? 'ao'
                : language == 'fr'
                    ? 'au'
                    : language == 'de'
                        ? 'bis'
                        : language == 'ja'
                            ? '～'
                            : language == 'zh'
                                ? '至'
                                : language == 'hi'
                                    ? 'से'
                                    : language == 'ar'
                                        ? 'إلى'
                                        : 'al';
        result += ' $toWord $verseEnd';
      }
      return result;
    });
  }
}
