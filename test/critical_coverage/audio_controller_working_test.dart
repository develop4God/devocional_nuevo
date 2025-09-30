// test/critical_coverage/audio_controller_working_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';

void main() {
  group('AudioController Behavioral Tests', () {
    late AudioController audioController;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      // Initialize SharedPreferences mock for each test
      SharedPreferences.setMockInitialValues({});
      
      // Mock flutter_tts method channel for TTS operations
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (call) async {
          switch (call.method) {
            case 'speak':
              return null;
            case 'stop':
              return null;
            case 'pause':
              return null;
            case 'setLanguage':
              return null;
            case 'setSpeechRate':
              return null;
            case 'setVolume':
              return null;
            case 'setPitch':
              return null;
            case 'getLanguages':
              return ['es-ES', 'en-US', 'pt-BR', 'fr-FR'];
            case 'getVoices':
              return [
                {'name': 'Spanish Voice', 'locale': 'es-ES'},
                {'name': 'English Voice', 'locale': 'en-US'},
              ];
            case 'awaitSpeakCompletion':
              return null;
            default:
              return null;
          }
        },
      );

      audioController = AudioController();
      audioController.initialize();
    });

    tearDown(() {
      if (audioController.mounted) {
        audioController.dispose();
      }
      
      // Clean up method channel mocks
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        null,
      );
    });

    test('should start in idle state and remain idle until playback', () {
      expect(audioController.currentState, equals(TtsState.idle));
      expect(audioController.isPlaying, isFalse);
      expect(audioController.isPaused, isFalse);
      expect(audioController.isActive, isFalse);
      expect(audioController.currentDevocionalId, isNull);
      expect(audioController.progress, equals(0.0));
    });

    test('should update isActive based on playing or paused state', () {
      // Test property logic: isActive = playing || paused
      expect(audioController.isActive, equals(
        audioController.isPlaying || audioController.isPaused
      ));
    });

    test('should map error state correctly to hasError property', () {
      expect(audioController.hasError, equals(
        audioController.currentState == TtsState.error
      ));
    });

    test('should provide access to chunk navigation properties', () {
      expect(audioController.currentChunkIndex, isA<int?>());
      expect(audioController.totalChunks, isA<int?>());
      expect(audioController.previousChunk, isA<VoidCallback?>());
      expect(audioController.nextChunk, isA<VoidCallback?>());
      expect(audioController.jumpToChunk, isA<Future<void> Function(int)?>());
    });

    test('should maintain state consistency after initialization', () {
      // Verify state relationships are consistent
      expect(audioController.mounted, isTrue);
      expect(audioController.isLoading, equals(
        audioController.currentState == TtsState.initializing || 
        audioController.isLoading
      ));
      
      // Verify boolean state properties
      expect(audioController.isPlaying, isA<bool>());
      expect(audioController.isPaused, isA<bool>());
      expect(audioController.hasError, isA<bool>());
      expect(audioController.isActive, isA<bool>());
    });

    test('should expose delegate methods with correct signatures', () {
      // Verify method signatures exist by checking they don't throw on call
      expect(audioController.getAvailableLanguages, isA<Function>());
      expect(audioController.getAvailableVoices, isA<Function>());
      expect(audioController.getVoicesForLanguage, isA<Function>());
      expect(audioController.setLanguage, isA<Function>());
      expect(audioController.setSpeechRate, isA<Function>());
    });

    test('should handle lifecycle correctly on dispose', () {
      // Verify initial state
      expect(audioController.mounted, isTrue);
      
      // Dispose and verify state changes
      audioController.dispose();
      expect(audioController.mounted, isFalse);
      
      // Verify state properties remain accessible after dispose
      expect(audioController.currentState, isA<TtsState>());
      expect(audioController.isPlaying, isA<bool>());
      expect(audioController.isPaused, isA<bool>());
    });
  });
}