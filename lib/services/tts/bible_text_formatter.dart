/// Bible text formatting utilities for TTS
/// Handles ordinal formatting and Bible version expansions across multiple languages
class BibleTextFormatter {
  /// Formats Bible book names with ordinals based on the specified language
  static String formatBibleBook(String reference, String language) {
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
          'RVR60': 'Reina Valera sesenta',
          'RVR1995': 'Reina Valera mil novecientos noventa y cinco',
          'RVR09': 'Reina Valera dos mil nueve',
          'NVI': 'Nueva Versión Internacional',
          'DHH': 'Dios Habla Hoy',
          'TLA': 'Traducción en Lenguaje Actual',
          'NTV': 'Nueva Traducción Viviente',
          'PDT': 'Palabra de Dios para Todos',
          'BLP': 'Biblia La Palabra',
          'CST': 'Castilian',
          'LBLA': 'La Biblia de las Américas',
          'NBLH': 'Nueva Biblia Latinoamericana de Hoy',
          'RVC': 'Reina Valera Contemporánea',
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
          'LSG1910': 'Louis Segond mil nove cento e dez',
          'LSG': 'Louis Segond',
          'TOB': 'Traduction Oecuménique de la Bible',
        };
      default:
        return {
          'RVR1960': 'Reina Valera mil novecientos sesenta',
        };
    }
  }
}
