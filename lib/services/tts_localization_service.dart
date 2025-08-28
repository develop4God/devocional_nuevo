import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling TTS localization across multiple languages
class TtsLocalizationService {
  static final TtsLocalizationService _instance =
      TtsLocalizationService._internal();

  factory TtsLocalizationService() => _instance;

  TtsLocalizationService._internal();

  /// Get current TTS language from preferences
  Future<String> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tts_language') ?? 'es-US';
  }

  /// Get language code from full language identifier (e.g., 'es' from 'es-US')
  String getLanguageCode(String fullLanguage) {
    return fullLanguage.split('-').first.toLowerCase();
  }

  /// Get ordinal words for numbers based on language
  Map<int, String> getOrdinalsMap(String languageCode) {
    switch (languageCode) {
      case 'en':
        return {
          1: 'first',
          2: 'second',
          3: 'third',
          4: 'fourth',
          5: 'fifth',
          6: 'sixth',
          7: 'seventh',
          8: 'eighth',
          9: 'ninth',
          10: 'tenth',
        };
      case 'fr':
        return {
          1: 'premier',
          2: 'deuxième',
          3: 'troisième',
          4: 'quatrième',
          5: 'cinquième',
          6: 'sixième',
          7: 'septième',
          8: 'huitième',
          9: 'neuvième',
          10: 'dixième',
        };
      case 'pt':
        return {
          1: 'primeiro',
          2: 'segundo',
          3: 'terceiro',
          4: 'quarto',
          5: 'quinto',
          6: 'sexto',
          7: 'sétimo',
          8: 'oitavo',
          9: 'nono',
          10: 'décimo',
        };
      case 'es':
      default:
        return {
          1: 'primero',
          2: 'segundo',
          3: 'tercero',
          4: 'cuarto',
          5: 'quinto',
          6: 'sexto',
          7: 'séptimo',
          8: 'octavo',
          9: 'noveno',
          10: 'décimo',
        };
    }
  }

  /// Get book ordinal prefixes for Bible references based on language
  Map<String, String> getBookOrdinalsMap(String languageCode) {
    switch (languageCode) {
      case 'en':
        return {
          '1': 'First',
          '2': 'Second',
          '3': 'Third',
        };
      case 'fr':
        return {
          '1': 'Premier',
          '2': 'Deuxième',
          '3': 'Troisième',
        };
      case 'pt':
        return {
          '1': 'Primeiro',
          '2': 'Segundo',
          '3': 'Terceiro',
        };
      case 'es':
      default:
        return {
          '1': 'Primera de',
          '2': 'Segunda de',
          '3': 'Tercera de',
        };
    }
  }

  /// Get Bible version expansions based on language
  Map<String, String> getBibleVersionsMap(String languageCode) {
    switch (languageCode) {
      case 'en':
        return {
          'KJV': 'King James Version',
          'NIV': 'New International Version',
          'ESV': 'English Standard Version',
          'NLT': 'New Living Translation',
          'NASB': 'New American Standard Bible',
          'NKJV': 'New King James Version',
        };
      case 'fr':
        return {
          'LSG': 'Louis Segond',
          'NEG': 'Nouvelle Edition de Genève',
          'BDS': 'Bible du Semeur',
          'TOB': 'Traduction Oecuménique de la Bible',
          'FC': 'Français Courant',
          'PDV': 'Parole de Vie',
        };
      case 'pt':
        return {
          'ARC': 'Almeida Revista e Corrigida',
          'ARA': 'Almeida Revista e Atualizada',
          'NVI': 'Nova Versão Internacional',
          'NTLH': 'Nova Tradução na Linguagem de Hoje',
          'BV': 'Bíblia Viva',
          'NAA': 'Nova Almeida Atualizada',
        };
      case 'es':
      default:
        return {
          'RVR1960': 'Reina Valera mil novecientos sesenta',
          'RVR60': 'Reina Valera sesenta',
          'RVR1995': 'Reina Valera mil novecientos noventa y cinco',
          'RVR09': 'Reina Valera dos mil nueve',
          'NVI': 'Nueva Versión Internacional',
          'DHH': 'Dios Habla Hoy',
          'TLA': 'Traducción en Lenguaje Actual',
          'NTV': 'Nueva Traducción Viviente',
          'PDT': 'Palabra de Dios para Todos',
          'BLP': 'Biblia La Palabra',
          'CST': 'Castilian',
          'LBLA': 'La Biblia de las Américas',
          'NBLH': 'Nueva Biblia Latinoamericana de Hoy',
          'RVC': 'Reina Valera Contemporánea',
        };
    }
  }

  /// Get language-specific abbreviations
  Map<String, String> getAbbreviationsMap(String languageCode) {
    switch (languageCode) {
      case 'en':
        return {
          'vs.': 'verse',
          'vv.': 'verses',
          'ch.': 'chapter',
          'chs.': 'chapters',
          'cf.': 'compare',
          'etc.': 'etcetera',
          'e.g.': 'for example',
          'i.e.': 'that is',
          'BC': 'before Christ',
          'AD': 'anno domini',
          'am': 'in the morning',
          'pm': 'in the evening',
        };
      case 'fr':
        return {
          'vs.': 'verset',
          'vv.': 'versets',
          'ch.': 'chapitre',
          'chs.': 'chapitres',
          'cf.': 'comparez',
          'etc.': 'et cetera',
          'p.ex.': 'par exemple',
          'c.-à-d.': 'c\'est-à-dire',
          'av. J.-C.': 'avant Jésus-Christ',
          'ap. J.-C.': 'après Jésus-Christ',
          'matin': 'du matin',
          'soir': 'du soir',
        };
      case 'pt':
        return {
          'vs.': 'versículo',
          'vv.': 'versículos',
          'cap.': 'capítulo',
          'caps.': 'capítulos',
          'cf.': 'compare',
          'etc.': 'etcétera',
          'p.ex.': 'por exemplo',
          'ou seja': 'ou seja',
          'a.C.': 'antes de Cristo',
          'd.C.': 'depois de Cristo',
          'manhã': 'da manhã',
          'tarde': 'da tarde',
        };
      case 'es':
      default:
        return {
          'vs.': 'versículo',
          'vv.': 'versículos',
          'cap.': 'capítulo',
          'caps.': 'capítulos',
          'cf.': 'compárese',
          'etc.': 'etcétera',
          'p.ej.': 'por ejemplo',
          'i.e.': 'es decir',
          'a.C.': 'antes de Cristo',
          'd.C.': 'después de Cristo',
          'a.m.': 'de la mañana',
          'p.m.': 'de la tarde',
        };
    }
  }
}
