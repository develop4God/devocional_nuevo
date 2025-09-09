// test/unit/blocs/backup_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/google_drive_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoogleDriveBackupService extends Mock
    implements GoogleDriveBackupService {}

class MockDevocionalProvider extends Mock implements DevocionalProvider {}

void main() {
  group('BackupBloc', () {
    late MockGoogleDriveBackupService mockBackupService;
    late MockDevocionalProvider mockDevocionalProvider;
    late BackupBloc backupBloc;

    setUp(() {
      mockBackupService = MockGoogleDriveBackupService();
      mockDevocionalProvider = MockDevocionalProvider();
      backupBloc = BackupBloc(
        backupService: mockBackupService,
        devocionalProvider: mockDevocionalProvider,
      );
    });

    tearDown(() {
      backupBloc.close();
    });

    test('initial state is BackupInitial', () {
      expect(backupBloc.state, equals(const BackupInitial()));
    });

    group('LoadBackupSettings', () {
      blocTest<BackupBloc, BackupState>(
        'emits [BackupLoading, BackupLoaded] when successful',
        build: () {
          when(() => mockBackupService.isAuthenticated())
              .thenAnswer((_) async => true);
          when(() => mockBackupService.getUserEmail())
              .thenAnswer((_) async => 'test@gmail.com');
          when(() => mockBackupService.isAutoBackupEnabled())
              .thenAnswer((_) async => false);
          when(() => mockBackupService.getBackupFrequency())
              .thenAnswer((_) async => GoogleDriveBackupService.frequencyDaily);
          when(() => mockBackupService.isWifiOnlyEnabled())
              .thenAnswer((_) async => true);
          when(() => mockBackupService.isCompressionEnabled())
              .thenAnswer((_) async => true);
          when(() => mockBackupService.getBackupOptions())
              .thenAnswer((_) async => {'spiritual_stats': true});
          when(() => mockBackupService.getLastBackupTime())
              .thenAnswer((_) async => null);
          when(() => mockBackupService.getNextBackupTime())
              .thenAnswer((_) async => null);
          when(() => mockBackupService.getEstimatedBackupSize(any()))
              .thenAnswer((_) async => 5120);
          when(() => mockBackupService.getStorageInfo())
              .thenAnswer((_) async => {'used_gb': 1.4, 'total_gb': 100.0});

          return backupBloc;
        },
        act: (bloc) => bloc.add(const LoadBackupSettings()),
        expect: () => [
          const BackupLoading(),
          isA<BackupLoaded>()
              .having((state) => state.autoBackupEnabled, 'autoBackupEnabled',
                  false)
              .having((state) => state.backupFrequency, 'backupFrequency',
                  GoogleDriveBackupService.frequencyDaily)
              .having((state) => state.wifiOnlyEnabled, 'wifiOnlyEnabled', true)
              .having((state) => state.compressionEnabled, 'compressionEnabled',
                  true)
              .having((state) => state.estimatedSize, 'estimatedSize', 5120),
        ],
        verify: (_) {
          verify(() => mockBackupService.isAutoBackupEnabled()).called(1);
          verify(() => mockBackupService.getBackupFrequency()).called(1);
          verify(() => mockBackupService.isWifiOnlyEnabled()).called(1);
          verify(() => mockBackupService.isCompressionEnabled()).called(1);
          verify(() => mockBackupService.getBackupOptions()).called(1);
          verify(() => mockBackupService.getLastBackupTime()).called(1);
          verify(() => mockBackupService.getNextBackupTime()).called(1);
          verify(() => mockBackupService.getEstimatedBackupSize(any()))
              .called(1);
          verify(() => mockBackupService.getStorageInfo()).called(1);
        },
      );

      blocTest<BackupBloc, BackupState>(
        'emits [BackupLoading, BackupError] when fails',
        build: () {
          when(() => mockBackupService.isAutoBackupEnabled())
              .thenAnswer((_) async => false);
          when(() => mockBackupService.getBackupFrequency())
              .thenAnswer((_) async => GoogleDriveBackupService.frequencyDaily);
          when(() => mockBackupService.isWifiOnlyEnabled())
              .thenAnswer((_) async => true);
          when(() => mockBackupService.isCompressionEnabled())
              .thenAnswer((_) async => true);
          when(() => mockBackupService.getBackupOptions())
              .thenAnswer((_) async => {'spiritual_stats': true});
          when(() => mockBackupService.getLastBackupTime())
              .thenAnswer((_) async => null);
          when(() => mockBackupService.getNextBackupTime())
              .thenAnswer((_) async => null);
          when(() => mockBackupService.getEstimatedBackupSize(any()))
              .thenAnswer((_) async => 5120);
          when(() => mockBackupService.getStorageInfo())
              .thenThrow(Exception('Network error'));
          when(() => mockBackupService.isAuthenticated())
              .thenAnswer((_) async => true);
          when(() => mockBackupService.getUserEmail())
              .thenAnswer((_) async => 'test@gmail.com');

          return backupBloc;
        },
        act: (bloc) => bloc.add(const LoadBackupSettings()),
        expect: () => [
          const BackupLoading(),
          isA<BackupError>().having(
              (state) => state.message, 'message', contains('Network error')),
        ],
      );
    });

    group('ToggleAutoBackup', () {
      blocTest<BackupBloc, BackupState>(
        'calls setAutoBackupEnabled and loads settings',
        build: () {
          when(() => mockBackupService.setAutoBackupEnabled(any()))
              .thenAnswer((_) async {});
          when(() => mockBackupService.getNextBackupTime())
              .thenAnswer((_) async => null);

          return backupBloc;
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: false,
          backupFrequency: GoogleDriveBackupService.frequencyDaily,
          wifiOnlyEnabled: true,
          compressionEnabled: true,
          backupOptions: {'spiritual_stats': true},
          estimatedSize: 5120,
          storageInfo: {'used_gb': 1.4, 'total_gb': 100.0},
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(const ToggleAutoBackup(true)),
        verify: (_) {
          verify(() => mockBackupService.setAutoBackupEnabled(true)).called(1);
          verify(() => mockBackupService.getNextBackupTime()).called(1);
        },
      );
    });

    group('CreateManualBackup', () {
      blocTest<BackupBloc, BackupState>(
        'emits [BackupCreating, BackupCreated] when successful',
        build: () {
          when(() => mockBackupService.createBackup(any()))
              .thenAnswer((_) async => true);
          // Mock the subsequent LoadBackupSettings call
          when(() => mockBackupService.isAuthenticated())
              .thenAnswer((_) async => true);
          when(() => mockBackupService.getUserEmail())
              .thenAnswer((_) async => 'test@gmail.com');
          when(() => mockBackupService.isAutoBackupEnabled())
              .thenAnswer((_) async => true);
          when(() => mockBackupService.getBackupFrequency())
              .thenAnswer((_) async => GoogleDriveBackupService.frequencyDaily);
          when(() => mockBackupService.isWifiOnlyEnabled())
              .thenAnswer((_) async => true);
          when(() => mockBackupService.isCompressionEnabled())
              .thenAnswer((_) async => true);
          when(() => mockBackupService.getBackupOptions())
              .thenAnswer((_) async => {'spiritual_stats': true});
          when(() => mockBackupService.getLastBackupTime())
              .thenAnswer((_) async => DateTime.now());
          when(() => mockBackupService.getNextBackupTime())
              .thenAnswer((_) async => null);
          when(() => mockBackupService.getEstimatedBackupSize(any()))
              .thenAnswer((_) async => 5120);
          when(() => mockBackupService.getStorageInfo())
              .thenAnswer((_) async => {'used_gb': 1.4, 'total_gb': 100.0});

          return backupBloc;
        },
        act: (bloc) => bloc.add(const CreateManualBackup()),
        expect: () => [
          const BackupCreating(),
          isA<BackupCreated>(),
          const BackupLoading(),
          isA<BackupLoaded>(),
        ],
        verify: (_) {
          verify(() => mockBackupService.createBackup(any())).called(1);
        },
      );

      blocTest<BackupBloc, BackupState>(
        'emits [BackupCreating, BackupError] when fails',
        build: () {
          when(() => mockBackupService.createBackup(any()))
              .thenAnswer((_) async => false);

          return backupBloc;
        },
        act: (bloc) => bloc.add(const CreateManualBackup()),
        expect: () => [
          const BackupCreating(),
          const BackupError('Failed to create backup'),
        ],
        verify: (_) {
          verify(() => mockBackupService.createBackup(any())).called(1);
        },
      );
    });
  });
}
