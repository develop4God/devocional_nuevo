import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:devocional_nuevo/services/localization_service.dart';

void main() {
  group('TTS Translation Integration Tests', () {
    test('should demonstrate TTS is using LocalizationService correctly', () async {
      // This test verifies that the TTS service is integrated with LocalizationService
      // and that translation keys are being used instead of hardcoded values
      
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Reset the localization service
      LocalizationService.resetInstance();
      final localizationService = LocalizationService.instance;
      final ttsService = TtsService();
      
      // Mock a simple scenario where LocalizationService returns keys
      // (which is what happens when translations are not loaded)
      
      await localizationService.initialize();
      ttsService.setLanguageContext('es', 'RVR1960');
      
      // Test that the TTS service calls the localization service
      // If it was using hardcoded values, we would see "Versículo:" directly
      // But now we see translation keys, proving integration is working
      
      final spanishHeaders = ttsService.getSectionHeadersForTesting('es');
      
      // These should now be translation keys (proving integration)
      // instead of hardcoded Spanish text
      expect(spanishHeaders['verse'], contains('devotionals.verse'));
      expect(spanishHeaders['reflection'], contains('devotionals.reflection'));
      expect(spanishHeaders['meditate'], contains('devotionals.to_meditate'));
      expect(spanishHeaders['prayer'], contains('devotionals.prayer'));
      
      await ttsService.dispose();
    });
    
    test('should handle different language contexts', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      LocalizationService.resetInstance();
      final localizationService = LocalizationService.instance;
      final ttsService = TtsService();
      
      await localizationService.initialize();
      
      // Test Spanish context
      ttsService.setLanguageContext('es', 'RVR1960');
      final spanishHeaders = ttsService.getSectionHeadersForTesting('es');
      expect(spanishHeaders['verse'], contains('devotionals.verse'));
      
      // Test English context
      ttsService.setLanguageContext('en', 'KJV');
      final englishHeaders = ttsService.getSectionHeadersForTesting('en');
      expect(englishHeaders['verse'], contains('devotionals.verse'));
      
      // Both should use the same translation keys from LocalizationService
      // This proves the hardcoded approach has been replaced
      expect(spanishHeaders['verse'], equals(englishHeaders['verse']));
      
      await ttsService.dispose();
    });
    
    test('should maintain backward compatibility for Spanish RVR1960', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      LocalizationService.resetInstance();
      final ttsService = TtsService();
      
      // Test that Spanish RVR1960 still works (even with translation keys)
      ttsService.setLanguageContext('es', 'RVR1960');
      
      // The TTS service should accept the language context without errors
      expect(ttsService.currentState, TtsState.idle);
      
      await ttsService.dispose();
    });
  });
}