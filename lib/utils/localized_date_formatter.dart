import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Utility for creating locale-aware date formatters.
///
/// Provides consistent date formatting across the app based on the
/// user's locale. Follows Single Responsibility Principle.
class LocalizedDateFormatter {
  const LocalizedDateFormatter._();

  /// Returns a [DateFormat] appropriate for the given locale.
  ///
  /// Supports: es, en, fr, pt, ja, zh. Defaults to English format.
  static DateFormat getDateFormat(String languageCode) {
    switch (languageCode) {
      case 'es':
        return DateFormat("EEEE, d 'de' MMMM", 'es');
      case 'en':
        return DateFormat('EEEE, MMMM d', 'en');
      case 'fr':
        return DateFormat('EEEE d MMMM', 'fr');
      case 'pt':
        return DateFormat("EEEE, d 'de' MMMM", 'pt');
      case 'ja':
        return DateFormat('y年M月d日 EEEE', 'ja');
      case 'zh':
        return DateFormat('y年M月d日 EEEE', 'zh');
      default:
        return DateFormat('EEEE, MMMM d', 'en');
    }
  }

  /// Convenience method: format [dateTime] using the locale from [context].
  static String formatForContext(BuildContext context, {DateTime? dateTime}) {
    final locale = Localizations.localeOf(context).languageCode;
    return getDateFormat(locale).format(dateTime ?? DateTime.now());
  }
}
