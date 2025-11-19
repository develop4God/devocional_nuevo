// ignore_for_file: dangling_library_doc_comments
/// Integration tests for TTS Dependency Injection
/// 
/// These tests validate that the DI implementation works correctly
/// with real consumers (AudioController, DevocionalProvider)
/// 
/// Focus: End-to-end integration, not unit behavior
library;

import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/i_tts_service.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TTS DI Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ServiceLocator().reset();

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
              return ['es-ES', 'en-US', 'pt-BR'];
            case 'getVoices':
              return [];
            case 'isLanguageAvailable':
              return true;
            default:
              return null;
          }
        },
      );

      // Mock path_provider for DevocionalProvider
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async {
          switch (call.method) {
            case 'getApplicationDocumentsDirectory':
              return '/mock_documents';
            case 'getTemporaryDirectory':
              return '/mock_temp';
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      ServiceLocator().reset();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/path_provider'), null);
    });

    test('ServiceLocator provides ITtsService instance', () {
      // Given: Service locator is set up
      setupServiceLocator();

      // When: We request ITtsService
      final service = getService<ITtsService>();

      // Then: We get a valid instance
      expect(service, isNotNull);
      expect(service, isA<ITtsService>());
      expect(service, isA<TtsService>());
    });

    test('ServiceLocator returns same singleton instance on multiple calls',
        () {
      // Given: Service locator is set up
      setupServiceLocator();

      // When: We request service multiple times
      final service1 = getService<ITtsService>();
      final service2 = getService<ITtsService>();
      final service3 = getService<ITtsService>();

      // Then: All references should be identical (same instance)
      expect(identical(service1, service2), true,
          reason: 'Service locator should return same singleton instance');
      expect(identical(service2, service3), true);
      expect(identical(service1, service3), true);
    });

    test('AudioController works with injected ITtsService', () async {
      // Given: Service locator is set up and we have a TTS service
      setupServiceLocator();
      final ttsService = getService<ITtsService>();

      // When: We create AudioController with injected service
      final controller = AudioController(ttsService);
      controller.initialize();

      // Then: Controller should be functional
      expect(controller.currentState, TtsState.idle);
      expect(controller.isPlaying, false);
      expect(controller.isPaused, false);

      // And: We can access TTS through controller
      expect(controller.ttsService, same(ttsService));

      // Cleanup
      controller.dispose();
    });

    test('AudioController can play devotional through DI', () async {
      // Given: Service locator with TTS service
      setupServiceLocator();
      final ttsService = getService<ITtsService>();
      final controller = AudioController(ttsService);
      controller.initialize();

      // And: A devotional to play
      final devotional = Devocional(
        id: 'di-test-1',
        date: DateTime.now(),
        versiculo: 'Test verse for DI integration',
        reflexion: 'Test reflection',
        oracion: 'Test prayer',
        paraMeditar: [],
      );

      // When: We play the devotional
      await controller.playDevotional(devotional);
      await Future.delayed(const Duration(milliseconds: 200));

      // Then: Playback should start (allow time for initialization)
      expect(
        controller.currentDevocionalId, 
        'di-test-1',
        reason: 'Devotional ID should be set after play command'
      );
      expect(
        controller.isPlaying || 
        controller.currentState == TtsState.initializing ||
        controller.currentState == TtsState.playing,
        true,
        reason: 'Should be playing or initializing after play command',
      );

      // Cleanup
      await controller.stop();
      controller.dispose();
    });

    test('DevocionalProvider retrieves TTS from service locator', () async {
      // Given: Service locator is set up
      setupServiceLocator();

      // When: We create DevocionalProvider (which uses service locator internally)
      final provider = DevocionalProvider();
      await provider.initializeData();

      // Then: Provider should be functional and have audio controller
      expect(provider.audioController, isNotNull);
      
      // And: Audio controller should have TTS service
      expect(provider.audioController.ttsService, isA<ITtsService>());

      // Cleanup
      provider.dispose();
    });

    test('Multiple AudioControllers share same TTS singleton', () async {
      // Given: Service locator with TTS service
      setupServiceLocator();

      // When: We create multiple controllers
      final controller1 = AudioController(getService<ITtsService>());
      final controller2 = AudioController(getService<ITtsService>());
      final controller3 = AudioController(getService<ITtsService>());

      // Then: All should share the same TTS instance
      expect(
        identical(controller1.ttsService, controller2.ttsService),
        true,
        reason: 'All controllers should share same TTS singleton',
      );
      expect(identical(controller2.ttsService, controller3.ttsService), true);

      // Cleanup
      controller1.dispose();
      controller2.dispose();
      controller3.dispose();
    });

    test('Concurrent access to service locator returns same instance',
        () async {
      // Given: Service locator is set up
      setupServiceLocator();

      // When: We request service concurrently from multiple futures
      final futures = List.generate(
        50,
        (_) => Future(() => getService<ITtsService>()),
      );
      final services = await Future.wait(futures);

      // Then: All should be the same instance
      final uniqueInstances = services.toSet();
      expect(uniqueInstances.length, 1,
          reason: 'Concurrent access should return same singleton');
    });

    test('ServiceLocator throws clear error when service not registered', () {
      // Given: Service locator is reset (no services registered)
      ServiceLocator().reset();

      // When/Then: Requesting unregistered service should throw
      expect(
        () => getService<ITtsService>(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not registered'),
          ),
        ),
        reason: 'Should throw clear error for unregistered service',
      );
    });

    test('ServiceLocator can be reset and re-initialized', () async {
      // Given: Service locator is set up
      setupServiceLocator();
      final service1 = getService<ITtsService>();

      // When: We reset and re-initialize
      ServiceLocator().reset();
      setupServiceLocator();
      final service2 = getService<ITtsService>();

      // Then: We should get a new instance
      expect(identical(service1, service2), false,
          reason: 'Reset should create new instance');

      // Cleanup
      await service1.dispose();
      await service2.dispose();
    });

    test('TTS service lifecycle works through DI', () async {
      // Given: Service through service locator
      setupServiceLocator();
      final service = getService<ITtsService>();

      // When: We initialize and use the service
      await service.initialize();
      expect(service.currentState, TtsState.idle);

      // And: Speak some text
      await service.speakText('Integration test');
      await Future.delayed(const Duration(milliseconds: 50));

      // Then: Service should be functional
      expect(service.isDisposed, false);

      // When: We dispose
      await service.dispose();

      // Then: Service should be disposed
      expect(service.isDisposed, true);
    });

    test('Factory constructor creates functional TTS instance', () async {
      // Given: We use the factory constructor directly (for legacy compatibility)
      final service = TtsService();

      // When: We initialize
      await service.initialize();

      // Then: Service should work
      expect(service.currentState, TtsState.idle);
      expect(service.isDisposed, false);

      // Cleanup
      await service.dispose();
    });

    test('Integration: Full user flow with DI', () async {
      // Given: Complete DI setup
      setupServiceLocator();
      final ttsService = getService<ITtsService>();
      final controller = AudioController(ttsService);
      controller.initialize();

      // And: A devotional
      final devotional = Devocional(
        id: 'integration-flow',
        date: DateTime.now(),
        versiculo: 'Juan 3:16 - Porque de tal manera amó Dios al mundo',
        reflexion: 'Una reflexión sobre el amor de Dios que es profunda y significativa.',
        oracion: 'Padre celestial, gracias por tu amor incondicional.',
        paraMeditar: [
          ParaMeditar(
            cita: '1 Juan 4:8',
            texto: 'Dios es amor',
          ),
        ],
      );

      // When: User plays devotional
      await controller.playDevotional(devotional);
      await Future.delayed(const Duration(milliseconds: 150));

      // Then: Should be playing
      expect(controller.currentDevocionalId, 'integration-flow');

      // When: User pauses
      await controller.pause();
      await Future.delayed(const Duration(milliseconds: 50));

      // Then: Should be paused
      expect(controller.isPaused, true);

      // When: User resumes
      await controller.resume();
      await Future.delayed(const Duration(milliseconds: 50));

      // Then: Should be playing again
      expect(controller.isPlaying, true);

      // When: User stops
      await controller.stop();
      await Future.delayed(const Duration(milliseconds: 50));

      // Then: Should be idle
      expect(controller.currentState, TtsState.idle);
      expect(controller.currentDevocionalId, null);

      // Cleanup
      controller.dispose();
    });
  });
}
