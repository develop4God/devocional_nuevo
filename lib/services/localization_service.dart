import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app localization and translations
class LocalizationService {
  static LocalizationService? _instance;

  static LocalizationService get instance =>
      _instance ??= LocalizationService._();

  LocalizationService._();

  /// Reset instance for testing purposes
  static void resetInstance() {
    _instance = null;
  }

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

  // Translation cache
  Map<String, dynamic> _translations = {};

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

  /// Load translations from JSON file
  Future<void> _loadTranslations(String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString('i18n/$languageCode.json');
      _translations = json.decode(jsonString);
    } catch (e) {
      // If loading fails, try to load default language
      if (languageCode != defaultLocale.languageCode) {
        try {
          final jsonString = await rootBundle
              .loadString('i18n/${defaultLocale.languageCode}.json');
          _translations = json.decode(jsonString);
        } catch (e) {
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
