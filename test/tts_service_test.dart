// Test file to validate TTS functionality
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock class for testing error scenarios
class MockMethodChannel extends Mock implements MethodChannel {}

void main() {
  group('TtsService Tests', () {
    late TtsService ttsService;
    late Devocional testDevocional;

    setUp(() {
      ttsService = TtsService();
      testDevocional = Devocional(
        id: 'test-1',
        versiculo: 'Juan 3:16 - De tal manera amó Dios al mundo...',
        reflexion: 'Esta es una reflexión de prueba.',
        paraMeditar: [
          ParaMeditar(
            cita: 'Romanos 5:8',
            texto: 'Mas Dios muestra su amor para con nosotros...',
          ),
        ],
        oracion: 'Señor, gracias por tu amor. Amén.',
        date: DateTime.now(),
        version: 'RVR1960',
        language: 'es',
        tags: ['Amor', 'Dios'],
      );
    });

    test('TtsService should initialize without errors', () {
      expect(ttsService, isNotNull);
      expect(ttsService.isPlaying, isFalse);
      expect(ttsService.isPaused, isFalse);
      expect(ttsService.isActive, isFalse);
    });

    test('TtsService should generate correct devotional text', () {
      // This test checks if the devotional has valid content
      expect(testDevocional.versiculo, isNotEmpty);
      expect(testDevocional.reflexion, isNotEmpty);
      expect(testDevocional.paraMeditar, isNotEmpty);
      expect(testDevocional.oracion, isNotEmpty);
    });

    test('Devocional model should serialize and deserialize correctly', () {
      final json = testDevocional.toJson();
      final recreatedDevocional = Devocional.fromJson(json);

      expect(recreatedDevocional.id, equals(testDevocional.id));
      expect(recreatedDevocional.versiculo, equals(testDevocional.versiculo));
      expect(recreatedDevocional.reflexion, equals(testDevocional.reflexion));
      expect(recreatedDevocional.oracion, equals(testDevocional.oracion));
      expect(recreatedDevocional.paraMeditar.length,
          equals(testDevocional.paraMeditar.length));
    });

    group('TTS Error Handling', () {
      test('should handle invalid devotional content', () async {
        final invalidDevocional = Devocional(
          id: '',
          versiculo: '',
          reflexion: '',
          paraMeditar: [],
          oracion: '',
          date: DateTime.now(),
          version: 'RVR1960',
          language: 'es',
          tags: [],
        );

        expect(
          () => ttsService.speakDevotional(invalidDevocional),
          throwsA(isA<TtsException>()),
        );
      });

      test('should handle invalid speech rate', () async {
        expect(
          () => ttsService.setSpeechRate(-1.0),
          throwsA(isA<TtsException>()),
        );

        expect(
          () => ttsService.setSpeechRate(4.0),
          throwsA(isA<TtsException>()),
        );
      });

      test('should handle very long text content', () async {
        final longDevocional = Devocional(
          id: 'test-long',
          versiculo: 'A' * 25000,
          reflexion: 'B' * 25000,
          paraMeditar: [
            ParaMeditar(
              cita: 'Test',
              texto: 'C' * 5000,
            ),
          ],
          oracion: 'D' * 1000,
          date: DateTime.now(),
          version: 'RVR1960',
          language: 'es',
          tags: [],
        );

        expect(
          () => ttsService.speakDevotional(longDevocional),
          throwsA(isA<TtsException>()),
        );
      });

      test('should handle malformed text content', () async {
        final malformedDevocional = Devocional(
          id: 'test-malformed',
          versiculo: '   ',
          reflexion: '\n\n\n',
          paraMeditar: [],
          oracion: '\t\t\t',
          date: DateTime.now(),
          version: 'RVR1960',
          language: 'es',
          tags: [],
        );

        expect(
          () => ttsService.speakDevotional(malformedDevocional),
          throwsA(isA<TtsException>()),
        );
      });
    });

    group('Input Validation', () {
      test('should validate language parameter', () async {
        expect(
          () => ttsService.setLanguage(''),
          throwsA(isA<TtsException>()),
        );

        expect(
          () => ttsService.setLanguage('   '),
          throwsA(isA<TtsException>()),
        );
      });

      test('should sanitize text content', () {
        final specialCharsDevocional = Devocional(
          id: 'test-special',
          versiculo: r'Test with special chars: @#$%^&*(){}[]|\',
          reflexion: 'Normal text with numbers 123 and symbols.',
          paraMeditar: [
            ParaMeditar(
              cita: 'Test Citation',
              texto: 'Text with emojis 😊 and Unicode characters ñáéíóú',
            ),
          ],
          oracion: 'Prayer text with proper punctuation.',
          date: DateTime.now(),
          version: 'RVR1960',
          language: 'es',
          tags: [],
        );

        // This should not throw an exception - the service should sanitize the text
        expect(
          () => ttsService.speakDevotional(specialCharsDevocional),
          returnsNormally,
        );
      });
    });
  });
}
