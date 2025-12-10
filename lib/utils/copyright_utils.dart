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
        'NTV':
            'Santa Biblia, Nueva Traducción Viviente, copyright © 2010 by Tyndale House Foundation.',
        'default':
            'El texto bíblico Reina-Valera 1960® Sociedades Bíblicas en América Latina, 1960. Derechos renovados 1988, Sociedades Bíblicas Unidas.',
      },
      'en': {
        'KJV': 'The biblical text King James Version® Public Domain.',
        'NIV':
            'The biblical text New International Version® © 2011 Biblica, Inc. All rights reserved.',
        'ESV':
            'The Holy Bible, English Standard Version Copyright © 2001 by Crossway Bibles, a publishing ministry of Good News Publishers.',
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
        // Nouvelle Bible Segond (BDS) 2002
        'BDS':
            'Nouvelle Bible Segond © 2002, Société biblique française. Avec autorisation. Tous droits réservés.',
        // La Bible du Semeur (2015) - copyright line in French
        'Semeur': 'La Bible du Semeur © 1992, 1999, 2015 par Biblica, Inc.®',
        'default': 'Le texte biblique Louis Segond 1910® Domaine Public.',
      },
      'ja': {
        '新改訳2003':
            '\u8056\u66f8\u672c\u6587 \u65b0\u6539\u8a332003\u8056\u66f8\u00ae \u00a9 2003 \u65b0\u65e5\u672c\u8056\u66f8\u520a\u884c\u4f1a\u3002\u3059\u3079\u3066\u306e\u6a29\u5229\u304c\u4fdd\u8b77\u3055\u308c\u3066\u3044\u307e\u3059\u3002',
        'リビングバイブル':
            '\u8056\u66f8\u672c\u6587 \u30ea\u30d3\u30f3\u30b0\u30d0\u30a4\u30d6\u30eb\u65e5\u672c\u8a9e\u5171\u540c\u8a33\u8056\u66f8\u00ae \u00a9 2018 \u65e5\u672c\u8056\u66f8\u5354\u4f1a\u3002\u3059\u3079\u3066\u306e\u6a29\u5229\u304c\u4fdd\u8b77\u3055\u308c\u3066\u3044\u307e\u3059\u3002',
        // 口語訳 (Kougo-yaku) — Colloquial Japanese
        '口語訳':
            '\u53e3\u8a9e\u8a33\u8056\u66f8\uff08\u30eb\u30d3\u3042\u308a\uff09 \u30b3\u30ed\u30b1\u30a2\u30eb\u30b8\u30e3\u30d1\u30cb\u30fc (Kougo-yaku) \u00a9 1954/1955. \u3059\u3079\u3066\u306e\u6a29\u5229\u3092\u4fdd\u8b77\u3057\u307e\u3059\u3002',
        'devocional':
            '\u30c7\u30dc\u30fc\u30b7\u30e7\u30f3\u8457\u4f5c\u6a29 \u00a9 2025 develop4God. \u7121\u65ad\u8ee2\u8f09\u30fb\u8907\u88fd\u3092\u7981\u3058\u307e\u3059\u3002',
        'KJV':
            '\u8056\u66f8\u672c\u6587 \u30ad\u30f3\u30b0\u30fb\u30b8\u30a7\u30fc\u30e0\u30ba\u7248\u00ae \u30d1\u30d6\u30ea\u30c3\u30af\u30c9\u30e1\u30a4\u30f3\u3002',
        'NIV':
            '\u8056\u66f8\u672c\u6587 \u65b0\u56fd\u969b\u7248\u00ae \u00a9 2011 Biblica, Inc. \u3059\u3079\u3066\u306e\u6a29\u5229\u304c\u4fdd\u8b77\u3055\u308c\u3066\u3044\u307e\u3059\u3002',
        'default':
            '\u8056\u66f8\u672c\u6587 \u65b0\u6539\u8a33\u8056\u66f8\u00ae \u30d1\u30d6\u30ea\u30c3\u30af\u30c9\u30e1\u30a4\u30f3\u3002',
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
        'NTV': 'Nueva Traducción Viviente',
      },
      'en': {
        'KJV': 'King James Version',
        'NIV': 'New International Version',
        'ESV': 'English Standard Version',
      },
      'pt': {
        'ARC': 'Almeida Revista e Corrigida',
        'NVI': 'Nova Versão Internacional',
      },
      'fr': {
        'BDS': 'NBS Nouvelle Bible Segond ',
        'NBS': 'La Bible du Semeur',
        'LSG1910': 'Louis Segond 1910',
        'TOB': 'Traduction Oecuménique de la Bible',
      },
      'ja': {
        '口語訳': '\u53e3\u8a9e\u8a33\u8056\u66f8 (Kougo-yaku)',
        '新改訳2003': '\u65b0\u6539\u8a332003\u8056\u66f8',
        'リビングバイブル':
            '\u30ea\u30d3\u30f3\u30b0\u30d0\u30a4\u30d6\u30eb\u65e5\u672c\u8a9e\u5171\u540c\u8a33\u8056\u66f8',
        'KJV': '\u30ad\u30f3\u30b0\u30fb\u30b8\u30a7\u30fc\u30e0\u30ba\u7248',
        'NIV': '\u65b0\u56fd\u969b\u7248',
      },
    };

    return versionNames[language]?[version] ?? version;
  }
}
