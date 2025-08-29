import 'package:devocional_nuevo/extensions/string_extensions.dart';

/// Utility class for handling copyright text based on language and Bible version
class CopyrightUtils {
  /// Get the appropriate copyright text for a given language and version
  static String getCopyrightText(String language, String version) {
    // Create version-specific copyright key
    String versionKey = version.toLowerCase();
    String copyrightKey = 'devotionals.copyright_$versionKey';

    // Try to get version-specific copyright text
    String copyrightText = copyrightKey.tr();

    // If the translation key doesn't exist, it will return the key itself
    // In that case, fall back to the generic copyright text
    if (copyrightText == copyrightKey) {
      copyrightText = 'devotionals.copyright_text'.tr();
    }

    return copyrightText;
  }

  /// Get Bible version display name for TTS
  static String getBibleVersionDisplayName(String language, String version) {
    final Map<String, Map<String, String>> versionNames = {
      'es': {
        'RVR1960': 'Reina Valera 1960',
        'NVI': 'Nueva Versión Internacional',
      },
      'en': {
        'KJV': 'King James Version',
        'NIV': 'New International Version',
      },
      'pt': {
        'ARC': 'Almeida Revista e Corrigida',
        'NVI': 'Nova Versão Internacional',
      },
      'fr': {
        'LSG1910': 'Louis Segond 1910',
        'LSG': 'Louis Segond',
        'TOB': 'Traduction Oecuménique de la Bible',
      },
    };

    return versionNames[language]?[version] ?? version;
  }
}
