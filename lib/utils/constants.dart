import 'package:flutter/material.dart'; // ¡Importante! Necesario para GlobalKey y NavigatorState

// --- Constantes ---
// Es una buena práctica definir URLs y claves de SharedPreferences como constantes dentro de una clase.
class Constants {
  // Lógica original: Función para generar la URL del JSON de devocionales por año.
  // Mantén esta función para compatibilidad con rutas antiguas.
  static String getDevocionalesApiUrl(int year) {
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$year.json';
  }

  // Nueva lógica: Función para generar la URL del JSON por año, idioma y versión.
  // Úsala para rutas nuevas que incluyan idioma y versión.
  static String getDevocionalesApiUrlFull(int year, String languageCode, String versionCode) {
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocionales_year_${year}_${languageCode}_$versionCode.json';
  }

  // Las siguientes constantes pueden no ser necesarias en el nuevo modelo basado en fechas y objetos,
  // pero se mantienen aquí por si aún las usas en otras partes de tu código.
  static const String prefSeenIndices = 'seenIndices'; // Esto ya no se usa en el nuevo Provider
  static const String prefFavorites = 'favorites'; // Esto ya no se usa directamente en el nuevo Provider (usa 'favorites' clave)
  static const String prefDontShowInvitation = 'dontShowInvitation';
  static const String prefCurrentIndex = 'currentIndex'; // Esto ya no se usa en el nuevo Provider
  static const String prefLastNotificationDate = 'lastNotificationDate';
}

// Clase de utilidad para obtener el contexto del Navigator.
// Asegúrate de que NavigationService.navigatorKey se asigne a tu MaterialApp en main.dart.
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
