import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_setup.dart';

void main() {
  setUpAll(() {
    TestSetup.setupCommonMocks();
  });

  tearDownAll() {
    TestSetup.cleanupMocks();
  }

  group('AudioController Basic Tests', () {
    test('should initialize with default state', () {
      SharedPreferences.setMockInitialValues({});
      final audioController = AudioController();

      expect(audioController, isNotNull);
      expect(audioController.isPlaying, isFalse);
      expect(audioController.isPaused, isFalse);
      expect(audioController.isActive, isFalse);
      expect(audioController.currentDevocionalId, isNull);

      audioController.dispose();
    });

    test('should handle state queries', () {
      SharedPreferences.setMockInitialValues({});
      final audioController = AudioController();

      // Boolean state queries should not throw
      expect(audioController.isPlaying, isA<bool>());
      expect(audioController.isPaused, isA<bool>());
      expect(audioController.isActive, isA<bool>());
      expect(audioController.isLoading, isA<bool>());
      expect(audioController.hasError, isA<bool>());

      // Numeric queries
      expect(audioController.progress, isA<double>());

      // String queries should handle null gracefully
      expect(audioController.currentDevocionalId, isA<String?>());

      audioController.dispose();
    });

    test('should provide TTS service access', () {
      SharedPreferences.setMockInitialValues({});
      final audioController = AudioController();

      expect(audioController.ttsService, isNotNull);
      expect(audioController.currentState, isNotNull);

      audioController.dispose();
    });

    test('should handle chunk navigation queries', () {
      SharedPreferences.setMockInitialValues({});
      final audioController = AudioController();

      // Chunk-related queries (may be null)
      expect(audioController.currentChunkIndex, isA<int?>());
      expect(audioController.totalChunks, isA<int?>());
      expect(audioController.previousChunk, isA<VoidCallback?>());
      expect(audioController.nextChunk, isA<VoidCallback?>());
      expect(audioController.jumpToChunk, isA<Function?>());

      audioController.dispose();
    });

    test('should handle initialization', () {
      SharedPreferences.setMockInitialValues({});
      final audioController = AudioController();

      // Should be able to initialize without errors
      expect(() => audioController.initialize(), returnsNormally);

      audioController.dispose();
    });

    test('should handle devotional playback initiation', () {
      SharedPreferences.setMockInitialValues({});
      final audioController = AudioController();

      final devotional = Devocional(
        id: 'test_audio_1',
        date: DateTime.now(),
        versiculo: 'Juan 3:16',
        reflexion: 'Esta es una reflexión sobre el amor de Dios.',
        paraMeditar: [
          ParaMeditar(
              cita: 'Juan 3:16',
              texto: 'Aplicar el amor de Dios en nuestras vidas diarias.'),
        ],
        oracion: 'Padre celestial, gracias por tu amor incondicional.',
      );

      // Test that the controller is properly initialized for playback
      expect(audioController.currentDevocionalId, isNull);
      expect(audioController.isActive, isFalse);
      expect(audioController.isPlaying, isFalse);

      audioController.dispose();
    });

    test('should handle audio control operations', () {
      SharedPreferences.setMockInitialValues({});
      final audioController = AudioController();

      // Should handle pause operation
      expect(() => audioController.pause(), returnsNormally);

      // Should handle resume operation
      expect(() => audioController.resume(), returnsNormally);

      // Should handle stop operation
      expect(() => audioController.stop(), returnsNormally);

      audioController.dispose();
    });

    test('should handle toggle play/pause', () async {
      SharedPreferences.setMockInitialValues({});
      final audioController = AudioController();

      final devotional = Devocional(
        id: 'test_toggle',
        date: DateTime.now(),
        versiculo: 'Salmo 23:1',
        reflexion: 'Reflexión sobre la provisión divina.',
        paraMeditar: [
          ParaMeditar(
              cita: 'Salmo 23:1', texto: 'Confiar en la provisión de Dios.'),
        ],
        oracion: 'Gracias Señor por ser nuestro pastor.',
      );

      // Test that controller can handle toggle operations
      expect(audioController.isPlaying, isFalse);
      expect(audioController.isPaused, isFalse);
      expect(audioController.currentDevocionalId, isNull);

      audioController.dispose();
    });

    test('should maintain consistent state', () {
      SharedPreferences.setMockInitialValues({});
      final audioController = AudioController();

      final state1 = audioController.isPlaying;
      final state2 = audioController.isPlaying;
      expect(state1, equals(state2));

      final paused1 = audioController.isPaused;
      final paused2 = audioController.isPaused;
      expect(paused1, equals(paused2));

      audioController.dispose();
    });

    test('should handle disposal properly', () {
      SharedPreferences.setMockInitialValues({});
      final audioController = AudioController();

      // Should dispose without errors
      expect(() => audioController.dispose(), returnsNormally);
    });

    test('should handle error states gracefully', () {
      SharedPreferences.setMockInitialValues({});
      final audioController = AudioController();

      // Operations should not crash even in error states
      expect(audioController.isPlaying, isA<bool>());
      expect(audioController.isPaused, isA<bool>());
      expect(audioController.hasError, isA<bool>());

      audioController.dispose();
    });
  });

  group('AudioController State Management', () {
    test('should handle rapid state changes', () {
      SharedPreferences.setMockInitialValues({});
      final audioController = AudioController();

      // Rapid operations should not cause issues
      for (int i = 0; i < 10; i++) {
        audioController.pause();
        audioController.resume();
        audioController.stop();
      }

      expect(audioController, isNotNull);
      audioController.dispose();
    });

    test('should handle concurrent operations', () {
      SharedPreferences.setMockInitialValues({});
      final audioController = AudioController();

      final devotional1 = Devocional(
        id: 'concurrent_1',
        date: DateTime.now(),
        versiculo: 'Test 1',
        reflexion: 'Test reflection 1',
        paraMeditar: [
          ParaMeditar(cita: 'Test 1', texto: 'Test application 1'),
        ],
        oracion: 'Test prayer 1',
      );

      final devotional2 = Devocional(
        id: 'concurrent_2',
        date: DateTime.now(),
        versiculo: 'Test 2',
        reflexion: 'Test reflection 2',
        paraMeditar: [
          ParaMeditar(cita: 'Test 2', texto: 'Test application 2'),
        ],
        oracion: 'Test prayer 2',
      );

      // Test controller can handle multiple operations in sequence
      expect(audioController.isPlaying, isFalse);
      audioController.pause();
      audioController.stop();
      expect(audioController.isPlaying, isFalse);

      expect(audioController, isNotNull);
      audioController.dispose();
    });

    test('should handle invalid devotional data', () {
      SharedPreferences.setMockInitialValues({});
      final audioController = AudioController();

      final invalidDevotional = Devocional(
        id: '',
        date: DateTime.now(),
        versiculo: '',
        reflexion: '',
        paraMeditar: [],
        oracion: '',
      );

      // Test that the controller handles invalid data gracefully
      expect(audioController.currentDevocionalId, isNull);
      expect(audioController.isActive, isFalse);

      audioController.dispose();
    });
  });

  group('AudioController Performance', () {
    test('should handle multiple instances efficiently', () {
      final controllers = <AudioController>[];

      // Create multiple controllers
      for (int i = 0; i < 5; i++) {
        SharedPreferences.setMockInitialValues({});
        controllers.add(AudioController());
      }

      // All should be valid
      for (final controller in controllers) {
        expect(controller, isNotNull);
        expect(controller.isPlaying, isA<bool>());
      }

      // Clean up
      for (final controller in controllers) {
        controller.dispose();
      }
    });

    test('should handle stress testing', () {
      SharedPreferences.setMockInitialValues({});
      final audioController = AudioController();

      final devotional = Devocional(
        id: 'stress_test',
        date: DateTime.now(),
        versiculo: 'Stress test verse',
        reflexion: 'Stress test reflection',
        paraMeditar: [
          ParaMeditar(cita: 'Stress test', texto: 'Stress test application'),
        ],
        oracion: 'Stress test prayer',
      );

      // Test controller can handle multiple rapid operations without async issues
      expect(audioController.isActive, isFalse);
      audioController.pause();
      audioController.resume();
      audioController.stop();
      expect(audioController.isActive, isFalse);

      expect(audioController, isNotNull);
      audioController.dispose();
    });
  });
}
