/// Utility class for handling copyright text based on language and Bible version
class CopyrightUtils {
  /// Get the appropriate copyright text for a given language and version
  static String getCopyrightText(String language, String version) {
    // Extract version code from "Display Name (CODE)" format for Latin-script languages
    String versionKey = version;
    if (language == 'es' ||
        language == 'en' ||
        language == 'pt' ||
        language == 'fr' ||
        language == 'de' ||
        language == 'ar' ||
        language == 'fil') {
      final regex = RegExp(r'\(([A-Z0-9]+)\)$');
      final match = regex.firstMatch(version);
      if (match != null) {
        versionKey = match.group(1)!;
      }
    }

    const Map<String, Map<String, String>> copyrightMap = {
      'es': {
        'RVR1960':
            'El texto bíblico Reina-Valera 1960® Sociedades Bíblicas en América Latina, 1960. Derechos renovados 1988, Sociedades Bíblicas Unidas.',
        'NVI':
            'El texto bíblico Nueva Versión Internacional® © 1999 Biblica, Inc. Todos los derechos reservados.',
        'NTV':
            'El texto bíblico Nueva Traducción Viviente® © 2010 Tyndale House Foundation. Todos los derechos reservados.',
        'NTV_es.SQLite3':
            'El texto bíblico Nueva Traducción Viviente® © 2010 Tyndale House Foundation. Todos los derechos reservados.',
        'Nueva Traducción Viviente (NTV)':
            'El texto bíblico Nueva Traducción Viviente® © 2010 Tyndale House Foundation. Todos los derechos reservados.',
        'default':
            'El texto bíblico Reina-Valera 1960® Sociedades Bíblicas en América Latina, 1960. Derechos renovados 1988, Sociedades Bíblicas Unidas.',
      },
      'en': {
        'KJV': 'The biblical text King James Version® Public Domain.',
        'NIV':
            'The biblical text New International Version® © 2011 Biblica, Inc. All rights reserved.',
        'ESV': 'The Holy Bible, English Standard Version® © 2001, 2007, 2011 Crossway, a publishing ministry of Good News Publishers. All rights reserved.',
        'ESV_en.SQLite3': 'The Holy Bible, English Standard Version® © 2001, 2007, 2011 Crossway, a publishing ministry of Good News Publishers. All rights reserved.',
        'English Standard Version (ESV)': 'The Holy Bible, English Standard Version® © 2001, 2007, 2011 Crossway, a publishing ministry of Good News Publishers. All rights reserved.',
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
        // BDS - Bible du Semeur (new)
        'BDS':
            'Le texte biblique Bible du Semeur® © Éditions Semeur. Tous droits réservés.',
        'default': 'Le texte biblique Louis Segond 1910® Domaine Public.',
      },
      'ja': {
        '新改訳2003': '聖書本文 新改訳2003聖書® © 2003 新日本聖書刊行会。すべての権利が保護されています。',
        'リビングバイブル': '聖書本文 リビングバイブル® © 1997 新日本聖書刊行会。すべての権利が保護されています。',
        'default': '聖書本文 新改訳聖書® パブリックドメイン。',
      },
      'zh': {
        '和合本1919': '圣经和合本版权属于公有领域。',
        '新译本': '圣经《新译本》版权属于环球圣经公会，蒙允准使用。版权所有，不得翻印。',
        'default': '圣经和合本版权属于公有领域。',
      },
      'hi': {
        'HIOV_hi.SQLite3':
            'पवित्र बाइबिल हिन्दी ओ.वी. संस्करण (HIOV) © Bible Society of India. सभी अधिकार सुरक्षित।',
        'HERV_hi.SQLite3':
            'पवित्र बाइबिल आसान हिंदी संस्करण (HERV) © 1995, 2010 Bible League International. सभी अधिकार सुरक्षित।',
        'HIOV':
            'पवित्र बाइबिल हिन्दी ओ.वी. संस्करण (HIOV) © Bible Society of India. सभी अधिकार सुरक्षित।',
        'HERV':
            'पवित्र बाइबिल आसान हिंदी संस्करण (HERV) © 1995, 2010 Bible League International. सभी अधिकार सुरक्षित।',
        'पवित्र बाइबिल (ओ.वी.)':
            'पवित्र बाइबिल हिन्दी ओ.वी. संस्करण (HIOV) © Bible Society of India. सभी अधिकार सुरक्षित।',
        'पवित्र बाइबिल':
            'पवित्र बाइबिल आसान हिंदी संस्करण (HERV) © 1995, 2010 Bible League International. सभी अधिकार सुरक्षित।',
        'default':
            'पवित्र बाइबिल हिन्दी ओ.वी. संस्करण (HIOV) © Bible Society of India. सभी अधिकार सुरक्षित।',
      },
      'de': {
        'LU17':
            'Lutherbibel, revidiert 2017, © 2016 Deutsche Bibelgesellschaft, Stuttgart.',
        'SCH2000':
            'Schlachter 2000 © Genfer Bibelgesellschaft. Alle Rechte vorbehalten.',
        'LU17_de.SQLite3':
            'Lutherbibel, revidiert 2017, © 2016 Deutsche Bibelgesellschaft, Stuttgart.',
        'SCH2000_de.SQLite3':
            'Schlachter 2000 © Genfer Bibelgesellschaft. Alle Rechte vorbehalten.',
        'Lutherbibel 2017 (LU17)':
            'Lutherbibel, revidiert 2017, © 2016 Deutsche Bibelgesellschaft, Stuttgart.',
        'Schlachter 2000 (SCH2000)':
            'Schlachter 2000 © Genfer Bibelgesellschaft. Alle Rechte vorbehalten.',
        'default':
            'Lutherbibel, revidiert 2017, © 2016 Deutsche Bibelgesellschaft, Stuttgart.',
      },
      'ar': {
        'NAV':
            'النص الكتابي الترجمة العربية الجديدة © 2005 Biblica, Inc. جميع الحقوق محفوظة.',
        'SVDA': 'النص الكتابي ترجمة سميث وفاندايك، ملك عام.',
        'NAV_ar.SQLite3':
            'النص الكتابي الترجمة العربية الجديدة © 2005 Biblica, Inc. جميع الحقوق محفوظة.',
        'SVDA_ar.SQLite3': 'النص الكتابي ترجمة سميث وفاندايك، ملك عام.',
        'كتاب الحياة (NAV)':
            'النص الكتابي الترجمة العربية الجديدة © 2005 Biblica, Inc. جميع الحقوق محفوظة.',
        'الكتاب المقدس — فان دايك (SVDA)':
            'النص الكتابي ترجمة سميث وفاندايك، ملك عام.',
        'default':
            'النص الكتابي الترجمة العربية الجديدة © 2005 Biblica, Inc. جميع الحقوق محفوظة.',
      },
      'fil': {
        'MBB05':
            'Ang Magandang Balita Biblia (MBB) © 2005, 2012 Philippine Bible Society. Lahat ng karapatan ay nakalaan.',
        'ASND':
            'Ang Salita ng Dios (Tagalog Contemporary Bible) © 2009, 2011, 2014, 2015 Biblica, Inc. ® Ginamit sa pahintulot ng Biblica, Inc.® Lahat ng karapatan ay nakalaan sa buong mundo.',
        'MBB05_fil.SQLite3':
            'Ang Magandang Balita Biblia (MBB) © 2005, 2012 Philippine Bible Society. Lahat ng karapatan ay nakalaan.',
        'ASND_fil.SQLite3':
            'Ang Salita ng Dios (Tagalog Contemporary Bible) © 2009, 2011, 2014, 2015 Biblica, Inc. ® Ginamit sa pahintulot ng Biblica, Inc.® Lahat ng karapatan ay nakalaan sa buong mundo.',
        'ADB_fil.SQLite3':
            'Ang Dating Biblia (1905) © Philippine Bible Society. Pampublikong domain.',
        'Magandang Balita Biblia (MBB05)':
            'Ang Magandang Balita Biblia (MBB) © 2005, 2012 Philippine Bible Society. Lahat ng karapatan ay nakalaan.',
        'Ang Salita ng Dios (ASND)':
            'Ang Salita ng Dios (Tagalog Contemporary Bible) © 2009, 2011, 2014, 2015 Biblica, Inc. ® Ginamit sa pahintulot ng Biblica, Inc.® Lahat ng karapatan ay nakalaan sa buong mundo.',
        'Ang Dating Biblia (ADB)':
            'Ang Dating Biblia (1905) © Philippine Bible Society. Pampublikong domain.',
        'default':
            'Ang Magandang Balita Biblia (MBB) © 2005, 2012 Philippine Bible Society. Lahat ng karapatan ay nakalaan.',
      },
    };

    final langMap = copyrightMap[language] ?? copyrightMap['en']!;
    return langMap[versionKey] ?? langMap['default']!;
  }
}
