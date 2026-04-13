import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Voice Settings Service - Manages TTS voice selection and preferences.
///
/// This service is registered as a lazy singleton in the Service Locator.
/// Access it via `getService<VoiceSettingsService>()` instead of direct instantiation.
///
/// ## Usage
/// ```dart
/// // Get the service via DI
/// final voiceService = getService<VoiceSettingsService>();
/// await voiceService.saveVoice('es', 'es-us-x-esd-local', 'es-US');
/// ```
class VoiceSettingsService {
  /// Default constructor for DI registration.
  /// The Service Locator will create and manage the singleton instance.
  VoiceSettingsService();

  /// Constructor for injecting a mock FlutterTts instance.
  VoiceSettingsService.withTts(FlutterTts tts) : _flutterTtsInstance = tts;

  /// Constructor for injecting both main and sample TTS instances.
  VoiceSettingsService.withBothTts(FlutterTts mainTts, FlutterTts sampleTts)
      : _flutterTtsInstance = mainTts,
        _sampleTtsInstance = sampleTts;

  // FlutterTts instance - initialized lazily or injected for testing
  FlutterTts? _flutterTtsInstance;

  // Dedicated TTS instance ONLY for voice samples (no handlers, no state changes)
  FlutterTts? _sampleTtsInstance;

  FlutterTts get _flutterTts => _flutterTtsInstance ??= FlutterTts();

  /// Get dedicated TTS instance for samples (isolated from main playback)
  FlutterTts get _sampleTts {
    if (_sampleTtsInstance == null) {
      _sampleTtsInstance = FlutterTts();
      debugPrint(
        '🔊 VoiceSettings: Created dedicated TTS instance for samples',
      );
    }
    return _sampleTtsInstance!;
  }

  /// Asigna automáticamente una voz válida por defecto para un idioma si no hay ninguna guardada o la guardada es inválida
  /// Asigna automáticamente una voz válida por defecto para un idioma si no hay ninguna guardada o la guardada es inválida
  Future<void> autoAssignDefaultVoice(String language) async {
    final hasVoice = await hasSavedVoice(language);
    debugPrint(
      '🎵 [autoAssignDefaultVoice] ¿Ya hay voz guardada para "$language"? $hasVoice',
    );
    if (hasVoice) return;

    // Define los locales preferidos para cada idioma
    final Map<String, List<String>> preferredLocales = {
      'es': ['es-US', 'es-MX', 'es-ES'],
      'en': ['en-US', 'en-GB', 'en-AU'],
      'pt': ['pt-BR', 'pt-PT'],
      'fr': ['fr-FR', 'fr-CA'],
      'ja': ['ja-JP'],
      'zh': ['zh-CN', 'zh-TW', 'yue-HK'],
      'hi': ['hi-IN'], // Hindi
      'de': ['de-DE', 'de-AT', 'de-CH'], // German
      'ar': [
        'ar-xa',
        'ar-SA',
        'ar-EG',
        'ar-AE',
        'ar'
      ], // Arabic - any ar-* device voice
    };
    final locales = preferredLocales[language] ?? [language];

    final voices = await _flutterTts.getVoices;
    if (voices is List) {
      debugPrint(
        '🎵 [autoAssignDefaultVoice] Voces filtradas para $language (${locales.join(", ")}):',
      );
      final filtered = voices
          .cast<Map>()
          .where(
            (voice) =>
                locales.any(
                  (loc) =>
                      (voice['locale'] as String?)?.toLowerCase().startsWith(
                            loc.toLowerCase(),
                          ) ??
                      false,
                ) &&
                (voice['name'] as String?) != null &&
                (voice['name'] as String).trim().isNotEmpty,
          )
          .toList();

      for (final v in filtered) {
        final n = v['name'] as String? ?? '';
        final l = v['locale'] as String? ?? '';
        debugPrint('    - name: "$n", locale: "$l"');
      }

      if (filtered.isEmpty) {
        debugPrint(
          '⚠️ [autoAssignDefaultVoice] ¡No se encontró voz válida para $language!',
        );
        return;
      }

      // Try to find a preferred male voice first
      final preferredMaleVoices = {
        'es': ['es-us-x-esd-local', 'es-us-x-esd-network'],
        'en': [
          'en-us-x-tpd-network',
          'en-us-x-tpd-local',
          'en-us-x-iom-network',
        ],
        'pt': ['pt-br-x-ptd-network', 'pt-br-x-ptd-local'],
        'fr': ['fr-fr-x-frd-local', 'fr-fr-x-frd-network', 'fr-fr-x-vlf-local'],
        'ja': ['ja-jp-x-jac-local', 'ja-jp-x-jad-local', 'ja-jp-x-jac-network'],
        'zh': [
          'cmn-cn-x-cce-local', // Voz masculina China por defecto
          'cmn-cn-x-ccc-local', // Voz femenina China por defecto
          'cmn-cn-x-cce-network',
          'cmn-cn-x-ccc-network',
          'zh-CN-language',
          'zh-TW-language',
          'cmn-tw-x-ctd-local',
          'cmn-tw-x-cte-local',
          'cmn-tw-x-ctc-local',
          'cmn-tw-x-ctd-network',
          'cmn-tw-x-cte-network',
          'cmn-tw-x-ctc-network',
          'yue-hk-x-yue-local',
          'yue-hk-x-yue-network',
          'yue-hk-x-yud-local',
          'yue-hk-x-yud-network',
          'yue-hk-x-yuf-local',
          'yue-hk-x-yuf-network',
          'yue-hk-x-jar-local',
          'yue-hk-x-jar-network',
        ],
        'hi': [
          'hi-in-x-hid-local', // Voz masculina India por defecto (पुरुष भारत)
          'hi-in-x-hia-local', // Voz femenina India alternativa
          'hi-in-x-hie-network',
          'hi-IN-language',
        ],
        'de': [
          'de-de-x-ded-local', // Male voice Germany default
          'de-de-x-dec-network', // Male voice Germany 2
          'de-de-x-dea-local', // Female voice Germany
          'de-DE-language', // Female voice Germany 2
        ],
        'ar': [
          'ar-xa-x-are-local', // Male voice Arabic primary
          'ar-xa-x-ard-local', // Male voice Arabic 2
          'ar-xa-x-arz-local', // Female voice Arabic 1
          'ar-xa-x-arz-network', // Female voice Arabic 2
        ],
      };
      final preferredVoices = preferredMaleVoices[language] ?? [];
      Map? selectedVoice;

      for (final preferredVoiceName in preferredVoices) {
        selectedVoice = filtered.firstWhere(
          (voice) =>
              (voice['name'] as String?)?.toLowerCase() ==
              preferredVoiceName.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );
        if (selectedVoice.isNotEmpty && selectedVoice['name'] != null) {
          debugPrint(
            '🎤✅ [autoAssignDefaultVoice] Found preferred male voice: \\${selectedVoice['name']}',
          );
          break;
        }
        selectedVoice = null;
      }

      // Fallback to first available voice if no preferred voice found
      selectedVoice ??= filtered.isNotEmpty ? filtered.first : null;

      final name =
          selectedVoice != null ? selectedVoice['name'] as String? ?? '' : '';
      final locale =
          selectedVoice != null ? selectedVoice['locale'] as String? ?? '' : '';
      final friendlyName = getFriendlyVoiceName(language, name);
      debugPrint(
        '🎵🔊 [autoAssignDefaultVoice] → Asignada: name="$name" ($friendlyName), locale="$locale" para $language',
      );
      if (name.isNotEmpty && locale.isNotEmpty) {
        await saveVoice(language, name, locale);
        debugPrint(
          '✅🎙️ [autoAssignDefaultVoice] Default voice saved successfully for $language: $friendlyName',
        );
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
    String language,
    String voiceName,
    String locale,
  ) async {
    try {
      // ✅ VALIDATION: Don't save empty or invalid voice names
      if (voiceName.trim().isEmpty || locale.trim().isEmpty) {
        debugPrint(
          '⚠️ VoiceSettings: Attempted to save invalid voice (name: "$voiceName", locale: "$locale") for language $language. Skipping save.',
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      // Guardar tanto el nombre técnico como el amigable
      final voiceData = {
        'technical_name': voiceName,
        'locale': locale,
        'friendly_name': _getFriendlyVoiceName(voiceName, locale),
      };

      await prefs.setString('tts_voice_$language', voiceData.toString());

      // Solo aplicar la voz globalmente al TTS al guardar
      await _flutterTts.setVoice({'name': voiceName, 'locale': locale});

      debugPrint(
        '🔧🗂️ VoiceSettings: Saved & applied voice ${voiceData['friendly_name']} (${voiceData['technical_name']}) for language $language',
      );
    } catch (e) {
      debugPrint('❌ VoiceSettings: Failed to save voice: $e');
      rethrow;
    }
  }

  /// Reproduce solo el sample de voz, sin guardar ni aplicar globalmente
  Future<void> playVoiceSample(
    String voiceName,
    String locale,
    String sampleText,
  ) async {
    try {
      // ✅ VALIDATION: Prevent null voice crashes (Crashlytics fix)
      if (voiceName.trim().isEmpty || locale.trim().isEmpty) {
        debugPrint(
          '⚠️ VoiceSettings: Cannot play sample with invalid voice (name: "$voiceName", locale: "$locale"). Skipping.',
        );
        return;
      }

      // CRITICAL: Use dedicated sample TTS instance to prevent interference
      // with main playback and avoid triggering the mini-player modal
      await _sampleTts.stop();

      // ✅ Additional safety: Wrap setVoice in try-catch to handle native crashes
      try {
        await _sampleTts.setVoice({'name': voiceName, 'locale': locale});
      } catch (e) {
        debugPrint(
          '⚠️ VoiceSettings: Failed to set voice for sample (name: "$voiceName", locale: "$locale"): $e. Voice may not be available.',
        );
        // Don't return - try to play with default voice
      }

      // Siempre aplicar rate 1.0 para samples (voz natural)
      await _sampleTts.setSpeechRate(0.6);
      await _sampleTts.speak(sampleText);
      debugPrint(
        '🔊🔬 VoiceSettings: Played sample for $voiceName ($locale) using dedicated TTS instance',
      );
    } catch (e) {
      debugPrint('❌ VoiceSettings: Failed to play sample: $e');
    }
  }

  /// Stops any playing voice sample
  Future<void> stopVoiceSample() async {
    try {
      // Use dedicated sample TTS instance
      await _sampleTts.stop();
      debugPrint('🛑 VoiceSettings: Stopped voice sample');
    } catch (e) {
      debugPrint('❌ VoiceSettings: Failed to stop sample: $e');
    }
  }

  /// Guarda la voz seleccionada en SharedPreferences y muestra debugPrint
  Future<void> saveVoiceWithDebug(
    String language,
    String name,
    String locale,
  ) async {
    debugPrint(
      '🔊 Voz seleccionada: name=$name, locale=$locale, language=$language',
    );
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

        // --- VALIDATION: Detect invalid saved voices for ALL languages ---
        if (voiceName.trim().isEmpty || locale.trim().isEmpty) {
          debugPrint(
            '⚠️ [VoiceSettings] Invalid saved voice detected for $language (name: "$voiceName", locale: "$locale"). Clearing and re-assigning.',
          );
          await clearSavedVoice(language);
          await autoAssignDefaultVoice(language);
          return await loadSavedVoice(language); // Try again after fix
        }

        // Additional validation for Chinese to ensure correct locale
        if (language == 'zh' && !locale.toLowerCase().startsWith('zh')) {
          debugPrint(
            '⚠️ [VoiceSettings] Invalid locale for zh detected (locale: "$locale"). Clearing and re-assigning.',
          );
          await clearSavedVoice(language);
          await autoAssignDefaultVoice(language);
          return await loadSavedVoice(language); // Try again after fix
        }

        // Additional validation for Arabic: ar-xa-x-* voices use locale 'ar', not 'ar-SA'
        if (language == 'ar' &&
            !locale.toLowerCase().startsWith('ar-xa') &&
            locale != 'ar') {
          debugPrint(
            '⚠️ [VoiceSettings] Invalid locale for ar detected (locale: "$locale"). Clearing and re-assigning.',
          );
          await clearSavedVoice(language);
          await autoAssignDefaultVoice(language);
          return await loadSavedVoice(language); // Try again after fix
        }
        // --- END VALIDATION ---

        // Aplicar la voz al TTS
        await _flutterTts.setVoice({'name': voiceName, 'locale': locale});

        debugPrint(
          '🔧 VoiceSettings: Loaded saved voice $voiceName for language $language (locale: $locale)',
        );
        return _getFriendlyVoiceName(voiceName, locale);
      }
    } catch (e) {
      debugPrint('⚠️ VoiceSettings: Failed to load saved voice: $e');
    }

    return null;
  }

  /// Applies the saved voice for [language] directly to the given [ttsInstance].
  ///
  /// This is the critical method that ensures the correct voice is set on the
  /// [TtsAudioController]'s own FlutterTts instance before calling speak().
  /// Without this, the controller speaks with the default system voice regardless
  /// of user voice selection (the voice was previously only applied to the
  /// VoiceSettingsService's own internal FlutterTts instance).
  Future<void> applyVoiceToInstance(
      FlutterTts ttsInstance, String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVoice = prefs.getString('tts_voice_$language');

      if (savedVoice == null) {
        debugPrint(
          '⚠️ VoiceSettings: No saved voice for $language, skipping applyVoiceToInstance',
        );
        return;
      }

      String voiceName, locale;
      if (savedVoice.contains('technical_name')) {
        final parts = savedVoice.split(', ');
        voiceName = parts
            .firstWhere((p) => p.contains('technical_name'))
            .split(': ')[1];
        locale = parts.firstWhere((p) => p.contains('locale')).split(': ')[1];
        // Strip trailing '}' if present
        locale = locale.replaceAll('}', '').trim();
        voiceName = voiceName.trim();
      } else {
        final voiceParts = savedVoice.split(' (');
        voiceName = voiceParts[0].trim();
        locale = voiceParts.length > 1
            ? voiceParts[1].replaceAll(')', '').trim()
            : _getDefaultLocaleForLanguage(language);
      }

      if (voiceName.isEmpty || locale.isEmpty) {
        debugPrint(
          '⚠️ VoiceSettings: Invalid voice data for $language in applyVoiceToInstance (name: "$voiceName", locale: "$locale")',
        );
        return;
      }

      // CRITICAL: setLanguage() MUST be called before setVoice() to ensure the
      // TTS engine loads the correct language module. Without this, speak() can
      // hang indefinitely on non-system languages (e.g. Arabic on a Spanish device)
      // because the engine never fires onStart/onError callbacks.
      final langResult = await ttsInstance.setLanguage(locale);
      debugPrint(
        '🌐 [VoiceSettings] setLanguage("$locale") → result: $langResult (language: $language)',
      );

      final voiceResult =
          await ttsInstance.setVoice({'name': voiceName, 'locale': locale});
      debugPrint(
        '🎙️ VoiceSettings: setVoice result: $voiceResult — applied "$voiceName" (locale: $locale) to controller FlutterTts for language $language',
      );
    } catch (e) {
      debugPrint(
        '⚠️ VoiceSettings: Failed to applyVoiceToInstance for $language: $e',
      );
    }
  }

  /// ✅ METODO PRINCIPAL MEJORADO PARA NOMBRES USER-FRIENDLY
  String _getFriendlyVoiceName(String technicalName, String locale) {
    // 1. Verificar mapeo amigable con emoji y nombre
    final language = locale.split('-').first;
    final map = friendlyVoiceMap[language];
    if (map != null && map.containsKey(technicalName)) {
      return map[technicalName] ?? technicalName;
    }

    // 2. Verificar patrones complejos
    for (final pattern in _voicePatternMappings.keys) {
      if (pattern.hasMatch(technicalName)) {
        final match = pattern.firstMatch(technicalName);
        String baseName = _voicePatternMappings[pattern] ?? '';

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
    friendlyName = friendlyName.replaceAll(
      RegExp(r'^com\.apple\.ttsbundle\.'),
      '',
    );
    friendlyName = friendlyName.replaceAll(
      RegExp(r'^com\.apple\.speech\.synthesis\.voice\.'),
      '',
    );
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
        case 'zh':
          friendlyName = '默认语音';
          break;
        case 'hi':
          friendlyName = 'डिफ़ॉल्ट आवाज़';
          break;
        case 'de':
          friendlyName = 'Standardstimme';
          break;
        case 'ar':
          friendlyName = 'الصوت الافتراضي';
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
      case String s when s.startsWith('zh'):
        return gender == 'female' ? '女性声音$num' : '男性声音$num';
      case String s when s.startsWith('hi'):
        return gender == 'female' ? 'महिला आवाज़$num' : 'पुरुष आवाज़$num';
      case String s when s.startsWith('de'):
        return gender == 'female'
            ? 'Weibliche Stimme$num'
            : 'Männliche Stimme$num';
      case String s when s.startsWith('ar'):
        return gender == 'female' ? 'صوت أنثى$num' : 'صوت ذكر$num';
      default:
        return gender == 'female' ? 'Female Voice$num' : 'Male Voice$num';
    }
  }

  /// Metodo proactivo para inicializar el TTS con la voz correcta al iniciar la app o cambiar idioma
  Future<void> proactiveAssignVoiceOnInit(String language) async {
    debugPrint(
      '🔄 [proactiveAssignVoiceOnInit] Inicializando TTS para idioma: $language',
    );
    final friendlyName = await loadSavedVoice(language);
    if (friendlyName == null) {
      debugPrint(
        '🔄 [proactiveAssignVoiceOnInit] No hay voz guardada válida, asignando automáticamente...',
      );
      await autoAssignDefaultVoice(language);
      final newFriendlyName = await loadSavedVoice(language);
      debugPrint(
        '🔄 [proactiveAssignVoiceOnInit] Voz asignada: $newFriendlyName',
      );
    } else {
      debugPrint(
        '🔄 [proactiveAssignVoiceOnInit] Voz guardada aplicada: $friendlyName',
      );
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
        List<dynamic> filteredVoices;
        if (language == 'zh') {
          // Para chino, mostrar todas las voces técnicas disponibles
          filteredVoices = rawVoices;
        } else {
          filteredVoices = rawVoices.where((voice) {
            if (voice is Map) {
              final locale = voice['locale'] as String? ?? '';
              return locale.toLowerCase().startsWith(
                    targetLocale.toLowerCase(),
                  );
            }
            return false;
          }).toList();
        }

        final formattedVoices = filteredVoices.map((voice) {
          final name = voice['name'] as String? ?? '';
          final locale = voice['locale'] as String? ?? '';
          final friendlyName = _getFriendlyVoiceName(name, locale);
          // Para zh, mostrar el nombre técnico y el locale para fácil identificación
          if (language == 'zh') {
            return '$name ($locale)';
          }
          return '$friendlyName ($locale)';
        }).toList();

        // Ordenar por nombre técnico para zh, por nombre amigable para otros
        formattedVoices.sort();
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
    String language,
  ) async {
    final voices = await _flutterTts.getVoices;
    if (voices is List) {
      if (language == 'zh') {
        // Para chino, mostrar todas las voces técnicas disponibles
        return voices.cast<Map>().map((voice) {
          return {
            'name': voice['name'] as String? ?? '',
            'locale': voice['locale'] as String? ?? '',
          };
        }).toList();
      }
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
      case 'zh':
        return 'zh-CN';
      case 'de':
        return 'de-DE';
      case 'hi':
        return 'hi-IN';
      case 'ar':
        return 'ar';
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
        '🗑️ VoiceSettings: Cleared saved voice for language $language',
      );
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
    final flag = prefs.getBool('tts_voice_user_saved_$language') ?? false;
    debugPrint('🔊 VoiceSettings: hasUserSavedVoice($language): $flag');
    return flag;
  }

  /// Marca que el usuario guardó su voz personalizada
  Future<void> setUserSavedVoice(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_voice_user_saved_$language', true);
    debugPrint('🔧 VoiceSettings: setUserSavedVoice($language): true');
  }

  /// Borra el flag de voz guardada por el usuario
  Future<void> clearUserSavedVoiceFlag(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tts_voice_user_saved_$language');
    debugPrint('🔧 VoiceSettings: clearUserSavedVoiceFlag($language): removed');
  }

  /// Obtiene la velocidad de reproducción TTS guardada (settings-scale 0.1..1.0)
  Future<double> getSavedSpeechRate() async {
    final prefs = await SharedPreferences.getInstance();
    final stored =
        prefs.getDouble('tts_rate') ?? 0.5; // settings-scale (0.1..1.0)
    return stored;
  }

  /// Devuelve la velocidad del miniplayer (display) basada en el valor guardado
  Future<double> getSavedMiniRate() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getDouble('tts_rate') ?? 0.5;
    return settingsToMini[stored] ?? getMiniPlayerRate(stored);
  }

  /// Guarda la velocidad en settings-scale (0.1..1.0). Si se pasa un mini-rate,
  /// se convierte y persiste en escala de settings.
  Future<void> setSavedSpeechRate(double rate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      double toStore;
      if (miniToSettings.containsKey(rate)) {
        toStore = miniToSettings[rate] ?? 0.5;
      } else if (rate >= 0.1 && rate <= 1.0) {
        toStore = rate;
      } else {
        // Fallback: clamp to sensible default
        toStore = 0.5;
      }
      await prefs.setDouble('tts_rate', toStore);
      debugPrint(
        '🔧 VoiceSettings: Saved speech rate (settings-scale) = $toStore',
      );
    } catch (e) {
      debugPrint('❌ VoiceSettings: Failed to save speech rate: $e');
    }
  }

  /// Lista de velocidades permitidas (homologadas para settings y miniplayer)
  static const List<double> allowedPlaybackRates = [
    0.5,
    1.0,
    1.5,
  ]; // 0.5x, 1.0x, 1.5x (was 2.0x)

  /// Rota la velocidad de reproducción (entre allowedPlaybackRates), la guarda y la aplica al TTS.
  /// Devuelve el nuevo playbackRate aplicado.
  Future<double> cyclePlaybackRate({
    double? currentMiniRate,
    FlutterTts? ttsOverride,
  }) async {
    final rates = miniPlayerRates;
    final current = (currentMiniRate ?? await getSavedMiniRate());

    int idx = rates.indexWhere((r) => (r - current).abs() < 0.001);
    if (idx == -1) idx = 0;
    final nextMini = rates[(idx + 1) % rates.length];
    final settingsValue = getSettingsRateForMini(nextMini);

    // Persistir settings-scale
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_rate', settingsValue);

    // Aplicar al motor (usar settings-scale, que es lo que esperan los motores históricamente)
    final tts = ttsOverride ?? _flutterTts;
    try {
      await tts.setSpeechRate(settingsValue);
    } catch (e) {
      debugPrint(
        'VoiceSettingsService: Failed to set speech rate on engine: $e',
      );
    }

    debugPrint(
      '🔄 VoiceSettingsService: cyclePlaybackRate -> nextMini=$nextMini settings=$settingsValue',
    );
    return nextMini;
  }

  /// Devuelve la lista de rates permitidos para el miniplayer (homologados)
  static const List<double> miniPlayerRates = [
    0.5,
    1.0,
    1.5,
  ]; // 0.5x, 1.0x, 1.5x (was 2.0x)
  static final Map<double, double> miniToSettings = {
    0.5: 0.25, // 0.5x → 25%
    1.0: 0.5, // 1.0x → 50%
    1.5: 0.75, // 1.5x → 75% (was 2.0: 1.0)
  };
  static final Map<double, double> settingsToMini = {
    0.25: 0.5,
    0.5: 1.0,
    0.75: 1.5,
  };

  /// Dado un rate de settings, devuelve el rate homologado del miniplayer
  double getMiniPlayerRate(double settingsRate) {
    if (settingsToMini.containsKey(settingsRate)) {
      return settingsToMini[settingsRate] ?? 1.0;
    }
    if ((settingsRate - 0.25).abs() < 0.08) return 0.5;
    if ((settingsRate - 0.5).abs() < 0.12) return 1.0;
    if ((settingsRate - 0.75).abs() < 0.12) return 1.5;
    // Por defecto, 1.0x
    return 1.0;
  }

  /// Devuelve el siguiente rate del miniplayer, ciclando
  double getNextMiniPlayerRate(double currentMiniRate) {
    final idx = miniPlayerRates.indexOf(currentMiniRate);
    if (idx == -1) return 1.0;
    return miniPlayerRates[(idx + 1) % miniPlayerRates.length];
  }

  /// Dado un rate del miniplayer, devuelve el valor equivalente para settings
  double getSettingsRateForMini(double miniRate) {
    return miniToSettings[miniRate] ?? 0.5;
  }

  // Mapeo amigable de voces con emoji y nombre
  static const Map<String, Map<String, String>> friendlyVoiceMap = {
    'es': {
      'es-us-x-esd-local': '🇲🇽 Hombre Latinoamérica',
      'es-us-x-esd-network': '🇲🇽 Hombre Latinoamérica',
      'es-US-language': '🇲🇽 Mujer Latinoamérica',
      'es-es-x-eed-local': '🇪🇸 Hombre España',
      'es-ES-language': '🇪🇸 Mujer España',
    },
    'en': {
      'en-us-x-tpd-network': '🇺🇸 Male United States',
      'en-us-x-tpd-local': '🇺🇸 Male United States',
      'en-us-x-tpf-local': '🇺🇸 Female United States',
      'en-us-x-iom-network': '🇺🇸 Male United States',
      'en-gb-x-gbb-local': '🇬🇧 Male United Kingdom',
      'en-GB-language': '🇬🇧 Female United Kingdom',
    },
    'pt': {
      'pt-br-x-ptd-network': '🇧🇷 Homem Brasil',
      'pt-br-x-ptd-local': '🇧🇷 Homem Brasil',
      'pt-br-x-afs-network': '🇧🇷 Mulher Brasil',
      'pt-pt-x-pmj-local': '🇵🇹 Homem Portugal',
      'pt-PT-language': '🇵🇹 Mulher Portugal',
    },
    'fr': {
      'fr-fr-x-frd-local': '🇫🇷 Homme France',
      'fr-fr-x-frd-network': '🇫🇷 Homme France',
      'fr-fr-x-vlf-local': '🇫🇷 Homme France',
      'fr-fr-x-frf-local': '🇫🇷 Femme France',
      'fr-ca-x-cad-local': '🇨🇦 Homme Canada',
      'fr-ca-x-caf-local': '🇨🇦 Femme Canada',
    },
    'ja': {
      'ja-jp-x-jac-local': '🇯🇵 男性 声 1',
      'ja-jp-x-jac-network': '🇯🇵 男性 声 1',
      'ja-jp-x-jab-local': '🇯🇵 女性 声 1',
      'ja-jp-x-jad-local': '🇯🇵 男性 声 2',
      'ja-jp-x-htm-local': '🇯🇵 女性 声 2',
    },
    'zh': {
      'cmn-cn-x-cce-local': '🇨🇳 男性 声 1', // Hombre (China)
      'cmn-cn-x-ccc-local': '🇨🇳 女性 声 1', // Mujer (China)
      'cmn-tw-x-cte-network': '🇹🇼 男性 声 2', // Hombre 2 (Taiwán)
      'cmn-tw-x-ctc-network': '🇹🇼 女性 声 2', // Mujer 2 (Taiwán)
    },
    'ar': {
      'ar-xa-x-are-local': '🇸🇦 رجل صوت 1', // Male Arabic 1
      'ar-xa-x-are-network': '🇸🇦 رجل صوت 1', // Male Arabic 1 network
      'ar-xa-x-ard-local': '🇸🇦 رجل صوت 2', // Male Arabic 2
      'ar-xa-x-ard-network': '🇸🇦 رجل صوت 2', // Male Arabic 2 network
      'ar-xa-x-arz-local': '🇸🇦 امرأة صوت 1', // Female Arabic 1
      'ar-xa-x-arz-network': '🇸🇦 امرأة صوت 1', // Female Arabic 1 network
    },
  };

  /// Nuevo metodo para obtener nombre amigable con emoji
  String getFriendlyVoiceName(String language, String technicalName) {
    final map = friendlyVoiceMap[language];
    if (map != null && map.containsKey(technicalName)) {
      return map[technicalName] ?? technicalName;
    }
    return technicalName;
  }
}
