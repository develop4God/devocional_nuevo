@Tags(['unit', 'services'])
library;

// test/unit/services/voice_persistence_user_workflow_test.dart
//
// Migrated from integration_test/voice_persistence_user_test.dart
// Tests user behavior for voice selection persistence across app sessions,
// multi-language isolation, and corrupted-preference recovery.

import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Voice Persistence - User Integration Tests', () {
    late VoiceSettingsService voiceSettingsService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ServiceLocator().reset();
      voiceSettingsService = VoiceSettingsService();
    });

    tearDown(() {
      ServiceLocator().reset();
    });

    group('Scenario 6: Voice Persists Across App Restarts', () {
      test('User voice preference survives simulated app restart', () async {
        await voiceSettingsService.setUserSavedVoice('es');

        // Simulate app restart by getting fresh service instance
        final freshService = VoiceSettingsService();

        final hasVoice = await freshService.hasUserSavedVoice('es');
        expect(hasVoice, isTrue);
      });

      test('Saved speech rate persists across service instances', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('tts_rate', 0.75);

        final freshService = VoiceSettingsService();
        final rate = await freshService.getSavedSpeechRate();

        expect(rate, equals(0.75));
      });
    });

    group('Scenario 7: Multiple Languages Isolated', () {
      test('User has different voice per language', () async {
        await voiceSettingsService.setUserSavedVoice('es');
        await voiceSettingsService.setUserSavedVoice('en');

        final hasSpanish = await voiceSettingsService.hasUserSavedVoice('es');
        final hasEnglish = await voiceSettingsService.hasUserSavedVoice('en');

        expect(hasSpanish, isTrue);
        expect(hasEnglish, isTrue);
      });

      test('Clearing Spanish voice does not affect English voice', () async {
        await voiceSettingsService.setUserSavedVoice('es');
        await voiceSettingsService.setUserSavedVoice('en');

        await voiceSettingsService.clearUserSavedVoiceFlag('es');

        expect(await voiceSettingsService.hasUserSavedVoice('es'), isFalse);
        expect(await voiceSettingsService.hasUserSavedVoice('en'), isTrue);
      });

      test('Each language maintains independent voice state', () async {
        final languages = ['es', 'en', 'pt', 'fr', 'ja'];
        for (final lang in languages) {
          await voiceSettingsService.setUserSavedVoice(lang);
        }

        for (final lang in languages) {
          expect(
            await voiceSettingsService.hasUserSavedVoice(lang),
            isTrue,
            reason: 'Language $lang should have voice saved',
          );
        }

        await voiceSettingsService.clearUserSavedVoiceFlag('es');
        await voiceSettingsService.clearUserSavedVoiceFlag('pt');
        await voiceSettingsService.clearUserSavedVoiceFlag('ja');

        expect(await voiceSettingsService.hasUserSavedVoice('es'), isFalse);
        expect(await voiceSettingsService.hasUserSavedVoice('en'), isTrue);
        expect(await voiceSettingsService.hasUserSavedVoice('pt'), isFalse);
        expect(await voiceSettingsService.hasUserSavedVoice('fr'), isTrue);
        expect(await voiceSettingsService.hasUserSavedVoice('ja'), isFalse);
      });
    });

    group('Scenario 8: Corrupted Preferences Recovery', () {
      test('User with missing prefs gets default voice behavior', () async {
        SharedPreferences.setMockInitialValues({});

        final hasVoice = await voiceSettingsService.hasSavedVoice('es');
        expect(hasVoice, isFalse);
      });

      test('User with no user saved flag defaults to false', () async {
        SharedPreferences.setMockInitialValues({});

        final hasFlag = await voiceSettingsService.hasUserSavedVoice('es');
        expect(hasFlag, isFalse);
      });

      test('Default speech rate returned when prefs empty', () async {
        SharedPreferences.setMockInitialValues({});

        final rate = await voiceSettingsService.getSavedSpeechRate();
        expect(rate, equals(0.5));
      });

      test('clearSavedVoice handles non-existent keys gracefully', () async {
        SharedPreferences.setMockInitialValues({});

        await expectLater(
          voiceSettingsService.clearSavedVoice('es'),
          completes,
        );
      });

      test('Service handles fresh state correctly', () async {
        SharedPreferences.setMockInitialValues({});
        final freshService = VoiceSettingsService();

        final hasSavedVoice = await freshService.hasSavedVoice('es');
        final hasUserFlag = await freshService.hasUserSavedVoice('es');
        final rate = await freshService.getSavedSpeechRate();

        expect(hasSavedVoice, isFalse);
        expect(hasUserFlag, isFalse);
        expect(rate, equals(0.5));
      });
    });

    group('Voice Persistence Flow', () {
      test('Complete user flow: save, verify, restart, verify', () async {
        await voiceSettingsService.setUserSavedVoice('es');
        expect(await voiceSettingsService.hasUserSavedVoice('es'), isTrue);

        // "Restart" app - create new service instance
        final serviceAfterRestart = VoiceSettingsService();
        expect(await serviceAfterRestart.hasUserSavedVoice('es'), isTrue);
      });

      test('Speech rate persists through service lifecycle', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('tts_rate', 1.0);

        expect(await voiceSettingsService.getSavedSpeechRate(), equals(1.0));

        final newService = VoiceSettingsService();
        expect(await newService.getSavedSpeechRate(), equals(1.0));
      });
    });
  });
}
