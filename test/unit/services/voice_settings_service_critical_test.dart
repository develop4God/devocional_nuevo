@Tags(['unit', 'services'])
library;

import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Critical unit tests for VoiceSettingsService
/// Focuses on voice assignment logic, save/load flows, and edge cases

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('VoiceSettingsService - Critical Tests', () {
    late VoiceSettingsService voiceSettingsService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ServiceLocator().reset();
      voiceSettingsService = VoiceSettingsService();
    });

    tearDown(() {
      ServiceLocator().reset();
    });

    group('Voice Assignment Logic', () {
      test(
        'autoAssignDefaultVoice - preferred male voice for Spanish is in friendlyVoiceMap',
        () {
          // GIVEN: The friendlyVoiceMap contains es-us-x-esd-local
          final map = VoiceSettingsService.friendlyVoiceMap['es'];

          // THEN: es-us-x-esd-local should be in the map with correct friendly name
          expect(map, isNotNull);
          expect(map!.containsKey('es-us-x-esd-local'), isTrue);
          expect(map['es-us-x-esd-local'], equals('🇲🇽 Hombre Latinoamérica'));
        },
      );

      test(
        'autoAssignDefaultVoice - preferred male voice for English is in friendlyVoiceMap',
        () {
          // GIVEN: The friendlyVoiceMap contains en-us-x-tpd-network
          final map = VoiceSettingsService.friendlyVoiceMap['en'];

          // THEN: en-us-x-tpd-network should be in the map
          expect(map, isNotNull);
          expect(map!.containsKey('en-us-x-tpd-network'), isTrue);
          expect(map['en-us-x-tpd-network'], equals('🇺🇸 Male United States'));
        },
      );

      test(
        'autoAssignDefaultVoice - preferred male voice for Portuguese is in friendlyVoiceMap',
        () {
          // GIVEN: The friendlyVoiceMap contains pt-br-x-ptd-network
          final map = VoiceSettingsService.friendlyVoiceMap['pt'];

          // THEN: pt-br-x-ptd-network should be in the map
          expect(map, isNotNull);
          expect(map!.containsKey('pt-br-x-ptd-network'), isTrue);
          expect(map['pt-br-x-ptd-network'], equals('🇧🇷 Homem Brasil'));
        },
      );

      test(
        'autoAssignDefaultVoice - preferred male voice for French is in friendlyVoiceMap',
        () {
          // GIVEN: The friendlyVoiceMap contains fr-fr-x-frd-local
          final map = VoiceSettingsService.friendlyVoiceMap['fr'];

          // THEN: fr-fr-x-frd-local should be in the map
          expect(map, isNotNull);
          expect(map!.containsKey('fr-fr-x-frd-local'), isTrue);
          expect(map['fr-fr-x-frd-local'], equals('🇫🇷 Homme France'));
        },
      );

      test(
        'autoAssignDefaultVoice - preferred male voice for Japanese is in friendlyVoiceMap',
        () {
          // GIVEN: The friendlyVoiceMap contains ja-jp-x-jac-local
          final map = VoiceSettingsService.friendlyVoiceMap['ja'];

          // THEN: ja-jp-x-jac-local should be in the map
          expect(map, isNotNull);
          expect(map!.containsKey('ja-jp-x-jac-local'), isTrue);
          expect(map['ja-jp-x-jac-local'], equals('🇯🇵 男性 声 1'));
        },
      );

      test(
        'getFriendlyVoiceName - returns technical name for unknown voice',
        () {
          // GIVEN: An unknown voice name
          const unknownVoice = 'unknown-voice-xyz';

          // WHEN: getFriendlyVoiceName is called
          final friendlyName = voiceSettingsService.getFriendlyVoiceName(
            'es',
            unknownVoice,
          );

          // THEN: Returns the technical name as fallback
          expect(friendlyName, equals(unknownVoice));
        },
      );

      test(
        'getFriendlyVoiceName - returns friendly name for all languages',
        () {
          // Test Spanish
          expect(
            voiceSettingsService.getFriendlyVoiceName(
              'es',
              'es-us-x-esd-local',
            ),
            equals('🇲🇽 Hombre Latinoamérica'),
          );

          // Test English
          expect(
            voiceSettingsService.getFriendlyVoiceName(
              'en',
              'en-us-x-tpd-network',
            ),
            equals('🇺🇸 Male United States'),
          );

          // Test Portuguese
          expect(
            voiceSettingsService.getFriendlyVoiceName(
              'pt',
              'pt-br-x-ptd-network',
            ),
            equals('🇧🇷 Homem Brasil'),
          );

          // Test French
          expect(
            voiceSettingsService.getFriendlyVoiceName(
              'fr',
              'fr-fr-x-frd-local',
            ),
            equals('🇫🇷 Homme France'),
          );

          // Test Japanese
          expect(
            voiceSettingsService.getFriendlyVoiceName(
              'ja',
              'ja-jp-x-jac-local',
            ),
            equals('🇯🇵 男性 声 1'),
          );
        },
      );
    });

    group('Save and Load Flow', () {
      test('hasSavedVoice - returns false when no voice saved', () async {
        // GIVEN: No voice has been saved for Spanish
        // WHEN: hasSavedVoice is called
        final hasSaved = await voiceSettingsService.hasSavedVoice('es');

        // THEN: Returns false
        expect(hasSaved, isFalse);
      });

      test('hasUserSavedVoice - returns false initially', () async {
        // GIVEN: User has never saved a voice
        // WHEN: hasUserSavedVoice is called
        final hasFlag = await voiceSettingsService.hasUserSavedVoice('es');

        // THEN: Returns false
        expect(hasFlag, isFalse);
      });

      test('setUserSavedVoice - sets flag to true', () async {
        // GIVEN: User saves a voice
        await voiceSettingsService.setUserSavedVoice('es');

        // WHEN: hasUserSavedVoice is called
        final hasFlag = await voiceSettingsService.hasUserSavedVoice('es');

        // THEN: Returns true
        expect(hasFlag, isTrue);
      });

      test('clearUserSavedVoiceFlag - removes the flag', () async {
        // GIVEN: User has saved voice flag set
        await voiceSettingsService.setUserSavedVoice('es');
        expect(await voiceSettingsService.hasUserSavedVoice('es'), isTrue);

        // WHEN: clearUserSavedVoiceFlag is called
        await voiceSettingsService.clearUserSavedVoiceFlag('es');

        // THEN: Flag is removed
        final hasFlag = await voiceSettingsService.hasUserSavedVoice('es');
        expect(hasFlag, isFalse);
      });

      test('getSavedSpeechRate - returns default 0.5 when not set', () async {
        // GIVEN: No speech rate saved
        // WHEN: getSavedSpeechRate is called
        final rate = await voiceSettingsService.getSavedSpeechRate();

        // THEN: Returns default 0.5
        expect(rate, equals(0.5));
      });

      test('getSavedSpeechRate - returns custom rate when set', () async {
        // GIVEN: A custom speech rate is saved
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('tts_rate', 0.8);

        // WHEN: getSavedSpeechRate is called
        final rate = await voiceSettingsService.getSavedSpeechRate();

        // THEN: Returns the custom rate
        expect(rate, equals(0.8));
      });
    });

    group('Voice Isolation per Language', () {
      test('User voice flags are isolated per language', () async {
        // GIVEN: User saves voice for Spanish
        await voiceSettingsService.setUserSavedVoice('es');

        // THEN: Spanish has flag, English does not
        expect(await voiceSettingsService.hasUserSavedVoice('es'), isTrue);
        expect(await voiceSettingsService.hasUserSavedVoice('en'), isFalse);
      });

      test('Clearing one language flag does not affect others', () async {
        // GIVEN: User saves voice for both Spanish and English
        await voiceSettingsService.setUserSavedVoice('es');
        await voiceSettingsService.setUserSavedVoice('en');

        // WHEN: Spanish flag is cleared
        await voiceSettingsService.clearUserSavedVoiceFlag('es');

        // THEN: Spanish is cleared, English remains
        expect(await voiceSettingsService.hasUserSavedVoice('es'), isFalse);
        expect(await voiceSettingsService.hasUserSavedVoice('en'), isTrue);
      });
    });

    group('Edge Cases', () {
      test('hasSavedVoice handles missing prefs gracefully', () async {
        // GIVEN: Fresh SharedPreferences
        SharedPreferences.setMockInitialValues({});

        // WHEN: hasSavedVoice is called for non-existent language
        final hasSaved = await voiceSettingsService.hasSavedVoice('xx');

        // THEN: Returns false, no crash
        expect(hasSaved, isFalse);
      });

      test('clearSavedVoice handles non-existent key gracefully', () async {
        // GIVEN: No voice saved
        // WHEN: clearSavedVoice is called
        // THEN: No error thrown
        await expectLater(
          voiceSettingsService.clearSavedVoice('es'),
          completes,
        );
      });

      test(
        'clearUserSavedVoiceFlag handles non-existent flag gracefully',
        () async {
          // GIVEN: No flag set
          // WHEN: clearUserSavedVoiceFlag is called
          // THEN: No error thrown
          await expectLater(
            voiceSettingsService.clearUserSavedVoiceFlag('es'),
            completes,
          );
        },
      );

      test('Multiple languages can have different voice flags', () async {
        // Set flags for multiple languages
        await voiceSettingsService.setUserSavedVoice('es');
        await voiceSettingsService.setUserSavedVoice('en');
        await voiceSettingsService.setUserSavedVoice('pt');

        // All should be set
        expect(await voiceSettingsService.hasUserSavedVoice('es'), isTrue);
        expect(await voiceSettingsService.hasUserSavedVoice('en'), isTrue);
        expect(await voiceSettingsService.hasUserSavedVoice('pt'), isTrue);

        // Clear one
        await voiceSettingsService.clearUserSavedVoiceFlag('en');

        // Only English should be cleared
        expect(await voiceSettingsService.hasUserSavedVoice('es'), isTrue);
        expect(await voiceSettingsService.hasUserSavedVoice('en'), isFalse);
        expect(await voiceSettingsService.hasUserSavedVoice('pt'), isTrue);
      });
    });
  });
}
