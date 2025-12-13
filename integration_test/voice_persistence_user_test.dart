import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration tests for voice persistence across app sessions
/// Tests user behavior scenarios for voice selection persistence
void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
        // GIVEN: User selects a voice and sets the flag
        await voiceSettingsService.setUserSavedVoice('es');

        // Simulate app restart by getting fresh SharedPreferences instance
        // The preferences are persisted in the mock
        final freshService = VoiceSettingsService();

        // WHEN: User checks if voice is saved after "restart"
        final hasVoice = await freshService.hasUserSavedVoice('es');

        // THEN: Same voice flag is still set
        expect(hasVoice, isTrue);
      });

      test('Saved speech rate persists across service instances', () async {
        // GIVEN: User saves a custom speech rate
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('tts_rate', 0.75);

        // Simulate app restart with new service instance
        final freshService = VoiceSettingsService();

        // WHEN: getSavedSpeechRate is called
        final rate = await freshService.getSavedSpeechRate();

        // THEN: Returns the persisted rate
        expect(rate, equals(0.75));
      });
    });

    group('Scenario 7: Multiple Languages Isolated', () {
      test('User has different voice per language', () async {
        // GIVEN: User selects Spanish male voice
        await voiceSettingsService.setUserSavedVoice('es');

        // AND: User switches to English and selects voice
        await voiceSettingsService.setUserSavedVoice('en');

        // WHEN: User checks each language
        final hasSpanish = await voiceSettingsService.hasUserSavedVoice('es');
        final hasEnglish = await voiceSettingsService.hasUserSavedVoice('en');

        // THEN: Both languages have their own saved voice
        expect(hasSpanish, isTrue);
        expect(hasEnglish, isTrue);
      });

      test('Clearing Spanish voice does not affect English voice', () async {
        // GIVEN: User has saved voices for both languages
        await voiceSettingsService.setUserSavedVoice('es');
        await voiceSettingsService.setUserSavedVoice('en');

        // WHEN: User clears Spanish voice
        await voiceSettingsService.clearUserSavedVoiceFlag('es');

        // THEN: Spanish is cleared, English remains
        expect(await voiceSettingsService.hasUserSavedVoice('es'), isFalse);
        expect(await voiceSettingsService.hasUserSavedVoice('en'), isTrue);
      });

      test('Each language maintains independent voice state', () async {
        // Set up voices for 5 languages
        final languages = ['es', 'en', 'pt', 'fr', 'ja'];
        for (final lang in languages) {
          await voiceSettingsService.setUserSavedVoice(lang);
        }

        // All should be set
        for (final lang in languages) {
          expect(
            await voiceSettingsService.hasUserSavedVoice(lang),
            isTrue,
            reason: 'Language $lang should have voice saved',
          );
        }

        // Clear alternating languages
        await voiceSettingsService.clearUserSavedVoiceFlag('es');
        await voiceSettingsService.clearUserSavedVoiceFlag('pt');
        await voiceSettingsService.clearUserSavedVoiceFlag('ja');

        // Check the state
        expect(await voiceSettingsService.hasUserSavedVoice('es'), isFalse);
        expect(await voiceSettingsService.hasUserSavedVoice('en'), isTrue);
        expect(await voiceSettingsService.hasUserSavedVoice('pt'), isFalse);
        expect(await voiceSettingsService.hasUserSavedVoice('fr'), isTrue);
        expect(await voiceSettingsService.hasUserSavedVoice('ja'), isFalse);
      });
    });

    group('Scenario 8: Corrupted Preferences Recovery', () {
      test('User with missing prefs gets default voice behavior', () async {
        // GIVEN: Empty preferences (corrupted or new user)
        SharedPreferences.setMockInitialValues({});

        // WHEN: User checks for saved voice
        final hasVoice = await voiceSettingsService.hasSavedVoice('es');

        // THEN: Returns false gracefully, no crash
        expect(hasVoice, isFalse);
      });

      test('User with no user saved flag defaults to false', () async {
        // GIVEN: No user saved flag in prefs
        SharedPreferences.setMockInitialValues({});

        // WHEN: hasUserSavedVoice is called
        final hasFlag = await voiceSettingsService.hasUserSavedVoice('es');

        // THEN: Returns false, not null or error
        expect(hasFlag, isFalse);
      });

      test('Default speech rate returned when prefs empty', () async {
        // GIVEN: No speech rate in prefs
        SharedPreferences.setMockInitialValues({});

        // WHEN: getSavedSpeechRate is called
        final rate = await voiceSettingsService.getSavedSpeechRate();

        // THEN: Returns default 0.5
        expect(rate, equals(0.5));
      });

      test('clearSavedVoice handles non-existent keys gracefully', () async {
        // GIVEN: No voice saved
        SharedPreferences.setMockInitialValues({});

        // WHEN: clearSavedVoice is called
        // THEN: No error thrown
        await expectLater(
          voiceSettingsService.clearSavedVoice('es'),
          completes,
        );
      });

      test('Service handles fresh state correctly', () async {
        // GIVEN: Completely fresh state
        SharedPreferences.setMockInitialValues({});
        final freshService = VoiceSettingsService();

        // WHEN: All check methods are called
        final hasSavedVoice = await freshService.hasSavedVoice('es');
        final hasUserFlag = await freshService.hasUserSavedVoice('es');
        final rate = await freshService.getSavedSpeechRate();

        // THEN: All return defaults, no crashes
        expect(hasSavedVoice, isFalse);
        expect(hasUserFlag, isFalse);
        expect(rate, equals(0.5));
      });
    });

    group('Voice Persistence Flow', () {
      test('Complete user flow: save, verify, restart, verify', () async {
        // 1. User selects voice
        await voiceSettingsService.setUserSavedVoice('es');
        expect(await voiceSettingsService.hasUserSavedVoice('es'), isTrue);

        // 2. "Restart" app - create new service instance
        final serviceAfterRestart = VoiceSettingsService();

        // 3. Voice should still be saved
        expect(await serviceAfterRestart.hasUserSavedVoice('es'), isTrue);
      });

      test('Speech rate persists through service lifecycle', () async {
        // 1. Set custom rate
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('tts_rate', 1.0);

        // 2. Verify with current service
        expect(await voiceSettingsService.getSavedSpeechRate(), equals(1.0));

        // 3. Create new service instance
        final newService = VoiceSettingsService();

        // 4. Rate should persist
        expect(await newService.getSavedSpeechRate(), equals(1.0));
      });
    });
  });
}
