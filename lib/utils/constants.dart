// lib/utils/constants.dart

import 'package:flutter/material.dart'; // ¡Importante! Necesario para GlobalKey y NavigatorState

// --- Constantes ---
// Es una buena práctica definir URLs y claves de SharedPreferences como constantes dentro de una clase.
class Constants {
  // AHORA: Función para generar la URL del JSON de devocionales por año, idioma y versión.
  static String getDevocionalesApiUrl(int year,
      [String? language, String? version]) {
    // Mantener compatibilidad con la URL original para español RVR1960
    if (language == null || language == 'es') {
      return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$year.json';
    }

    // Nueva estructura para otros idiomas y versiones
    final String languageCode = language.toUpperCase();
    final String versionCode = version?.toUpperCase() ?? '';
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$year_${languageCode}_$versionCode.json';
  }

  // Idiomas soportados con sus códigos
  static const Map<String, String> supportedLanguages = {
    'es': 'Español',
    'en': 'English',
    // TODO: Uncomment when Portuguese and French content is ready
    // 'pt': 'Português',
    // 'fr': 'Français',
  };

  // Versiones de la Biblia por idioma
  static const Map<String, List<String>> bibleVersionsByLanguage = {
    'es': ['RVR1960', 'NVI'],
    'en': ['KJV', 'NIV'],
    // TODO: Uncomment when Portuguese and French content is ready
    // 'pt': ['ARC', 'NVI'],
    // 'fr': ['LSG', 'TOB'],
  };

  // Versión por defecto por idioma
  static const Map<String, String> defaultVersionByLanguage = {
    'es': 'RVR1960',
    'en': 'KJV',
    // TODO: Uncomment when Portuguese and French content is ready
    // 'pt': 'ARC',
    // 'fr': 'LSG',
  };

  // Las siguientes constantes no son necesarias en el nuevo modelo basado en fechas y objetos
  // pero las mantengo aquí si las usas en otras partes de tu código por ahora.
  // En el nuevo DevocionalProvider, 'seenIndices' y 'currentIndex' ya no se usan.
  // Y 'favorites' se gestiona directamente con la lista de Devocional objetos.
  static const String prefSeenIndices =
      'seenIndices'; // Esto ya no se usa en el nuevo Provider
  static const String prefFavorites =
      'favorites'; // Esto ya no se usa directamente en el nuevo Provider (usa 'favorites' clave)
  static const String prefDontShowInvitation = 'dontShowInvitation';
  static const String prefCurrentIndex =
      'currentIndex'; // Esto ya no se usa en el nuevo Provider
  static const String prefLastNotificationDate = 'lastNotificationDate';
}

// Clase de utilidad para obtener el contexto del Navigator.
// Asegúrate de que NavigationService.navigatorKey se asigne a tu MaterialApp en main.dart.
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
