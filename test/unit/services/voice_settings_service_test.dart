import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('VoiceSettingsService', () {
    late VoiceSettingsService voiceSettingsService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      voiceSettingsService = VoiceSettingsService();
    });

    group('Friendly Voice Name Mapping', () {
      test('should return friendly name for Spanish Latin America male voice',
          () {
        // Technical name: es-us-x-esd-local
        // Friendly name: 🇲🇽 Hombre Latinoamérica
        final friendlyName = voiceSettingsService.getFriendlyVoiceName(
            'es', 'es-us-x-esd-local');
        expect(friendlyName, equals('🇲🇽 Hombre Latinoamérica'));
      });

      test('should return friendly name for English US male voice', () {
        // Technical name: en-us-x-tpd-network
        // Friendly name: 🇺🇸 Male United States
        final friendlyName = voiceSettingsService.getFriendlyVoiceName(
            'en', 'en-us-x-tpd-network');
        expect(friendlyName, equals('🇺🇸 Male United States'));
      });

      test('should return friendly name for Portuguese Brazil male voice', () {
        // Technical name: pt-br-x-ptd-network
        // Friendly name: 🇧🇷 Homem Brasil
        final friendlyName = voiceSettingsService.getFriendlyVoiceName(
            'pt', 'pt-br-x-ptd-network');
        expect(friendlyName, equals('🇧🇷 Homem Brasil'));
      });

      test('should return friendly name for French France male voice', () {
        // Technical name: fr-fr-x-frd-local
        // Friendly name: 🇫🇷 Homme France
        final friendlyName = voiceSettingsService.getFriendlyVoiceName(
            'fr', 'fr-fr-x-frd-local');
        expect(friendlyName, equals('🇫🇷 Homme France'));
      });

      test('should return friendly name for Japanese male voice', () {
        // Technical name: ja-jp-x-jac-local
        // Friendly name: 🇯🇵 男性 声 1
        final friendlyName = voiceSettingsService.getFriendlyVoiceName(
            'ja', 'ja-jp-x-jac-local');
        expect(friendlyName, equals('🇯🇵 男性 声 1'));
      });

      test('should return technical name for unknown voice', () {
        final friendlyName = voiceSettingsService.getFriendlyVoiceName(
            'es', 'unknown-voice-name');
        expect(friendlyName, equals('unknown-voice-name'));
      });
    });

    group('Preferred Default Voices', () {
      test('Spanish preferred male voices should include es-us-x-esd-local',
          () {
        // Verify the map contains the expected Spanish male voice
        final map = VoiceSettingsService.friendlyVoiceMap['es'];
        expect(map, isNotNull);
        expect(map!.containsKey('es-us-x-esd-local'), isTrue);
        expect(map['es-us-x-esd-local'], equals('🇲🇽 Hombre Latinoamérica'));
      });

      test('English preferred male voices should include en-us-x-tpd-network',
          () {
        final map = VoiceSettingsService.friendlyVoiceMap['en'];
        expect(map, isNotNull);
        expect(map!.containsKey('en-us-x-tpd-network'), isTrue);
        expect(map['en-us-x-tpd-network'], equals('🇺🇸 Male United States'));
      });

      test(
          'Portuguese preferred male voices should include pt-br-x-ptd-network',
          () {
        final map = VoiceSettingsService.friendlyVoiceMap['pt'];
        expect(map, isNotNull);
        expect(map!.containsKey('pt-br-x-ptd-network'), isTrue);
        expect(map['pt-br-x-ptd-network'], equals('🇧🇷 Homem Brasil'));
      });

      test('French preferred male voices should include fr-fr-x-frd-local', () {
        final map = VoiceSettingsService.friendlyVoiceMap['fr'];
        expect(map, isNotNull);
        expect(map!.containsKey('fr-fr-x-frd-local'), isTrue);
        expect(map['fr-fr-x-frd-local'], equals('🇫🇷 Homme France'));
      });

      test('Japanese preferred male voices should include ja-jp-x-jac-local',
          () {
        final map = VoiceSettingsService.friendlyVoiceMap['ja'];
        expect(map, isNotNull);
        expect(map!.containsKey('ja-jp-x-jac-local'), isTrue);
        expect(map['ja-jp-x-jac-local'], equals('🇯🇵 男性 声 1'));
      });
    });

    group('Voice Persistence', () {
      test('hasSavedVoice should return false when no voice is saved',
          () async {
        final hasSaved = await voiceSettingsService.hasSavedVoice('es');
        expect(hasSaved, isFalse);
      });

      // Note: Tests that call saveVoice require platform TTS implementation
      // These would fail in unit tests without mocking FlutterTts
      // The integration tests should cover actual voice saving behavior
    });

    group('User Saved Voice Flag', () {
      test('hasUserSavedVoice should return false initially', () async {
        final hasFlag = await voiceSettingsService.hasUserSavedVoice('es');
        expect(hasFlag, isFalse);
      });

      test('setUserSavedVoice should set the flag to true', () async {
        await voiceSettingsService.setUserSavedVoice('es');
        final hasFlag = await voiceSettingsService.hasUserSavedVoice('es');
        expect(hasFlag, isTrue);
      });

      test('clearUserSavedVoiceFlag should remove the flag', () async {
        await voiceSettingsService.setUserSavedVoice('es');
        await voiceSettingsService.clearUserSavedVoiceFlag('es');
        final hasFlag = await voiceSettingsService.hasUserSavedVoice('es');
        expect(hasFlag, isFalse);
      });
    });

    group('Speech Rate', () {
      test('getSavedSpeechRate should return default rate of 0.5', () async {
        final rate = await voiceSettingsService.getSavedSpeechRate();
        expect(rate, equals(0.5));
      });
    });
  });
}
