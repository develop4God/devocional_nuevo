@Tags(['unit', 'blocs', 'onboarding'])
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

class MockGoogleDriveBackupService extends Mock
    implements IGoogleDriveBackupService {}

class MockDevocionalProvider extends Mock implements DevocionalProvider {}

/// Verifies the bloc-state precondition that
/// OnboardingBackupConfigurationPage's "always show a way forward"
/// safeguard button relies on: once already authenticated, LoadBackupSettings
/// must land on BackupLoaded(isAuthenticated: true), regardless of whether
/// this is a fresh sign-in or the user re-entering an already-connected step
/// (e.g. navigating back and forward again). The page reads this exact
/// state to decide whether to show the safeguard "Next" button.
void main() {
  group('BackupBloc — already-authenticated safeguard precondition', () {
    late MockGoogleDriveBackupService mockBackupService;
    late MockDevocionalProvider mockDevocionalProvider;

    setUp(() {
      mockBackupService = MockGoogleDriveBackupService();
      mockDevocionalProvider = MockDevocionalProvider();

      when(
        () => mockBackupService.isAutoBackupEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => mockBackupService.getBackupFrequency(),
      ).thenAnswer((_) async => 'daily');
      when(
        () => mockBackupService.isWifiOnlyEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => mockBackupService.isCompressionEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => mockBackupService.getBackupOptions(),
      ).thenAnswer((_) async => <String, bool>{});
      when(
        () => mockBackupService.getLastBackupTime(),
      ).thenAnswer((_) async => null);
      when(
        () => mockBackupService.getNextBackupTime(),
      ).thenAnswer((_) async => null);
      when(
        () => mockBackupService.getEstimatedBackupSize(any()),
      ).thenAnswer((_) async => 0);
      when(
        () => mockBackupService.getUserEmail(),
      ).thenAnswer((_) async => 'user@example.com');
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
      when(
        () => mockDevocionalProvider.waitUntilInitialized(),
      ).thenAnswer((_) async {});
    });

    blocTest<BackupBloc, BackupState>(
      'emits BackupLoaded(isAuthenticated: true) when the service reports '
      'an existing session — the safeguard button must appear in this state',
      build: () {
        when(
          () => mockBackupService.isAuthenticated(),
        ).thenAnswer((_) async => true);
        return BackupBloc(
          backupService: mockBackupService,
          devocionalProvider: mockDevocionalProvider,
        );
      },
      act: (bloc) => bloc.add(const LoadBackupSettings()),
      expect: () => [
        const BackupLoading(),
        isA<BackupLoaded>().having(
          (s) => s.isAuthenticated,
          'isAuthenticated',
          true,
        ),
      ],
    );

    blocTest<BackupBloc, BackupState>(
      'emits BackupLoaded(isAuthenticated: false) when not signed in — '
      'the safeguard button must stay hidden in this state',
      build: () {
        when(
          () => mockBackupService.isAuthenticated(),
        ).thenAnswer((_) async => false);
        return BackupBloc(
          backupService: mockBackupService,
          devocionalProvider: mockDevocionalProvider,
        );
      },
      act: (bloc) => bloc.add(const LoadBackupSettings()),
      expect: () => [
        const BackupLoading(),
        isA<BackupLoaded>().having(
          (s) => s.isAuthenticated,
          'isAuthenticated',
          false,
        ),
      ],
    );
  });
}
