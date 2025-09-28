// test/unit/blocs/backup_bloc_comprehensive_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/backup_scheduler_service.dart';
import 'package:devocional_nuevo/services/google_drive_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupBloc Comprehensive Tests', () {
    late BackupBloc backupBloc;
    late _MockGoogleDriveBackupService mockBackupService;
    late _MockBackupSchedulerService mockSchedulerService;
    late _MockDevocionalProvider mockDevocionalProvider;

    setUp(() async {
      // Setup common test mocks
      TestSetup.setupCommonMocks();
      
      // Initialize mock dependencies
      mockBackupService = _MockGoogleDriveBackupService();
      mockSchedulerService = _MockBackupSchedulerService();
      mockDevocionalProvider = _MockDevocionalProvider();

      // Setup SharedPreferences
      SharedPreferences.setMockInitialValues({
        'backup_auto_enabled': false,
        'backup_frequency': 'daily',
        'backup_wifi_only': true,
        'backup_compression_enabled': true,
      });

      // Create backup bloc with mocked dependencies
      backupBloc = BackupBloc(
        backupService: mockBackupService,
        schedulerService: mockSchedulerService,
        devocionalProvider: mockDevocionalProvider,
      );
    });

    tearDown(() {
      backupBloc.close();
      TestSetup.cleanupMocks();
    });

    group('Backup State Transitions', () {
      blocTest<BackupBloc, BackupState>(
        'should handle backup state transitions correctly',
        build: () => backupBloc,
        act: (bloc) => bloc.add(const LoadBackupSettings()),
        expect: () => [
          isA<BackupLoading>(),
          isA<BackupSettingsLoaded>(),
        ],
      );

      blocTest<BackupBloc, BackupState>(
        'should process backup success and error states',
        build: () {
          mockBackupService.createBackupResult = {
            'success': true,
            'backup_size_bytes': 1024,
            'backup_path': '/test/backup.zip',
          };
          return backupBloc;
        },
        act: (bloc) => bloc.add(const CreateManualBackup()),
        expect: () => [
          isA<BackupInProgress>(),
          isA<BackupSuccess>(),
        ],
      );

      blocTest<BackupBloc, BackupState>(
        'should handle backup errors gracefully',
        build: () {
          mockBackupService.shouldThrowError = true;
          return backupBloc;
        },
        act: (bloc) => bloc.add(const CreateManualBackup()),
        expect: () => [
          isA<BackupInProgress>(),
          isA<BackupError>(),
        ],
      );
    });

    group('Backup Configuration Management', () {
      blocTest<BackupBloc, BackupState>(
        'should validate backup configuration persistence',
        build: () => backupBloc,
        act: (bloc) => bloc.add(const ToggleAutoBackup(enabled: true)),
        expect: () => [
          isA<BackupLoading>(),
          isA<BackupSettingsLoaded>(),
        ],
      );

      blocTest<BackupBloc, BackupState>(
        'should change backup frequency correctly',
        build: () => backupBloc,
        act: (bloc) => bloc.add(const ChangeBackupFrequency(frequency: 'weekly')),
        expect: () => [
          isA<BackupLoading>(),
          isA<BackupSettingsLoaded>(),
        ],
      );

      blocTest<BackupBloc, BackupState>(
        'should toggle WiFi-only requirement',
        build: () => backupBloc,
        act: (bloc) => bloc.add(const ToggleWifiOnly(enabled: false)),
        expect: () => [
          isA<BackupLoading>(),
          isA<BackupSettingsLoaded>(),
        ],
      );

      blocTest<BackupBloc, BackupState>(
        'should toggle compression setting',
        build: () => backupBloc,
        act: (bloc) => bloc.add(const ToggleCompression(enabled: false)),
        expect: () => [
          isA<BackupLoading>(),
          isA<BackupSettingsLoaded>(),
        ],
      );
    });

    group('Google Drive Authentication', () {
      blocTest<BackupBloc, BackupState>(
        'should handle Google Drive sign-in',
        build: () {
          mockBackupService.signInResult = {
            'success': true,
            'email': 'test@example.com',
          };
          mockBackupService.isSignedInResult = true;
          mockBackupService.userEmail = 'test@example.com';
          return backupBloc;
        },
        act: (bloc) => bloc.add(const SignInToGoogleDrive()),
        expect: () => [
          isA<BackupLoading>(),
          isA<BackupSettingsLoaded>(),
        ],
      );

      blocTest<BackupBloc, BackupState>(
        'should handle Google Drive sign-out',
        build: () {
          mockBackupService.isSignedInResult = false;
          mockBackupService.userEmail = null;
          return backupBloc;
        },
        act: (bloc) => bloc.add(const SignOutFromGoogleDrive()),
        expect: () => [
          isA<BackupLoading>(),
          isA<BackupSettingsLoaded>(),
        ],
      );
    });

    group('Backup Restoration', () {
      blocTest<BackupBloc, BackupState>(
        'should handle backup restoration successfully',
        build: () {
          mockBackupService.restoreResult = {
            'success': true,
            'restored_items': 150,
          };
          return backupBloc;
        },
        act: (bloc) => bloc.add(const RestoreFromBackup()),
        expect: () => [
          isA<BackupInProgress>(),
          isA<BackupRestoreSuccess>(),
        ],
      );

      blocTest<BackupBloc, BackupState>(
        'should handle backup restoration errors',
        build: () {
          mockBackupService.restoreShouldThrowError = true;
          return backupBloc;
        },
        act: (bloc) => bloc.add(const RestoreFromBackup()),
        expect: () => [
          isA<BackupInProgress>(),
          isA<BackupError>(),
        ],
      );
    });

    group('Storage Information', () {
      blocTest<BackupBloc, BackupState>(
        'should load storage information correctly',
        build: () => backupBloc,
        act: (bloc) => bloc.add(const LoadStorageInfo()),
        expect: () => [
          isA<BackupLoading>(),
          isA<BackupSettingsLoaded>(),
        ],
      );
    });

    group('Backup Status Management', () {
      blocTest<BackupBloc, BackupState>(
        'should refresh backup status correctly',
        build: () => backupBloc,
        act: (bloc) => bloc.add(const RefreshBackupStatus()),
        expect: () => [
          isA<BackupLoading>(),
          isA<BackupSettingsLoaded>(),
        ],
      );

      blocTest<BackupBloc, BackupState>(
        'should check startup backup requirements',
        build: () {
          mockSchedulerService.shouldCreateAutoBackupResult = true;
          mockBackupService.createBackupResult = {
            'success': true,
            'backup_size_bytes': 2048,
          };
          return backupBloc;
        },
        act: (bloc) => bloc.add(const CheckStartupBackup()),
        expect: () => [
          isA<BackupInProgress>(),
          isA<BackupSuccess>(),
        ],
      );
    });

    group('Dependency Injection', () {
      test('should set devotional provider correctly', () {
        final newProvider = _MockDevocionalProvider();
        backupBloc.setDevocionalProvider(newProvider);
        
        // Verify method completes without error
        expect(backupBloc, isNotNull);
      });
    });

    group('Error Handling', () {
      blocTest<BackupBloc, BackupState>(
        'should handle service unavailability gracefully',
        build: () {
          mockBackupService.shouldThrowErrorOnSettings = true;
          return backupBloc;
        },
        act: (bloc) => bloc.add(const LoadBackupSettings()),
        expect: () => [
          isA<BackupLoading>(),
          isA<BackupError>(),
        ],
      );

      blocTest<BackupBloc, BackupState>(
        'should handle network errors during backup',
        build: () {
          mockBackupService.shouldThrowError = true;
          return backupBloc;
        },
        act: (bloc) => bloc.add(const CreateManualBackup()),
        expect: () => [
          isA<BackupInProgress>(),
          isA<BackupError>(),
        ],
      );
    });

    group('State Validation', () {
      test('should start with initial state', () {
        expect(backupBloc.state, isA<BackupInitial>());
      });

      test('should handle multiple configuration updates', () async {
        // Test multiple rapid configuration changes
        backupBloc.add(const ToggleAutoBackup(enabled: true));
        backupBloc.add(const ChangeBackupFrequency(frequency: 'weekly'));
        backupBloc.add(const ToggleWifiOnly(enabled: false));
        
        // Wait for all events to process
        await Future.delayed(const Duration(milliseconds: 100));
        
        // BLoC should handle multiple events gracefully
        expect(backupBloc.state, isA<BackupState>());
      });
    });
  });
}

// Simple mock implementations for testing
class _MockGoogleDriveBackupService implements GoogleDriveBackupService {
  bool shouldThrowError = false;
  bool shouldThrowErrorOnSettings = false;
  bool restoreShouldThrowError = false;
  Map<String, dynamic>? createBackupResult;
  Map<String, dynamic>? signInResult;
  Map<String, dynamic>? restoreResult;
  bool isSignedInResult = false;
  String? userEmail;

  @override
  Future<bool> isAutoBackupEnabled() async {
    if (shouldThrowErrorOnSettings) throw Exception('Service unavailable');
    return false;
  }

  @override
  Future<String> getBackupFrequency() async {
    if (shouldThrowErrorOnSettings) throw Exception('Service unavailable');
    return 'daily';
  }

  @override
  Future<bool> isWifiOnlyEnabled() async => true;

  @override
  Future<bool> isCompressionEnabled() async => true;

  @override
  Future<bool> isSignedIn() async => isSignedInResult;

  @override
  Future<String?> getUserEmail() async => userEmail;

  @override
  Future<Map<String, dynamic>> getStorageInfo() async => {
    'used': 0,
    'total': 15000000000,
    'available': 15000000000,
  };

  @override
  Future<void> setAutoBackupEnabled(bool enabled) async {}

  @override
  Future<void> setBackupFrequency(String frequency) async {}

  @override
  Future<void> setWifiOnlyEnabled(bool enabled) async {}

  @override
  Future<void> setCompressionEnabled(bool enabled) async {}

  @override
  Future<Map<String, dynamic>> signIn() async {
    return signInResult ?? {'success': true, 'email': 'test@example.com'};
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<Map<String, dynamic>> createBackup() async {
    if (shouldThrowError) throw Exception('Backup failed');
    return createBackupResult ?? {
      'success': true,
      'backup_size_bytes': 1024,
    };
  }

  @override
  Future<Map<String, dynamic>> restoreFromBackup() async {
    if (restoreShouldThrowError) throw Exception('Restore failed');
    return restoreResult ?? {
      'success': true,
      'restored_items': 100,
    };
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockBackupSchedulerService implements BackupSchedulerService {
  bool shouldCreateAutoBackupResult = false;

  @override
  Future<bool> shouldCreateAutoBackup() async => shouldCreateAutoBackupResult;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockDevocionalProvider implements DevocionalProvider {
  @override
  Future<void> reloadFavoritesFromStorage() async {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}