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
      'es': ['es-ES', 'es-US', 'es-MX'],
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

  // ✅ MAPEO DE NOMBRES TÉCNICOS A NOMBRES AMIGABLES
  static const Map<String, String> _voiceNameMappings = {
    // Apple iOS/macOS voces
    'com.apple.ttsbundle.Mónica-compact': 'Mónica',
    'com.apple.ttsbundle.Diego-compact': 'Diego',
    'com.apple.ttsbundle.Paulina-compact': 'Paulina',
    'com.apple.ttsbundle.Carlos-compact': 'Carlos',
    'com.apple.ttsbundle.Angelica-compact': 'Angélica',
    'com.apple.ttsbundle.Jorge-compact': 'Jorge',
    'com.apple.ttsbundle.Juan-compact': 'Juan',
    'com.apple.ttsbundle.Marisol-compact': 'Marisol',
    'com.apple.ttsbundle.Samantha-compact': 'Samantha',
    'com.apple.ttsbundle.Alex-compact': 'Alex',
    'com.apple.ttsbundle.Victoria-compact': 'Victoria',
    'com.apple.ttsbundle.Daniel-compact': 'Daniel',
    'com.apple.ttsbundle.Karen-compact': 'Karen',
    'com.apple.ttsbundle.Moira-compact': 'Moira',
    'com.apple.ttsbundle.Tessa-compact': 'Tessa',
    'com.apple.ttsbundle.Veena-compact': 'Veena',
    'com.apple.ttsbundle.Rishi-compact': 'Rishi',
    'com.apple.ttsbundle.Fiona-compact': 'Fiona',

    // Android/Google voces
    'es-es-x-eef#female_1-local': 'Carmen',
    'es-es-x-eef#female_2-local': 'Esperanza',
    'es-es-x-eef#female_3-local': 'Gloria',
    'es-es-x-eed#male_1-local': 'Enrique',
    'es-es-x-eed#male_2-local': 'Francisco',
    'es-es-x-eed#male_3-local': 'Álvaro',
    'es-us-x-sfb#female_1-local': 'Penélope',
    'es-us-x-sfb#female_2-local': 'Lupe',
    'es-us-x-sfb#male_1-local': 'Miguel',
    'es-us-x-sfb#male_2-local': 'Juan Carlos',

    'en-us-x-sfg#female_1-local': 'Rachel',
    'en-us-x-sfg#female_2-local': 'Sarah',
    'en-us-x-sfg#female_3-local': 'Amy',
    'en-us-x-sfg#male_1-local': 'John',
    'en-us-x-sfg#male_2-local': 'Mike',
    'en-us-x-sfg#male_3-local': 'David',
    'en-gb-x-gba#female_1-local': 'Emma',
    'en-gb-x-gba#female_2-local': 'Sophie',
    'en-gb-x-gba#male_1-local': 'James',
    'en-gb-x-gba#male_2-local': 'Oliver',

    'pt-br-x-afs#female_1-local': 'Vitória',
    'pt-br-x-afs#female_2-local': 'Lúcia',
    'pt-br-x-afs#female_3-local': 'Francisca',
    'pt-br-x-afs#male_1-local': 'Ricardo',
    'pt-br-x-afs#male_2-local': 'Thiago',
    'pt-br-x-afs#male_3-local': 'Antônio',
    'pt-pt-x-jmn#female_1-local': 'Inês',
    'pt-pt-x-jmn#male_1-local': 'Cristiano',

    'fr-fr-x-frc#female_1-local': 'Céline',
    'fr-fr-x-frc#female_2-local': 'Amélie',
    'fr-fr-x-frc#female_3-local': 'Marie',
    'fr-fr-x-frc#male_1-local': 'Henri',
    'fr-fr-x-frc#male_2-local': 'Claude',
    'fr-fr-x-frc#male_3-local': 'Antoine',
    'fr-ca-x-cab#female_1-local': 'Chantal',
    'fr-ca-x-cab#male_1-local': 'Nicolas',

    // Microsoft Edge voces
    'Microsoft Zira - English (United States)': 'Zira',
    'Microsoft David - English (United States)': 'David',
    'Microsoft Mark - English (United States)': 'Mark',
    'Microsoft Hazel - English (Great Britain)': 'Hazel',
    'Microsoft George - English (Great Britain)': 'George',
    'Microsoft Susan - English (Great Britain)': 'Susan',
    'Microsoft Helena - Spanish (Spain)': 'Helena',
    'Microsoft Laura - Spanish (Spain)': 'Laura',
    'Microsoft Pablo - Spanish (Spain)': 'Pablo',
    'Microsoft Sabina - Spanish (Mexico)': 'Sabina',
    'Microsoft Raul - Spanish (Mexico)': 'Raúl',
    'Microsoft Maria - Portuguese (Brazil)': 'Maria',
    'Microsoft Daniel - Portuguese (Brazil)': 'Daniel',
    'Microsoft Hortense - French (France)': 'Hortense',
    'Microsoft Paul - French (France)': 'Paul',
    'Microsoft Caroline - French (Canada)': 'Caroline',
    'Microsoft Claude - French (Canada)': 'Claude',
  };

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
    // 1. Primero verificar mapeo directo
    if (_voiceNameMappings.containsKey(technicalName)) {
      final friendlyName = _voiceNameMappings[technicalName]!;
      final genderInfo = _getVoiceGenderInfo(technicalName);
      return genderInfo.isNotEmpty ? '$friendlyName $genderInfo' : friendlyName;
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
      friendlyName = _getLocalizedDefaultName(locale);
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

  /// ✅ NOMBRES POR DEFECTO LOCALIZADOS
  String _getLocalizedDefaultName(String locale) {
    switch (locale.toLowerCase()) {
      case String s when s.contains('es-es'):
        return 'Voz Española';
      case String s when s.contains('es-us') || s.contains('es-mx'):
        return 'Voz Latina';
      case String s when s.contains('en-us'):
        return 'American Voice';
      case String s when s.contains('en-gb'):
        return 'British Voice';
      case String s when s.contains('pt-br'):
        return 'Voz Brasileira';
      case String s when s.contains('pt-pt'):
        return 'Voz Portuguesa';
      case String s when s.contains('fr-fr'):
        return 'Voix Française';
      case String s when s.contains('fr-ca'):
        return 'Voix Canadienne';
      default:
        return 'Sistema';
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

  /// Obtiene información del género de la voz
  String _getVoiceGenderInfo(String voiceName) {
    final name = voiceName.toLowerCase();

    // Indicadores explícitos de género
    if (name.contains('female') ||
        name.contains('woman') ||
        name.contains('femenina')) {
      return '♀';
    }
    if (name.contains('male') ||
        name.contains('man') ||
        name.contains('masculina')) {
      return '♂';
    }

    // Nombres femeninos comunes (expandido)
    const femaleNames = [
      'samantha',
      'anna',
      'karen',
      'moira',
      'tessa',
      'veena',
      'zuzana',
      'carolina',
      'silvia',
      'monica',
      'lucia',
      'sofia',
      'paloma',
      'maria',
      'carmen',
      'elena',
      'isabel',
      'fernanda',
      'ines',
      'alice',
      'amelie',
      'marie',
      'celine',
      'claudia',
      'audrey',
      'susan',
      'victoria',
      'kate',
      'zira',
      'hazel',
      'heather',
      'cortana',
      'aria',
      'eva',
      'joanna',
      'kimberly',
      'salli',
      'nicole',
      'emma',
      'amy',
      'elly',
      'chloe',
      'olivia',
      'bianca',
      'carla',
      'vitoria',
      'esperanza',
      'gloria',
      'penelope',
      'lupe',
      'rachel',
      'sarah',
      'sophie',
      'francisca',
      'ines',
      'chantal',
      'helena',
      'laura',
      'sabina',
      'hortense',
      'caroline',
      'angelica',
      'marisol'
    ];

    // Nombres masculinos comunes (expandido)
    const maleNames = [
      'alex',
      'daniel',
      'diego',
      'carlos',
      'jorge',
      'juan',
      'thomas',
      'ricky',
      'fred',
      'david',
      'mark',
      'richard',
      'aaron',
      'albert',
      'brad',
      'bruce',
      'ralph',
      'kevin',
      'lee',
      'paul',
      'reed',
      'alan',
      'gordon',
      'henry',
      'james',
      'john',
      'malcolm',
      'michael',
      'nathan',
      'oliver',
      'ryan',
      'sean',
      'william',
      'antonio',
      'francisco',
      'ricardo',
      'miguel',
      'pedro',
      'jose',
      'felipe',
      'sebastiao',
      'enrique',
      'alvaro',
      'thiago',
      'cristiano',
      'henri',
      'claude',
      'antoine',
      'nicolas',
      'pablo',
      'raul',
      'george',
      'pablo'
    ];

    // Verificar contra nombres conocidos
    for (final femaleName in femaleNames) {
      if (name.contains(femaleName)) {
        return '♀';
      }
    }

    for (final maleName in maleNames) {
      if (name.contains(maleName)) {
        return '♂';
      }
    }

    return ''; // Sin género determinado
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
}
