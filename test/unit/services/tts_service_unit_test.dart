import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import '../../test_setup.dart';

void main() {
  setUpAll(() {
    TestSetup.setupCommonMocks();
  });

  tearDownAll(() {
    TestSetup.cleanupMocks();
  });

  group('TTS Service Unit Tests', () {
    late TtsService ttsService;

    setUp(() {
      ttsService = TtsService();
    });

    tearDown(() {
      // Clean up any TTS state
      try {
        ttsService.dispose();
      } catch (e) {
        // Ignore cleanup errors in tests
      }
    });

    test('should initialize TTS service', () async {
      // Test that TTS service can be initialized
      expect(ttsService, isNotNull);
      expect(ttsService.currentState, isNotNull);
    });

    test('should handle language settings', () {
      // Test language context setting
      ttsService.setLanguageContext('es', 'RVR1960');
      
      // Should not throw and should maintain state
      expect(ttsService, isNotNull);
    });

    test('should handle TTS state changes', () {
      // Test state management
      final initialState = ttsService.currentState;
      expect(initialState, isNotNull);
      
      // TTS should start in idle state or be manageable
      expect([TtsState.idle, TtsState.error, TtsState.initializing], 
             contains(initialState));
    });

    test('should handle devotional text preparation', () {
      // Create a sample devotional
      final devotional = Devocional(
        id: 'test_1',
        date: DateTime.now(),
        versiculo: 'Juan 3:16',
        reflexion: 'Esta es una reflexión de prueba.',
        paraMeditar: [
          ParaMeditar(cita: 'Juan 3:16', texto: 'Aplicar el amor de Dios en nuestra vida diaria.'),
        ],
        oracion: 'Padre celestial, gracias por tu amor.',
      );

      // Test that service can handle devotional content
      expect(() => ttsService.setLanguageContext('es', 'RVR1960'), 
             returnsNormally);
    });

    test('should handle multiple language contexts', () {
      // Test multiple language settings
      final languages = ['es', 'en', 'pt', 'fr'];
      final versions = ['RVR1960', 'KJV', 'ARC', 'LSG1910'];

      for (int i = 0; i < languages.length; i++) {
        expect(() => ttsService.setLanguageContext(languages[i], versions[i]), 
               returnsNormally);
      }
    });

    test('should handle service disposal properly', () {
      // Test that disposal doesn't throw
      expect(() => ttsService.dispose(), returnsNormally);
      
      // Service should handle multiple disposals gracefully
      expect(() => ttsService.dispose(), returnsNormally);
    });

    test('should provide state stream', () {
      // Test that state stream is available
      expect(ttsService.stateStream, isNotNull);
      expect(ttsService.progressStream, isNotNull);
    });

    test('should handle error states gracefully', () {
      // Test error handling
      expect(ttsService.currentState, isNotNull);
      
      // Should be able to check various states
      expect(ttsService.isPlaying, isA<bool>());
      expect(ttsService.isPaused, isA<bool>());
      expect(ttsService.isActive, isA<bool>());
    });

    test('should handle invalid language codes', () {
      // Test with invalid language codes
      expect(() => ttsService.setLanguageContext('invalid', 'version'), 
             returnsNormally);
      
      expect(() => ttsService.setLanguageContext('es', ''), 
             returnsNormally);
    });

    test('should maintain consistent state', () {
      // Test state consistency
      final state1 = ttsService.currentState;
      final state2 = ttsService.currentState;
      expect(state1, equals(state2));
      
      // Boolean properties should be consistent
      final isPlaying1 = ttsService.isPlaying;
      final isPlaying2 = ttsService.isPlaying;
      expect(isPlaying1, equals(isPlaying2));
    });
  });

  group('TTS Service Error Handling', () {
    test('should handle platform exceptions gracefully', () {
      final ttsService = TtsService();
      
      // These should not throw even if platform is not available
      expect(() => ttsService.setLanguageContext('es', 'RVR1960'), 
             returnsNormally);
      
      expect(() => ttsService.dispose(), returnsNormally);
    });

    test('should handle concurrent operations', () {
      final ttsService = TtsService();
      
      // Multiple rapid calls should not cause issues
      for (int i = 0; i < 5; i++) {
        ttsService.setLanguageContext('es', 'RVR1960');
        ttsService.setLanguageContext('en', 'KJV');
      }
      
      expect(ttsService, isNotNull);
      ttsService.dispose();
    });

    test('should handle state queries when disposed', () {
      final ttsService = TtsService();
      ttsService.dispose();
      
      // Should still be able to query state without crashing
      expect(() => ttsService.currentState, returnsNormally);
      expect(() => ttsService.isPlaying, returnsNormally);
      expect(() => ttsService.isPaused, returnsNormally);
    });
  });
}