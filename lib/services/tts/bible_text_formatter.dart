import 'package:flutter/foundation.dart';

/// Bible text formatting utilities for TTS
/// Handles ordinal formatting and Bible version expansions across multiple languages
class BibleTextFormatter {
  /// Helper to check if a match starts with whitespace
  static bool _startsWithWhitespace(String text) {
    return text.isNotEmpty && text[0].trim().isEmpty;
  }
  
  /// Formats Bible book names with ordinals based on the specified language
  static String formatBibleBook(String reference, String language) {
    debugPrint(
        '[BibleTextFormatter] formatBibleBook called with reference="$reference", language="$language"');
    switch (language) {
      case 'es':
        return _formatBibleBookSpanish(reference);
      case 'en':
        return _formatBibleBookEnglish(reference);
      case 'pt':
        return _formatBibleBookPortuguese(reference);
      case 'fr':
        return _formatBibleBookFrench(reference);
      case 'ja':
        return _formatBibleBookJapanese(reference);
      default:
        debugPrint(
            '[BibleTextFormatter] Unknown language "$language", using Spanish as default');
        return _formatBibleBookSpanish(reference);
    }
  }

  /// Formats Spanish Bible book ordinals (Primera de, Segunda de, Tercera de)
  /// Now uses replaceAllMapped to work anywhere in text, not just at beginning
  static String _formatBibleBookSpanish(String reference) {
    // Use word boundary (\b) or start of string to match Bible book references anywhere
    final exp =
        RegExp(r'(?:^|\s)([123])\s+([A-Za-záéíóúÁÉÍÓÚñÑ]+)', caseSensitive: false);
    
    return reference.replaceAllMapped(exp, (match) {
      final matchText = match.group(0)!;
      final prefix = _startsWithWhitespace(matchText) ? ' ' : '';
      final number = match.group(1)!;
      final book = match.group(2)!;
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
      final matchText = match.group(0)!;
      final prefix = _startsWithWhitespace(matchText) ? ' ' : '';
      final number = match.group(1)!;
      final bookName = match.group(2)!;
      final ordinal = ordinals[number] ?? number;
      return '$prefix$ordinal $bookName';
    });
  }

  /// Formats Portuguese Bible book ordinals (Primeiro, Segundo, Terceiro)
  /// Now uses replaceAllMapped to work anywhere in text, not just at beginning
  static String _formatBibleBookPortuguese(String reference) {
    final exp = RegExp(r'(?:^|\s)([123])\s+([A-Za-záéíóúâêîôûãõç]+)', caseSensitive: false);
    final ordinals = {'1': 'Primeiro', '2': 'Segundo', '3': 'Terceiro'};
    
    return reference.replaceAllMapped(exp, (match) {
      final matchText = match.group(0)!;
      final prefix = _startsWithWhitespace(matchText) ? ' ' : '';
      final number = match.group(1)!;
      final bookName = match.group(2)!;
      final ordinal = ordinals[number] ?? number;
      return '$prefix$ordinal $bookName';
    });
  }

  /// Formats French Bible book ordinals (Premier, Deuxième, Troisième)
  /// Now uses replaceAllMapped to work anywhere in text, not just at beginning
  static String _formatBibleBookFrench(String reference) {
    final exp = RegExp(r'(?:^|\s)([123])\s+([A-Za-zéèêëàâäùûüôîïç]+)', caseSensitive: false);
    final ordinals = {'1': 'Premier', '2': 'Deuxième', '3': 'Troisième'};
    
    return reference.replaceAllMapped(exp, (match) {
      final matchText = match.group(0)!;
      final prefix = _startsWithWhitespace(matchText) ? ' ' : '';
      final number = match.group(1)!;
      final bookName = match.group(2)!;
      final ordinal = ordinals[number] ?? number;
      return '$prefix$ordinal $bookName';
    });
  }

  /// Formato para libros bíblicos en japonés (sin ordinales, solo limpieza básica)
  static String _formatBibleBookJapanese(String reference) {
    // En japonés, los libros bíblicos no usan ordinales, solo se devuelve el texto tal cual
    return reference.trim();
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
      default:
        return {
          'RVR1960': 'Reina Valera mil novecientos sesenta',
        };
    }
  }

  /// Normaliza y arma el texto para TTS (capítulo, versículo, ordinales, versión bíblica)
  static String normalizeTtsText(String text, String language,
      [String? version]) {
    String normalized = text;
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
      'ja': '章|節', // Japonés: capítulo=章, versículo=節
    };

    final words = referenceWords[language] ?? referenceWords['es']!;
    final chapterWord = words.split('|')[0];
    final verseWord = words.split('|')[1];

    return text.replaceAllMapped(
      RegExp(
          r'(\b(?:\d+\s+)?[A-Za-záéíóúÁÉÍÓÚñÑ一-龯ぁ-んァ-ン]+)\s+(\d+):(\d+)(?:-(\d+))?',
          caseSensitive: false),
      (match) {
        final book = match.group(1)!;
        final chapter = match.group(2)!;
        final verseStart = match.group(3)!;
        final verseEnd = match.group(4);

        String result = '$book $chapterWord $chapter $verseWord $verseStart';
        if (verseEnd != null) {
          final toWord = language == 'en'
              ? 'to'
              : language == 'pt'
                  ? 'ao'
                  : language == 'fr'
                      ? 'au'
                      : language == 'ja'
                          ? '～'
                          : 'al';
          result += ' $toWord $verseEnd';
        }
        return result;
      },
    );
  }
}
