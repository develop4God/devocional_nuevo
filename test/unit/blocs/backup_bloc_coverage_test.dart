@Tags(['critical', 'unit', 'blocs'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/models/backup_content_summary.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/backup/i_google_drive_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes for testing
class MockGoogleDriveBackupService extends Mock
    implements IGoogleDriveBackupService {}

class MockDevocionalProvider extends Mock implements DevocionalProvider {}

void main() {
  group('BackupBloc Additional Coverage Tests', () {
    late MockGoogleDriveBackupService mockBackupService;
    late MockDevocionalProvider mockDevocionalProvider;

    setUp(() {
      mockBackupService = MockGoogleDriveBackupService();
      mockDevocionalProvider = MockDevocionalProvider();

      // Default mock responses
      when(() => mockBackupService.isAuthenticated())
          .thenAnswer((_) async => false);
      when(() => mockBackupService.isAutoBackupEnabled())
          .thenAnswer((_) async => false);
      when(() => mockBackupService.getBackupFrequency())
          .thenAnswer((_) async => 'deactivated');
      when(() => mockBackupService.isWifiOnlyEnabled())
          .thenAnswer((_) async => false);
      when(() => mockBackupService.isCompressionEnabled())
          .thenAnswer((_) async => false);
      when(() => mockBackupService.getBackupOptions())
          .thenAnswer((_) async => <String, bool>{});
      when(() => mockBackupService.getLastBackupTime())
          .thenAnswer((_) async => null);
      when(() => mockBackupService.getNextBackupTime())
          .thenAnswer((_) async => null);
      when(() => mockBackupService.getEstimatedBackupSize(any()))
          .thenAnswer((_) async => 0);
      when(() => mockBackupService.getUserEmail())
          .thenAnswer((_) async => null);
      when(() => mockBackupService.getBackupContentSummary()).thenAnswer(
        (_) async => const BackupContentSummary(
          prayersCount: 0,
          thanksgivingsCount: 0,
          testimoniesCount: 0,
          favoritesCount: 0,
          encountersCount: 0,
          discoveryCount: 0,
          versesCount: 0,
        ),
      );
      when(() => mockDevocionalProvider.waitUntilInitialized())
          .thenAnswer((_) async {});
    });

    group('LoadBackupSettings Error Handling', () {
      blocTest<BackupBloc, BackupState>(
        'emits BackupError when loading settings fails',
        build: () {
          when(() => mockBackupService.isAuthenticated())
              .thenThrow(Exception('Network error'));
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        act: (bloc) async {
          // Wait for CheckStartupBackup to complete
          await Future<void>.delayed(const Duration(milliseconds: 200));
          bloc.add(const LoadBackupSettings());
        },
        wait: const Duration(milliseconds: 300),
        expect: () => [
          const BackupLoading(),
          isA<BackupError>().having(
            (state) => state.message,
            'message',
            contains('Error loading backup settings'),
          ),
        ],
      );
    });

    group('ToggleAutoBackup Event Handler', () {
      blocTest<BackupBloc, BackupState>(
        'enables auto backup and changes frequency from deactivated to daily',
        build: () {
          when(() => mockBackupService.setAutoBackupEnabled(any()))
              .thenAnswer((_) async {});
          when(() => mockBackupService.getBackupFrequency())
              .thenAnswer((_) async => 'deactivated');
          when(() => mockBackupService.setBackupFrequency(any()))
              .thenAnswer((_) async {});
          when(() => mockBackupService.getNextBackupTime())
              .thenAnswer((_) async => DateTime.now());
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: false,
          backupFrequency: 'deactivated',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          isAuthenticated: false,
        ),
        act: (bloc) => bloc.add(const ToggleAutoBackup(true)),
        verify: (_) {
          verify(() => mockBackupService.setAutoBackupEnabled(true)).called(1);
          verify(() => mockBackupService.setBackupFrequency('daily')).called(1);
        },
      );

      blocTest<BackupBloc, BackupState>(
        'disables auto backup without changing frequency',
        build: () {
          when(() => mockBackupService.setAutoBackupEnabled(any()))
              .thenAnswer((_) async {});
          when(() => mockBackupService.getBackupFrequency())
              .thenAnswer((_) async => 'daily');
          when(() => mockBackupService.getNextBackupTime())
              .thenAnswer((_) async => null);
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: 'daily',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(const ToggleAutoBackup(false)),
        verify: (_) {
          verify(() => mockBackupService.setAutoBackupEnabled(false)).called(1);
          verifyNever(() => mockBackupService.setBackupFrequency(any()));
        },
      );

      blocTest<BackupBloc, BackupState>(
        'triggers LoadBackupSettings when current state is not BackupLoaded',
        build: () {
          when(() => mockBackupService.setAutoBackupEnabled(any()))
              .thenAnswer((_) async {});
          when(() => mockBackupService.getBackupFrequency())
              .thenAnswer((_) async => 'daily');
          when(() => mockBackupService.getNextBackupTime())
              .thenAnswer((_) async => null);
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        act: (bloc) async {
          // Wait for CheckStartupBackup to complete
          await Future<void>.delayed(const Duration(milliseconds: 100));
          bloc.add(const ToggleAutoBackup(true));
        },
        wait: const Duration(milliseconds: 200),
        verify: (_) {
          verify(() => mockBackupService.setAutoBackupEnabled(true)).called(1);
        },
      );

      blocTest<BackupBloc, BackupState>(
        'emits BackupError when toggle fails',
        build: () {
          when(() => mockBackupService.setAutoBackupEnabled(any()))
              .thenThrow(Exception('Service error'));
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: false,
          backupFrequency: 'daily',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          isAuthenticated: false,
        ),
        act: (bloc) => bloc.add(const ToggleAutoBackup(true)),
        expect: () => [
          isA<BackupError>().having(
            (state) => state.message,
            'message',
            contains('Error updating auto backup'),
          ),
        ],
      );
    });

    group('ChangeBackupFrequency Event Handler', () {
      blocTest<BackupBloc, BackupState>(
        'changes frequency to deactivated and signs out',
        build: () {
          when(() => mockBackupService.signOut()).thenAnswer((_) async {});
          when(() => mockBackupService.setBackupFrequency(any()))
              .thenAnswer((_) async {});
          when(() => mockBackupService.getNextBackupTime())
              .thenAnswer((_) async => null);
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: 'daily',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          isAuthenticated: true,
          userEmail: 'test@example.com',
        ),
        act: (bloc) => bloc.add(const ChangeBackupFrequency('deactivated')),
        verify: (_) {
          verify(() => mockBackupService.signOut()).called(1);
          verify(() => mockBackupService.setBackupFrequency('deactivated'))
              .called(1);
        },
        expect: () => [
          isA<BackupLoaded>()
              .having((s) => s.backupFrequency, 'frequency', 'deactivated')
              .having((s) => s.isAuthenticated, 'authenticated', false),
        ],
      );

      blocTest<BackupBloc, BackupState>(
        'changes frequency to weekly without signing out',
        build: () {
          when(() => mockBackupService.setBackupFrequency(any()))
              .thenAnswer((_) async {});
          when(() => mockBackupService.getNextBackupTime()).thenAnswer(
              (_) async => DateTime.now().add(const Duration(days: 7)));
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: 'daily',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(const ChangeBackupFrequency('weekly')),
        verify: (_) {
          verifyNever(() => mockBackupService.signOut());
          verify(() => mockBackupService.setBackupFrequency('weekly'))
              .called(1);
        },
      );

      blocTest<BackupBloc, BackupState>(
        'emits BackupError when frequency change fails',
        build: () {
          when(() => mockBackupService.setBackupFrequency(any()))
              .thenThrow(Exception('Service error'));
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: 'daily',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(const ChangeBackupFrequency('weekly')),
        expect: () => [
          isA<BackupError>().having(
            (state) => state.message,
            'message',
            contains('Error changing backup frequency'),
          ),
        ],
      );
    });

    group('ToggleWifiOnly Event Handler', () {
      blocTest<BackupBloc, BackupState>(
        'enables WiFi-only backup',
        build: () {
          when(() => mockBackupService.setWifiOnlyEnabled(any()))
              .thenAnswer((_) async {});
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: 'daily',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(const ToggleWifiOnly(true)),
        verify: (_) {
          verify(() => mockBackupService.setWifiOnlyEnabled(true)).called(1);
        },
        expect: () => [
          isA<BackupLoaded>().having(
            (s) => s.wifiOnlyEnabled,
            'wifiOnlyEnabled',
            true,
          ),
        ],
      );

      blocTest<BackupBloc, BackupState>(
        'disables WiFi-only backup',
        build: () {
          when(() => mockBackupService.setWifiOnlyEnabled(any()))
              .thenAnswer((_) async {});
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: 'daily',
          wifiOnlyEnabled: true,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(const ToggleWifiOnly(false)),
        verify: (_) {
          verify(() => mockBackupService.setWifiOnlyEnabled(false)).called(1);
        },
        expect: () => [
          isA<BackupLoaded>().having(
            (s) => s.wifiOnlyEnabled,
            'wifiOnlyEnabled',
            false,
          ),
        ],
      );

      blocTest<BackupBloc, BackupState>(
        'emits BackupError when toggle fails',
        build: () {
          when(() => mockBackupService.setWifiOnlyEnabled(any()))
              .thenThrow(Exception('Service error'));
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: 'daily',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(const ToggleWifiOnly(true)),
        expect: () => [
          isA<BackupError>().having(
            (state) => state.message,
            'message',
            contains('Error updating WiFi-only setting'),
          ),
        ],
      );
    });

    group('ToggleCompression Event Handler', () {
      blocTest<BackupBloc, BackupState>(
        'enables compression',
        build: () {
          when(() => mockBackupService.setCompressionEnabled(any()))
              .thenAnswer((_) async {});
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: 'daily',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(const ToggleCompression(true)),
        verify: (_) {
          verify(() => mockBackupService.setCompressionEnabled(true)).called(1);
        },
        expect: () => [
          isA<BackupLoaded>().having(
            (s) => s.compressionEnabled,
            'compressionEnabled',
            true,
          ),
        ],
      );

      blocTest<BackupBloc, BackupState>(
        'disables compression',
        build: () {
          when(() => mockBackupService.setCompressionEnabled(any()))
              .thenAnswer((_) async {});
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: 'daily',
          wifiOnlyEnabled: false,
          compressionEnabled: true,
          backupOptions: {},
          estimatedSize: 0,
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(const ToggleCompression(false)),
        verify: (_) {
          verify(() => mockBackupService.setCompressionEnabled(false))
              .called(1);
        },
        expect: () => [
          isA<BackupLoaded>().having(
            (s) => s.compressionEnabled,
            'compressionEnabled',
            false,
          ),
        ],
      );

      blocTest<BackupBloc, BackupState>(
        'emits BackupError when toggle fails',
        build: () {
          when(() => mockBackupService.setCompressionEnabled(any()))
              .thenThrow(Exception('Service error'));
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: 'daily',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(const ToggleCompression(true)),
        expect: () => [
          isA<BackupError>().having(
            (state) => state.message,
            'message',
            contains('Error updating compression setting'),
          ),
        ],
      );
    });

    group('UpdateBackupOptions Event Handler', () {
      blocTest<BackupBloc, BackupState>(
        'updates backup options successfully',
        build: () {
          when(() => mockBackupService.setBackupOptions(any()))
              .thenAnswer((_) async {});
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: 'daily',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(
          const UpdateBackupOptions({'favorites': true, 'settings': false}),
        ),
        verify: (_) {
          verify(
            () => mockBackupService
                .setBackupOptions({'favorites': true, 'settings': false}),
          ).called(1);
        },
        expect: () => [
          isA<BackupLoaded>().having(
            (s) => s.backupOptions,
            'backupOptions',
            {'favorites': true, 'settings': false},
          ),
        ],
      );

      blocTest<BackupBloc, BackupState>(
        'emits BackupError when update fails',
        build: () {
          when(() => mockBackupService.setBackupOptions(any()))
              .thenThrow(Exception('Service error'));
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: 'daily',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(const UpdateBackupOptions({'test': true})),
        expect: () => [
          isA<BackupError>().having(
            (state) => state.message,
            'message',
            contains('Error updating backup options'),
          ),
        ],
      );
    });

    group('RefreshBackupStatus Event Handler', () {
      blocTest<BackupBloc, BackupState>(
        'refreshes backup status successfully',
        build: () {
          final now = DateTime.now();
          when(() => mockBackupService.getLastBackupTime())
              .thenAnswer((_) async => now);
          when(() => mockBackupService.getNextBackupTime())
              .thenAnswer((_) async => now.add(const Duration(days: 1)));
          when(() => mockBackupService.getEstimatedBackupSize(any()))
              .thenAnswer((_) async => 2048);
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: 'daily',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(const RefreshBackupStatus()),
        expect: () => [
          const BackupLoading(),
          isA<BackupLoaded>()
              .having((s) => s.estimatedSize, 'estimatedSize', 2048),
        ],
      );

      blocTest<BackupBloc, BackupState>(
        'emits BackupError when refresh fails',
        build: () {
          when(() => mockBackupService.getLastBackupTime())
              .thenThrow(Exception('Service error'));
          return BackupBloc(
            backupService: mockBackupService,
            devocionalProvider: mockDevocionalProvider,
          );
        },
        seed: () => const BackupLoaded(
          autoBackupEnabled: true,
          backupFrequency: 'daily',
          wifiOnlyEnabled: false,
          compressionEnabled: false,
          backupOptions: {},
          estimatedSize: 0,
          isAuthenticated: true,
        ),
        act: (bloc) => bloc.add(const RefreshBackupStatus()),
        expect: () => [
          const BackupLoading(),
          isA<BackupError>().having(
            (state) => state.message,
            'message',
            contains('Error refreshing backup status'),
          ),
        ],
      );
    });
  });
}
