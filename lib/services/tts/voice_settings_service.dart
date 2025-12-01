import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceSettingsService {
  static final VoiceSettingsService _instance =
      VoiceSettingsService._internal();

  factory VoiceSettingsService() => _instance;

  VoiceSettingsService._internal();

  final FlutterTts _flutterTts = FlutterTts();

  /// Asigna automáticamente una voz válida por defecto para un idioma si no hay ninguna guardada o la guardada es inválida
  /// Asigna automáticamente una voz válida por defecto para un idioma si no hay ninguna guardada o la guardada es inválida
  Future<void> autoAssignDefaultVoice(String language) async {
    final hasVoice = await hasSavedVoice(language);
    debugPrint(
        '🎵 [autoAssignDefaultVoice] ¿Ya hay voz guardada para "$language"? $hasVoice');
    if (hasVoice) return;

    // Define los locales preferidos para cada idioma
    final Map<String, List<String>> preferredLocales = {
      'es': ['es-US', 'es-MX', 'es-ES'],
      'en': ['en-US', 'en-GB', 'en-AU'],
      'pt': ['pt-BR', 'pt-PT'],
      'fr': ['fr-FR', 'fr-CA'],
      'ja': ['ja-JP'],
    };
    final locales = preferredLocales[language] ?? [language];

    final voices = await _flutterTts.getVoices;
    if (voices is List) {
      debugPrint(
          '🎵 [autoAssignDefaultVoice] Voces filtradas para $language (${locales.join(", ")}):');
      final filtered = voices
          .cast<Map>()
          .where((voice) =>
              locales.any((loc) =>
                  (voice['locale'] as String?)?.toLowerCase() ==
                  loc.toLowerCase()) &&
              (voice['name'] as String?) != null &&
              (voice['name'] as String).trim().isNotEmpty)
          .toList();

      for (final v in filtered) {
        final n = v['name'] as String? ?? '';
        final l = v['locale'] as String? ?? '';
        debugPrint('    - name: "$n", locale: "$l"');
      }

      if (filtered.isEmpty) {
        debugPrint(
            '⚠️ [autoAssignDefaultVoice] ¡No se encontró voz válida para $language!');
        return;
      }

      final selected = filtered.first;
      final name = selected['name'] as String? ?? '';
      final locale = selected['locale'] as String? ?? '';
      debugPrint(
          '🎵 [autoAssignDefaultVoice] → Asignada: name="$name", locale="$locale" para $language');
      if (name.isNotEmpty && locale.isNotEmpty) {
        await saveVoice(language, name, locale);
      }
    } else {
      debugPrint('⚠️ [autoAssignDefaultVoice] No se obtuvo lista de voces');
    }
  }

  // ✅ MAPEO DE PATRONES COMPLEJOS
  static final Map<RegExp, String> _voicePatternMappings = {
    // Patrones Android con códigos técnicos
    RegExp(r'es-es-x-[a-z]+#female_(\d+)-local'): 'Voz Femenina Española',
    RegExp(r'es-es-x-[a-z]+#male_(\d+)-local'): 'Voz Masculina Española',
    RegExp(r'es-us-x-[a-z]+#female_(\d+)-local'): 'Voz Femenina Latina',
    RegExp(r'es-us-x-[a-z]+#male_(\d+)-local'): 'Voz Masculina Latina',
    RegExp(r'en-us-x-[a-z]+#female_(\d+)-local'): 'American Female Voice',
    RegExp(r'en-us-x-[a-z]+#male_(\d+)-local'): 'American Male Voice',
    RegExp(r'en-gb-x-[a-z]+#female_(\d+)-local'): 'British Female Voice',
    RegExp(r'en-gb-x-[a-z]+#male_(\d+)-local'): 'British Male Voice',
    RegExp(r'pt-br-x-[a-z]+#female_(\d+)-local'): 'Voz Feminina Brasileira',
    RegExp(r'pt-br-x-[a-z]+#male_(\d+)-local'): 'Voz Masculina Brasileira',
    RegExp(r'pt-pt-x-[a-z]+#female_(\d+)-local'): 'Voz Feminina Portuguesa',
    RegExp(r'pt-pt-x-[a-z]+#male_(\d+)-local'): 'Voz Masculina Portuguesa',
    RegExp(r'fr-fr-x-[a-z]+#female_(\d+)-local'): 'Voix Féminine Française',
    RegExp(r'fr-fr-x-[a-z]+#male_(\d+)-local'): 'Voix Masculine Française',
    RegExp(r'fr-ca-x-[a-z]+#female_(\d+)-local'): 'Voix Féminine Canadienne',
    RegExp(r'fr-ca-x-[a-z]+#male_(\d+)-local'): 'Voix Masculine Canadienne',

    // Patrones generales con quality indicators
    RegExp(r'.*-compact$'): '',
    RegExp(r'.*-enhanced$'): '',
    RegExp(r'.*-premium$'): '',
    RegExp(r'.*-neural$'): '',
    RegExp(r'.*-local$'): '',
    RegExp(r'.*-network$'): '',
  };

  /// Guarda la voz seleccionada para un idioma específico
  Future<void> saveVoice(
      String language, String voiceName, String locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Guardar tanto el nombre técnico como el amigable
      final voiceData = {
        'technical_name': voiceName,
        'locale': locale,
        'friendly_name': _getFriendlyVoiceName(voiceName, locale),
      };

      await prefs.setString('tts_voice_$language', voiceData.toString());

      // También aplicar la voz inmediatamente al TTS
      await _flutterTts.setVoice({
        'name': voiceName,
        'locale': locale,
      });

      debugPrint(
          '🔧 VoiceSettings: Saved voice ${voiceData['friendly_name']} (${voiceData['technical_name']}) for language $language');
    } catch (e) {
      debugPrint('❌ VoiceSettings: Failed to save voice: $e');
      rethrow;
    }
  }

  /// Guarda la voz seleccionada en SharedPreferences y muestra debugPrint
  Future<void> saveVoiceWithDebug(
      String language, String name, String locale) async {
    debugPrint(
        '🔊 Voz seleccionada: name=$name, locale=$locale, language=$language');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('voice_name_$language', name);
    await prefs.setString('voice_locale_$language', locale);
  }

  /// Carga la voz guardada para un idioma específico
  Future<String?> loadSavedVoice(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVoice = prefs.getString('tts_voice_$language');

      if (savedVoice != null) {
        // Parse del formato legacy o nuevo
        String voiceName, locale;

        if (savedVoice.contains('technical_name')) {
          // Formato nuevo - parsear como mapa (simplificado)
          final parts = savedVoice.split(', ');
          voiceName = parts
              .firstWhere((p) => p.contains('technical_name'))
              .split(': ')[1];
          locale = parts.firstWhere((p) => p.contains('locale')).split(': ')[1];
        } else {
          // Formato legacy
          final voiceParts = savedVoice.split(' (');
          voiceName = voiceParts[0];
          locale = voiceParts.length > 1
              ? voiceParts[1].replaceAll(')', '')
              : _getDefaultLocaleForLanguage(language);
        }

        // Aplicar la voz al TTS
        await _flutterTts.setVoice({
          'name': voiceName,
          'locale': locale,
        });

        debugPrint(
            '🔧 VoiceSettings: Loaded saved voice $voiceName for language $language (locale: $locale)');
        return _getFriendlyVoiceName(voiceName, locale);
      }
    } catch (e) {
      debugPrint('⚠️ VoiceSettings: Failed to load saved voice: $e');
    }

    return null;
  }

  /// ✅ METODO PRINCIPAL MEJORADO PARA NOMBRES USER-FRIENDLY
  String _getFriendlyVoiceName(String technicalName, String locale) {
    // 1. Verificar mapeo amigable con emoji y nombre
    final language = locale.split('-').first;
    final map = friendlyVoiceMap[language];
    if (map != null && map.containsKey(technicalName)) {
      return map[technicalName]!;
    }

    // 2. Verificar patrones complejos
    for (final pattern in _voicePatternMappings.keys) {
      if (pattern.hasMatch(technicalName)) {
        final match = pattern.firstMatch(technicalName);
        String baseName = _voicePatternMappings[pattern]!;

        // Si hay un grupo capturado (número), agregarlo
        if (match != null && match.groupCount > 0) {
          final number = match.group(1);
          if (number != null) {
            baseName += ' $number';
          }
        }

        return baseName;
      }
    }

    // 3. Procesamiento avanzado para nombres no mapeados
    return _processUnmappedVoiceName(technicalName, locale);
  }

  /// ✅ PROCESAMIENTO AVANZADO PARA NOMBRES NO MAPEADOS
  String _processUnmappedVoiceName(String voiceName, String locale) {
    String friendlyName = voiceName;

    // Eliminar prefijos comunes de plataforma
    friendlyName =
        friendlyName.replaceAll(RegExp(r'^com\.apple\.ttsbundle\.'), '');
    friendlyName = friendlyName.replaceAll(
        RegExp(r'^com\.apple\.speech\.synthesis\.voice\.'), '');
    friendlyName = friendlyName.replaceAll(RegExp(r'^Microsoft\s+'), '');
    friendlyName = friendlyName.replaceAll(RegExp(r'^Google\s+'), '');
    friendlyName = friendlyName.replaceAll(RegExp(r'^Amazon\s+'), '');

    // Eliminar sufijos técnicos
    friendlyName = friendlyName.replaceAll(RegExp(r'-compact$'), '');
    friendlyName = friendlyName.replaceAll(RegExp(r'-enhanced$'), '');
    friendlyName = friendlyName.replaceAll(RegExp(r'-premium$'), '');
    friendlyName = friendlyName.replaceAll(RegExp(r'-neural$'), '');
    friendlyName = friendlyName.replaceAll(RegExp(r'-local$'), '');
    friendlyName = friendlyName.replaceAll(RegExp(r'-network$'), '');

    // Manejo especial para códigos técnicos de Android
    if (friendlyName.contains('#')) {
      final parts = friendlyName.split('#');
      if (parts.length > 1) {
        final genderPart = parts[1];
        final voiceNumber =
            RegExp(r'(\d+)').firstMatch(genderPart)?.group(1) ?? '';

        if (genderPart.contains('female')) {
          friendlyName = _getLocalizedGenderName('female', locale, voiceNumber);
        } else if (genderPart.contains('male')) {
          friendlyName = _getLocalizedGenderName('male', locale, voiceNumber);
        }
      }
    }

    // Si aún contiene códigos técnicos, usar nombre por locale
    if (friendlyName.contains('x-') ||
        friendlyName.contains('#') ||
        friendlyName.length < 3) {
      // Devuelve un nombre genérico por idioma
      switch (locale.split('-').first) {
        case 'es':
          friendlyName = 'Voz por Defecto';
          break;
        case 'en':
          friendlyName = 'Default Voice';
          break;
        case 'pt':
          friendlyName = 'Voz Padrão';
          break;
        case 'fr':
          friendlyName = 'Voix par Défaut';
          break;
        case 'ja':
          friendlyName = 'デフォルトの声';
          break;
        default:
          friendlyName = 'Default Voice';
      }
    }

    // Limpiar y capitalizar
    friendlyName = friendlyName
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');

    // Remover palabras técnicas residuales
    friendlyName = friendlyName
        .replaceAll(RegExp(r'\bVoice\b'), '')
        .replaceAll(RegExp(r'\bTts\b'), '')
        .replaceAll(RegExp(r'\bSpeech\b'), '')
        .replaceAll(RegExp(r'\bSynthesis\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return friendlyName.isEmpty ? 'Voz por Defecto' : friendlyName;
  }

  /// ✅ NOMBRES LOCALIZADOS POR GÉNERO
  String _getLocalizedGenderName(String gender, String locale, String number) {
    final num = number.isNotEmpty ? ' $number' : '';

    switch (locale.toLowerCase()) {
      case String s when s.startsWith('es'):
        return gender == 'female' ? 'Voz Femenina$num' : 'Voz Masculina$num';
      case String s when s.startsWith('en'):
        return gender == 'female' ? 'Female Voice$num' : 'Male Voice$num';
      case String s when s.startsWith('pt'):
        return gender == 'female' ? 'Voz Feminina$num' : 'Voz Masculina$num';
      case String s when s.startsWith('fr'):
        return gender == 'female' ? 'Voix Féminine$num' : 'Voix Masculine$num';
      default:
        return gender == 'female' ? 'Female Voice$num' : 'Male Voice$num';
    }
  }

  /// Metodo proactivo para inicializar el TTS con la voz correcta al iniciar la app o cambiar idioma
  Future<void> proactiveAssignVoiceOnInit(String language) async {
    debugPrint(
        '🔄 [proactiveAssignVoiceOnInit] Inicializando TTS para idioma: $language');
    final friendlyName = await loadSavedVoice(language);
    if (friendlyName == null) {
      debugPrint(
          '🔄 [proactiveAssignVoiceOnInit] No hay voz guardada válida, asignando automáticamente...');
      await autoAssignDefaultVoice(language);
      final newFriendlyName = await loadSavedVoice(language);
      debugPrint(
          '🔄 [proactiveAssignVoiceOnInit] Voz asignada: $newFriendlyName');
    } else {
      debugPrint(
          '🔄 [proactiveAssignVoiceOnInit] Voz guardada aplicada: $friendlyName');
    }
  }

  /// Obtiene todas las voces disponibles y las formatea de manera user-friendly
  Future<List<String>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;

      if (voices is List<dynamic>) {
        return voices.map((voice) {
          if (voice is Map) {
            final name = voice['name'] as String? ?? '';
            final locale = voice['locale'] as String? ?? '';
            final friendlyName = _getFriendlyVoiceName(name, locale);
            return '$friendlyName ($locale)';
          }
          return voice.toString();
        }).toList()
          ..sort();
      }

      return [];
    } catch (e) {
      debugPrint('❌ VoiceSettings: Failed to get available voices: $e');
      return [];
    }
  }

  /// Obtiene las voces disponibles para un idioma específico
  Future<List<String>> getVoicesForLanguage(String language) async {
    try {
      final targetLocale = _getDefaultLocaleForLanguage(language);
      final rawVoices = await _flutterTts.getVoices;

      if (rawVoices is List<dynamic>) {
        final filteredVoices = rawVoices.where((voice) {
          if (voice is Map) {
            final locale = voice['locale'] as String? ?? '';
            return locale.toLowerCase().startsWith(targetLocale.toLowerCase());
          }
          return false;
        }).toList();

        final formattedVoices = filteredVoices.map((voice) {
          final name = voice['name'] as String? ?? '';
          final locale = voice['locale'] as String? ?? '';
          final friendlyName = _getFriendlyVoiceName(name, locale);
          return '$friendlyName ($locale)';
        }).toList();

        // ✅ ORDENAMIENTO MEJORADO
        formattedVoices.sort((a, b) {
          // Prioridad 1: Voces con nombres propios
          final aHasProperName = _hasProperName(a);
          final bHasProperName = _hasProperName(b);
          if (aHasProperName && !bHasProperName) return -1;
          if (!aHasProperName && bHasProperName) return 1;

          // Prioridad 2: Locales preferidos (US, ES, etc.)
          final aIsPreferred = _isPreferredLocale(a, language);
          final bIsPreferred = _isPreferredLocale(b, language);
          if (aIsPreferred && !bIsPreferred) return -1;
          if (!aIsPreferred && bIsPreferred) return 1;

          // Prioridad 3: Voces femeninas primero
          final aIsFemale = a.contains('♀') ||
              a.toLowerCase().contains('female') ||
              a.toLowerCase().contains('femenina');
          final bIsFemale = b.contains('♀') ||
              b.toLowerCase().contains('female') ||
              b.toLowerCase().contains('femenina');
          if (aIsFemale && !bIsFemale) return -1;
          if (!aIsFemale && bIsFemale) return 1;

          return a.compareTo(b);
        });

        return formattedVoices;
      }

      return [];
    } catch (e) {
      debugPrint('❌ VoiceSettings: Failed to get voices for $language: $e');
      return [];
    }
  }

  /// Obtiene todas las voces disponibles para el idioma actual
  Future<List<Map<String, String>>> getAvailableVoicesForLanguage(
      String language) async {
    final voices = await _flutterTts.getVoices;
    if (voices is List) {
      return voices.cast<Map>().where((voice) {
        final locale = voice['locale'] as String? ?? '';
        return locale.toLowerCase().contains(language.toLowerCase());
      }).map((voice) {
        return {
          'name': voice['name'] as String? ?? '',
          'locale': voice['locale'] as String? ?? '',
        };
      }).toList();
    }
    return [];
  }

  /// ✅ VERIFICA SI UNA VOZ TIENE NOMBRE PROPIO
  bool _hasProperName(String voiceName) {
    final cleanName = voiceName.split('(')[0].trim();
    // Si no contiene palabras como "Voz", "Voice", "Female", "Male", probablemente es un nombre propio
    return !cleanName.toLowerCase().contains('voz') &&
        !cleanName.toLowerCase().contains('voice') &&
        !cleanName.toLowerCase().contains('female') &&
        !cleanName.toLowerCase().contains('male') &&
        !cleanName.toLowerCase().contains('masculina') &&
        !cleanName.toLowerCase().contains('femenina') &&
        cleanName.split(' ').length <= 2; // Nombres simples
  }

  /// ✅ VERIFICA SI ES UN LOCALE PREFERIDO
  bool _isPreferredLocale(String voiceName, String language) {
    final preferredLocales = {
      'es': ['es-US', 'es-ES', 'es-MX'],
      'en': ['en-US', 'en-GB'],
      'pt': ['pt-BR', 'pt-PT'],
      'fr': ['fr-FR', 'fr-CA'],
    };

    final preferred = preferredLocales[language] ?? [];
    return preferred.any((locale) => voiceName.contains(locale));
  }

  /// Obtiene el locale por defecto para un idioma
  String _getDefaultLocaleForLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'es':
        return 'es-ES';
      case 'en':
        return 'en-US';
      case 'pt':
        return 'pt-BR';
      case 'fr':
        return 'fr-FR';
      case 'ja':
        return 'ja-JP';
      default:
        return 'es-ES';
    }
  }

  /// Elimina la voz guardada para un idioma específico
  Future<void> clearSavedVoice(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('tts_voice_$language');
      debugPrint(
          '🗑️ VoiceSettings: Cleared saved voice for language $language');
    } catch (e) {
      debugPrint('❌ VoiceSettings: Failed to clear saved voice: $e');
    }
  }

  /// Verifica si hay una voz guardada para un idioma específico
  Future<bool> hasSavedVoice(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('tts_voice_$language');
    } catch (e) {
      debugPrint('❌ VoiceSettings: Failed to check saved voice: $e');
      return false;
    }
  }

  /// Verifica si el usuario ya guardó su voz personalizada
  Future<bool> hasUserSavedVoice(String language) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tts_voice_user_saved_$language') ?? false;
  }

  /// Marca que el usuario guardó su voz personalizada
  Future<void> setUserSavedVoice(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_voice_user_saved_$language', true);
  }

  /// Borra el flag de voz guardada por el usuario
  Future<void> clearUserSavedVoiceFlag(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tts_voice_user_saved_$language');
  }

  /// Obtiene la velocidad de reproducción TTS guardada
  Future<double> getSavedSpeechRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('tts_rate') ?? 0.5;
  }

  // Mapeo amigable de voces con emoji y nombre
  static const Map<String, Map<String, String>> friendlyVoiceMap = {
    'es': {
      'es-us-x-esd-local': '🇲🇽 Hombre Latinoamérica',
      'es-US-language': '🇲🇽 Mujer Latinoamérica',
      'es-es-x-eed-local': '🇪🇸 Hombre España',
      'es-ES-language': '🇪🇸 Mujer España',
    },
    'en': {
      'en-us-x-tpd-network': '🇺🇸 Male United States',
      'en-us-x-tpf-local': '🇺🇸 Female United States',
      'en-gb-x-gbb-local': '🇬🇧 Male United Kingdom',
      'en-GB-language': '🇬🇧 Female United Kingdom',
    },
    'pt': {
      'pt-br-x-ptd-network': '🇧🇷 Homem Brasil',
      'pt-br-x-afs-network': '🇧🇷 Mulher Brasil',
      'pt-pt-x-pmj-local': '🇵🇹 Homem Portugal',
      'pt-PT-language': '🇵🇹 Mulher Portugal',
    },
    'ja': {
      'ja-jp-x-jac-local': '🇯🇵 男性 声 1',
      'ja-jp-x-jab-local': '🇯🇵 女性 声 1',
      'ja-jp-x-jad-local': '🇯🇵 男性 声 2',
      'ja-jp-x-htm-local': '🇯🇵 女性 声 2',
    },
  };

  /// Nuevo método para obtener nombre amigable con emoji
  String getFriendlyVoiceName(String language, String technicalName) {
    final map = friendlyVoiceMap[language];
    if (map != null && map.containsKey(technicalName)) {
      return map[technicalName]!;
    }
    return technicalName;
  }
}
