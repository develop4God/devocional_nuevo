import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app localization and translations.
///
/// This service is registered as a lazy singleton in the Service Locator.
/// Access it via `getService<LocalizationService>()` instead of direct instantiation.
/// The singleton pattern was removed to enable proper dependency injection and testing.
///
/// ## Usage
/// ```dart
/// // Get the service via DI
/// final localizationService = getService<LocalizationService>();
/// await localizationService.initialize();
/// ```
class LocalizationService {
  /// Default constructor for DI registration.
  /// The Service Locator will create and manage the singleton instance.
  LocalizationService();

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('es', ''), // Spanish
    Locale('en', ''), // English
    Locale('pt', ''), // Portuguese
    Locale('fr', ''), // French
    Locale('ja', ''), // Japanese
  ];

  // Default locale
  static const Locale defaultLocale = Locale('es', '');

  // Current locale
  Locale _currentLocale = defaultLocale;

  Locale get currentLocale => _currentLocale;

  // Translation cache - stores loaded translations by language code to avoid
  // repeated JSON parsing on language switches (~300ms savings per switch)
  final Map<String, Map<String, dynamic>> _translationsCache = {};

  // Current translations (reference to cached entry)
  Map<String, dynamic> _translations = {};

  /// Check if translations for a language are cached (for testing)
  @visibleForTesting
  bool isCached(String languageCode) =>
      _translationsCache.containsKey(languageCode);

  /// Initialize the localization service
  Future<void> initialize() async {
    // Try to load saved locale
    final prefs = await SharedPreferences.getInstance();
    final savedLocaleCode = prefs.getString('locale');

    if (savedLocaleCode != null) {
      final savedLocale = Locale(savedLocaleCode);
      if (supportedLocales.contains(savedLocale)) {
        _currentLocale = savedLocale;
      }
    } else {
      // Auto-detect device locale
      _currentLocale = _detectDeviceLocale();
    }

    // Load translations for current locale
    await _loadTranslations(_currentLocale.languageCode);
  }

  /// Detect device locale with fallback to default
  Locale _detectDeviceLocale() {
    final deviceLocale = PlatformDispatcher.instance.locale;

    // Check if device locale is supported
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == deviceLocale.languageCode) {
        return supportedLocale;
      }
    }

    // Fallback to default
    return defaultLocale;
  }

  /// Load translations from JSON file with caching
  Future<void> _loadTranslations(String languageCode) async {
    // Check cache first to avoid repeated JSON parsing
    if (_translationsCache.containsKey(languageCode)) {
      _translations = _translationsCache[languageCode]!;
      developer.log(
        'Loaded translations from cache for: $languageCode',
        name: 'LocalizationService',
      );
      return;
    }

    try {
      final jsonString = await rootBundle.loadString('i18n/$languageCode.json');
      final translations = json.decode(jsonString) as Map<String, dynamic>;
      _translationsCache[languageCode] = translations;
      _translations = translations;
      developer.log(
        'Loaded and cached translations for: $languageCode',
        name: 'LocalizationService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load translations for language: $languageCode',
        name: 'LocalizationService',
        error: e,
        stackTrace: stackTrace,
      );
      // If loading fails, try to load default language
      if (languageCode != defaultLocale.languageCode) {
        try {
          // Check cache for default locale
          if (_translationsCache.containsKey(defaultLocale.languageCode)) {
            _translations = _translationsCache[defaultLocale.languageCode]!;
            developer.log(
              'Using cached default locale fallback: ${defaultLocale.languageCode}',
              name: 'LocalizationService',
            );
            return;
          }

          final jsonString = await rootBundle
              .loadString('i18n/${defaultLocale.languageCode}.json');
          final translations = json.decode(jsonString) as Map<String, dynamic>;
          _translationsCache[defaultLocale.languageCode] = translations;
          _translations = translations;
          developer.log(
            'Loaded default locale fallback: ${defaultLocale.languageCode}',
            name: 'LocalizationService',
          );
        } catch (fallbackError, fallbackStackTrace) {
          developer.log(
            'Failed to load default language fallback: ${defaultLocale.languageCode}',
            name: 'LocalizationService',
            error: fallbackError,
            stackTrace: fallbackStackTrace,
          );
          // If even default fails, use empty map
          _translations = {};
        }
      } else {
        _translations = {};
      }
    }
  }

  /// Change current locale
  Future<void> changeLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) {
      return;
    }

    _currentLocale = locale;

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);

    // Load new translations
    await _loadTranslations(locale.languageCode);
  }

  /// Get translation for given key
  String translate(String key, [Map<String, dynamic>? params]) {
    final keys = key.split('.');
    dynamic value = _translations;

    // Navigate through nested keys
    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        // Return key if translation not found
        return key;
      }
    }

    String result = value?.toString() ?? key;

    // Replace parameters if provided
    if (params != null) {
      params.forEach((param, paramValue) {
        result = result.replaceAll('{$param}', paramValue.toString());
      });
    }

    return result;
  }

  /// Get TTS locale mapping for current language
  String getTtsLocale() {
    switch (_currentLocale.languageCode) {
      case 'es':
        return 'es-ES';
      case 'en':
        return 'en-US';
      case 'pt':
        return 'pt-BR';
      case 'fr':
        return 'fr-FR';
      case 'ja':
        return 'ja-JP';
      default:
        return 'es-ES';
    }
  }

  /// Get language name in native language
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      case 'pt':
        return 'Português';
      case 'fr':
        return 'Français';
      case 'ja':
        return '日本語';
      default:
        return languageCode;
    }
  }

  /// Get localized date format
  DateFormat getLocalizedDateFormat(String languageCode) {
    switch (languageCode) {
      case 'es':
        return DateFormat('EEEE, d ' 'de' ' MMMM', 'es');
      case 'en':
        return DateFormat('EEEE, MMMM d', 'en');
      case 'fr':
        return DateFormat('EEEE d MMMM', 'fr');
      case 'pt':
        return DateFormat('EEEE, d ' 'de' ' MMMM', 'pt');
      case 'ja':
        return DateFormat('y年M月d日 EEEE', 'ja');
      default:
        return DateFormat('EEEE, MMMM d', 'en');
    }
  }
}
