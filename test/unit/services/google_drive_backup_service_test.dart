@Tags(['unit', 'services', 'backup'])
library;

// test/unit/services/google_drive_backup_service_test.dart
//
// Real behavioral tests for GoogleDriveBackupService, driven through its
// public IGoogleDriveBackupService API with mocked collaborators — not the
// previous file's approach of re-implementing the service's logic as local
// functions and testing the copies (see google_drive_backup_service_working_test.dart,
// which never imports GoogleDriveBackupService at all).
//
// Drive-API upload/download paths that require a real drive.DriveApi are out
// of scope here — DriveApi is a concrete googleapis class with no seam for a
// lightweight fake; those paths need an http.Client-level mock (see Flags in
// the delegation report). This file covers everything reachable without one:
// auth/connectivity gating, backup content summary, auto-backup scheduling,
// size estimation, and backup options persistence. Bible-note restore is
// covered separately in google_drive_backup_service_restore_bible_notes_test.dart.

import 'package:devocional_nuevo/services/backup/google_drive_backup_service.dart';
import 'package:devocional_nuevo/utils/constants/backup_keys_constants.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/google_drive_backup_mock_helper.dart';

void main() {
  late MockGoogleDriveAuthService authService;
  late MockConnectivityService connectivityService;
  late MockSpiritualStatsService statsService;
  late MockLocalizationService localizationService;
  late MockBackupSettingsService settingsService;
  late MockBibleNotesRepository bibleNotesRepository;
  late GoogleDriveBackupService service;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    authService = MockGoogleDriveAuthService();
    connectivityService = MockConnectivityService();
    statsService = MockSpiritualStatsService();
    localizationService = MockLocalizationService();
    settingsService = MockBackupSettingsService();
    bibleNotesRepository = MockBibleNotesRepository();

    when(
      () => localizationService.translate(any()),
    ).thenAnswer((inv) => inv.positionalArguments.first as String);
    when(
      () => localizationService.currentLocale,
    ).thenReturn(const Locale('en'));

    service = GoogleDriveBackupService(
      authService: authService,
      connectivityService: connectivityService,
      statsService: statsService,
      localizationService: localizationService,
      settingsService: settingsService,
      bibleNotesRepository: bibleNotesRepository,
    );
  });

  group('createBackup — auth and connectivity gating', () {
    test('returns false and does not call Drive API when sign-in fails',
        () async {
      when(() => authService.isSignedIn()).thenAnswer((_) async => false);
      when(() => authService.signIn()).thenAnswer((_) async => false);

      final result = await service.createBackup(null);

      expect(result, isFalse);
      verifyNever(() => authService.getDriveApi());
    });

    test(
      'returns false when WiFi-only is enabled but not on WiFi',
      () async {
        when(() => authService.isSignedIn()).thenAnswer((_) async => true);
        when(
          () => settingsService.isWifiOnlyEnabled(),
        ).thenAnswer((_) async => true);
        when(
          () => connectivityService.shouldProceedWithBackup(true),
        ).thenAnswer((_) async => false);

        final result = await service.createBackup(null);

        expect(result, isFalse);
        verifyNever(() => authService.getDriveApi());
      },
    );

    test('returns false when Drive API client is unavailable', () async {
      when(() => authService.isSignedIn()).thenAnswer((_) async => true);
      when(
        () => settingsService.isWifiOnlyEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => connectivityService.shouldProceedWithBackup(false),
      ).thenAnswer((_) async => true);
      when(() => authService.getDriveApi()).thenAnswer((_) async => null);
      when(
        () => settingsService.isCompressionEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => statsService.getAllStats(),
      ).thenAnswer((_) async => {'stats': {}});

      final result = await service.createBackup(null);

      expect(result, isFalse);
    });
  });

  group('shouldCreateAutoBackup', () {
    test('returns false when auto-backup is disabled', () async {
      when(
        () => settingsService.isAutoBackupEnabled(),
      ).thenAnswer((_) async => false);

      final result = await service.shouldCreateAutoBackup();

      expect(result, isFalse);
      verifyNever(() => settingsService.getLastBackupTime());
    });

    test('returns true when enabled and no backup has ever run', () async {
      when(
        () => settingsService.isAutoBackupEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => settingsService.getLastBackupTime(),
      ).thenAnswer((_) async => null);

      final result = await service.shouldCreateAutoBackup();

      expect(result, isTrue);
    });

    test('returns false when next backup time is unschedulable', () async {
      when(
        () => settingsService.isAutoBackupEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => settingsService.getLastBackupTime(),
      ).thenAnswer((_) async => DateTime.now());
      when(
        () => settingsService.getNextBackupTime(),
      ).thenAnswer((_) async => null);

      final result = await service.shouldCreateAutoBackup();

      expect(result, isFalse);
    });

    test('returns true only once next backup time has passed', () async {
      when(
        () => settingsService.isAutoBackupEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => settingsService.getLastBackupTime(),
      ).thenAnswer(
          (_) async => DateTime.now().subtract(const Duration(days: 2)));

      when(
        () => settingsService.getNextBackupTime(),
      ).thenAnswer(
          (_) async => DateTime.now().subtract(const Duration(hours: 1)));
      expect(await service.shouldCreateAutoBackup(), isTrue);

      when(
        () => settingsService.getNextBackupTime(),
      ).thenAnswer((_) async => DateTime.now().add(const Duration(hours: 1)));
      expect(await service.shouldCreateAutoBackup(), isFalse);
    });
  });

  group('getBackupContentSummary', () {
    test('returns empty summary when SharedPreferences has no data', () async {
      final summary = await service.getBackupContentSummary();

      expect(summary.isEmpty, isTrue);
      expect(summary.totalItems, 0);
    });

    test('counts prayers from real SharedPreferences state', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'prayers',
        '[{"id":"1"},{"id":"2"},{"id":"3"}]',
      );

      final summary = await service.getBackupContentSummary();

      expect(summary.prayersCount, 3);
      expect(summary.isEmpty, isFalse);
    });

    test('sums devotional notes and bible notes into notesCount', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('devotional_notes', '[{"devocionalId":"a"}]');
      await prefs.setString(
        'bible_notes',
        '[{"bookName":"Gen"},{"bookName":"Exo"}]',
      );

      final summary = await service.getBackupContentSummary();

      expect(summary.notesCount, 3);
    });

    test('returns an empty summary if a stored value is corrupt JSON',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prayers', 'not-valid-json');

      final summary = await service.getBackupContentSummary();

      // Corrupt JSON throws inside the try/catch — service returns the
      // all-zero fallback rather than crashing the caller.
      expect(summary.isEmpty, isTrue);
    });
  });

  group('getEstimatedBackupSize', () {
    test('returns 0 when all backup options are disabled', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'google_drive_backup_options',
        '{"spiritual_stats":false,"favorite_devotionals":false,'
            '"saved_prayers":false,"saved_thanksgivings":false,'
            '"devotional_notes":false,"bible_notes":false,'
            '"completed_encounters":false,"discovery_progress":false,'
            '"discovery_favorites":false,"testimonies":false,'
            '"preferred_bible_version":false,"marked_bible_verses":false}',
      );

      final size = await service.getEstimatedBackupSize(null);

      expect(size, 0);
    });

    test('includes fixed-size sections when enabled (default options)',
        () async {
      final size = await service.getEstimatedBackupSize(null);

      // Defaults enable spiritualStats(5KB) + savedPrayers(15KB) +
      // savedThanksgivings(15KB) + testimonies(10KB) = 45KB.
      // favoriteDevotionals contributes 0 because provider is null.
      expect(size, 45 * 1024);
    });
  });

  // restoreBibleNotes is covered by
  // google_drive_backup_service_restore_bible_notes_test.dart — not
  // duplicated here.

  group('checkForExistingBackup / restoreExistingBackup — no Drive access', () {
    test('checkForExistingBackup returns null when Drive API unavailable',
        () async {
      when(() => authService.getDriveApi()).thenAnswer((_) async => null);

      final result = await service.checkForExistingBackup();

      expect(result, isNull);
    });

    test('restoreExistingBackup returns false when Drive API unavailable',
        () async {
      when(() => authService.getDriveApi()).thenAnswer((_) async => null);

      final result = await service.restoreExistingBackup('some-file-id');

      expect(result, isFalse);
    });
  });

  group('isAuthenticated / signIn / signOut / getUserEmail — passthrough', () {
    test('isAuthenticated reflects auth service state', () async {
      when(() => authService.isSignedIn()).thenAnswer((_) async => true);
      expect(await service.isAuthenticated(), isTrue);

      when(() => authService.isSignedIn()).thenAnswer((_) async => false);
      expect(await service.isAuthenticated(), isFalse);
    });

    test('signOut clears the cached backup folder id', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('google_drive_backup_folder_id', 'cached-folder');
      when(() => authService.signOut()).thenAnswer((_) async {});

      await service.signOut();

      expect(prefs.getString('google_drive_backup_folder_id'), isNull);
      verify(() => authService.signOut()).called(1);
    });

    test('getUserEmail passes through the auth service value', () async {
      when(
        () => authService.getUserEmail(),
      ).thenAnswer((_) async => 'user@example.com');

      expect(await service.getUserEmail(), 'user@example.com');
    });
  });

  group('backup options round-trip', () {
    test('setBackupOptions persists and getBackupOptions reads it back',
        () async {
      final options = {
        BackupKeys.spiritualStats: false,
        BackupKeys.favoriteDevotionals: true,
        BackupKeys.savedPrayers: false,
        BackupKeys.savedThanksgivings: false,
        BackupKeys.devotionalNotes: false,
        BackupKeys.bibleNotes: false,
        BackupKeys.completedEncounters: false,
        BackupKeys.discoveryProgress: false,
        BackupKeys.discoveryFavorites: false,
        BackupKeys.testimonies: false,
        BackupKeys.preferredBibleVersion: false,
        BackupKeys.markedBibleVerses: false,
      };

      await service.setBackupOptions(options);
      final result = await service.getBackupOptions();

      expect(result[BackupKeys.spiritualStats], isFalse);
      expect(result[BackupKeys.favoriteDevotionals], isTrue);
    });

    test('getBackupOptions defaults to all-enabled when nothing stored',
        () async {
      final result = await service.getBackupOptions();

      expect(result.values.every((v) => v == true), isTrue);
    });
  });
}
