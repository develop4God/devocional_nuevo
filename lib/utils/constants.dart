import 'package:flutter/material.dart';

/// Clase de constantes globales para devocionales
class Constants {
  /// FUNCIONES DE GENERACIÓN DE URLS
  
  // Lógica vieja: solo año
  static String getDevocionalesApiUrl(int year) {
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$year.json';
  }

  // Nueva lógica: año, idioma y versión (para los nuevos archivos)
  static String getDevocionalesApiUrlFull(int year, String languageCode, String versionCode) {
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocionales_year_${year}_${languageCode}_$versionCode.json';
  }

  /// MAPAS DE IDIOMAS Y VERSIONES

  // Idiomas soportados y su nombre legible
  static const Map<String, String> supportedLanguages = {
    'es': 'Español',
    'en': 'English',
    'pt': 'Português',
  };

  // Versiones de la Biblia disponibles por idioma
  static const Map<String, List<String>> bibleVersionsByLanguage = {
    'es': ['RVR1960', 'NVI'],
    'en': ['KJV', 'NIV'],
    'pt': ['NVT', 'ARA'],
  };

  // Versión de Biblia por defecto por idioma
  static const Map<String, String> defaultVersionByLanguage = {
    'es': 'RVR1960',
    'en': 'KJV',
    'pt': 'NVT',
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
