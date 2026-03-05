/// Registry of TTS voice metadata per language.
///
/// Follows Single Responsibility Principle: centralizes all voice data
/// (premium maps, sample texts, descriptions, emojis, gender icons) in one
/// place. The UI widget (`VoiceSelectorDialog`) only handles presentation.
///
/// Adding a new language requires a single edit to this file.
library;

import 'package:flutter/material.dart';

/// Describes a premium voice with its display metadata.
class VoiceMetadata {
  /// Country flag or regional emoji
  final String emoji;

  /// Localized description (e.g. "Male United States")
  final String description;

  /// Gender icon to show in the list
  final IconData genderIcon;

  const VoiceMetadata({
    required this.emoji,
    required this.description,
    this.genderIcon = Icons.person,
  });
}

/// Centralized registry of TTS voice data for all supported languages.
///
/// Voice data is organized by language code and voice name. This allows
/// the voice selector UI to remain thin and language-agnostic.
class VoiceDataRegistry {
  const VoiceDataRegistry._();

  // ─── Premium Voice Maps ───────────────────────────────────────────────

  /// Spanish premium voices
  static const Map<String, VoiceMetadata> spanishVoices = {
    'es-us-x-esd-local': VoiceMetadata(
      emoji: '🌎',
      description: 'Hombre Latinoamérica',
      genderIcon: Icons.man_3_outlined,
    ),
    'es-US-language': VoiceMetadata(
      emoji: '🌎',
      description: 'Mujer Latinoamérica',
      genderIcon: Icons.woman_outlined,
    ),
    'es-es-x-eed-local': VoiceMetadata(
      emoji: '🇪🇸',
      description: 'Hombre España',
      genderIcon: Icons.man_3_outlined,
    ),
    'es-ES-language': VoiceMetadata(
      emoji: '🇪🇸',
      description: 'Mujer España',
      genderIcon: Icons.woman_outlined,
    ),
  };

  /// English premium voices
  static const Map<String, VoiceMetadata> englishVoices = {
    'en-us-x-tpd-network': VoiceMetadata(
      emoji: '🇺🇸',
      description: 'Male United States',
      genderIcon: Icons.man_3_outlined,
    ),
    'en-us-x-tpf-local': VoiceMetadata(
      emoji: '🇺🇸',
      description: 'Female United States',
      genderIcon: Icons.woman_outlined,
    ),
    'en-us-x-iob-local': VoiceMetadata(
      emoji: '🇺🇸',
      description: 'Female United States',
      genderIcon: Icons.woman_outlined,
    ),
    'en-US-language': VoiceMetadata(
      emoji: '🇺🇸',
      description: 'Female United States',
      genderIcon: Icons.woman_outlined,
    ),
    'en-gb-x-gbb-local': VoiceMetadata(
      emoji: '🇬🇧',
      description: 'Male United Kingdom',
      genderIcon: Icons.man_3_outlined,
    ),
    'en-GB-language': VoiceMetadata(
      emoji: '🇬🇧',
      description: 'Female United Kingdom',
      genderIcon: Icons.woman_outlined,
    ),
  };

  /// Portuguese premium voices
  static const Map<String, VoiceMetadata> portugueseVoices = {
    'pt-br-x-ptd-network': VoiceMetadata(
      emoji: '🇧🇷',
      description: 'Homem Brasil',
      genderIcon: Icons.man_3_outlined,
    ),
    'pt-br-x-afs-network': VoiceMetadata(
      emoji: '🇧🇷',
      description: 'Mulher Brasil',
      genderIcon: Icons.woman_outlined,
    ),
    'pt-pt-x-pmj-local': VoiceMetadata(
      emoji: '🇵🇹',
      description: 'Homem Portugal',
      genderIcon: Icons.man_3_outlined,
    ),
    'pt-PT-language': VoiceMetadata(
      emoji: '🇵🇹',
      description: 'Mulher Portugal',
      genderIcon: Icons.woman_outlined,
    ),
  };

  /// Japanese premium voices
  static const Map<String, VoiceMetadata> japaneseVoices = {
    'ja-jp-x-jac-local': VoiceMetadata(
      emoji: '🇯🇵',
      description: '男性 声 1',
      genderIcon: Icons.man_3_outlined,
    ),
    'ja-jp-x-jad-local': VoiceMetadata(
      emoji: '🇯🇵',
      description: '男性 声 2',
      genderIcon: Icons.man_3_outlined,
    ),
    'ja-jp-x-jab-local': VoiceMetadata(
      emoji: '🇯🇵',
      description: '女性 声 1',
      genderIcon: Icons.woman_outlined,
    ),
    'ja-jp-x-htm-local': VoiceMetadata(
      emoji: '🇯🇵',
      description: '女性 声 2',
      genderIcon: Icons.woman_outlined,
    ),
  };

  /// French premium voices
  static const Map<String, VoiceMetadata> frenchVoices = {
    'fr-fr-x-frd-network': VoiceMetadata(
      emoji: '🇫🇷',
      description: 'Homme France',
      genderIcon: Icons.man_3_outlined,
    ),
    'fr-FR-language': VoiceMetadata(
      emoji: '🇫🇷',
      description: 'Femme France',
      genderIcon: Icons.woman_outlined,
    ),
    'fr-ca-x-cab-network': VoiceMetadata(
      emoji: '🇨🇦',
      description: 'Homme Canada',
      genderIcon: Icons.man_3_outlined,
    ),
    'fr-CA-language': VoiceMetadata(
      emoji: '🇨🇦',
      description: 'Femme Canada',
      genderIcon: Icons.woman_outlined,
    ),
  };

  /// Chinese premium voices
  static const Map<String, VoiceMetadata> chineseVoices = {
    'cmn-cn-x-cce-local': VoiceMetadata(
      emoji: '🇨🇳',
      description: '男性 声 1',
      genderIcon: Icons.man_3_outlined,
    ),
    'cmn-cn-x-ccc-local': VoiceMetadata(
      emoji: '🇨🇳',
      description: '女性 声 1',
      genderIcon: Icons.woman_outlined,
    ),
    'cmn-tw-x-cte-network': VoiceMetadata(
      emoji: '🇹🇼',
      description: '男性 声 2',
      genderIcon: Icons.man_3_outlined,
    ),
    'cmn-tw-x-ctc-network': VoiceMetadata(
      emoji: '🇹🇼',
      description: '女性 声 2',
      genderIcon: Icons.woman_outlined,
    ),
  };

  /// Hindi premium voices
  static const Map<String, VoiceMetadata> hindiVoices = {
    'hi-in-x-hid-local': VoiceMetadata(
      emoji: '🇮🇳',
      description: 'पुरुष भारत',
      genderIcon: Icons.man_3_outlined,
    ),
    'hi-in-x-hia-local': VoiceMetadata(
      emoji: '🇮🇳',
      description: 'महिला भारत',
      genderIcon: Icons.woman_outlined,
    ),
    'hi-in-x-hic-local': VoiceMetadata(
      emoji: '🇮🇳',
      description: 'पुरुष भारत 2',
      genderIcon: Icons.man_3_outlined,
    ),
    'hi-IN-language': VoiceMetadata(
      emoji: '🇮🇳',
      description: 'महिला भारत 2',
      genderIcon: Icons.woman_outlined,
    ),
  };

  // ─── Language → Voice Map Lookup ──────────────────────────────────────

  /// All premium voice maps indexed by language code.
  static const Map<String, Map<String, VoiceMetadata>> _voicesByLanguage = {
    'es': spanishVoices,
    'en': englishVoices,
    'pt': portugueseVoices,
    'ja': japaneseVoices,
    'fr': frenchVoices,
    'zh': chineseVoices,
    'hi': hindiVoices,
  };

  /// Returns the premium voice map for [language], or `null` if none exists.
  static Map<String, VoiceMetadata>? getVoiceMap(String language) {
    return _voicesByLanguage[language];
  }

  /// Whether [voiceName] is a premium voice for [language].
  static bool isPremiumVoice(String voiceName, String language) {
    return _voicesByLanguage[language]?.containsKey(voiceName) ?? false;
  }

  /// Get metadata for a specific premium voice.
  static VoiceMetadata? getVoiceMetadata(String voiceName, String language) {
    return _voicesByLanguage[language]?[voiceName];
  }

  // ─── Sample Text ──────────────────────────────────────────────────────

  /// Localized sample text for voice preview by language code.
  static const Map<String, String> sampleTexts = {
    'es': 'Puede guardar esta voz o seleccionar otra, de su preferencia',
    'en': 'You can save this voice or select another, as you prefer',
    'pt': 'Você pode salvar esta voz ou selecionar outra, de sua preferência',
    'fr':
        'Vous pouvez enregistrer cette voix ou en choisir une autre, selon votre préférence',
    'ja': 'この声を保存するか、別の声を選択することができます。お好みに合わせて',
    'zh': '您可以保存此语音或选择其他语音，按您的喜好',
    'hi':
        'आप इस आवाज़ को सहेज सकते हैं या अपनी पसंद के अनुसार दूसरी आवाज़ चुन सकते हैं',
  };

  /// Returns the localized sample text for [language], defaulting to Spanish.
  static String getSampleText(String language) {
    return sampleTexts[language] ?? sampleTexts['es']!;
  }

  // ─── Priority Locales ─────────────────────────────────────────────────

  /// Priority locales for fallback voice grouping per language.
  static const Map<String, List<String>> priorityLocales = {
    'es': ['es-ES', 'es-MX', 'es-US', 'es-AR'],
    'en': ['en-US', 'en-GB', 'en-AU', 'en-CA'],
    'pt': ['pt-BR', 'pt-PT'],
    'fr': ['fr-FR', 'fr-CA'],
    'ja': ['ja-JP'],
    'zh': ['zh-CN', 'zh-TW'],
    'hi': ['hi-IN'],
  };

  /// Returns the priority locales for [language].
  static List<String> getPriorityLocales(String language) {
    return priorityLocales[language] ?? [];
  }

  // ─── Supported Languages ──────────────────────────────────────────────

  /// All languages with premium voice support.
  static final List<String> supportedLanguages =
      _voicesByLanguage.keys.toList();
}
