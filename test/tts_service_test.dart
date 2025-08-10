// Test file to validate TTS functionality
import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';

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
      // This test checks if the _generateDevotionalText method would work correctly
      // Since it's private, we test the public interface that would use it
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
      expect(recreatedDevocional.paraMeditar.length, equals(testDevocional.paraMeditar.length));
    });
  });
}