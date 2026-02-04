import 'package:devocional_nuevo/services/notification_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

@Tags(['unit', 'services'])
void main() {
  group('ServiceLocator', () {
    setUp(() {
      // Reset the service locator before each test
      ServiceLocator().reset();
    });

    tearDown(() {
      // Clean up service locator after tests
      ServiceLocator().reset();
    });

    group('Service Registration', () {
      test('registerLazySingleton creates service only once', () {
        int createCount = 0;
        ServiceLocator().registerLazySingleton<VoiceSettingsService>(() {
          createCount++;
          return VoiceSettingsService();
        });

        // First access creates the service
        getService<VoiceSettingsService>();
        expect(createCount, equals(1));

        // Second access uses cached instance
        getService<VoiceSettingsService>();
        expect(createCount, equals(1));

        // Third access still uses cached instance
        getService<VoiceSettingsService>();
        expect(createCount, equals(1));
      });

      test('registerSingleton returns the exact instance provided', () {
        final instance = VoiceSettingsService();
        ServiceLocator().registerSingleton<VoiceSettingsService>(instance);

        final retrieved = getService<VoiceSettingsService>();
        expect(identical(retrieved, instance), isTrue);
      });

      test('registerFactory creates new instance each time', () {
        ServiceLocator().registerFactory<VoiceSettingsService>(
          () => VoiceSettingsService(),
        );

        final instance1 = getService<VoiceSettingsService>();
        final instance2 = getService<VoiceSettingsService>();

        // Factory should create new instances
        expect(identical(instance1, instance2), isFalse);
      });
    });

    group('Error Handling', () {
      test('Accessing unregistered service throws StateError', () {
        // VoiceSettingsService not registered
        expect(
          () => getService<VoiceSettingsService>(),
          throwsA(isA<StateError>()),
        );
      });

      test('Error message mentions setupServiceLocator', () {
        try {
          getService<VoiceSettingsService>();
          fail('Should have thrown StateError');
        } on StateError catch (e) {
          expect(e.message, contains('setupServiceLocator()'));
          expect(e.message, contains('VoiceSettingsService'));
        }
      });

      test('isRegistered returns false for unregistered service', () {
        expect(ServiceLocator().isRegistered<VoiceSettingsService>(), isFalse);
      });

      test('isRegistered returns true after registration', () {
        ServiceLocator().registerLazySingleton<VoiceSettingsService>(
          () => VoiceSettingsService(),
        );
        expect(ServiceLocator().isRegistered<VoiceSettingsService>(), isTrue);
      });
    });

    group('Lifecycle Management', () {
      test('reset clears all singletons', () {
        ServiceLocator().registerSingleton<VoiceSettingsService>(
          VoiceSettingsService(),
        );

        expect(ServiceLocator().isRegistered<VoiceSettingsService>(), isTrue);

        ServiceLocator().reset();

        expect(ServiceLocator().isRegistered<VoiceSettingsService>(), isFalse);
      });

      test('reset clears all factories', () {
        ServiceLocator().registerFactory<VoiceSettingsService>(
          () => VoiceSettingsService(),
        );

        expect(ServiceLocator().isRegistered<VoiceSettingsService>(), isTrue);

        ServiceLocator().reset();

        expect(ServiceLocator().isRegistered<VoiceSettingsService>(), isFalse);
      });

      test('unregister removes specific service', () {
        ServiceLocator().registerSingleton<VoiceSettingsService>(
          VoiceSettingsService(),
        );

        expect(ServiceLocator().isRegistered<VoiceSettingsService>(), isTrue);

        ServiceLocator().unregister<VoiceSettingsService>();

        expect(ServiceLocator().isRegistered<VoiceSettingsService>(), isFalse);
      });
    });

    group('Mock Replacement for Testing', () {
      test('Can replace singleton registration with mock', () {
        final original = VoiceSettingsService();
        final mock = VoiceSettingsService();

        // Register original
        ServiceLocator().registerSingleton<VoiceSettingsService>(original);
        expect(identical(getService<VoiceSettingsService>(), original), isTrue);

        // Unregister and replace with mock
        ServiceLocator().unregister<VoiceSettingsService>();
        ServiceLocator().registerSingleton<VoiceSettingsService>(mock);

        expect(identical(getService<VoiceSettingsService>(), mock), isTrue);
      });
    });

    group('NotificationService Registration', () {
      test('NotificationService can be registered and verified', () {
        // Register NotificationService as lazy singleton using factory
        ServiceLocator().registerLazySingleton<NotificationService>(
          NotificationService.create,
        );

        // Verify it's registered
        expect(ServiceLocator().isRegistered<NotificationService>(), isTrue);

        // Clean up to avoid instantiation issues (Firebase not initialized in test)
        ServiceLocator().unregister<NotificationService>();
        expect(ServiceLocator().isRegistered<NotificationService>(), isFalse);
      });

      test('NotificationService enforces private constructor pattern', () {
        // Verify that NotificationService.create factory exists and can be used
        final factory = NotificationService.create;
        expect(factory, isNotNull);
        expect(factory, isA<Function>());

        // This test documents that direct instantiation (NotificationService())
        // is prevented by the private constructor pattern.
        // Attempting NotificationService() would result in a compile-time error:
        // "The constructor 'NotificationService._' is private and can't be accessed outside the library."
      });
    });
  });
}
