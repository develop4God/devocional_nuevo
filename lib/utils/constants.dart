import 'package:flutter/material.dart';

/// Clase de constantes globales para devocionales
class Constants {
  /// FUNCIONES DE GENERACIÓN DE URLS

  // Función unificada que maneja tanto la compatibilidad hacia atrás como los nuevos formatos
  static String getDevocionalesApiUrl(int year,
      [String? languageCode, String? versionCode]) {
    // Si no se especifica idioma o versión, usar el formato original (español)
    if (languageCode == null || versionCode == null) {
      return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$year.json';
    }

    // Compatibilidad hacia atrás para español con RVR1960
    if (languageCode == 'es' && versionCode == 'RVR1960') {
      return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$year.json';
    }

    // Nuevo formato para otros idiomas y versiones
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
    'fr': ['LSG', 'TOB'],
  };

  // Versión de Biblia por defecto por idioma
  static const Map<String, String> defaultVersionByLanguage = {
    'es': 'RVR1960',
    'en': 'KJV',
    'pt': 'ARC',
    'fr': 'LSG',
  };

  /// PREFERENCIAS (SharedPreferences KEYS)
  static const String prefSeenIndices = 'seenIndices';
  static const String prefFavorites = 'favorites';
  static const String prefDontShowInvitation = 'dontShowInvitation';
  static const String prefCurrentIndex = 'currentIndex';
  static const String prefLastNotificationDate = 'lastNotificationDate';

  /// Compatibilidad con lógica de mostrar/no mostrar diálogos de invitación (usada en el provider)
  static const String prefShowInvitationDialog = 'showInvitationDialog';
}

// Servicio de navegación global
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
