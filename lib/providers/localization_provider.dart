import 'package:flutter/material.dart';

import '../services/localization_service.dart';
import '../services/tts/voice_settings_service.dart';

/// Provider for managing app localization state
class LocalizationProvider extends ChangeNotifier {
  final LocalizationService _localizationService = LocalizationService.instance;

  Locale get currentLocale => _localizationService.currentLocale;

  List<Locale> get supportedLocales => LocalizationService.supportedLocales;

  /// Initialize localization
  Future<void> initialize() async {
    await _localizationService.initialize();
    notifyListeners();
  }

  /// Change app language
  Future<void> changeLanguage(String languageCode) async {
    final locale = Locale(languageCode);
    await _localizationService.changeLocale(locale);
    // Proactivo: asignar voz TTS al cambiar idioma
    await VoiceSettingsService().proactiveAssignVoiceOnInit(languageCode);
    notifyListeners();
  }

  /// Get translation for key
  String translate(String key, [Map<String, dynamic>? params]) {
    return _localizationService.translate(key, params);
  }

  /// Get TTS locale for current language
  String getTtsLocale() {
    return _localizationService.getTtsLocale();
  }

  /// Get language name in native format
  String getLanguageName(String languageCode) {
    return _localizationService.getLanguageName(languageCode);
  }

  /// Get all available languages with their native names
  Map<String, String> getAvailableLanguages() {
    return {
      'es': getLanguageName('es'),
      'en': getLanguageName('en'),
      'pt': getLanguageName('pt'),
      'fr': getLanguageName('fr'),
      'ja': getLanguageName('ja'),
    };
  }
}
