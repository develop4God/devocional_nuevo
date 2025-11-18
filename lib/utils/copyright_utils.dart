/// Utility class for handling copyright text based on language and Bible version
class CopyrightUtils {
  /// Get the appropriate copyright text for a given language and version
  static String getCopyrightText(String language, String version) {
    const Map<String, Map<String, String>> copyrightMap = {
      'es': {
        'RVR1960':
            'El texto bíblico Reina-Valera 1960® Sociedades Bíblicas en América Latina, 1960. Derechos renovados 1988, Sociedades Bíblicas Unidas.',
        'NVI':
            'El texto bíblico Nueva Versión Internacional® © 1999 Biblica, Inc. Todos los derechos reservados.',
        'default':
            'El texto bíblico Reina-Valera 1960® Sociedades Bíblicas en América Latina, 1960. Derechos renovados 1988, Sociedades Bíblicas Unidas.',
      },
      'en': {
        'KJV': 'The biblical text King James Version® Public Domain.',
        'NIV':
            'The biblical text New International Version® © 2011 Biblica, Inc. All rights reserved.',
        'default': 'The biblical text King James Version® Public Domain.',
      },
      'pt': {
        'ARC': 'O texto bíblico Almeida Revista e Corrigida® Domínio Público.',
        'NVI':
            'O texto bíblico Nova Versão Internacional® © 2000 Biblica, Inc. Todos os direitos reservados.',
        'default':
            'O texto bíblico Almeida Revista e Corrigida® Domínio Público.',
      },
      'fr': {
        'LSG1910': 'Le texte biblique Louis Segond 1910® Domaine Public.',
        'TOB':
            'Le texte biblique Traduction Oecuménique de la Bible® © Société Biblique Française et Éditions du Cerf.',
        'default': 'Le texte biblique Louis Segond 1910® Domaine Public.',
      },
      'ja': {
        'SK2003': '聖書本文 新改訳2003聖書® © 2003 新日本聖書刊行会。すべての権利が保護されています。',
        'JCB': '聖書本文 JCB日本語共同訳聖書® © 2018 日本聖書協会。すべての権利が保護されています。',
        'devocional': 'デボーション著作権 © 2025 develop4God. 無断転載・複製を禁じます。',
        'KJV': '聖書本文 キング・ジェームズ版® パブリックドメイン。',
        'NIV': '聖書本文 新国際版® © 2011 Biblica, Inc. すべての権利が保護されています。',
        'default': '聖書本文 新改訳聖書® パブリックドメイン。',
      },
    };

    final langMap = copyrightMap[language] ?? copyrightMap['en']!;
    return langMap[version] ?? langMap['default']!;
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
        'TOB': 'Traduction Oecuménique de la Bible',
      },
      'ja': {
        'KJV': 'キング・ジェームズ版',
        'NIV': '新国際版',
      },
    };

    return versionNames[language]?[version] ?? version;
  }
}
