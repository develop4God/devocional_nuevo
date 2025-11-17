import 'package:flutter/material.dart';

/// Clase de constantes globales para devocionales
class Constants {
  /// FUNCIONES DE GENERACIÓN DE URLS

  // ✅ ORIGINAL METHOD - DO NOT MODIFY (Backward Compatibility)
  static String getDevocionalesApiUrl(int year) {
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$year.json';
  }

  // ✅ NEW METHOD for multilingual support
  static String getDevocionalesApiUrlMultilingual(
      int year, String languageCode, String versionCode) {
    // Backward compatibility for Spanish RVR1960
    if (languageCode == 'es' && versionCode == 'RVR1960') {
      return getDevocionalesApiUrl(year); // Use original method
    }

    // New format for other languages/versions
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_${year}_${languageCode}_$versionCode.json';
  }

  /// MAPAS DE IDIOMAS Y VERSIONES

  // Idiomas soportados y su nombre legible
  static const Map<String, String> supportedLanguages = {
    'es': 'Español',
    'en': 'English',
    'pt': 'Português',
    'fr': 'Français',
  };

  // Versiones de la Biblia disponibles por idioma
  static const Map<String, List<String>> bibleVersionsByLanguage = {
    'es': ['RVR1960', 'NVI'],
    'en': ['KJV', 'NIV'],
    'pt': ['ARC', 'NVI'],
    'fr': ['LSG1910', 'TOB'],
  };

  // Versión de Biblia por defecto por idioma
  static const Map<String, String> defaultVersionByLanguage = {
    'es': 'RVR1960',
    'en': 'KJV',
    'pt': 'ARC',
    'fr': 'LSG1910',
  };

  /// PREFERENCIAS (SharedPreferences KEYS)
  static const String prefSeenIndices = 'seenIndices';
  static const String prefFavorites = 'favorites';
  static const String prefDontShowInvitation = 'dontShowInvitation';
  static const String prefCurrentIndex = 'currentIndex';
  static const String prefLastNotificationDate = 'lastNotificationDate';

  /// Compatibilidad con lógica de mostrar/no mostrar diálogos de invitación (usada en el provider)
  static const String prefShowInvitationDialog = 'showInvitationDialog';

  /// FEATURE FLAGS
  /// Feature flag to disable onboarding initialization (not available to users)
  static const bool enableOnboardingFeature = false;

  /// Feature flag to disable backup initialization (not available to users)
  static const bool enableBackupFeature = false;
}

// Servicio de navegación global
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
