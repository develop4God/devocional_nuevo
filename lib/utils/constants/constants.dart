import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/debug/debug_flags.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Clase de constantes globales para devocionales
class Constants {
  /// FUNCIONES DE GENERACIÓN DE URLS

  // ✅ ORIGINAL METHOD - DO NOT MODIFY (Backward Compatibility)
  static String getDevocionalesApiUrl(int year) {
    final branch = kDebugMode ? DebugFlags.debugBranchDevotionals : 'main';
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/$branch/Devocional_year_$year.json';
  }

  // TEMPORARY: the devotional JSON repo (Devocionales-json) still uses the
  // legacy KJV code, while the app now uses KJ2000 (the English SQLite bible
  // content is King James 2000). Remove this map once the devotional JSON
  // files and index.json migrate KJV → KJ2000.
  static const Map<String, String> legacyDevotionalApiVersionCodes = {
    'KJ2000': 'KJV',
  };

  /// Maps an app version code to the code used by the devotional content API.
  static String devotionalApiVersionCode(String versionCode) {
    return legacyDevotionalApiVersionCodes[versionCode] ?? versionCode;
  }

  // ✅ NEW METHOD for multilingual support
  static String getDevocionalesApiUrlMultilingual(
    int year,
    String languageCode,
    String versionCode,
  ) {
    final branch = kDebugMode ? DebugFlags.debugBranchDevotionals : 'main';

    // Backward compatibility for Spanish RVR1960
    if (languageCode == 'es' && versionCode == 'RVR1960') {
      return getDevocionalesApiUrl(year); // Use original method
    }

    final apiVersionCode = devotionalApiVersionCode(versionCode);

    // New format for other languages/versions
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/$branch/Devocional_year_${year}_${languageCode}_$apiVersionCode.json';
  }

  /// MAPAS DE IDIOMAS Y VERSIONES

  // Idiomas soportados y su nombre legible
  static const Map<String, String> supportedLanguages = {
    'es': 'Español',
    'en': 'English',
    'de': 'Deutsch', // Habilitar alemán
    'ar': 'العربية', // Habilitar árabe
    'fil': 'Filipino', // Habilitar filipino
    'pt': 'Português',
    'fr': 'Français',
    'hi': 'हिन्दी', // Habilitar hindi
    'ja': '日本語', // Habilitar japonés
    'zh': '中文', // Habilitar chino
  };

  // Banderas emoji para cada idioma
  static const Map<String, String> languageFlags = {
    'es': '🇪🇸',
    'en': '🇬🇧',
    'pt': '🇵🇹',
    'fr': '🇫🇷',
    'ja': '🇯🇵',
    'zh': '🇨🇳',
    'hi': '🇮🇳',
    'de': '🇩🇪',
    'ar': '🇸🇦',
    'fil': '🇵🇭',
  };

  /// Obtiene el emoji de la bandera para un idioma
  static String getLanguageFlag(String languageCode) {
    return languageFlags[languageCode] ?? '🌐';
  }

  // Available versions by language / Drawer menu options (SRP: single source of truth for all version lists)
  static const Map<String, List<String>> bibleVersionsByLanguage = {
    'es': ['RVR1960', 'NVI'], //> ,'NTV' not available on drawer yet
    'en': ['KJ2000', 'NIV'], //> ,'ESV'not available on drawer yet
    'pt': ['ARC', 'NVI'],
    'fr': ['LSG1910', 'TOB'],
    'ja': ['新改訳2003', 'リビングバイブル'], // Japanese versions
    'zh': ['和合本1919', '新译本'], // Chinese versions (fix: 新译本)
    'hi': ['HIOV', 'HERV'], // Hindi versions
    'de': ['LU17', 'SCH2000'], // German versions
    'ar': ['NAV', 'SVDA'], // Arabic versions
    'fil': [
      'MBB05',
      'ASND',
    ], // Filipino versions (only versions with devotional content)
  };

  // Versión de Biblia por defecto por idioma
  static const Map<String, String> defaultVersionByLanguage = {
    'es': 'RVR1960',
    'en': 'KJ2000',
    'pt': 'ARC',
    'fr': 'LSG1910',
    'ja': '新改訳2003', // Default Japanese version
    'zh': '和合本1919', // Default Chinese version
    'hi': 'HIOV', // Default Hindi version
    'de': 'LU17', // Default German version
    'ar': 'NAV', // Default Arabic version
    'fil': 'MBB05', // Default Filipino version (Magandang Balita Biblia 2005)
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
  /// Feature flag for Discovery Studies feature
  static const bool enableDiscoveryFeature = true;

  /// Feature flag for Encounters feature
  static const bool enableEncountersFeature = true;

  /// Set to true to use cache + bundled fallback assets when network is unavailable.
  /// Set to false to skip all fallbacks and always require network.
  /// Mutable so it can be toggled from the debug page at runtime.
  static bool enableEncounterFallback = true;

  /// Obtiene la URL del índice de Devocionales (cache invalidation)
  static String getDevocionalIndexUrl() {
    final branch = kDebugMode ? DebugFlags.debugBranchDevotionals : 'main';
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/$branch/index.json';
  }

  /// Timeout for fetching the devocional index — keep short to avoid blocking load
  static const Duration indexFetchTimeout = Duration(seconds: 3);

  /// Obtiene la URL del índice de Discovery
  static String getDiscoveryIndexUrl() {
    final branch = kDebugMode ? DebugFlags.debugBranch : 'main';
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/$branch/discovery/index.json';
  }

  /// Obtiene la URL de un archivo de estudio
  static String getDiscoveryStudyFileUrl(String fileName, String languageCode) {
    final branch = kDebugMode ? DebugFlags.debugBranch : 'main';
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
    final branch = kDebugMode ? DebugFlags.debugEncounterBranch : 'main';
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/$branch/encounters/index.json';
  }

  /// Obtiene la URL de un estudio de Encounter.
  ///
  /// [filename] — the exact filename from the index `files` map
  ///   (e.g. `peter_water_001_es.json`). When omitted the convention
  ///   `{id}_{lang}.json` is used as a fallback.
  static String getEncounterStudyUrl(
    String id,
    String lang, {
    String? filename,
  }) {
    final branch = kDebugMode ? DebugFlags.debugEncounterBranch : 'main';
    final file = filename ?? '${id}_$lang.json';
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/$branch/encounters/$lang/$file';
  }

  /// Resolves an encounter image URL.
  ///
  /// [filename] — base name WITHOUT extension (e.g. "peter_intro").
  ///   Legacy callers passing a name with extension are handled gracefully:
  ///   the extension is stripped and replaced by [format].
  /// [encounterId] — encounter folder name.
  /// [format] — image format extension, default 'avif'. Pass 'png' for fallback.
  static String getEncounterImageUrl(
    String filename, {
    required String encounterId,
    String format = 'avif',
  }) {
    // Strip any existing extension to support both old (with ext) and new (no ext) callers
    final base = filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    return 'https://raw.githubusercontent.com/develop4God/Devocionales-assets/main/images/encounters/$encounterId/$base.$format';
  }

  // ---------------------------------------------------------------------------
  // Prayer Wall
  // ---------------------------------------------------------------------------

  /// Number of prayers to fetch per page in the Prayer Wall
  static const int prayerWallPageSize = 20;

  /// Extracts display abbreviation from a BibleVersion's database filename.
  /// Returns display abbreviation derived from dbFileName.
  /// Returns '' for languages where name is self-describing (ja, zh).
  /// SRP: single source of truth for all abbreviation logic.
  static String versionAbbreviation(BibleVersion version) {
    if (version.languageCode == 'ja' ||
        version.languageCode == 'zh' ||
        version.languageCode == 'hi' ||
        version.languageCode == 'ar' ||
        version.languageCode == 'fil') {
      // For languages whose version names are self-describing (native-script or
      // already include the code in the name), return '' so _versionPickerLabel
      // does not append a duplicate code suffix.
      return '';
    }
    final parts = version.dbFileName.split('_');
    if (parts.isNotEmpty) {
      final abbr = parts[0];
      return abbr;
    }
    return '';
  }
}

/// Schema versioning and migration constants for favorites storage
class FavoritesSchema {
  static const int currentVersion = 2;
  static const String versionKey = 'favorites_schema_version';
  static const String migratedAtKey = 'favorites_migrated_at';
}

/// Backup schedule constants
class BackupSchedule {
  static const int intervalHours = 24;
}

// Servicio de navegación global
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
