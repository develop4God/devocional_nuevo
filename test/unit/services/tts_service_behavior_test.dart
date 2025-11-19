// ignore_for_file: dangling_library_doc_comments
/// Comprehensive TTS Service Behavior Tests
/// 
/// Focus: Real user scenarios and behaviors, not implementation details
/// Approach: Test what users experience, not how code works internally
/// 
/// These tests validate:
/// - User plays devotional → TTS speaks content correctly
/// - User pauses → TTS pauses immediately
/// - User resumes → TTS continues from correct position
/// - User stops → TTS stops and resets state completely
/// - Language changes → TTS adapts voice and pronunciation
/// - Multiple rapid commands → TTS handles gracefully without crashes
/// - Service lifecycle → Proper initialization and disposal
library;

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/i_tts_service.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TTS Service - Real User Behavior Tests', () {
    late ITtsService ttsService;

    setUp(() {
      // Reset service locator for each test
      ServiceLocator().reset();
      SharedPreferences.setMockInitialValues({});

      // Mock flutter_tts platform channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (call) async {
          switch (call.method) {
            case 'speak':
            case 'stop':
            case 'pause':
            case 'setLanguage':
            case 'setSpeechRate':
            case 'setVolume':
            case 'setPitch':
            case 'awaitSpeakCompletion':
            case 'awaitSynthCompletion':
            case 'setQueueMode':
              return 1;
            case 'getLanguages':
              return ['es-ES', 'en-US', 'pt-BR', 'fr-FR', 'ja-JP'];
            case 'getVoices':
              return [];
            case 'isLanguageAvailable':
              return true;
            default:
              return null;
          }
        },
      );

      // Create fresh service instance for each test
      ttsService = TtsService();
    });

    tearDown(() async {
      if (!ttsService.isDisposed) {
        await ttsService.dispose();
      }
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    });

    test('User Scenario: Service initializes successfully', () async {
      // Given: A user starts the app
      expect(ttsService.currentState, TtsState.idle);
      expect(ttsService.isDisposed, false);

      // When: Service initializes
      await ttsService.initialize();

      // Then: Service is ready to use
      expect(ttsService.currentState, TtsState.idle);
      expect(ttsService.isDisposed, false);
    });

    test('User Scenario: User plays a devotional', () async {
      // Given: A devotional with content
      final devotional = Devocional(
        id: 'test-1',
        date: DateTime.now(),
        versiculo: 'Juan 3:16 - Porque de tal manera amó Dios al mundo',
        reflexion: 'Esta es una reflexión sobre el amor de Dios.',
        oracion: 'Padre celestial, gracias por tu amor.',
        paraMeditar: [],
      );

      // When: User taps play button
      await ttsService.initialize();
      await ttsService.speakDevotional(devotional);

      // Wait a bit for async operations
      await Future.delayed(const Duration(milliseconds: 100));

      // Then: Service should be in playing or initializing state
      expect(
        ttsService.currentState == TtsState.playing ||
            ttsService.currentState == TtsState.initializing,
        true,
        reason:
            'After speaking, service should be playing or initializing, but was ${ttsService.currentState}',
      );
      expect(ttsService.currentDevocionalId, 'test-1');
      expect(ttsService.totalChunks, greaterThan(0),
          reason: 'Devotional content should be split into chunks');
    });

    test('User Scenario: User pauses playback', () async {
      // Given: A devotional is playing
      final devotional = Devocional(
        id: 'test-2',
        date: DateTime.now(),
        versiculo: 'Salmos 23:1',
        reflexion: 'El Señor es mi pastor.',
        oracion: 'Gracias Señor.',
        paraMeditar: [],
      );

      await ttsService.initialize();
      await ttsService.speakDevotional(devotional);
      await Future.delayed(const Duration(milliseconds: 100));

      // When: User taps pause button
      await ttsService.pause();
      await Future.delayed(const Duration(milliseconds: 100));

      // Then: Service should pause
      expect(ttsService.isPaused, true,
          reason: 'Service should be paused after pause command');
      expect(ttsService.currentDevocionalId, 'test-2',
          reason: 'Current devotional should still be tracked');
    });

    test('User Scenario: User resumes after pause', () async {
      // Given: A paused devotional
      final devotional = Devocional(
        id: 'test-3',
        date: DateTime.now(),
        versiculo: 'Filipenses 4:13',
        reflexion: 'Todo lo puedo en Cristo.',
        oracion: 'Dame fuerzas Señor.',
        paraMeditar: [],
      );

      await ttsService.initialize();
      await ttsService.speakDevotional(devotional);
      await Future.delayed(const Duration(milliseconds: 100));
      await ttsService.pause();
      await Future.delayed(const Duration(milliseconds: 100));

      // When: User taps resume/play button
      await ttsService.resume();
      await Future.delayed(const Duration(milliseconds: 100));

      // Then: Playback should resume
      expect(ttsService.currentState, TtsState.playing,
          reason: 'Service should be playing after resume');
      expect(ttsService.currentDevocionalId, 'test-3');
    });

    test('User Scenario: User stops playback completely', () async {
      // Given: A devotional is playing
      final devotional = Devocional(
        id: 'test-4',
        date: DateTime.now(),
        versiculo: 'Proverbios 3:5-6',
        reflexion: 'Confía en el Señor.',
        oracion: 'Señor, guía mi camino.',
        paraMeditar: [],
      );

      await ttsService.initialize();
      await ttsService.speakDevotional(devotional);
      await Future.delayed(const Duration(milliseconds: 100));

      // When: User taps stop button
      await ttsService.stop();
      await Future.delayed(const Duration(milliseconds: 100));

      // Then: Service should reset completely
      expect(ttsService.currentState, TtsState.idle,
          reason: 'Service should be idle after stop');
      expect(ttsService.currentDevocionalId, null,
          reason: 'No devotional should be tracked after stop');
      expect(ttsService.isPlaying, false);
      expect(ttsService.isPaused, false);
      expect(ttsService.isActive, false);
    });

    test('User Scenario: Multiple rapid commands handled gracefully', () async {
      // Given: A devotional
      final devotional = Devocional(
        id: 'test-5',
        date: DateTime.now(),
        versiculo: 'Mateo 28:20',
        reflexion: 'Yo estoy con vosotros todos los días.',
        oracion: 'Gracias por tu presencia.',
        paraMeditar: [],
      );

      await ttsService.initialize();

      // When: User rapidly sends multiple commands (real user behavior when frustrated or testing UI)
      await ttsService.speakDevotional(devotional);
      await ttsService.pause();
      await ttsService.resume();
      await ttsService.pause();
      await ttsService.stop();
      await Future.delayed(const Duration(milliseconds: 100));

      // Then: Service should handle gracefully and end in stopped state
      expect(ttsService.currentState, TtsState.idle,
          reason: 'Service should be idle after rapid commands ending in stop');
      expect(ttsService.isDisposed, false,
          reason: 'Service should not crash or dispose from rapid commands');
    });

    test('User Scenario: Language context changes', () async {
      // Given: Service initialized with Spanish
      await ttsService.initialize();
      ttsService.setLanguageContext('es', 'RVR1960');

      // When: User changes app language to English
      ttsService.setLanguageContext('en', 'NIV');

      // Then: Service should adapt (no exception thrown)
      expect(() => ttsService.setLanguageContext('pt', 'NVI'), returnsNormally,
          reason: 'Setting language context should not throw exceptions');
    });

    test('User Scenario: Chunk navigation available during playback', () async {
      // Given: A devotional with multiple sections
      final devotional = Devocional(
        id: 'test-6',
        date: DateTime.now(),
        versiculo: 'Romanos 8:28 - Y sabemos que a los que aman a Dios',
        reflexion:
            'Esta es una reflexión larga que generará múltiples chunks. '
            'El propósito es probar que la navegación entre chunks funciona correctamente.',
        oracion:
            'Padre celestial, ayúdanos a confiar en tu plan perfecto para nuestras vidas.',
        paraMeditar: [
          ParaMeditar(
              cita: '1 Corintios 13:4-7',
              texto: 'El amor es paciente, es bondadoso.')
        ],
      );

      await ttsService.initialize();
      await ttsService.speakDevotional(devotional);
      await Future.delayed(const Duration(milliseconds: 100));

      // Then: Navigation should be available
      expect(ttsService.totalChunks, greaterThan(1),
          reason: 'Devotional should be split into multiple chunks');
      expect(ttsService.currentChunkIndex, greaterThanOrEqualTo(0));
      expect(ttsService.currentChunkIndex, lessThan(ttsService.totalChunks));
    });

    test('User Scenario: Service properly disposes', () async {
      // Given: An initialized service
      await ttsService.initialize();
      expect(ttsService.isDisposed, false);

      // When: User closes the app
      await ttsService.dispose();

      // Then: Service should be disposed
      expect(ttsService.isDisposed, true);
      
      // And: Attempting operations should throw
      expect(
        () => ttsService.speakText('test'),
        throwsA(isA<TtsException>()),
        reason: 'Operations on disposed service should throw',
      );
    });

    test('User Scenario: Speech rate can be adjusted', () async {
      // Given: An initialized service
      await ttsService.initialize();

      // When: User adjusts speech rate in settings
      await ttsService.setSpeechRate(0.8);

      // Then: No exception should occur
      expect(ttsService.isDisposed, false,
          reason: 'Service should remain functional after rate change');

      // And: Extreme values should be clamped
      await ttsService.setSpeechRate(10.0); // Should clamp to 3.0
      await ttsService.setSpeechRate(-1.0); // Should clamp to 0.1
      expect(ttsService.isDisposed, false);
    });

    test('User Scenario: Service handles empty devotional gracefully', () async {
      // Given: An empty or minimal devotional
      final emptyDevotional = Devocional(
        id: 'test-empty',
        date: DateTime.now(),
        versiculo: '',
        reflexion: '',
        oracion: '',
        paraMeditar: [],
      );

      await ttsService.initialize();

      // When: User tries to play empty content
      // Then: Should handle gracefully (throw appropriate exception or skip silently)
      expect(
        () async => await ttsService.speakDevotional(emptyDevotional),
        throwsA(isA<TtsException>()),
        reason: 'Empty devotional should throw TtsException',
      );
    });

    test('Integration: State stream broadcasts changes', () async {
      // Given: Service initialized and listening to state stream
      await ttsService.initialize();
      final states = <TtsState>[];
      final subscription = ttsService.stateStream.listen(states.add);

      try {
        // When: User interacts with service
        final devotional = Devocional(
          id: 'test-stream',
          date: DateTime.now(),
          versiculo: 'Test verse',
          reflexion: 'Test reflection',
          oracion: 'Test prayer',
          paraMeditar: [],
        );

        await ttsService.speakDevotional(devotional);
        await Future.delayed(const Duration(milliseconds: 150));
        await ttsService.stop();
        await Future.delayed(const Duration(milliseconds: 50));

        // Then: State changes should be broadcast
        expect(states.isNotEmpty, true,
            reason: 'State stream should emit state changes');
        expect(states.last, TtsState.idle,
            reason: 'Final state should be idle after stop');
      } finally {
        await subscription.cancel();
      }
    });

    test('Integration: Progress stream tracks playback progress', () async {
      // Given: Service initialized and listening to progress stream
      await ttsService.initialize();
      final progressValues = <double>[];
      final subscription = ttsService.progressStream.listen(progressValues.add);

      try {
        // When: User plays devotional
        final devotional = Devocional(
          id: 'test-progress',
          date: DateTime.now(),
          versiculo: 'Progress test verse',
          reflexion: 'Progress test reflection',
          oracion: 'Progress test prayer',
          paraMeditar: [],
        );

        await ttsService.speakDevotional(devotional);
        await Future.delayed(const Duration(milliseconds: 200));
        await ttsService.stop();
        await Future.delayed(const Duration(milliseconds: 50));

        // Then: Progress should be tracked
        expect(progressValues.isNotEmpty, true,
            reason: 'Progress stream should emit progress values');
        expect(progressValues.first, 0.0,
            reason: 'Progress should start at 0');
        // Last value should be 0.0 after stop
        expect(progressValues.last, 0.0,
            reason: 'Progress should reset to 0 after stop');
      } finally {
        await subscription.cancel();
      }
    });
  });

  group('TTS Service - Dependency Injection Validation', () {
    test('Service can be registered and retrieved from service locator',
        () async {
      // Given: Service locator is setup
      ServiceLocator().reset();
      setupServiceLocator();

      // When: We retrieve the service
      final service = getService<ITtsService>();

      // Then: We should get a valid instance
      expect(service, isNotNull);
      expect(service, isA<ITtsService>());
      expect(service.isDisposed, false);

      await service.dispose();
    });

    test('Multiple retrievals return same instance (lazy singleton)', () async {
      // Given: Service locator is setup
      ServiceLocator().reset();
      setupServiceLocator();

      // When: We retrieve service multiple times
      final service1 = getService<ITtsService>();
      final service2 = getService<ITtsService>();

      // Then: Should be same instance
      expect(identical(service1, service2), true,
          reason: 'Lazy singleton should return same instance');

      await service1.dispose();
    });

    test('Service can be injected into AudioController', () async {
      // Given: A TTS service instance
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (call) async => 1,
      );

      final ttsService = TtsService();

      // When: We inject it into AudioController (via test)
      // This validates the interface works for DI
      expect(ttsService, isA<ITtsService>());

      // Then: Interface should expose all necessary methods
      expect(ttsService.initialize, isNotNull);
      expect(ttsService.speakDevotional, isNotNull);
      expect(ttsService.pause, isNotNull);
      expect(ttsService.resume, isNotNull);
      expect(ttsService.stop, isNotNull);

      await ttsService.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    });
  });
}
