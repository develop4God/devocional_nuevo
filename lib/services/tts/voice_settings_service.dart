import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Voice Settings Service - Manages TTS voice selection and preferences.
class VoiceSettingsService {
  VoiceSettingsService();

  @visibleForTesting
  VoiceSettingsService.withTts(FlutterTts tts) : _flutterTtsInstance = tts;

  @visibleForTesting
  VoiceSettingsService.withBothTts(FlutterTts mainTts, FlutterTts sampleTts)
      : _flutterTtsInstance = mainTts,
        _sampleTtsInstance = sampleTts;

  FlutterTts? _flutterTtsInstance;
  FlutterTts? _sampleTtsInstance;

  /// Main TTS instance with enterprise-grade configuration
  FlutterTts get _flutterTts {
    if (_flutterTtsInstance == null) {
      _flutterTtsInstance = FlutterTts();
      // Important Architectural Recommendation:
      // Ensure completion awaiting is active to reduce race conditions on start/resume
      _flutterTtsInstance!.awaitSpeakCompletion(true);
    }
    return _flutterTtsInstance!;
  }

  FlutterTts get _sampleTts {
    if (_sampleTtsInstance == null) {
      _sampleTtsInstance = FlutterTts();
      _sampleTtsInstance!.awaitSpeakCompletion(true);
      debugPrint(
          '🔊 VoiceSettings: Created dedicated TTS instance for samples');
    }
    return _sampleTtsInstance!;
  }

  /// SURGICAL FIX: Verifies system voices before calling native setVoice.
  /// Prevents NPE in FlutterTtsPlugin.kt:515 on devices with broken TTS engines.
  Future<void> _applyVoiceSafely(
      FlutterTts tts, String name, String locale) async {
    if (name.isEmpty) return;

    try {
      // Fetch available voices from the system
      final dynamic voices = await tts.getVoices;

      // CRITICAL SHIELD: If system returns null or empty, abort to prevent native crash
      if (voices == null || voices is! List || voices.isEmpty) {
        debugPrint(
            '⚠️ [TTS Shield] No voices available in system. Skipping setVoice.');
        return;
      }

      // ENTERPRISE-GRADE VALIDATION: Match both Name and Locale
      // Prevents iterator mismatches on engines that reuse voice names
      final bool exists = voices.any((v) =>
          v is Map &&
          v['name'] == name &&
          (locale.isEmpty || v['locale'] == locale));

      if (exists) {
        await tts.setVoice({'name': name, 'locale': locale});
        debugPrint('✅ [TTS Shield] Voice set safely: $name ($locale)');
      } else {
        debugPrint(
            '⚠️ [TTS Shield] Voice "$name" with locale "$locale" not found in system list.');
      }
    } catch (e) {
      debugPrint('❌ [TTS Shield] Validation error: $e');
    }
  }

  Future<void> autoAssignDefaultVoice(String language) async {
    final hasVoice = await hasSavedVoice(language);
    if (hasVoice) return;

    final Map<String, List<String>> preferredLocales = {
      'es': ['es-US', 'es-MX', 'es-ES'],
      'en': ['en-US', 'en-GB', 'en-AU'],
      'pt': ['pt-BR', 'pt-PT'],
      'fr': ['fr-FR', 'fr-CA'],
      'ja': ['ja-JP'],
      'zh': ['zh-CN', 'zh-TW', 'yue-HK'],
    };
    final locales = preferredLocales[language] ?? [language];

    final dynamic voices = await _flutterTts.getVoices;
    if (voices is List) {
      final filtered = voices
          .cast<Map>()
          .where((voice) =>
              locales.any((loc) =>
                  (voice['locale'] as String?)?.toLowerCase() ==
                  loc.toLowerCase()) &&
              (voice['name'] as String?) != null &&
              (voice['name'] as String).trim().isNotEmpty)
          .toList();

      if (filtered.isEmpty) return;

      final preferredMaleVoices = {
        'es': ['es-us-x-esd-local', 'es-us-x-esd-network'],
        'en': [
          'en-us-x-tpd-network',
          'en-us-x-tpd-local',
          'en-us-x-iom-network'
        ],
        'pt': ['pt-br-x-ptd-network', 'pt-br-x-ptd-local'],
        'fr': ['fr-fr-x-frd-local', 'fr-fr-x-frd-network', 'fr-fr-x-vlf-local'],
        'ja': ['ja-jp-x-jac-local', 'ja-jp-x-jad-local', 'ja-jp-x-jac-network'],
        'zh': ['cmn-cn-x-cce-local', 'cmn-cn-x-ccc-local'],
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
        if (selectedVoice.isNotEmpty && selectedVoice['name'] != null) break;
        selectedVoice = null;
      }

      selectedVoice ??= filtered.isNotEmpty ? filtered.first : null;

      final name =
          selectedVoice != null ? selectedVoice['name'] as String? ?? '' : '';
      final locale =
          selectedVoice != null ? selectedVoice['locale'] as String? ?? '' : '';

      if (name.isNotEmpty && locale.isNotEmpty) {
        await saveVoice(language, name, locale);
      }
    }
  }

  static final Map<RegExp, String> _voicePatternMappings = {
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
    RegExp(r'pt-pt-x-[a-z]+#female_(\d+)-local'): 'Voz Femenina Portuguesa',
    RegExp(r'pt-pt-x-[a-z]+#male_(\d+)-local'): 'Voz Masculina Portuguesa',
    RegExp(r'fr-fr-x-[a-z]+#female_(\d+)-local'): 'Voix Féminine Française',
    RegExp(r'fr-fr-x-[a-z]+#male_(\d+)-local'): 'Voix Masculine Française',
    RegExp(r'fr-ca-x-[a-z]+#female_(\d+)-local'): 'Voix Féminine Canadienne',
    RegExp(r'fr-ca-x-[a-z]+#male_(\d+)-local'): 'Voix Masculine Canadienne',
  };

  Future<void> saveVoice(
      String language, String voiceName, String locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final voiceData = {
        'technical_name': voiceName,
        'locale': locale,
        'friendly_name': _getFriendlyVoiceName(voiceName, locale),
      };

      await prefs.setString('tts_voice_$language', voiceData.toString());

      // Use safe dispatcher
      await _applyVoiceSafely(_flutterTts, voiceName, locale);

      debugPrint(
          '🔧 VoiceSettings: Saved & applied voice ${voiceData['friendly_name']} for $language');
    } catch (e) {
      debugPrint('❌ VoiceSettings: Failed to save voice: $e');
      rethrow;
    }
  }

  Future<void> playVoiceSample(
      String voiceName, String locale, String sampleText) async {
    try {
      await _sampleTts.stop();
      // Use safe dispatcher
      await _applyVoiceSafely(_sampleTts, voiceName, locale);
      await _sampleTts.setSpeechRate(0.6);
      await _sampleTts.speak(sampleText);
    } catch (e) {
      debugPrint('❌ VoiceSettings: Failed to play sample: $e');
    }
  }

  Future<void> stopVoiceSample() async {
    try {
      await _sampleTts.stop();
    } catch (e) {
      debugPrint('❌ VoiceSettings: Failed to stop sample: $e');
    }
  }

  Future<String?> loadSavedVoice(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVoice = prefs.getString('tts_voice_$language');

      if (savedVoice != null) {
        String voiceName, locale;
        if (savedVoice.contains('technical_name')) {
          final parts = savedVoice.split(', ');
          voiceName = parts
              .firstWhere((p) => p.contains('technical_name'))
              .split(': ')[1];
          locale = parts.firstWhere((p) => p.contains('locale')).split(': ')[1];
        } else {
          final voiceParts = savedVoice.split(' (');
          voiceName = voiceParts[0];
          locale = voiceParts.length > 1
              ? voiceParts[1].replaceAll(')', '')
              : _getDefaultLocaleForLanguage(language);
        }

        if (language == 'zh' &&
            (voiceName.trim().isEmpty ||
                !locale.toLowerCase().startsWith('zh'))) {
          await clearSavedVoice(language);
          await autoAssignDefaultVoice(language);
          return await loadSavedVoice(language);
        }

        // Use safe dispatcher when loading as well
        await _applyVoiceSafely(_flutterTts, voiceName, locale);

        return _getFriendlyVoiceName(voiceName, locale);
      }
    } catch (e) {
      debugPrint('⚠️ VoiceSettings: Failed to load saved voice: $e');
    }
    return null;
  }

  String _getFriendlyVoiceName(String technicalName, String locale) {
    final language = locale.split('-').first;
    final map = friendlyVoiceMap[language];
    if (map != null && map.containsKey(technicalName))
      return map[technicalName]!;

    for (final pattern in _voicePatternMappings.keys) {
      if (pattern.hasMatch(technicalName)) {
        final match = pattern.firstMatch(technicalName);
        String baseName = _voicePatternMappings[pattern]!;
        if (match != null && match.groupCount > 0) {
          final number = match.group(1);
          if (number != null) baseName += ' $number';
        }
        return baseName;
      }
    }
    return _processUnmappedVoiceName(technicalName, locale);
  }

  String _processUnmappedVoiceName(String voiceName, String locale) {
    String friendlyName = voiceName;
    friendlyName =
        friendlyName.replaceAll(RegExp(r'^com\.apple\.ttsbundle\.'), '');
    friendlyName = friendlyName.replaceAll(
        RegExp(r'^com\.apple\.speech\.synthesis\.voice\.'), '');
    friendlyName =
        friendlyName.replaceAll(RegExp(r'^(Microsoft|Google|Amazon)\s+'), '');
    friendlyName = friendlyName.replaceAll(
        RegExp(r'-(compact|enhanced|premium|neural|local|network)$'), '');

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

    if (friendlyName.contains('x-') ||
        friendlyName.contains('#') ||
        friendlyName.length < 3) {
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
        default:
          friendlyName = 'Default Voice';
      }
    }

    friendlyName = friendlyName
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');

    friendlyName = friendlyName
        .replaceAll(RegExp(r'\b(Voice|Tts|Speech|Synthesis)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return friendlyName.isEmpty ? 'Voz por Defecto' : friendlyName;
  }

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
      default:
        return gender == 'female' ? 'Female Voice$num' : 'Male Voice$num';
    }
  }

  Future<void> proactiveAssignVoiceOnInit(String language) async {
    final friendlyName = await loadSavedVoice(language);
    if (friendlyName == null) {
      await autoAssignDefaultVoice(language);
      await loadSavedVoice(language);
    }
  }

  Future<List<String>> getAvailableVoices() async {
    try {
      final dynamic voices = await _flutterTts.getVoices;
      if (voices is List) {
        return voices.map((voice) {
          if (voice is Map) {
            final name = voice['name'] as String? ?? '';
            final locale = voice['locale'] as String? ?? '';
            return '${_getFriendlyVoiceName(name, locale)} ($locale)';
          }
          return voice.toString();
        }).toList()
          ..sort();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getVoicesForLanguage(String language) async {
    try {
      final targetLocale = _getDefaultLocaleForLanguage(language);
      final dynamic rawVoices = await _flutterTts.getVoices;
      if (rawVoices is List) {
        List filteredVoices;
        if (language == 'zh') {
          filteredVoices = rawVoices;
        } else {
          filteredVoices = rawVoices.where((voice) {
            if (voice is Map) {
              final locale = voice['locale'] as String? ?? '';
              return locale
                  .toLowerCase()
                  .startsWith(targetLocale.toLowerCase());
            }
            return false;
          }).toList();
        }
        return filteredVoices.map((voice) {
          final name = voice['name'] as String? ?? '';
          final locale = voice['locale'] as String? ?? '';
          return language == 'zh'
              ? '$name ($locale)'
              : '${_getFriendlyVoiceName(name, locale)} ($locale)';
        }).toList()
          ..sort();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, String>>> getAvailableVoicesForLanguage(
      String language) async {
    final dynamic voices = await _flutterTts.getVoices;
    if (voices is List) {
      final list = voices.cast<Map>();
      if (language == 'zh') {
        return list
            .map((v) => {
                  'name': v['name'] as String? ?? '',
                  'locale': v['locale'] as String? ?? ''
                })
            .toList();
      }
      return list
          .where((v) =>
              (v['locale'] as String?)
                  ?.toLowerCase()
                  .contains(language.toLowerCase()) ??
              false)
          .map((v) => {
                'name': v['name'] as String? ?? '',
                'locale': v['locale'] as String? ?? ''
              })
          .toList();
    }
    return [];
  }

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
      default:
        return 'es-ES';
    }
  }

  Future<void> clearSavedVoice(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('tts_voice_$language');
    } catch (e) {
      debugPrint('VoiceSettings: Failed to clear saved voice: $e');
    }
  }

  Future<bool> hasSavedVoice(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('tts_voice_$language');
    } catch (e) {
      debugPrint('VoiceSettings: Failed to check saved voice: $e');
      return false;
    }
  }

  Future<bool> hasUserSavedVoice(String language) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tts_voice_user_saved_$language') ?? false;
  }

  Future<void> setUserSavedVoice(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_voice_user_saved_$language', true);
  }

  Future<void> clearUserSavedVoiceFlag(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tts_voice_user_saved_$language');
  }

  Future<double> getSavedSpeechRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('tts_rate') ?? 0.5;
  }

  Future<double> getSavedMiniRate() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getDouble('tts_rate') ?? 0.5;
    return settingsToMini[stored] ?? getMiniPlayerRate(stored);
  }

  Future<void> setSavedSpeechRate(double rate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      double toStore =
          miniToSettings[rate] ?? (rate >= 0.1 && rate <= 1.0 ? rate : 0.5);
      await prefs.setDouble('tts_rate', toStore);
    } catch (e) {
      debugPrint('VoiceSettings: Failed to save speech rate: $e');
    }
  }

  static const List<double> allowedPlaybackRates = [0.5, 1.0, 1.5];
  static const List<double> miniPlayerRates = [0.5, 1.0, 1.5];
  static final Map<double, double> miniToSettings = {
    0.5: 0.25,
    1.0: 0.5,
    1.5: 0.75
  };
  static final Map<double, double> settingsToMini = {
    0.25: 0.5,
    0.5: 1.0,
    0.75: 1.5
  };

  Future<double> cyclePlaybackRate(
      {double? currentMiniRate, FlutterTts? ttsOverride}) async {
    final rates = miniPlayerRates;
    final current = currentMiniRate ?? await getSavedMiniRate();
    int idx = rates.indexWhere((r) => (r - current).abs() < 0.001);
    final nextMini = rates[(idx + 1) % rates.length];
    final settingsValue = getSettingsRateForMini(nextMini);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_rate', settingsValue);

    final tts = ttsOverride ?? _flutterTts;
    try {
      await tts.setSpeechRate(settingsValue);
    } catch (e) {
      debugPrint('VoiceSettings: Failed to set speech rate on engine: $e');
    }
    return nextMini;
  }

  double getMiniPlayerRate(double settingsRate) {
    if (settingsToMini.containsKey(settingsRate))
      return settingsToMini[settingsRate]!;
    if ((settingsRate - 0.25).abs() < 0.08) return 0.5;
    if ((settingsRate - 0.5).abs() < 0.12) return 1.0;
    if ((settingsRate - 0.75).abs() < 0.12) return 1.5;
    return 1.0;
  }

  double getNextMiniPlayerRate(double currentMiniRate) {
    final idx = miniPlayerRates.indexOf(currentMiniRate);
    if (idx == -1) return 1.0;
    return miniPlayerRates[(idx + 1) % miniPlayerRates.length];
  }

  double getSettingsRateForMini(double miniRate) {
    return miniToSettings[miniRate] ?? 0.5;
  }

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
      'cmn-cn-x-cce-local': '🇨🇳 男性 声 1',
      'cmn-cn-x-ccc-local': '🇨🇳 女性 声 1',
      'cmn-tw-x-cte-network': '🇹🇼 男性 声 2',
      'cmn-tw-x-ctc-network': '🇹🇼 女性 声 2',
    },
  };

  String getFriendlyVoiceName(String language, String technicalName) {
    return (friendlyVoiceMap[language]?[technicalName]) ?? technicalName;
  }
}
