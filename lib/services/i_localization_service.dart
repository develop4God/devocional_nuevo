import 'dart:ui';

/// Minimal interface for localization service used by other services.
abstract class ILocalizationService {
  /// Currently selected locale
  Locale get currentLocale;

  /// Change the current locale
  Future<void> changeLocale(Locale locale);
}
