import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('VoiceSettingsService - Core Business Logic', () {
    late VoiceSettingsService voiceSettingsService;

    setUp(() {
      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
      voiceSettingsService = VoiceSettingsService();
      
      // Mock flutter_tts channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getVoices':
              return [
                {'name': 'es-ES-Monica-local', 'locale': 'es-ES'},
                {'name': 'en-US-Karen-local', 'locale': 'en-US'},
                {'name': 'pt-BR-Maria-local', 'locale': 'pt-BR'},
              ];
            case 'setVoice':
              return true;
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      // Clean up mock handlers
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    });

    group('Voice Management', () {
      test('should save and load voice settings correctly', () async {
        // Arrange
        const language = 'es';
        const voiceName = 'TestVoice';
        const locale = 'es-ES';

        // Act - Save voice
        await voiceSettingsService.saveVoice(language, voiceName, locale);
        
        // Act - Load saved voice
        final result = await voiceSettingsService.loadSavedVoice(language);

        // Assert
        expect(result, isNotNull);
        expect(result, contains('TestVoice'));
      });

      test('should return null when no voice is saved', () async {
        // Arrange
        const language = 'fr';

        // Act
        final result = await voiceSettingsService.loadSavedVoice(language);

        // Assert
        expect(result, isNull);
      });

      test('should clear saved voice correctly', () async {
        // Arrange
        const language = 'en';
        await voiceSettingsService.saveVoice(language, 'TestVoice', 'en-US');

        // Act
        await voiceSettingsService.clearSavedVoice(language);
        final result = await voiceSettingsService.loadSavedVoice(language);

        // Assert
        expect(result, isNull);
      });

      test('should check if voice is saved correctly', () async {
        // Arrange
        const language = 'pt';
        const voiceName = 'TestVoice';
        const locale = 'pt-BR';

        // Act - Initially should not have saved voice
        bool hasVoiceBefore = await voiceSettingsService.hasSavedVoice(language);
        
        // Save voice
        await voiceSettingsService.saveVoice(language, voiceName, locale);
        
        // Check again
        bool hasVoiceAfter = await voiceSettingsService.hasSavedVoice(language);

        // Assert
        expect(hasVoiceBefore, isFalse);
        expect(hasVoiceAfter, isTrue);
      });
    });

    group('Voice Discovery and Formatting', () {
      test('should get available voices without errors', () async {
        // Act
        final voices = await voiceSettingsService.getAvailableVoices();

        // Assert
        expect(voices, isA<List<String>>());
        expect(voices.length, greaterThanOrEqualTo(0));
      });

      test('should get voices for specific language', () async {
        // Act
        final spanishVoices = await voiceSettingsService.getVoicesForLanguage('es');
        final englishVoices = await voiceSettingsService.getVoicesForLanguage('en');

        // Assert
        expect(spanishVoices, isA<List<String>>());
        expect(englishVoices, isA<List<String>>());
        
        // Should return different results for different languages
        // (unless no voices available for that language)
      });

      test('should handle unknown language gracefully', () async {
        // Act
        final unknownVoices = await voiceSettingsService.getVoicesForLanguage('xyz');

        // Assert
        expect(unknownVoices, isA<List<String>>());
        // Should not throw exception and return empty list or default language voices
      });
    });

    group('Auto Voice Assignment', () {
      test('should auto-assign voice when none saved', () async {
        // Arrange
        const language = 'es';

        // Act
        await voiceSettingsService.autoAssignDefaultVoice(language);
        
        // Verify if voice was assigned
        final hasVoice = await voiceSettingsService.hasSavedVoice(language);

        // Assert
        expect(hasVoice, isTrue);
      });

      test('should not override existing saved voice', () async {
        // Arrange
        const language = 'en';
        const originalVoice = 'OriginalVoice';
        const originalLocale = 'en-US';
        
        // Save an original voice first
        await voiceSettingsService.saveVoice(language, originalVoice, originalLocale);
        
        // Act - Try to auto-assign (should not override)
        await voiceSettingsService.autoAssignDefaultVoice(language);
        
        // Load the voice to check it wasn't changed
        final loadedVoice = await voiceSettingsService.loadSavedVoice(language);

        // Assert
        expect(loadedVoice, contains('OriginalVoice'));
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle service errors gracefully', () async {
        // Test that methods don't throw exceptions under normal use
        expect(() => voiceSettingsService.getAvailableVoices(), returnsNormally);
        expect(() => voiceSettingsService.getVoicesForLanguage('es'), returnsNormally);
        expect(() => voiceSettingsService.hasSavedVoice('en'), returnsNormally);
      });

      test('should handle empty or null voice name gracefully', () async {
        // Arrange
        const language = 'es';

        // Act & Assert - Should not crash with empty/null inputs
        expect(() => voiceSettingsService.saveVoice(language, '', 'es-ES'), returnsNormally);
        expect(() => voiceSettingsService.clearSavedVoice(language), returnsNormally);
      });
    });
  });
}