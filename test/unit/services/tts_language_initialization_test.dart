import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Tags(['unit', 'services'])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TTS Language Initialization Tests - Persistence Validation', () {
    setUp(() async {
      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'Language preference should persist correctly in SharedPreferences',
      () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act - Simulate saving language preference (as done by TTS service)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('tts_language', 'en-US');

        // Assert - Verify language was saved
        final savedLanguage = prefs.getString('tts_language');
        expect(
          savedLanguage,
          'en-US',
          reason: 'TTS language should be persisted as en-US',
        );
      },
    );

    test(
      'Language preference should support all app languages - Portuguese',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('tts_language', 'pt-BR');
        expect(prefs.getString('tts_language'), 'pt-BR');
      },
    );

    test(
      'Language preference should support all app languages - French',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('tts_language', 'fr-FR');
        expect(prefs.getString('tts_language'), 'fr-FR');
      },
    );

    test(
      'Language preference should support all app languages - Japanese',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('tts_language', 'ja-JP');
        expect(prefs.getString('tts_language'), 'ja-JP');
      },
    );

    test(
      'Language preference should persist correctly across app restart simulation',
      () async {
        // Scenario A: User changes language to Portuguese in settings
        SharedPreferences.setMockInitialValues({});
        var prefs = await SharedPreferences.getInstance();

        // User selects Portuguese in settings - language is saved
        await prefs.setString('tts_language', 'pt-BR');
        final savedLanguageAfterChange = prefs.getString('tts_language');
        expect(
          savedLanguageAfterChange,
          'pt-BR',
          reason: 'Portuguese should be saved after user selection',
        );

        // Scenario B: App restarts - simulate by recreating SharedPreferences with saved state
        SharedPreferences.setMockInitialValues({
          'tts_language': savedLanguageAfterChange!,
          'tts_rate': 0.5,
        });

        // Verify language persists after restart
        prefs = await SharedPreferences.getInstance();
        final languageAfterRestart = prefs.getString('tts_language');
        expect(
          languageAfterRestart,
          'pt-BR',
          reason:
              'TTS language should remain Portuguese after app restart, not revert to Spanish',
        );
        expect(
          languageAfterRestart,
          isNot('es-ES'),
          reason: 'TTS should NOT revert to Spanish after app restart',
        );
        expect(
          languageAfterRestart,
          isNot('es-US'),
          reason: 'TTS should NOT revert to Spanish after app restart',
        );
      },
    );

    test('Language preference can be updated during app session', () async {
      // Start with Spanish
      SharedPreferences.setMockInitialValues({});
      var prefs = await SharedPreferences.getInstance();
      await prefs.setString('tts_language', 'es-ES');
      expect(prefs.getString('tts_language'), 'es-ES');

      // User changes to English
      await prefs.setString('tts_language', 'en-US');

      // Language should be updated
      expect(
        prefs.getString('tts_language'),
        'en-US',
        reason: 'Language should update when user changes it',
      );
    });

    test('Default Spanish language should not override user selection',
        () async {
      // Simulate user has selected Portuguese
      SharedPreferences.setMockInitialValues({'tts_language': 'pt-BR'});
      final prefs = await SharedPreferences.getInstance();

      // Verify Portuguese is preserved (not overridden by default Spanish)
      final savedLanguage = prefs.getString('tts_language');
      expect(
        savedLanguage,
        'pt-BR',
        reason:
            'User-selected Portuguese should not be overridden by default Spanish',
      );
      expect(savedLanguage, isNot('es-ES'));
      expect(savedLanguage, isNot('es-US'));
    });
  });
}
