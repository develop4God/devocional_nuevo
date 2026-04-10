@Tags(['integration'])
library;

// test/integration/tts_di_integration_test.dart
//
// Migrated from integration_test/tts_di_integration_test.dart
// End-to-end DI integration tests: validates ServiceLocator + ITtsService
// + AudioController + DevocionalProvider wiring without a real device.

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
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
        call,
      ) async {
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
      });

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
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
    });

    test('ServiceLocator provides ITtsService instance', () {
      setupServiceLocator();

      final service = getService<ITtsService>();

      expect(service, isNotNull);
      expect(service, isA<ITtsService>());
      expect(service, isA<TtsService>());
    });

    test(
      'ServiceLocator returns same singleton instance on multiple calls',
      () {
        setupServiceLocator();

        final service1 = getService<ITtsService>();
        final service2 = getService<ITtsService>();
        final service3 = getService<ITtsService>();

        expect(
          identical(service1, service2),
          true,
          reason: 'Service locator should return same singleton instance',
        );
        expect(identical(service2, service3), true);
        expect(identical(service1, service3), true);
      },
    );

    test('AudioController works with injected ITtsService', () async {
      setupServiceLocator();
      final ttsService = getService<ITtsService>();

      final controller = AudioController(ttsService);
      controller.initialize();

      expect(controller.currentState, TtsState.idle);
      expect(controller.isPlaying, false);
      expect(controller.isPaused, false);
      expect(controller.ttsService, same(ttsService));

      controller.dispose();
    });

    test('AudioController can play devotional through DI', () async {
      setupServiceLocator();
      final ttsService = getService<ITtsService>();
      final controller = AudioController(ttsService);
      controller.initialize();

      final devotional = Devocional(
        id: 'di-test-1',
        date: DateTime.now(),
        versiculo: 'Test verse for DI integration',
        reflexion: 'Test reflection',
        oracion: 'Test prayer',
        paraMeditar: [],
      );

      await controller.playDevotional(devotional);
      await Future.delayed(const Duration(milliseconds: 200));

      expect(
        controller.currentDevocionalId,
        'di-test-1',
        reason: 'Devotional ID should be set after play command',
      );

      await controller.stop();
      controller.dispose();
    });

    test('DevocionalProvider retrieves TTS from service locator', () async {
      setupServiceLocator();

      final provider = DevocionalProvider();
      await provider.initializeData();

      expect(provider.audioController, isNotNull);
      expect(provider.audioController.ttsService, isA<ITtsService>());

      provider.dispose();
    });

    test('Multiple AudioControllers share same TTS singleton', () async {
      setupServiceLocator();

      final controller1 = AudioController(getService<ITtsService>());
      final controller2 = AudioController(getService<ITtsService>());
      final controller3 = AudioController(getService<ITtsService>());

      expect(
        identical(controller1.ttsService, controller2.ttsService),
        true,
        reason: 'All controllers should share same TTS singleton',
      );
      expect(identical(controller2.ttsService, controller3.ttsService), true);

      controller1.dispose();
      controller2.dispose();
      controller3.dispose();
    });

    test(
      'Concurrent access to service locator returns same instance',
      () async {
        setupServiceLocator();

        final futures = List.generate(
          50,
          (_) => Future(() => getService<ITtsService>()),
        );
        final services = await Future.wait(futures);

        final uniqueInstances = services.toSet();
        expect(
          uniqueInstances.length,
          1,
          reason: 'Concurrent access should return same singleton',
        );
      },
    );

    test('ServiceLocator throws clear error when service not registered', () {
      ServiceLocator().reset();

      expect(
        () => getService<ITtsService>(),
        throwsStateError,
        reason: 'Should throw StateError for unregistered service',
      );
    });

    test('ServiceLocator can be reset and re-initialized', () async {
      setupServiceLocator();
      final service1 = getService<ITtsService>();

      ServiceLocator().reset();
      setupServiceLocator();
      final service2 = getService<ITtsService>();

      expect(
        identical(service1, service2),
        false,
        reason: 'Reset should create new instance',
      );

      await service1.dispose();
      await service2.dispose();
    });

    test('TTS service lifecycle works through DI', () async {
      setupServiceLocator();
      final service = getService<ITtsService>();

      await service.initialize();
      expect(service.currentState, TtsState.idle);

      await service.speakText('Integration test');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(service.isDisposed, false);

      await service.dispose();
      expect(service.isDisposed, true);
    });

    test('Factory constructor creates functional TTS instance', () async {
      setupServiceLocator();

      final service = TtsService();
      await service.initialize();

      expect(service.currentState, TtsState.idle);
      expect(service.isDisposed, false);

      await service.dispose();
    });

    test('Integration: Full user flow with DI', () async {
      setupServiceLocator();
      final ttsService = getService<ITtsService>();
      final controller = AudioController(ttsService);
      controller.initialize();

      final devotional = Devocional(
        id: 'integration-flow',
        date: DateTime.now(),
        versiculo: 'Juan 3:16 - Porque de tal manera amo Dios al mundo',
        reflexion:
            'Una reflexion sobre el amor de Dios que es profunda y significativa.',
        oracion: 'Padre celestial, gracias por tu amor incondicional.',
        paraMeditar: [ParaMeditar(cita: '1 Juan 4:8', texto: 'Dios es amor')],
      );

      await controller.playDevotional(devotional);
      await Future.delayed(const Duration(milliseconds: 150));

      expect(controller.currentDevocionalId, 'integration-flow');

      await controller.pause();
      await Future.delayed(const Duration(milliseconds: 50));

      await controller.resume();
      await Future.delayed(const Duration(milliseconds: 50));

      await controller.stop();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(
        controller.mounted,
        true,
        reason: 'Controller should still be mounted after user flow',
      );

      controller.dispose();
    });
  });
}
