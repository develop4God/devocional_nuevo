@Tags(['critical', 'unit', 'blocs'])
library;

// test/unit/blocs/backup_bloc_restore_stats_test.dart
//
// Validates that after a backup restore, spiritual stats (read/heard devotional
// IDs) are refreshed on DevocionalProvider immediately — so that any widget
// depending on the provider rebuilds with the newly-restored data without
// requiring an app restart.

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/backup/i_google_drive_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class MockGoogleDriveBackupService extends Mock
    implements IGoogleDriveBackupService {}

class MockDevocionalProvider extends Mock implements DevocionalProvider {}

// ── Test group ──────────────────────────────────────────────────────────────

void main() {
  group('BackupBloc — Restore Stats Refresh', () {
    late MockGoogleDriveBackupService mockBackupService;
    late MockDevocionalProvider mockProvider;

    setUp(() {
      mockBackupService = MockGoogleDriveBackupService();
      mockProvider = MockDevocionalProvider();

      // Default stubs so LoadBackupSettings succeeds when the bloc
      // re-dispatches it after a successful restore.
      when(() => mockBackupService.isAuthenticated())
          .thenAnswer((_) async => true);
      when(() => mockBackupService.isAutoBackupEnabled())
          .thenAnswer((_) async => true);
      when(() => mockBackupService.getBackupFrequency())
          .thenAnswer((_) async => 'daily');
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
          .thenAnswer((_) async => 'user@test.com');

      // Provider method stubs
      when(() => mockProvider.reloadFavoritesFromStorage())
          .thenAnswer((_) async {});
      when(() => mockProvider.reloadSpiritualStatsFromStorage())
          .thenAnswer((_) async {});
    });

    // ── Test 1: RestoreFromBackup calls reloadSpiritualStatsFromStorage ────

    blocTest<BackupBloc, BackupState>(
      'RestoreFromBackup — on success calls reloadSpiritualStatsFromStorage '
      'so read/heard IDs are visible in UI without restart',
      build: () => BackupBloc(
        backupService: mockBackupService,
        devocionalProvider: mockProvider,
      ),
      setUp: () {
        // Successful restore
        when(
          () => mockBackupService.restoreBackup(
              onRestored: any(named: 'onRestored')),
        ).thenAnswer((invocation) async {
          // Simulate the service calling the onRestored callback,
          // just as the real implementation does after writing to SharedPreferences.
          final cb = invocation.namedArguments[#onRestored] as Future<void>
              Function()?;
          await cb?.call();
          return true;
        });
      },
      act: (bloc) => bloc.add(const RestoreFromBackup()),
      expect: () => [
        const BackupRestoring(),
        const BackupRestored(),
        // BackupBloc adds LoadBackupSettings after restore → emits Loading + Loaded
        const BackupLoading(),
        isA<BackupLoaded>(),
      ],
      verify: (_) {
        // Both reload methods MUST be called after a successful restore.
        verify(() => mockProvider.reloadFavoritesFromStorage()).called(1);
        verify(() => mockProvider.reloadSpiritualStatsFromStorage()).called(1);
      },
    );

    // ── Test 2: RestoreFromBackup failure does NOT call reload methods ─────

    blocTest<BackupBloc, BackupState>(
      'RestoreFromBackup — on failure does NOT call provider reload methods',
      build: () => BackupBloc(
        backupService: mockBackupService,
        devocionalProvider: mockProvider,
      ),
      setUp: () {
        when(
          () => mockBackupService.restoreBackup(
              onRestored: any(named: 'onRestored')),
        ).thenAnswer((_) async => false);
      },
      act: (bloc) => bloc.add(const RestoreFromBackup()),
      expect: () => [
        const BackupRestoring(),
        const BackupError('Failed to restore backup'),
      ],
      verify: (_) {
        // When restore fails, provider must NOT be reloaded (no partial state).
        verifyNever(() => mockProvider.reloadFavoritesFromStorage());
        verifyNever(() => mockProvider.reloadSpiritualStatsFromStorage());
      },
    );

    // ── Test 3: RestoreFromBackup without a provider is safe ──────────────

    blocTest<BackupBloc, BackupState>(
      'RestoreFromBackup — works safely when devocionalProvider is null',
      build: () => BackupBloc(
        backupService: mockBackupService,
        // No provider injected — simulates headless / background restore
      ),
      setUp: () {
        when(
          () => mockBackupService.restoreBackup(
              onRestored: any(named: 'onRestored')),
        ).thenAnswer((invocation) async {
          final cb = invocation.namedArguments[#onRestored] as Future<void>
              Function()?;
          await cb?.call(); // cb is null → no-op
          return true;
        });
      },
      act: (bloc) => bloc.add(const RestoreFromBackup()),
      expect: () => [
        const BackupRestoring(),
        const BackupRestored(),
        const BackupLoading(),
        isA<BackupLoaded>(),
      ],
    );

    // ── Test 4: reloadSpiritualStatsFromStorage called on sign-in restore ──

    blocTest<BackupBloc, BackupState>(
      'SignInToGoogleDrive — auto-restore calls reloadSpiritualStatsFromStorage '
      'so read devotionals appear without restart',
      build: () => BackupBloc(
        backupService: mockBackupService,
        devocionalProvider: mockProvider,
      ),
      setUp: () {
        when(() => mockBackupService.signIn()).thenAnswer((_) async => true);
        when(() => mockBackupService.isAutoBackupEnabled())
            .thenAnswer((_) async => true);
        when(() => mockBackupService.checkForExistingBackup()).thenAnswer(
          (_) async => {'found': true, 'fileId': 'file-123'},
        );
        when(
          () => mockBackupService.restoreExistingBackup(
            'file-123',
            prayerBloc: any(named: 'prayerBloc'),
          ),
        ).thenAnswer((_) async => true);
      },
      act: (bloc) => bloc.add(const SignInToGoogleDrive()),
      // State sequence: Loading → BackupRestoring → BackupSuccess → Loading → Loaded
      // We only assert that reloadSpiritualStatsFromStorage is verified below.
      verify: (_) {
        verify(() => mockProvider.reloadSpiritualStatsFromStorage()).called(1);
      },
    );
  });
}
