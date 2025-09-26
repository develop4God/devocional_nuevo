import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/backup_scheduler_service.dart';
import 'package:devocional_nuevo/services/google_drive_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks mínimos necesarios
class MockGoogleDriveBackupService extends Mock
    implements GoogleDriveBackupService {}

class MockBackupSchedulerService extends Mock
    implements BackupSchedulerService {}

class MockDevocionalProvider extends Mock implements DevocionalProvider {}

void main() {
  group('BackupBloc - Logic Tests', () {
    late MockGoogleDriveBackupService mockService;
    late MockBackupSchedulerService mockScheduler;
    late MockDevocionalProvider mockProvider;
    late BackupBloc bloc;

    setUp(() {
      mockService = MockGoogleDriveBackupService();
      mockScheduler = MockBackupSchedulerService();
      mockProvider = MockDevocionalProvider();

      // Setup básico para evitar errores
      when(() => mockScheduler.scheduleAutomaticBackup())
          .thenAnswer((_) async {});
      when(() => mockScheduler.cancelAutomaticBackup())
          .thenAnswer((_) async {});

      bloc = BackupBloc(
        backupService: mockService,
        schedulerService: mockScheduler,
        devocionalProvider: mockProvider,
      );
    });

    tearDown(() => bloc.close());

    test('initial state is BackupInitial', () {
      expect(bloc.state, const BackupInitial());
    });

    group('ToggleAutoBackup - Business Logic', () {
      blocTest<BackupBloc, BackupState>(
        'LÓGICA: enabling auto-backup activates frequency when deactivated',
        build: () {
          // Mock: frecuencia está desactivada
          when(() => mockService.getBackupFrequency()).thenAnswer(
              (_) async => GoogleDriveBackupService.frequencyDeactivated);
          when(() => mockService.setAutoBackupEnabled(any()))
              .thenAnswer((_) async {});
          when(() => mockService.setBackupFrequency(any()))
              .thenAnswer((_) async {});
          when(() => mockService.getNextBackupTime())
              .thenAnswer((_) async => null);

          return bloc;
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: false,
          backupFrequency: GoogleDriveBackupService.frequencyDeactivated,
          wifiOnlyEnabled: true,
          compressionEnabled: true,
          backupOptions: {},
          estimatedSize: 0,
          storageInfo: {},
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(const ToggleAutoBackup(true)),
        verify: (_) {
          // VALIDACIÓN: debe cambiar frecuencia a "daily" automáticamente
          verify(() => mockService.setBackupFrequency(
              GoogleDriveBackupService.frequencyDaily)).called(1);
          verify(() => mockScheduler.scheduleAutomaticBackup()).called(1);
        },
      );

      blocTest<BackupBloc, BackupState>(
        'LÓGICA: disabling auto-backup doesn\'t change frequency',
        build: () {
          when(() => mockService.setAutoBackupEnabled(any()))
              .thenAnswer((_) async {});
          when(() => mockService.getBackupFrequency())
              .thenAnswer((_) async => GoogleDriveBackupService.frequencyDaily);
          when(() => mockService.getNextBackupTime())
              .thenAnswer((_) async => null);

          return bloc;
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: GoogleDriveBackupService.frequencyDaily,
          wifiOnlyEnabled: true,
          compressionEnabled: true,
          backupOptions: {},
          estimatedSize: 0,
          storageInfo: {},
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(const ToggleAutoBackup(false)),
        verify: (_) {
          // VALIDACIÓN: NO debe cambiar frecuencia
          verifyNever(() => mockService.setBackupFrequency(any()));
          verify(() => mockScheduler.scheduleAutomaticBackup()).called(1);
        },
      );
    });

    group('ChangeBackupFrequency - Business Logic', () {
      blocTest<BackupBloc, BackupState>(
        'LÓGICA: setting frequency to "deactivated" signs out user',
        build: () {
          when(() => mockService.setBackupFrequency(any()))
              .thenAnswer((_) async {});
          when(() => mockService.signOut()).thenAnswer((_) async {});
          when(() => mockService.getNextBackupTime())
              .thenAnswer((_) async => null);

          return bloc;
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: GoogleDriveBackupService.frequencyDaily,
          wifiOnlyEnabled: true,
          compressionEnabled: true,
          backupOptions: {},
          estimatedSize: 0,
          storageInfo: {},
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(const ChangeBackupFrequency(
            GoogleDriveBackupService.frequencyDeactivated)),
        verify: (_) {
          // VALIDACIÓN: debe cerrar sesión automáticamente
          verify(() => mockService.signOut()).called(1);
          verify(() => mockScheduler.scheduleAutomaticBackup()).called(1);
        },
      );

      blocTest<BackupBloc, BackupState>(
        'LÓGICA: changing to active frequency doesn\'t sign out',
        build: () {
          when(() => mockService.setBackupFrequency(any()))
              .thenAnswer((_) async {});
          when(() => mockService.getNextBackupTime())
              .thenAnswer((_) async => null);

          return bloc;
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: GoogleDriveBackupService.frequencyDaily,
          wifiOnlyEnabled: true,
          compressionEnabled: true,
          backupOptions: {},
          estimatedSize: 0,
          storageInfo: {},
          isAuthenticated: true,
        ),
        verify: (_) {
          // VALIDACIÓN: NO debe cerrar sesión
          verifyNever(() => mockService.signOut());
          verify(() => mockScheduler.scheduleAutomaticBackup()).called(1);
        },
      );
    });

    group('SignInToGoogleDrive - Business Logic', () {
      blocTest<BackupBloc, BackupState>(
        'LÓGICA: successful sign-in enables auto-backup by default',
        build: () {
          when(() => mockService.signIn()).thenAnswer((_) async => true);
          when(() => mockService.isAutoBackupEnabled())
              .thenAnswer((_) async => false);
          when(() => mockService.setAutoBackupEnabled(any()))
              .thenAnswer((_) async {});
          when(() => mockService.checkForExistingBackup())
              .thenAnswer((_) async => {'found': false});

          return bloc;
        },
        act: (bloc) => bloc.add(const SignInToGoogleDrive()),
        wait: const Duration(seconds: 3),
        verify: (_) {
          // VALIDACIÓN: debe activar auto-backup automáticamente
          verify(() => mockService.setAutoBackupEnabled(true)).called(1);
          verify(() => mockScheduler.scheduleAutomaticBackup()).called(1);
        },
      );

      blocTest<BackupBloc, BackupState>(
        'LÓGICA: existing backup triggers automatic restore',
        build: () {
          when(() => mockService.signIn()).thenAnswer((_) async => true);
          when(() => mockService.isAutoBackupEnabled())
              .thenAnswer((_) async => false);
          when(() => mockService.setAutoBackupEnabled(any()))
              .thenAnswer((_) async {});
          when(() => mockService.checkForExistingBackup())
              .thenAnswer((_) async => {'found': true, 'fileId': 'test123'});
          when(() => mockService.restoreExistingBackup(any(),
              devocionalProvider: any(),
              prayerBloc: any())).thenAnswer((_) async => true);

          return bloc;
        },
        act: (bloc) => bloc.add(const SignInToGoogleDrive()),
        expect: () => [
          const BackupLoading(),
          const BackupRestoring(),
          isA<BackupSuccess>(),
          const BackupLoading(),
        ],
        wait: const Duration(seconds: 3),
        verify: (_) {
          // VALIDACIÓN: debe restaurar automáticamente
          verify(() => mockService.restoreExistingBackup('test123',
              devocionalProvider: any(named: 'devocionalProvider'),
              prayerBloc: any(named: 'prayerBloc'))).called(1);
          verify(() => mockScheduler.scheduleAutomaticBackup())
              .called(2); // Una para login, otra para restore
        },
      );

      blocTest<BackupBloc, BackupState>(
        'LÓGICA: user cancels sign-in (null result)',
        build: () {
          when(() => mockService.signIn()).thenAnswer((_) async => null);
          return bloc;
        },
        act: (bloc) => bloc.add(const SignInToGoogleDrive()),
        expect: () => [
          const BackupLoading(),
          const BackupLoading(),
        ],
        verify: (_) {
          // VALIDACIÓN: no debe hacer nada más si usuario cancela
          verifyNever(() => mockService.setAutoBackupEnabled(any()));
          verifyNever(() => mockScheduler.scheduleAutomaticBackup());
        },
      );
    });

    group('CreateManualBackup - Business Logic', () {
      blocTest<BackupBloc, BackupState>(
        'LÓGICA: successful backup reschedules automatic backup',
        build: () {
          when(() => mockService.createBackup(any()))
              .thenAnswer((_) async => true);
          return bloc;
        },
        act: (bloc) => bloc.add(const CreateManualBackup()),
        expect: () => [
          const BackupCreating(),
          isA<BackupCreated>(),
          const BackupLoading(),
        ],
        verify: (_) {
          // VALIDACIÓN: debe reprogramar backup automático después del manual
          verify(() => mockScheduler.scheduleAutomaticBackup()).called(1);
        },
      );

      blocTest<BackupBloc, BackupState>(
        'LÓGICA: failed backup doesn\'t reschedule',
        build: () {
          when(() => mockService.createBackup(any()))
              .thenAnswer((_) async => false);
          return bloc;
        },
        act: (bloc) => bloc.add(const CreateManualBackup()),
        expect: () => [
          const BackupCreating(),
          const BackupError('Failed to create backup'),
        ],
        verify: (_) {
          // VALIDACIÓN: NO debe reprogramar si falla
          verifyNever(() => mockScheduler.scheduleAutomaticBackup());
        },
      );
    });

    group('Error Handling', () {
      blocTest<BackupBloc, BackupState>(
        'handles service exceptions gracefully',
        build: () {
          when(() => mockService.setAutoBackupEnabled(any()))
              .thenThrow(Exception('Network error'));
          return bloc;
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: false,
          backupFrequency: GoogleDriveBackupService.frequencyDaily,
          wifiOnlyEnabled: true,
          compressionEnabled: true,
          backupOptions: {},
          estimatedSize: 0,
          storageInfo: {},
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(const ToggleAutoBackup(true)),
        expect: () => [
          isA<BackupError>()
              .having((e) => e.message, 'message', contains('Network error')),
        ],
      );
    });
  });
}
