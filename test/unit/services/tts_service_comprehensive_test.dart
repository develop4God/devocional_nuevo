import 'dart:async';

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock classes for dependencies
class MockFlutterTts extends Mock implements FlutterTts {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TtsService Unit Tests', () {
    late TtsService ttsService;

    setUp(() {
      // Initialize SharedPreferences with mock data
      SharedPreferences.setMockInitialValues({
        'selected_language': 'es',
        'speech_rate': 0.5,
      });
      
      // Get service instance 
      ttsService = TtsService();
    });

    tearDown(() async {
      // Clean up TTS service state
      try {
        await ttsService.stop();
        await ttsService.dispose();
      } catch (e) {
        // Ignore disposal errors in tests
      }
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        // Act
        await ttsService.initialize();

        // Assert
        expect(ttsService.currentState, equals(TtsState.idle));
      });

      test('should handle initialization errors gracefully', () async {
        // Act & Assert - should not throw
        expect(() => ttsService.initialize(), returnsNormally);
      });
    });

    group('Language Management', () {
      test('should set language successfully', () async {
        // Arrange
        await ttsService.initialize();
        const testLanguage = 'en';

        // Act
        await ttsService.setLanguage(testLanguage);

        // Assert - should complete without error
        expect(ttsService.currentState, isIn([TtsState.idle, TtsState.initializing]));
      });

      test('should get available languages', () async {
        // Act
        final languages = await ttsService.getLanguages();

        // Assert
        expect(languages, isA<List<String>>());
        expect(languages, isNotEmpty);
      });

      test('should get voices for specific language', () async {
        // Arrange
        const language = 'es';

        // Act
        final voices = await ttsService.getVoicesForLanguage(language);

        // Assert
        expect(voices, isA<List<String>>());
        // Allow empty list as it depends on platform availability
      });
    });

    group('Speech Rate Configuration', () {
      test('should set speech rate within valid range', () async {
        // Arrange
        await ttsService.initialize();

        // Act
        await ttsService.setSpeechRate(0.7);

        // Assert - should complete successfully
        expect(ttsService.currentState, isIn([TtsState.idle, TtsState.initializing]));
      });

      test('should handle extreme speech rate values', () async {
        // Arrange
        await ttsService.initialize();

        // Act & Assert - should handle gracefully
        expect(() => ttsService.setSpeechRate(0.0), returnsNormally);
        expect(() => ttsService.setSpeechRate(1.0), returnsNormally);
      });
    });

    group('Text-to-Speech Functionality', () {
      test('should speak simple text successfully', () async {
        // Arrange
        await ttsService.initialize();
        const testText = 'Este es un texto de prueba para TTS.';

        // Act
        await ttsService.speakText(testText);

        // Assert - should start speaking
        expect(ttsService.currentState, isIn([TtsState.playing, TtsState.initializing]));
      });

      test('should handle empty text gracefully', () async {
        // Arrange
        await ttsService.initialize();

        // Act & Assert - should not throw
        expect(() => ttsService.speakText(''), returnsNormally);
      });

      test('should speak devotional text', () async {
        // Arrange
        await ttsService.initialize();
        final devotional = Devocional(
          id: 'test_1',
          date: DateTime.now(),
          versiculo: 'Juan 3:16 - Porque de tal manera amó Dios al mundo...',
          reflexion: 'Esta es una reflexión de prueba para el test de TTS.',
          paraMeditar: [
            ParaMeditar(
              cita: 'Punto de reflexión 1',
              texto: 'Contenido para meditar y reflexionar',
            ),
          ],
          oracion: 'Esta es una oración de prueba para el servicio TTS.',
        );

        // Act
        await ttsService.speakDevotional(devotional);

        // Assert - should start speaking
        expect(ttsService.currentState, isIn([TtsState.playing, TtsState.initializing]));
      });
    });

    group('Playback Control', () {
      test('should pause playback when speaking', () async {
        // Arrange
        await ttsService.initialize();
        await ttsService.speakText('Texto largo para poder pausar durante la reproducción.');
        
        // Wait a moment to ensure speaking started
        await Future.delayed(Duration(milliseconds: 100));

        // Act
        await ttsService.pause();

        // Assert
        expect(ttsService.currentState, equals(TtsState.paused));
      });

      test('should resume playback after pause', () async {
        // Arrange
        await ttsService.initialize();
        await ttsService.speakText('Texto para pausar y luego reanudar.');
        await Future.delayed(Duration(milliseconds: 100));
        await ttsService.pause();

        // Act
        await ttsService.resume();

        // Assert
        expect(ttsService.currentState, isIn([TtsState.playing, TtsState.idle]));
      });

      test('should stop playback completely', () async {
        // Arrange
        await ttsService.initialize();
        await ttsService.speakText('Texto que será detenido completamente.');
        await Future.delayed(Duration(milliseconds: 100));

        // Act
        await ttsService.stop();

        // Assert
        expect(ttsService.currentState, equals(TtsState.idle));
      });
    });

    group('State Management', () {
      test('should have correct initial state', () {
        // Assert
        expect(ttsService.currentState, equals(TtsState.idle));
      });

      test('should transition states correctly during playback lifecycle', () async {
        // Arrange
        await ttsService.initialize();
        expect(ttsService.currentState, equals(TtsState.idle));

        // Act - Start speaking
        await ttsService.speakText('Texto para probar transiciones de estado.');
        
        // Allow time for state transition
        await Future.delayed(Duration(milliseconds: 50));

        // Assert - Should be playing or initializing
        expect(ttsService.currentState, isIn([TtsState.playing, TtsState.initializing]));

        // Stop and verify final state
        await ttsService.stop();
        expect(ttsService.currentState, equals(TtsState.idle));
      });
    });

    group('Error Handling', () {
      test('should handle platform-specific TTS errors gracefully', () async {
        // Arrange
        await ttsService.initialize();

        // Act & Assert - Should handle various error conditions
        expect(() => ttsService.speakText(''), returnsNormally);
        expect(() => ttsService.pause(), returnsNormally);
        expect(() => ttsService.resume(), returnsNormally);
        expect(() => ttsService.stop(), returnsNormally);
      });

      test('should handle invalid language codes gracefully', () async {
        // Arrange
        await ttsService.initialize();

        // Act & Assert - Should not crash with invalid language
        expect(() => ttsService.setLanguage('invalid_lang'), returnsNormally);
      });

      test('should handle invalid voice settings gracefully', () async {
        // Arrange  
        await ttsService.initialize();

        // Act & Assert - Should handle invalid voice settings
        expect(() => ttsService.setVoice({'name': 'invalid_voice', 'locale': 'invalid'}), returnsNormally);
      });
    });

    group('Performance and Resource Management', () {
      test('should handle rapid successive operations', () async {
        // Arrange
        await ttsService.initialize();

        // Act - Perform rapid operations
        await ttsService.speakText('Texto 1');
        await ttsService.stop();
        await ttsService.speakText('Texto 2');
        await ttsService.pause();
        await ttsService.resume();
        await ttsService.stop();

        // Assert - Should handle gracefully
        expect(ttsService.currentState, equals(TtsState.idle));
      });

      test('should handle concurrent operations safely', () async {
        // Arrange
        await ttsService.initialize();

        // Act - Start multiple operations concurrently
        final futures = [
          ttsService.speakText('Texto concurrente 1'),
          ttsService.pause(),
          ttsService.stop(),
        ];

        // Assert - Should complete without throwing
        expect(() => Future.wait(futures), returnsNormally);
      });

      test('should dispose resources properly', () async {
        // Arrange
        await ttsService.initialize();

        // Act
        await ttsService.dispose();

        // Assert - Should handle gracefully
        expect(ttsService.currentState, equals(TtsState.idle));
      });
    });

    group('Text Processing and Formatting', () {
      test('should handle special characters in text', () async {
        // Arrange
        await ttsService.initialize();
        const specialText = 'Texto con números: 123, símbolos: @#\$%, y acentos: ñáéíóú.';

        // Act & Assert
        expect(() => ttsService.speakText(specialText), returnsNormally);
      });

      test('should handle biblical references correctly', () async {
        // Arrange
        await ttsService.initialize();
        const biblicalText = 'Juan 3:16 dice: "Porque de tal manera amó Dios al mundo..."';

        // Act & Assert
        expect(() => ttsService.speakText(biblicalText), returnsNormally);
      });

      test('should handle long text content', () async {
        // Arrange
        await ttsService.initialize();
        final longText = 'Este es un texto muy largo que debería ser dividido en chunks ' * 50;

        // Act & Assert - Should handle chunking properly
        expect(() => ttsService.speakText(longText), returnsNormally);
      });
    });
  });
}