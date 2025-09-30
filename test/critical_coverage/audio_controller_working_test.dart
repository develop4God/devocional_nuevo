// test/critical_coverage/audio_controller_working_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/services/tts_service.dart';

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

    test('should initialize with isActive false in idle state', () {
      // Verify initial state is idle
      expect(audioController.currentState, equals(TtsState.idle),
          reason: 'Controller should start in idle state');

      // Verify all activity indicators are false
      expect(audioController.isActive, isFalse,
          reason: 'isActive must be false when in idle state');
      expect(audioController.isPlaying, isFalse,
          reason: 'isPlaying must be false when in idle state');
      expect(audioController.isPaused, isFalse,
          reason: 'isPaused must be false when in idle state');

      // Verify no devotional is set
      expect(audioController.currentDevocionalId, isNull,
          reason: 'No devotional should be set initially');

      // Verify progress is zero
      expect(audioController.progress, equals(0.0),
          reason: 'Progress should be 0.0 initially');
    });

    test('should have hasError false when not in error state', () {
      // Given: Controller in idle state (not error)
      expect(audioController.currentState, equals(TtsState.idle));

      // Then: hasError must be false
      expect(audioController.hasError, isFalse,
          reason:
              'hasError should be false when currentState is not TtsState.error');

      // Note: We can't easily test hasError=true without triggering actual errors
      // but we validate the false case which is the normal operating condition
    });

    test('should return progress in valid range [0.0, 1.0]', () {
      // Verify progress is within valid bounds
      final progress = audioController.progress;

      expect(progress, greaterThanOrEqualTo(0.0),
          reason: 'Progress must be >= 0.0');
      expect(progress, lessThanOrEqualTo(1.0),
          reason: 'Progress must be <= 1.0');

      // In initial state, progress should be exactly 0.0
      expect(progress, equals(0.0), reason: 'Initial progress should be 0.0');
    });

    test('should have chunk navigation null when no chunks loaded', () {
      // Verify chunk index is null or 0 initially
      final chunkIndex = audioController.currentChunkIndex;
      expect(chunkIndex == null || chunkIndex == 0, isTrue,
          reason: 'Chunk index should be null or 0 when no audio loaded');

      // Verify total chunks is null or 0 initially
      final totalChunks = audioController.totalChunks;
      expect(totalChunks == null || totalChunks == 0, isTrue,
          reason: 'Total chunks should be null or 0 when no audio loaded');

      // Verify navigation controls are null when no chunks
      expect(audioController.previousChunk, isNull,
          reason: 'previousChunk should be null when no audio loaded');
      expect(audioController.nextChunk, isNull,
          reason: 'nextChunk should be null when no audio loaded');
    });

    test('should have mutually exclusive playing and paused states', () {
      // Verify business rule: isPlaying and isPaused cannot both be true
      final isPlaying = audioController.isPlaying;
      final isPaused = audioController.isPaused;
      final bothTrue = isPlaying && isPaused;

      expect(bothTrue, isFalse,
          reason: 'Controller cannot be playing AND paused simultaneously');

      // Additionally verify that in idle state, both are false
      expect(isPlaying, isFalse);
      expect(isPaused, isFalse);
    });

    test('should have isActive false when neither playing nor paused', () {
      // Given: Controller in idle state
      expect(audioController.currentState, equals(TtsState.idle));
      expect(audioController.isPlaying, isFalse);
      expect(audioController.isPaused, isFalse);

      // Then: isActive must be false
      expect(audioController.isActive, isFalse,
          reason: 'isActive should be false when neither playing nor paused');
    });

    test('should have mounted false after dispose', () {
      // Verify initial state
      expect(audioController.mounted, isTrue,
          reason: 'Controller should be mounted initially');

      // Dispose the controller
      audioController.dispose();

      // Verify mounted is now false
      expect(audioController.mounted, isFalse,
          reason: 'Controller should not be mounted after dispose');

      // Verify state properties remain accessible (don't throw)
      expect(() => audioController.currentState, returnsNormally);
      expect(() => audioController.isPlaying, returnsNormally);
      expect(() => audioController.isPaused, returnsNormally);
    });
  });
}
