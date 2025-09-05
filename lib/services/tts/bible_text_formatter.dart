import 'package:flutter/foundation.dart';

/// Bible text formatting utilities for TTS
/// Handles ordinal formatting and Bible version expansions across multiple languages
class BibleTextFormatter {
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
      default:
        debugPrint(
            '[BibleTextFormatter] Idioma desconocido "$language", usando español por defecto');
        return _formatBibleBookSpanish(reference);
    }
  }

  /// Formats Spanish Bible book ordinals (Primera de, Segunda de, Tercera de)
  static String _formatBibleBookSpanish(String reference) {
    final exp =
        RegExp(r'^([123])\s+([A-Za-záéíóúÁÉÍÓÚñÑ]+)', caseSensitive: false);
    final match = exp.firstMatch(reference.trim());
    if (match != null) {
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
      return reference.replaceFirst(exp, '$ordinal $book');
    }
    return reference;
  }

  /// Formats English Bible book ordinals (First, Second, Third)
  static String _formatBibleBookEnglish(String reference) {
    final exp = RegExp(r'^([123])\s+([A-Za-z]+)', caseSensitive: false);
    final match = exp.firstMatch(reference.trim());
    if (match != null) {
      final number = match.group(1)!;
      final bookName = match.group(2)!;

      final ordinals = {'1': 'First', '2': 'Second', '3': 'Third'};
      final ordinal = ordinals[number] ?? number;

      return reference.replaceFirst(
        RegExp('^$number\\s+$bookName', caseSensitive: false),
        '$ordinal $bookName',
      );
    }
    return reference;
  }

  /// Formats Portuguese Bible book ordinals (Primeiro, Segundo, Terceiro)
  static String _formatBibleBookPortuguese(String reference) {
    final exp = RegExp(r'^([123])\s+([A-Za-z]+)', caseSensitive: false);
    final match = exp.firstMatch(reference.trim());
    if (match != null) {
      final number = match.group(1)!;
      final bookName = match.group(2)!;

      final ordinals = {'1': 'Primeiro', '2': 'Segundo', '3': 'Terceiro'};
      final ordinal = ordinals[number] ?? number;

      return reference.replaceFirst(
        RegExp('^$number\\s+$bookName', caseSensitive: false),
        '$ordinal $bookName',
      );
    }
    return reference;
  }

  /// Formats French Bible book ordinals (Premier, Deuxième, Troisième)
  static String _formatBibleBookFrench(String reference) {
    final exp = RegExp(r'^([123])\s+([A-Za-z]+)', caseSensitive: false);
    final match = exp.firstMatch(reference.trim());
    if (match != null) {
      final number = match.group(1)!;
      final bookName = match.group(2)!;

      final ordinals = {'1': 'Premier', '2': 'Deuxième', '3': 'Troisième'};
      final ordinal = ordinals[number] ?? number;

      return reference.replaceFirst(
        RegExp('^$number\\s+$bookName', caseSensitive: false),
        '$ordinal $bookName',
      );
    }
    return reference;
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
}
