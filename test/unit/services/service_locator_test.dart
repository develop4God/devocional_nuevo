@Tags(['unit', 'services'])
library;

import 'dart:io';

import 'package:devocional_nuevo/services/i_connectivity_service.dart';
import 'package:devocional_nuevo/services/i_google_drive_auth_service.dart';
import 'package:devocional_nuevo/services/i_google_drive_backup_service.dart';
import 'package:devocional_nuevo/services/i_spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/notification_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/supporter_pet_service.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

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

    group('Service Locator - Interface Registrations', () {
      test(
        'Service locator file imports and registers all required services',
        () async {
          // This test validates that the service locator has the proper
          // registrations by checking the actual setupServiceLocator() code

          // Read the service locator file
          final serviceLocatorFile =
              File('lib/services/service_locator.dart');
          final content = await serviceLocatorFile.readAsString();

          // Verify all required service registrations exist
          expect(
            content.contains('registerLazySingleton<IGoogleDriveAuthService>'),
            isTrue,
            reason:
                'IGoogleDriveAuthService should be registered in service locator',
          );

          expect(
            content.contains('registerLazySingleton<IConnectivityService>'),
            isTrue,
            reason:
                'IConnectivityService should be registered in service locator',
          );

          expect(
            content.contains('registerLazySingleton<ISpiritualStatsService>'),
            isTrue,
            reason:
                'ISpiritualStatsService should be registered in service locator',
          );

          expect(
            content.contains('registerLazySingleton<IGoogleDriveBackupService>'),
            isTrue,
            reason:
                'IGoogleDriveBackupService should be registered in service locator',
          );

          expect(
            content.contains('registerLazySingleton<SupporterPetService>'),
            isTrue,
            reason:
                'SupporterPetService should be registered in service locator',
          );

          // Verify proper DI - services get dependencies from locator
          expect(
            content.contains('locator.get<IGoogleDriveAuthService>()') ||
                content.contains('getService<IGoogleDriveAuthService>()'),
            isTrue,
            reason:
                'GoogleDriveBackupService should resolve IGoogleDriveAuthService via DI',
          );

          expect(
            content.contains('locator.get<IConnectivityService>()') ||
                content.contains('getService<IConnectivityService>()'),
            isTrue,
            reason:
                'GoogleDriveBackupService should resolve IConnectivityService via DI',
          );

          expect(
            content.contains('locator.get<ISpiritualStatsService>()') ||
                content.contains('getService<ISpiritualStatsService>()'),
            isTrue,
            reason:
                'GoogleDriveBackupService should resolve ISpiritualStatsService via DI',
          );

          expect(
            content.contains('locator.get<SharedPreferences>()') ||
                content.contains('getService<SharedPreferences>()'),
            isTrue,
            reason:
                'SupporterPetService should resolve SharedPreferences via DI',
          );
        },
      );

      test('Main.dart uses DI for BackupBloc', () async {
        // Read the main.dart file
        final mainFile = File('lib/main.dart');
        final content = await mainFile.readAsString();

        // Verify BackupBloc uses DI
        expect(
          content.contains('getService<IGoogleDriveBackupService>()'),
          isTrue,
          reason: 'BackupBloc should use getService for IGoogleDriveBackupService',
        );

        // Verify no inline instantiation of these services
        expect(
          content.contains('GoogleDriveBackupService('),
          isFalse,
          reason:
              'Should not directly instantiate GoogleDriveBackupService in main.dart',
        );

        expect(
          content.contains('GoogleDriveAuthService('),
          isFalse,
          reason:
              'Should not directly instantiate GoogleDriveAuthService in main.dart',
        );

        expect(
          content.contains('ConnectivityService('),
          isFalse,
          reason:
              'Should not directly instantiate ConnectivityService in main.dart',
        );

        expect(
          content.contains('SpiritualStatsService('),
          isFalse,
          reason:
              'Should not directly instantiate SpiritualStatsService in main.dart',
        );
      });
    });
  });
}
