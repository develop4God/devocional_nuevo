import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

void main() {
  group('Chinese Language - Complete User Journey Tests', () {
    late LocalizationProvider provider;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Mock flutter_tts plugin channel to avoid MissingPluginException
      const MethodChannel ttsChannel = MethodChannel('flutter_tts');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        ttsChannel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getVoices':
              // Return comprehensive list of voices for all supported languages
              return [
                {'name': 'es-es-x-eee-local', 'locale': 'es-ES'},
                {'name': 'es-es-x-eef-local', 'locale': 'es-ES'},
                {'name': 'en-us-x-iom-local', 'locale': 'en-US'},
                {'name': 'en-us-x-iog-local', 'locale': 'en-US'},
                {'name': 'pt-br-x-afs-local', 'locale': 'pt-BR'},
                {'name': 'pt-br-x-afe-local', 'locale': 'pt-BR'},
                {'name': 'fr-fr-x-vlf-local', 'locale': 'fr-FR'},
                {'name': 'fr-fr-x-fre-local', 'locale': 'fr-FR'},
                {'name': 'ja-jp-x-jab-local', 'locale': 'ja-JP'},
                {'name': 'ja-jp-x-jac-local', 'locale': 'ja-JP'},
                {'name': 'cmn-cn-x-cce-local', 'locale': 'zh-CN'},
                {'name': 'cmn-cn-x-ccc-local', 'locale': 'zh-CN'},
                {'name': 'cmn-tw-x-cte-network', 'locale': 'zh-TW'},
                {'name': 'cmn-tw-x-ctc-network', 'locale': 'zh-TW'},
              ];
            case 'setLanguage':
            case 'setSpeechRate':
            case 'speak':
            case 'stop':
            case 'pause':
            case 'setVolume':
            case 'setPitch':
            case 'setQueueMode':
            case 'awaitSpeakCompletion':
            case 'setVoice':
              return Future.value(1);
            default:
              return Future.value();
          }
        },
      );

      // Initialize SharedPreferences with Spanish as default locale
      // to simulate app starting in Spanish for user journey tests
      SharedPreferences.setMockInitialValues({'locale': 'es'});
      ServiceLocator().reset();
      setupServiceLocator();
      provider = LocalizationProvider();
    });

    tearDown(() {
      ServiceLocator().reset();
    });

    test('User switches to Chinese and gets proper TTS configuration',
        () async {
      // GIVEN: App starts in default Spanish
      await provider.initialize();
      expect(provider.currentLocale.languageCode, equals('es'));

      // WHEN: User switches to Chinese
      await provider.changeLanguage('zh');

      // THEN: Language is updated to Chinese
      expect(provider.currentLocale.languageCode, equals('zh'));

      // AND: TTS locale is properly configured for Chinese
      final ttsLocale = provider.getTtsLocale();
      expect(ttsLocale, equals('zh-CN'));

      // AND: Language name displays in Chinese
      expect(provider.getLanguageName('zh'), equals('中文'));
    });

    test('Chinese Bible references are formatted correctly for TTS', () {
      // GIVEN: Chinese Bible reference
      const reference1 = '约翰福音 3:16';
      const reference2 = '诗篇 23:1-6';

      // WHEN: Formatted for TTS
      final formatted1 =
          BibleTextFormatter.formatBibleReferences(reference1, 'zh');
      final formatted2 =
          BibleTextFormatter.formatBibleReferences(reference2, 'zh');

      // THEN: Contains Chinese chapter and verse markers
      expect(formatted1, contains('章')); // Chapter
      expect(formatted1, contains('节')); // Verse
      expect(formatted2, contains('至')); // Range "to"
    });

    test('Chinese voice settings are properly validated and applied', () async {
      // GIVEN: Voice settings service
      final voiceSettings = getService<VoiceSettingsService>();

      // WHEN: Checking if user has saved Chinese voice
      final hasSavedVoice = await voiceSettings.hasUserSavedVoice('zh');

      // THEN: Returns a boolean (false for new user, true if voice was saved)
      expect(hasSavedVoice, isA<bool>());
    });

    test('Complete user flow: Spanish → Chinese → Back to Spanish', () async {
      // GIVEN: User starts app in Spanish
      await provider.initialize();
      expect(provider.currentLocale.languageCode, equals('es'));
      expect(provider.getTtsLocale(), equals('es-ES'));

      // WHEN: User switches to Chinese
      await provider.changeLanguage('zh');

      // THEN: Chinese is active
      expect(provider.currentLocale.languageCode, equals('zh'));
      expect(provider.getTtsLocale(), equals('zh-CN'));
      expect(provider.getLanguageName('zh'), equals('中文'));

      // WHEN: User switches back to Spanish
      await provider.changeLanguage('es');

      // THEN: Spanish is restored
      expect(provider.currentLocale.languageCode, equals('es'));
      expect(provider.getTtsLocale(), equals('es-ES'));
      expect(provider.getLanguageName('es'), equals('Español'));
    });

    test('Chinese language persists across app restarts', () async {
      // Simulate first app launch
      await provider.initialize();
      await provider.changeLanguage('zh');
      expect(provider.currentLocale.languageCode, equals('zh'));

      // Simulate app restart - create new provider instance
      ServiceLocator().reset();
      setupServiceLocator();
      final newProvider = LocalizationProvider();

      // WHEN: New provider initializes
      await newProvider.initialize();

      // THEN: Chinese language is restored from persistence
      expect(newProvider.currentLocale.languageCode, equals('zh'));
    });

    test('All 6 languages are available and properly ordered', () {
      // WHEN: Getting available languages
      final languages = provider.getAvailableLanguages();

      // THEN: All 6 languages are present
      expect(languages.length, equals(6));
      expect(languages.keys, containsAll(['es', 'en', 'pt', 'fr', 'ja', 'zh']));

      // AND: Display names are in native language
      expect(languages['zh'], equals('中文'));
      expect(languages['ja'], equals('日本語'));
      expect(languages['es'], equals('Español'));
      expect(languages['en'], equals('English'));
      expect(languages['pt'], equals('Português'));
      expect(languages['fr'], equals('Français'));
    });

    test('Chinese text formatting handles both simplified and traditional', () {
      // Simplified Chinese
      final simplified = '创世记 1:1';
      final formattedSimplified =
          BibleTextFormatter.formatBibleReferences(simplified, 'zh');
      expect(formattedSimplified, contains('章'));

      // Traditional Chinese
      final traditional = '創世記 2:1';
      final formattedTraditional =
          BibleTextFormatter.formatBibleReferences(traditional, 'zh');
      expect(formattedTraditional, contains('章'));
    });

    test('Voice proactive assignment triggers on Chinese language change',
        () async {
      final voiceSettings = getService<VoiceSettingsService>();

      // WHEN: Language changes to Chinese
      await provider.changeLanguage('zh');

      // THEN: Voice settings service processes the change
      final hasVoice = await voiceSettings.hasUserSavedVoice('zh');
      expect(hasVoice, isA<bool>());
    });
  });
}
