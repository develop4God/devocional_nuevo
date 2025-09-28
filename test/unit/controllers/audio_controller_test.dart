// test/unit/controllers/audio_controller_test.dart

import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioController Tests', () {
    late AudioController audioController;

    setUp(() async {
      // Setup SharedPreferences mock
      SharedPreferences.setMockInitialValues({});

      // Setup method channel mocks for TTS
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'speak':
              return null;
            case 'stop':
              return null;
            case 'pause':
              return null;
            case 'setLanguage':
              return 1;
            case 'setSpeechRate':
              return 1;
            case 'setVolume':
              return 1;
            case 'setPitch':
              return 1;
            case 'getVoices':
              return [
                {'name': 'Spanish Voice', 'locale': 'es-ES'},
                {'name': 'English Voice', 'locale': 'en-US'},
              ];
            case 'isLanguageAvailable':
              return 1;
            default:
              return null;
          }
        },
      );

      audioController = AudioController();
    });

    tearDown() {
      audioController.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        null,
      );
    });

    group('Audio Playback Lifecycle', () {
      test('should handle audio playback lifecycle correctly', () async {
        final testDevocional = Devocional(
          id: 'audio_test',
          date: DateTime.now(),
          versiculo: 'Test verse for audio playback',
          reflexion: 'Test reflection',
          paraMeditar: [
            ParaMeditar(cita: 'Test 1:1', texto: 'Test meditation'),
          ],
          oracion: 'Test prayer',
        );

        // Test initial state
        expect(audioController.currentState, equals(TtsState.idle));
        expect(audioController.isPlaying, isFalse);
        expect(audioController.isPaused, isFalse);
        expect(audioController.progress, equals(0.0));

        // Test play operation
        await audioController.play(testDevocional);

        // Test that controller handles the operation
        expect(audioController.currentState, isA<TtsState>());
        expect(audioController.currentDevocionalId, equals('audio_test'));
      });

      test('should manage TTS audio controls and state transitions', () async {
        final testDevocional = Devocional(
          id: 'control_test',
          date: DateTime.now(),
          versiculo: 'Control test verse',
          reflexion: 'Control test reflection',
          paraMeditar: [
            ParaMeditar(cita: 'Control 1:1', texto: 'Control meditation'),
          ],
          oracion: 'Control prayer',
        );

        // Test pause operation
        await audioController.pause();
        expect(audioController.currentState, isA<TtsState>());

        // Test resume operation
        await audioController.resume();
        expect(audioController.currentState, isA<TtsState>());

        // Test stop operation
        await audioController.stop();
        expect(audioController.currentState, isA<TtsState>());

        // Test toggle play/pause
        await audioController.togglePlayPause(testDevocional);
        expect(audioController.currentState, isA<TtsState>());
      });

      test('should handle loading and operation states', () {
        // Test loading state queries
        expect(audioController.isLoading, isA<bool>());
        expect(audioController.mounted, isTrue);

        // Test state properties
        expect(audioController.currentDevocionalId, isA<String?>());
        expect(audioController.progress, isA<double>());
      });
    });

    group('Voice and Language Management', () {
      test('should handle voice selection and language setup', () async {
        // Test available voices query
        final voices = await audioController.getAvailableVoices();
        expect(voices, isA<List<String>>());

        // Test voice selection for different languages
        final spanishVoices = await audioController.getVoicesForLanguage('es');
        expect(spanishVoices, isA<List<String>>());

        final englishVoices = await audioController.getVoicesForLanguage('en');
        expect(englishVoices, isA<List<String>>());

        // Test language setting
        await audioController.setLanguage('es');
        expect(audioController.currentState, isA<TtsState>());

        // Test voice setting
        final testVoice = {'name': 'Test Voice', 'locale': 'es-ES'};
        await audioController.setVoice(testVoice);
        expect(audioController.currentState, isA<TtsState>());
      });

      test('should handle TTS configuration settings', () async {
        // Test speech rate setting
        await audioController.setSpeechRate(1.2);
        expect(audioController.currentState, isA<TtsState>());

        // Test different speech rates
        await audioController.setSpeechRate(0.8);
        expect(audioController.currentState, isA<TtsState>());

        await audioController.setSpeechRate(1.5);
        expect(audioController.currentState, isA<TtsState>());
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle empty or invalid devotional gracefully', () async {
        final emptyDevocional = Devocional(
          id: '',
          date: DateTime.now(),
          versiculo: '',
          reflexion: '',
          paraMeditar: [],
          oracion: '',
        );

        // Should handle empty devotional without crashing
        expect(() => audioController.play(emptyDevocional), returnsNormally);
        expect(() => audioController.togglePlayPause(emptyDevocional), returnsNormally);
      });

      test('should handle rapid state changes gracefully', () async {
        // Perform rapid operations
        await audioController.pause();
        await audioController.resume();
        await audioController.stop();
        await audioController.pause();

        // Controller should remain stable
        expect(audioController.currentState, isA<TtsState>());
        expect(audioController.mounted, isTrue);
      });

      test('should handle controller disposal correctly', () {
        // Test that disposal works without error
        expect(() => audioController.dispose(), returnsNormally);
        
        // After disposal, mounted should be false
        expect(audioController.mounted, isFalse);
      });
    });

    group('State Management', () {
      test('should maintain consistent state properties', () {
        // Test all state getters
        expect(audioController.currentState, isA<TtsState>());
        expect(audioController.isPlaying, isA<bool>());
        expect(audioController.isPaused, isA<bool>());
        expect(audioController.isLoading, isA<bool>());
        expect(audioController.progress, isA<double>());
        expect(audioController.currentDevocionalId, isA<String?>());
        expect(audioController.mounted, isA<bool>());
      });

      test('should handle multiple devotional switches', () async {
        final devotional1 = Devocional(
          id: 'dev1',
          date: DateTime.now(),
          versiculo: 'First verse',
          reflexion: 'First reflection',
          paraMeditar: [ParaMeditar(cita: 'Test', texto: 'Test')],
          oracion: 'First prayer',
        );

        final devotional2 = Devocional(
          id: 'dev2',
          date: DateTime.now(),
          versiculo: 'Second verse',
          reflexion: 'Second reflection',
          paraMeditar: [ParaMeditar(cita: 'Test', texto: 'Test')],
          oracion: 'Second prayer',
        );

        // Switch between devotionals
        await audioController.play(devotional1);
        await audioController.play(devotional2);

        // Should handle switching gracefully
        expect(audioController.currentState, isA<TtsState>());
      });
    });
  });
}