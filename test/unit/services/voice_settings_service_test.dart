import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('VoiceSettingsService', () {
    late VoiceSettingsService voiceSettingsService;

    setUp(() {
      // Set up SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
      voiceSettingsService = VoiceSettingsService();
    });

    group('Speech Rate Management', () {
      test('should set and get speech rate', () async {
        // Arrange
        const speechRate = 0.7;

        // Act
        await voiceSettingsService.setSpeechRate(speechRate);
        final result = await voiceSettingsService.getSpeechRate();

        // Assert
        expect(result, equals(speechRate));
      });

      test('should return default speech rate when none set', () async {
        // Act
        final result = await voiceSettingsService.getSpeechRate();

        // Assert
        expect(result, equals(0.5)); // Default speech rate
      });

      test('should handle extreme speech rate values', () async {
        // Arrange
        const extremeRates = [0.0, 1.0, 0.1, 0.9];

        // Act & Assert
        for (final rate in extremeRates) {
          await voiceSettingsService.setSpeechRate(rate);
          final result = await voiceSettingsService.getSpeechRate();
          expect(result, equals(rate));
        }
      });

      test('should clamp invalid speech rate values', () async {
        // Arrange
        const invalidRates = [-0.5, 1.5, 2.0];

        // Act & Assert
        for (final rate in invalidRates) {
          await voiceSettingsService.setSpeechRate(rate);
          final result = await voiceSettingsService.getSpeechRate();
          expect(result, greaterThanOrEqualTo(0.0));
          expect(result, lessThanOrEqualTo(1.0));
        }
      });
    });

    group('Voice Pitch Management', () {
      test('should set and get voice pitch', () async {
        // Arrange
        const pitch = 1.2;

        // Act
        await voiceSettingsService.setVoicePitch(pitch);
        final result = await voiceSettingsService.getVoicePitch();

        // Assert
        expect(result, equals(pitch));
      });

      test('should return default voice pitch when none set', () async {
        // Act
        final result = await voiceSettingsService.getVoicePitch();

        // Assert
        expect(result, equals(1.0)); // Default pitch
      });

      test('should handle various pitch values', () async {
        // Arrange
        const pitchValues = [0.5, 1.0, 1.5, 2.0];

        // Act & Assert
        for (final pitch in pitchValues) {
          await voiceSettingsService.setVoicePitch(pitch);
          final result = await voiceSettingsService.getVoicePitch();
          expect(result, equals(pitch));
        }
      });
    });

    group('Voice Volume Management', () {
      test('should set and get voice volume', () async {
        // Arrange
        const volume = 0.8;

        // Act
        await voiceSettingsService.setVoiceVolume(volume);
        final result = await voiceSettingsService.getVoiceVolume();

        // Assert
        expect(result, equals(volume));
      });

      test('should return default voice volume when none set', () async {
        // Act
        final result = await voiceSettingsService.getVoiceVolume();

        // Assert
        expect(result, equals(1.0)); // Default volume
      });

      test('should handle volume range validation', () async {
        // Arrange
        const validVolumes = [0.0, 0.5, 1.0];

        // Act & Assert
        for (final volume in validVolumes) {
          await voiceSettingsService.setVoiceVolume(volume);
          final result = await voiceSettingsService.getVoiceVolume();
          expect(result, equals(volume));
        }
      });
    });

    group('Voice Language Management', () {
      test('should set and get voice language', () async {
        // Arrange
        const language = 'es-ES';

        // Act
        await voiceSettingsService.setVoiceLanguage(language);
        final result = await voiceSettingsService.getVoiceLanguage();

        // Assert
        expect(result, equals(language));
      });

      test('should return default voice language when none set', () async {
        // Act
        final result = await voiceSettingsService.getVoiceLanguage();

        // Assert
        expect(result, equals('en-US')); // Default language
      });

      test('should handle different language codes', () async {
        // Arrange
        const languages = ['en-US', 'es-ES', 'pt-BR', 'fr-FR'];

        // Act & Assert
        for (final lang in languages) {
          await voiceSettingsService.setVoiceLanguage(lang);
          final result = await voiceSettingsService.getVoiceLanguage();
          expect(result, equals(lang));
        }
      });
    });

    group('Voice Enabled State', () {
      test('should set and get voice enabled state', () async {
        // Arrange
        const enabled = false;

        // Act
        await voiceSettingsService.setVoiceEnabled(enabled);
        final result = await voiceSettingsService.isVoiceEnabled();

        // Assert
        expect(result, equals(enabled));
      });

      test('should return default enabled state when none set', () async {
        // Act
        final result = await voiceSettingsService.isVoiceEnabled();

        // Assert
        expect(result, isTrue); // Default enabled state
      });

      test('should toggle voice enabled state', () async {
        // Act & Assert
        await voiceSettingsService.setVoiceEnabled(true);
        expect(await voiceSettingsService.isVoiceEnabled(), isTrue);

        await voiceSettingsService.setVoiceEnabled(false);
        expect(await voiceSettingsService.isVoiceEnabled(), isFalse);

        await voiceSettingsService.setVoiceEnabled(true);
        expect(await voiceSettingsService.isVoiceEnabled(), isTrue);
      });
    });

    group('Settings Persistence', () {
      test('should persist all settings across service instances', () async {
        // Arrange
        const speechRate = 0.6;
        const pitch = 1.3;
        const volume = 0.9;
        const language = 'es-ES';
        const enabled = false;

        // Act - set all settings
        await voiceSettingsService.setSpeechRate(speechRate);
        await voiceSettingsService.setVoicePitch(pitch);
        await voiceSettingsService.setVoiceVolume(volume);
        await voiceSettingsService.setVoiceLanguage(language);
        await voiceSettingsService.setVoiceEnabled(enabled);

        // Create new service instance
        final newService = VoiceSettingsService();

        // Assert - all settings should be persisted
        expect(await newService.getSpeechRate(), equals(speechRate));
        expect(await newService.getVoicePitch(), equals(pitch));
        expect(await newService.getVoiceVolume(), equals(volume));
        expect(await newService.getVoiceLanguage(), equals(language));
        expect(await newService.isVoiceEnabled(), equals(enabled));
      });

      test('should handle missing preferences gracefully', () async {
        // Act - get settings when none are set
        final speechRate = await voiceSettingsService.getSpeechRate();
        final pitch = await voiceSettingsService.getVoicePitch();
        final volume = await voiceSettingsService.getVoiceVolume();
        final language = await voiceSettingsService.getVoiceLanguage();
        final enabled = await voiceSettingsService.isVoiceEnabled();

        // Assert - should return default values
        expect(speechRate, equals(0.5));
        expect(pitch, equals(1.0));
        expect(volume, equals(1.0));
        expect(language, equals('en-US'));
        expect(enabled, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle rapid setting changes gracefully', () async {
        // Arrange
        const rates = [0.3, 0.7, 0.5, 0.9, 0.4];

        // Act & Assert - should not throw
        for (final rate in rates) {
          expect(
            () => voiceSettingsService.setSpeechRate(rate),
            returnsNormally,
          );
        }
      });

      test('should handle concurrent setting operations', () async {
        // Act - perform concurrent operations
        final futures = [
          voiceSettingsService.setSpeechRate(0.6),
          voiceSettingsService.setVoicePitch(1.2),
          voiceSettingsService.setVoiceVolume(0.8),
          voiceSettingsService.setVoiceLanguage('es-ES'),
          voiceSettingsService.setVoiceEnabled(false),
        ];

        // Assert - should complete without errors
        expect(Future.wait(futures), completes);
      });

      test('should handle null or invalid values gracefully', () async {
        // Act & Assert - should handle gracefully without throwing
        expect(
          () => voiceSettingsService.setVoiceLanguage(''),
          returnsNormally,
        );
        expect(
          () => voiceSettingsService.setSpeechRate(double.nan),
          returnsNormally,
        );
        expect(
          () => voiceSettingsService.setVoicePitch(double.infinity),
          returnsNormally,
        );
      });
    });

    group('Business Logic Validation', () {
      test('should maintain setting consistency across operations', () async {
        // Arrange
        const testRate = 0.7;
        const testPitch = 1.1;
        const testVolume = 0.9;

        // Act
        await voiceSettingsService.setSpeechRate(testRate);
        await voiceSettingsService.setVoicePitch(testPitch);
        await voiceSettingsService.setVoiceVolume(testVolume);

        // Assert - all settings should be maintained
        expect(await voiceSettingsService.getSpeechRate(), equals(testRate));
        expect(await voiceSettingsService.getVoicePitch(), equals(testPitch));
        expect(await voiceSettingsService.getVoiceVolume(), equals(testVolume));
      });

      test('should validate setting ranges correctly', () async {
        // Test speech rate boundaries
        await voiceSettingsService.setSpeechRate(0.0);
        expect(await voiceSettingsService.getSpeechRate(),
            greaterThanOrEqualTo(0.0));

        await voiceSettingsService.setSpeechRate(1.0);
        expect(
            await voiceSettingsService.getSpeechRate(), lessThanOrEqualTo(1.0));

        // Test volume boundaries
        await voiceSettingsService.setVoiceVolume(0.0);
        expect(await voiceSettingsService.getVoiceVolume(),
            greaterThanOrEqualTo(0.0));

        await voiceSettingsService.setVoiceVolume(1.0);
        expect(await voiceSettingsService.getVoiceVolume(),
            lessThanOrEqualTo(1.0));
      });

      test('should handle service reinitialization properly', () async {
        // Arrange - set custom values
        await voiceSettingsService.setSpeechRate(0.8);
        await voiceSettingsService.setVoiceEnabled(false);

        // Act - reinitialize service
        final newService = VoiceSettingsService();

        // Assert - settings should persist
        expect(await newService.getSpeechRate(), equals(0.8));
        expect(await newService.isVoiceEnabled(), isFalse);
      });
    });
  });
}
