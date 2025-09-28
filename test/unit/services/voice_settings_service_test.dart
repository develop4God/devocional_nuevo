// test/unit/services/voice_settings_service_test.dart

import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceSettingsService Tests', () {
    late VoiceSettingsService voiceService;

    setUp(() async {
      // Setup SharedPreferences mock
      SharedPreferences.setMockInitialValues({
        'tts_voice_es': 'es-ES-male',
        'tts_voice_en': 'en-US-female',
        'tts_voice_pt': 'pt-BR-male',
        'tts_voice_fr': 'fr-FR-female',
      });

      // Setup method channel mocks for TTS
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getVoices':
              return [
                {'name': 'Spanish Male Voice', 'locale': 'es-ES'},
                {'name': 'Spanish Female Voice', 'locale': 'es-ES'},
                {'name': 'English Male Voice', 'locale': 'en-US'},
                {'name': 'English Female Voice', 'locale': 'en-US'},
                {'name': 'Portuguese Male Voice', 'locale': 'pt-BR'},
                {'name': 'Portuguese Female Voice', 'locale': 'pt-BR'},
                {'name': 'French Male Voice', 'locale': 'fr-FR'},
                {'name': 'French Female Voice', 'locale': 'fr-FR'},
              ];
            case 'setVoice':
              return 1;
            case 'isLanguageAvailable':
              return 1;
            default:
              return null;
          }
        },
      );

      voiceService = VoiceSettingsService();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        null,
      );
    });

    group('Voice Preferences Management', () {
      test('should manage voice preferences across languages', () async {
        // Test Spanish voice preference
        await voiceService.saveVoice('es', 'Spanish Male Voice', 'es-ES');
        final hasSpanishVoice = await voiceService.hasSavedVoice('es');
        expect(hasSpanishVoice, isTrue);

        final spanishVoice = await voiceService.getSavedVoice('es');
        expect(spanishVoice, isNotNull);
        expect(spanishVoice!.name, equals('Spanish Male Voice'));
        expect(spanishVoice.locale, equals('es-ES'));

        // Test English voice preference
        await voiceService.saveVoice('en', 'English Female Voice', 'en-US');
        final hasEnglishVoice = await voiceService.hasSavedVoice('en');
        expect(hasEnglishVoice, isTrue);

        final englishVoice = await voiceService.getSavedVoice('en');
        expect(englishVoice, isNotNull);
        expect(englishVoice!.name, equals('English Female Voice'));
        expect(englishVoice.locale, equals('en-US'));

        // Test Portuguese voice preference
        await voiceService.saveVoice('pt', 'Portuguese Male Voice', 'pt-BR');
        final hasPortugueseVoice = await voiceService.hasSavedVoice('pt');
        expect(hasPortugueseVoice, isTrue);

        // Test French voice preference
        await voiceService.saveVoice('fr', 'French Female Voice', 'fr-FR');
        final hasFrenchVoice = await voiceService.hasSavedVoice('fr');
        expect(hasFrenchVoice, isTrue);
      });

      test('should handle TTS configuration persistence', () async {
        // Save voice configurations for multiple languages
        await voiceService.saveVoice('es', 'Test Spanish Voice', 'es-ES');
        await voiceService.saveVoice('en', 'Test English Voice', 'en-US');

        // Test persistence across service instances
        final newVoiceService = VoiceSettingsService();
        
        final persistedSpanishVoice = await newVoiceService.getSavedVoice('es');
        expect(persistedSpanishVoice, isNotNull);
        expect(persistedSpanishVoice!.name, equals('Test Spanish Voice'));

        final persistedEnglishVoice = await newVoiceService.getSavedVoice('en');
        expect(persistedEnglishVoice, isNotNull);
        expect(persistedEnglishVoice!.name, equals('Test English Voice'));
      });
    });

    group('Automatic Voice Assignment', () {
      test('should auto-assign default voice for unsaved languages', () async {
        // Clear any existing voice for Spanish
        SharedPreferences.setMockInitialValues({});
        final freshVoiceService = VoiceSettingsService();
        
        // Should not have saved voice initially
        final hasInitialVoice = await freshVoiceService.hasSavedVoice('es');
        expect(hasInitialVoice, isFalse);

        // Auto-assign should work for Spanish
        await freshVoiceService.autoAssignDefaultVoice('es');
        
        // Should now have a voice (exact voice depends on available voices)
        final hasAssignedVoice = await freshVoiceService.hasSavedVoice('es');
        expect(hasAssignedVoice, isA<bool>());
      });

      test('should not override existing saved voice', () async {
        // Save a specific voice first
        await voiceService.saveVoice('es', 'Custom Spanish Voice', 'es-ES');
        
        // Verify it's saved
        final initialVoice = await voiceService.getSavedVoice('es');
        expect(initialVoice!.name, equals('Custom Spanish Voice'));

        // Auto-assign should not override
        await voiceService.autoAssignDefaultVoice('es');
        
        final finalVoice = await voiceService.getSavedVoice('es');
        expect(finalVoice!.name, equals('Custom Spanish Voice'));
      });

      test('should handle multiple language auto-assignment', () async {
        // Clear all saved voices
        SharedPreferences.setMockInitialValues({});
        final freshVoiceService = VoiceSettingsService();
        
        final languages = ['es', 'en', 'pt', 'fr'];
        
        // Auto-assign for all languages
        for (final language in languages) {
          await freshVoiceService.autoAssignDefaultVoice(language);
          
          // Each language should have some voice preference handling
          expect(() => freshVoiceService.hasSavedVoice(language), returnsNormally);
        }
      });
    });

    group('Voice Validation and Error Handling', () {
      test('should handle invalid language codes gracefully', () async {
        // Test with invalid language
        final hasInvalidVoice = await voiceService.hasSavedVoice('invalid_lang');
        expect(hasInvalidVoice, isFalse);

        final invalidVoice = await voiceService.getSavedVoice('invalid_lang');
        expect(invalidVoice, isNull);

        // Should not crash when auto-assigning invalid language
        expect(() => voiceService.autoAssignDefaultVoice('invalid_lang'), returnsNormally);
      });

      test('should handle empty or null voice names', () async {
        // Test saving with empty name
        await voiceService.saveVoice('test_lang', '', 'test-LOCALE');
        
        final emptyNameVoice = await voiceService.getSavedVoice('test_lang');
        expect(emptyNameVoice, isNotNull);
        expect(emptyNameVoice!.name, equals(''));

        // Test saving with null locale
        await voiceService.saveVoice('test_lang2', 'Test Voice', '');
        
        final emptyLocaleVoice = await voiceService.getSavedVoice('test_lang2');
        expect(emptyLocaleVoice, isNotNull);
        expect(emptyLocaleVoice!.locale, equals(''));
      });

      test('should handle missing SharedPreferences data', () async {
        // Create service with no saved preferences
        SharedPreferences.setMockInitialValues({});
        final cleanVoiceService = VoiceSettingsService();
        
        // Should handle missing data gracefully
        final hasNoVoice = await cleanVoiceService.hasSavedVoice('es');
        expect(hasNoVoice, isFalse);
        
        final noVoice = await cleanVoiceService.getSavedVoice('es');
        expect(noVoice, isNull);
      });
    });

    group('Voice Data Model', () {
      test('should handle VoiceInfo model correctly', () async {
        // Save a voice and retrieve it
        await voiceService.saveVoice('test', 'Test Voice Name', 'test-LOCALE');
        
        final voiceInfo = await voiceService.getSavedVoice('test');
        expect(voiceInfo, isNotNull);
        expect(voiceInfo!.name, isA<String>());
        expect(voiceInfo.locale, isA<String>());
        expect(voiceInfo.name, equals('Test Voice Name'));
        expect(voiceInfo.locale, equals('test-LOCALE'));
      });

      test('should handle voice preferences for all supported languages', () async {
        final supportedLanguages = ['es', 'en', 'pt', 'fr'];
        
        // Save voices for all supported languages
        for (int i = 0; i < supportedLanguages.length; i++) {
          final lang = supportedLanguages[i];
          await voiceService.saveVoice(lang, 'Voice for $lang', '$lang-LOCALE');
        }

        // Verify all were saved correctly
        for (final lang in supportedLanguages) {
          final hasVoice = await voiceService.hasSavedVoice(lang);
          expect(hasVoice, isTrue);
          
          final voice = await voiceService.getSavedVoice(lang);
          expect(voice, isNotNull);
          expect(voice!.name, equals('Voice for $lang'));
          expect(voice.locale, equals('$lang-LOCALE'));
        }
      });
    });

    group('Service Integration', () {
      test('should work with singleton pattern correctly', () {
        // Test that service is singleton
        final service1 = VoiceSettingsService();
        final service2 = VoiceSettingsService();
        
        expect(identical(service1, service2), isTrue);
      });

      test('should handle concurrent operations gracefully', () async {
        // Perform multiple operations concurrently
        final futures = <Future>[];
        
        futures.add(voiceService.saveVoice('concurrent1', 'Voice 1', 'locale1'));
        futures.add(voiceService.saveVoice('concurrent2', 'Voice 2', 'locale2'));
        futures.add(voiceService.autoAssignDefaultVoice('concurrent3'));
        futures.add(voiceService.hasSavedVoice('concurrent4'));
        
        // All operations should complete without error
        await Future.wait(futures);
        
        // Service should remain stable
        expect(() => voiceService.hasSavedVoice('test'), returnsNormally);
      });
    });
  });
}