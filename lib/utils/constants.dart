// lib/utils/constants.dart

import 'package:flutter/material.dart'; // ¡Importante! Necesario para GlobalKey y NavigatorState

// --- Constantes ---
// Es una buena práctica definir URLs y claves de SharedPreferences como constantes dentro de una clase.
class Constants {
  // AHORA: Función para generar la URL del JSON de devocionales por año.
  static String getDevocionalesApiUrl(int year) {
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_$year.json';
  }

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
