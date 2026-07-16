@Tags(['critical', 'unit', 'blocs'])
library;

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_bloc.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/models/backup_content_summary.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/backup/i_google_drive_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoogleDriveBackupService extends Mock
    implements IGoogleDriveBackupService {}

class MockDevocionalProvider extends Mock implements DevocionalProvider {}

class MockDiscoveryBloc extends Mock implements DiscoveryBloc {}

class MockEncounterBloc extends Mock implements EncounterBloc {}

class MockDevocionalesNavigationBloc extends Mock
    implements DevocionalesNavigationBloc {}

class _FakeDiscoveryEvent extends Fake implements DiscoveryEvent {}

class _FakeEncounterEvent extends Fake implements EncounterEvent {}

class _FakeDevocionalesNavigationEvent extends Fake
    implements DevocionalesNavigationEvent {}

const _emptySummary = BackupContentSummary(
  prayersCount: 0,
  thanksgivingsCount: 0,
  testimoniesCount: 0,
  favoritesCount: 0,
  encountersCount: 0,
  discoveryCount: 0,
  versesCount: 0,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeDiscoveryEvent());
    registerFallbackValue(_FakeEncounterEvent());
    registerFallbackValue(_FakeDevocionalesNavigationEvent());
  });

  late MockGoogleDriveBackupService mockBackupService;
  late MockDevocionalProvider mockDevocionalProvider;
  late MockDiscoveryBloc mockDiscoveryBloc;
  late MockEncounterBloc mockEncounterBloc;
  late MockDevocionalesNavigationBloc mockNavigationBloc;

  setUp(() {
    mockBackupService = MockGoogleDriveBackupService();
    mockDevocionalProvider = MockDevocionalProvider();
    mockDiscoveryBloc = MockDiscoveryBloc();
    mockEncounterBloc = MockEncounterBloc();
    mockNavigationBloc = MockDevocionalesNavigationBloc();

    when(
      () => mockBackupService.isAuthenticated(),
    ).thenAnswer((_) async => true);
    when(
      () => mockBackupService.isAutoBackupEnabled(),
    ).thenAnswer((_) async => false);
    when(
      () => mockBackupService.setAutoBackupEnabled(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockBackupService.getBackupFrequency(),
    ).thenAnswer((_) async => 'deactivated');
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
    ).thenAnswer((_) async => null);
    when(
      () => mockDevocionalProvider.waitUntilInitialized(),
    ).thenAnswer((_) async {});
    when(
      () => mockDevocionalProvider.reloadVersionFromStorage(),
    ).thenAnswer((_) async {});
    when(
      () => mockDevocionalProvider.reloadFavoritesFromStorage(),
    ).thenAnswer((_) async {});
    when(
      () => mockDevocionalProvider.reloadSpiritualStatsFromStorage(),
    ).thenAnswer((_) async {});
    when(
      () => mockDevocionalProvider.lastRestoredReadIds,
    ).thenReturn(<String>{'d1', 'd2'});
    when(
      () => mockBackupService.getBackupContentSummary(),
    ).thenAnswer((_) async => _emptySummary);
  });

  group('SignInToGoogleDrive — existing backup auto-restore', () {
    setUp(() {
      when(() => mockBackupService.signIn()).thenAnswer((_) async => true);
      when(() => mockBackupService.checkForExistingBackup()).thenAnswer(
        (_) async => {'found': true, 'fileId': 'file-123'},
      );
      when(
        () => mockBackupService.restoreExistingBackup(
          any(),
          prayerBloc: any(named: 'prayerBloc'),
        ),
      ).thenAnswer((_) async => true);
    });

    blocTest<BackupBloc, BackupState>(
      'restores existing backup, reloads discovery/encounter/provider, '
      'navigates to first unread, and emits BackupSuccess',
      build: () => BackupBloc(
        backupService: mockBackupService,
        devocionalProvider: mockDevocionalProvider,
        discoveryBloc: mockDiscoveryBloc,
        encounterBloc: mockEncounterBloc,
        navigationBloc: mockNavigationBloc,
      ),
      act: (bloc) => bloc.add(const SignInToGoogleDrive()),
      wait: const Duration(seconds: 3),
      expect: () => <dynamic>[
        const BackupSigningIn(),
        const BackupRestoring(),
        isA<BackupSuccess>()
            .having((s) => s.title, 'title', 'backup.sign_in_success')
            .having(
              (s) => s.message,
              'message',
              'backup.restored_successfully',
            ),
        const BackupLoading(),
        isA<BackupLoaded>(),
      ],
      verify: (_) {
        verify(
          () => mockBackupService.restoreExistingBackup(
            'file-123',
            prayerBloc: null,
          ),
        ).called(1);
        verify(
          () => mockDiscoveryBloc.add(
            any(that: isA<RefreshDiscoveryStudies>()),
          ),
        ).called(1);
        verify(
          () => mockEncounterBloc.add(any(that: isA<LoadEncounterIndex>())),
        ).called(1);
        verify(() => mockDevocionalProvider.reloadVersionFromStorage())
            .called(1);
        verify(() => mockDevocionalProvider.reloadFavoritesFromStorage())
            .called(1);
        verify(() => mockDevocionalProvider.reloadSpiritualStatsFromStorage())
            .called(1);
        final captured = verify(
          () => mockNavigationBloc.add(captureAny()),
        ).captured;
        expect(captured.single, isA<NavigateToFirstUnread>());
        expect(
          (captured.single as NavigateToFirstUnread).readDevocionalIds,
          containsAll(<String>['d1', 'd2']),
        );
      },
    );

    blocTest<BackupBloc, BackupState>(
      'emits BackupError when restore fails without touching discovery/encounter',
      build: () {
        when(
          () => mockBackupService.restoreExistingBackup(
            any(),
            prayerBloc: any(named: 'prayerBloc'),
          ),
        ).thenAnswer((_) async => false);
        return BackupBloc(
          backupService: mockBackupService,
          devocionalProvider: mockDevocionalProvider,
          discoveryBloc: mockDiscoveryBloc,
          encounterBloc: mockEncounterBloc,
          navigationBloc: mockNavigationBloc,
        );
      },
      act: (bloc) => bloc.add(const SignInToGoogleDrive()),
      expect: () => <dynamic>[
        const BackupSigningIn(),
        const BackupRestoring(),
        const BackupError('backup.restore_failed'),
      ],
      verify: (_) {
        verifyNever(() => mockDiscoveryBloc.add(any()));
        verifyNever(() => mockEncounterBloc.add(any()));
        verifyNever(() => mockNavigationBloc.add(any()));
      },
    );
  });

  group('SignInToGoogleDrive — user cancels sign-in', () {
    setUp(() {
      when(() => mockBackupService.signIn()).thenAnswer((_) async => null);
    });

    blocTest<BackupBloc, BackupState>(
      'falls back to LoadBackupSettings without emitting an error',
      build: () => BackupBloc(
        backupService: mockBackupService,
        devocionalProvider: mockDevocionalProvider,
      ),
      act: (bloc) => bloc.add(const SignInToGoogleDrive()),
      expect: () => <dynamic>[
        const BackupSigningIn(),
        const BackupLoading(),
        isA<BackupLoaded>(),
      ],
    );
  });

  group('SignInToGoogleDrive — provider not ready for initial backup', () {
    setUp(() {
      when(() => mockBackupService.signIn()).thenAnswer((_) async => true);
      when(
        () => mockBackupService.checkForExistingBackup(),
      ).thenAnswer((_) async => null);
      when(() => mockDevocionalProvider.waitUntilInitialized()).thenAnswer(
        (_) => Future<void>.error(TimeoutException('provider not ready')),
      );
    });

    blocTest<BackupBloc, BackupState>(
      'defers without creating a backup or crashing when provider times out',
      build: () => BackupBloc(
        backupService: mockBackupService,
        devocionalProvider: mockDevocionalProvider,
      ),
      act: (bloc) => bloc.add(const SignInToGoogleDrive()),
      expect: () => <dynamic>[const BackupSigningIn()],
      verify: (_) {
        verifyNever(() => mockBackupService.createBackup(any()));
      },
    );
  });

  group('SignOutFromGoogleDrive', () {
    blocTest<BackupBloc, BackupState>(
      'signs out and reloads settings',
      build: () {
        when(() => mockBackupService.signOut()).thenAnswer((_) async {});
        return BackupBloc(
          backupService: mockBackupService,
          devocionalProvider: mockDevocionalProvider,
        );
      },
      act: (bloc) => bloc.add(const SignOutFromGoogleDrive()),
      expect: () => <dynamic>[
        const BackupLoading(),
        isA<BackupLoaded>(),
      ],
      verify: (_) {
        verify(() => mockBackupService.signOut()).called(1);
      },
    );

    blocTest<BackupBloc, BackupState>(
      'emits BackupError with raw exception text when sign-out throws',
      build: () {
        when(
          () => mockBackupService.signOut(),
        ).thenThrow(Exception('network down'));
        return BackupBloc(
          backupService: mockBackupService,
          devocionalProvider: mockDevocionalProvider,
        );
      },
      act: (bloc) => bloc.add(const SignOutFromGoogleDrive()),
      expect: () => <dynamic>[
        isA<BackupError>().having(
          (s) => s.message,
          'message',
          contains('network down'),
        ),
      ],
    );
  });
}
