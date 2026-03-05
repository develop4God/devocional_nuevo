import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Clase de constantes globales para devocionales
class Constants {
  /// FUNCIONES DE GENERACIÓN DE URLS

  // ✅ ORIGINAL METHOD - DO NOT MODIFY (Backward Compatibility)
  static String getDevocionalesApiUrl(int year) {
    final branch = kDebugMode ? debugBranchDevotionals : 'main';
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/$branch/Devocional_year_$year.json';
  }

  // ✅ NEW METHOD for multilingual support
  static String getDevocionalesApiUrlMultilingual(
    int year,
    String languageCode,
    String versionCode,
  ) {
    final branch = kDebugMode ? debugBranchDevotionals : 'main';

    // Backward compatibility for Spanish RVR1960
    if (languageCode == 'es' && versionCode == 'RVR1960') {
      return getDevocionalesApiUrl(year); // Use original method
    }

    // New format for other languages/versions
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/$branch/Devocional_year_${year}_${languageCode}_$versionCode.json';
  }

  /// MAPAS DE IDIOMAS Y VERSIONES

  // Idiomas soportados y su nombre legible
  static const Map<String, String> supportedLanguages = {
    'es': 'Español',
    'en': 'English',
    'pt': 'Português',
    'fr': 'Français',
    'ja': '日本語', // Habilitar japonés
    'zh': '中文', // Habilitar chino
    'hi': 'हिन्दी', // Habilitar hindi
  };

  // Banderas emoji para cada idioma
  static const Map<String, String> languageFlags = {
    'es': '🇪🇸',
    'en': '🇺🇸🇬🇧',
    'pt': '🇧🇷🇵🇹',
    'fr': '🇫🇷',
    'ja': '🇯🇵',
    'zh': '🇨🇳',
    'hi': '🇮🇳',
  };

  /// Obtiene el emoji de la bandera para un idioma
  static String getLanguageFlag(String languageCode) {
    return languageFlags[languageCode] ?? '🌐';
  }

  // Versiones de la Biblia disponibles por idioma
  static const Map<String, List<String>> bibleVersionsByLanguage = {
    'es': ['RVR1960', 'NVI'],
    'en': ['KJV', 'NIV'],
    'pt': ['ARC', 'NVI'],
    'fr': ['LSG1910', 'TOB'],
    'ja': ['新改訳2003', 'リビングバイブル'], // Japanese versions
    'zh': ['和合本1919', '新译本'], // Chinese versions (fix: 新译本)
    'hi': ['पवित्र बाइबिल (ओ.वी.)', 'पवित्र बाइबिल'], // Hindi versions
  };

  // Versión de Biblia por defecto por idioma
  static const Map<String, String> defaultVersionByLanguage = {
    'es': 'RVR1960',
    'en': 'KJV',
    'pt': 'ARC',
    'fr': 'LSG1910',
    'ja': '新改訳2003', // Default Japanese version
    'zh': '和合本1919', // Default Chinese version
    'hi': 'पवित्र बाइबिल (ओ.वी.)', // Default Hindi version (MASTER_VERSION)
  };

  // Nombres japoneses para versiones de la Biblia (deprecated - versions now use Japanese names directly)
  static const Map<String, String> bibleJapaneseNames = {
    '新改訳2003': '新改訳2003', // Shinkaiyaku 2003
    'リビングバイブル': 'リビングバイブル', // Living Bible
  };

  /// PREFERENCIAS (SharedPreferences KEYS)
  static const String prefSeenIndices = 'seenIndices';
  static const String prefFavorites = 'favorites';
  static const String prefDontShowInvitation = 'dontShowInvitation';
  static const String prefCurrentIndex = 'currentIndex';
  static const String prefLastNotificationDate = 'lastNotificationDate';

  /// Favorites local storage schema version. Bump this when changing the
  /// local format for favorites so migrations can be applied.
  static const int favoritesSchemaVersion = 1;

  /// Compatibilidad con lógica de mostrar/no mostrar diálogos de invitación (usada en el provider)
  static const String prefShowInvitationDialog = 'showInvitationDialog';

  /// FEATURE FLAGS
  /// Feature flag to disable onboarding initialization (not available to users)
  static const bool enableOnboardingFeature = false;

  /// Feature flag to disable backup initialization (not available to users)
  static const bool enableBackupFeature = false;

  /// Feature flag for Discovery Studies feature
  static const bool enableDiscoveryFeature = true;

  /// Feature flag for Encounters feature
  static const bool enableEncountersFeature = true;

  /// Set to true to use cache + bundled fallback assets when network is unavailable.
  /// Set to false to skip all fallbacks and always require network.
  /// Mutable so it can be toggled from the debug page at runtime.
  static bool enableEncounterFallback = true;

  /// Branch para debug Discovery (solo kDebugMode)
  static String debugBranch = 'main';

  /// Branch para debug Encounters (solo kDebugMode)
  static String debugEncounterBranch = 'main';

  /// Branch para debug Devotionals (solo kDebugMode)
  static String debugBranchDevotionals = 'main';

  /// Obtiene la URL del índice de Devocionales (cache invalidation)
  static String getDevocionalIndexUrl() {
    final branch = kDebugMode ? debugBranchDevotionals : 'main';
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/$branch/index.json';
  }

  /// Timeout for fetching the devocional index — keep short to avoid blocking load
  static const Duration indexFetchTimeout = Duration(seconds: 3);

  /// Obtiene la URL del índice de Discovery
  static String getDiscoveryIndexUrl() {
    final branch = kDebugMode ? debugBranch : 'main';
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/$branch/discovery/index.json';
  }

  /// Obtiene la URL de un archivo de estudio
  static String getDiscoveryStudyFileUrl(String fileName, String languageCode) {
    final branch = kDebugMode ? debugBranch : 'main';
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/$branch/discovery/$languageCode/$fileName';
  }

  /// Legacy constant for backward compatibility (deprecated)
  @Deprecated('Use getDiscoveryIndexUrl() instead')
  static String get discoveryIndexUrl => getDiscoveryIndexUrl();

  // ---------------------------------------------------------------------------
  // Encounters URLs
  // ---------------------------------------------------------------------------

  /// Obtiene la URL del índice de Encounters
  static String getEncounterIndexUrl() {
    final branch = kDebugMode ? debugEncounterBranch : 'main';
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/$branch/encounters/index.json';
  }

  /// Obtiene la URL de un estudio de Encounter.
  ///
  /// [filename] — the exact filename from the index `files` map
  ///   (e.g. `peter_water_001_es.json`). When omitted the convention
  ///   `{id}_{lang}.json` is used as a fallback.
  static String getEncounterStudyUrl(String id, String lang,
      {String? filename}) {
    final branch = kDebugMode ? debugEncounterBranch : 'main';
    final file = filename ?? '${id}_$lang.json';
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/$branch/encounters/$lang/$file';
  }

  /// Obtiene la URL de una imagen de Encounter
  static String getEncounterImageUrl(String filename) {
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-assets/main/images/encounters/$filename';
  }

  // ---------------------------------------------------------------------------
  // Prayer Wall
  // ---------------------------------------------------------------------------

  /// Number of prayers to fetch per page in the Prayer Wall
  static const int prayerWallPageSize = 20;
}

/// Schema versioning and migration constants for favorites storage
class FavoritesSchema {
  static const int currentVersion = 2;
  static const String versionKey = 'favorites_schema_version';
  static const String migratedAtKey = 'favorites_migrated_at';
}

// Servicio de navegación global
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
