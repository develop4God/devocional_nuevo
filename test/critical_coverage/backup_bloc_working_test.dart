// test/critical_coverage/backup_bloc_working_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/services/google_drive_backup_service.dart';
import 'package:devocional_nuevo/services/backup_scheduler_service.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';

// Mock classes for testing
class MockGoogleDriveBackupService extends Mock
    implements GoogleDriveBackupService {}

class MockBackupSchedulerService extends Mock 
    implements BackupSchedulerService {}

class MockDevocionalProvider extends Mock 
    implements DevocionalProvider {}

void main() {
  group('BackupBloc Critical Coverage Tests', () {
    late MockGoogleDriveBackupService mockBackupService;
    late MockBackupSchedulerService mockSchedulerService;
    late MockDevocionalProvider mockDevocionalProvider;

    setUp(() {
      mockBackupService = MockGoogleDriveBackupService();
      mockSchedulerService = MockBackupSchedulerService();
      mockDevocionalProvider = MockDevocionalProvider();
      
      // Setup common mock responses
      when(() => mockBackupService.isAuthenticated()).thenAnswer((_) async => false);
      when(() => mockBackupService.isAutoBackupEnabled()).thenAnswer((_) async => false);
      when(() => mockBackupService.getBackupFrequency()).thenAnswer((_) async => 'deactivated');
      when(() => mockBackupService.isWifiOnlyEnabled()).thenAnswer((_) async => false);
      when(() => mockBackupService.isCompressionEnabled()).thenAnswer((_) async => false);
      when(() => mockBackupService.getBackupOptions()).thenAnswer((_) async => <String, bool>{});
      when(() => mockBackupService.getLastBackupTime()).thenAnswer((_) async => null);
      when(() => mockBackupService.getNextBackupTime()).thenAnswer((_) async => null);
      when(() => mockBackupService.getEstimatedBackupSize(any())).thenAnswer((_) async => 0);
      when(() => mockBackupService.getUserEmail()).thenAnswer((_) async => null);
      when(() => mockBackupService.getStorageInfo()).thenAnswer((_) async => <String, dynamic>{});
    });

    blocTest<BackupBloc, BackupState>(
      'should emit loading state when loading backup settings',
      build: () => BackupBloc(
        backupService: mockBackupService,
        schedulerService: mockSchedulerService,
        devocionalProvider: mockDevocionalProvider,
      ),
      act: (bloc) => bloc.add(const LoadBackupSettings()),
      expect: () => [
        const BackupLoading(),
        const BackupLoaded(
          autoBackupEnabled: false,
          backupFrequency: 'deactivated',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: <String, bool>{},
          lastBackupTime: null,
          nextBackupTime: null,
          estimatedSize: 0,
          storageInfo: <String, dynamic>{},
          isAuthenticated: false,
          userEmail: null,
        ),
      ],
    );

    blocTest<BackupBloc, BackupState>(
      'should handle auto backup toggle successfully',
      build: () => BackupBloc(
        backupService: mockBackupService,
        schedulerService: mockSchedulerService,
        devocionalProvider: mockDevocionalProvider,
      ),
      seed: () => const BackupLoaded(
        autoBackupEnabled: false,
        backupFrequency: 'deactivated',
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupOptions: <String, bool>{},
        estimatedSize: 0,
        storageInfo: <String, dynamic>{},
        isAuthenticated: false,
      ),
      setUp: () {
        when(() => mockBackupService.setAutoBackupEnabled(any())).thenAnswer((_) async {});
        when(() => mockSchedulerService.scheduleAutomaticBackup()).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const ToggleAutoBackup(true)),
      expect: () => [
        const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: 'deactivated',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: <String, bool>{},
          estimatedSize: 0,
          storageInfo: <String, dynamic>{},
          isAuthenticated: false,
          nextBackupTime: null,
        ),
      ],
    );

    blocTest<BackupBloc, BackupState>(
      'should handle backup creation workflow',
      build: () => BackupBloc(
        backupService: mockBackupService,
        schedulerService: mockSchedulerService,
        devocionalProvider: mockDevocionalProvider,
      ),
      setUp: () {
        when(() => mockBackupService.createBackup(any())).thenAnswer((_) async => true);
        when(() => mockSchedulerService.scheduleAutomaticBackup()).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const CreateManualBackup()),
      expect: () => [
        const BackupCreating(),
        isA<BackupCreated>(),
        const BackupLoading(),
        isA<BackupLoaded>(),
      ],
    );

    blocTest<BackupBloc, BackupState>(
      'should handle backup failure with error state',
      build: () => BackupBloc(
        backupService: mockBackupService,
        schedulerService: mockSchedulerService,
        devocionalProvider: mockDevocionalProvider,
      ),
      setUp: () {
        when(() => mockBackupService.createBackup(any())).thenAnswer((_) async => false);
      },
      act: (bloc) => bloc.add(const CreateManualBackup()),
      expect: () => [
        const BackupCreating(),
        const BackupError('Failed to create backup'),
      ],
    );

    blocTest<BackupBloc, BackupState>(
      'should handle restore from backup workflow',
      build: () => BackupBloc(
        backupService: mockBackupService,
        schedulerService: mockSchedulerService,
        devocionalProvider: mockDevocionalProvider,
      ),
      setUp: () {
        when(() => mockBackupService.restoreBackup()).thenAnswer((_) async => true);
        when(() => mockSchedulerService.scheduleAutomaticBackup()).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const RestoreFromBackup()),
      expect: () => [
        const BackupRestoring(),
        const BackupRestored(),
        const BackupLoading(),
        isA<BackupLoaded>(),
      ],
    );

    blocTest<BackupBloc, BackupState>(
      'should handle Google Drive sign-in success',
      build: () => BackupBloc(
        backupService: mockBackupService,
        schedulerService: mockSchedulerService,
        devocionalProvider: mockDevocionalProvider,
      ),
      setUp: () {
        when(() => mockBackupService.signIn()).thenAnswer((_) async => true);
        when(() => mockBackupService.setAutoBackupEnabled(any())).thenAnswer((_) async {});
        when(() => mockBackupService.checkForExistingBackup()).thenAnswer((_) async => null);
        when(() => mockSchedulerService.scheduleAutomaticBackup()).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const SignInToGoogleDrive()),
      expect: () => [
        const BackupLoading(),
        const BackupLoading(),
        isA<BackupLoaded>(),
      ],
    );

    blocTest<BackupBloc, BackupState>(
      'should emit error when backup service throws exception',
      build: () => BackupBloc(
        backupService: mockBackupService,
        schedulerService: mockSchedulerService,
        devocionalProvider: mockDevocionalProvider,
      ),
      setUp: () {
        when(() => mockBackupService.createBackup(any()))
            .thenThrow(Exception('Network error'));
      },
      act: (bloc) => bloc.add(const CreateManualBackup()),
      expect: () => [
        const BackupCreating(),
        isA<BackupError>(),
      ],
    );
  });
}
