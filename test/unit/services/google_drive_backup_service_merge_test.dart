@Tags(['unit', 'services', 'backup'])
library;

// test/unit/services/google_drive_backup_service_merge_test.dart
//
// Covers GoogleDriveBackupService.mergePayloads directly with plain maps —
// no Drive API involved. Focused on two fields that previously had no
// conflict-resolution at all (local always won, silently, on every
// automatic backup): preferredBibleVersion and markedBibleVerses.

import 'package:devocional_nuevo/services/backup/google_drive_backup_service.dart';
import 'package:devocional_nuevo/utils/constants/backup_keys_constants.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/google_drive_backup_mock_helper.dart';

void main() {
  late GoogleDriveBackupService service;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    final authService = MockGoogleDriveAuthService();
    final connectivityService = MockConnectivityService();
    final statsService = MockSpiritualStatsService();
    final localizationService = MockLocalizationService();
    final settingsService = MockBackupSettingsService();
    final bibleNotesRepository = MockBibleNotesRepository();

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

  group('mergePayloads — marked bible verses (union)', () {
    test('keeps verses unique to remote, not just local', () {
      final local = {
        BackupKeys.markedBibleVerses: ['John 3:16'],
      };
      final remote = {
        BackupKeys.markedBibleVerses: ['Psalm 23:1'],
      };

      final merged = service.mergePayloads(local, remote);

      expect(
        merged[BackupKeys.markedBibleVerses],
        containsAll(['John 3:16', 'Psalm 23:1']),
      );
    });

    test('does not duplicate a verse present on both sides', () {
      final local = {
        BackupKeys.markedBibleVerses: ['John 3:16'],
      };
      final remote = {
        BackupKeys.markedBibleVerses: ['John 3:16'],
      };

      final merged = service.mergePayloads(local, remote);

      expect(merged[BackupKeys.markedBibleVerses], equals(['John 3:16']));
    });
  });

  group('mergePayloads — preferred bible version', () {
    test('remote version wins over local when remote is set', () {
      final local = {BackupKeys.preferredBibleVersion: 'KJV'};
      final remote = {BackupKeys.preferredBibleVersion: 'NIV'};

      final merged = service.mergePayloads(local, remote);

      expect(merged[BackupKeys.preferredBibleVersion], equals('NIV'));
    });

    test('falls back to local when remote has no version set', () {
      final local = {BackupKeys.preferredBibleVersion: 'KJV'};
      final remote = {BackupKeys.preferredBibleVersion: ''};

      final merged = service.mergePayloads(local, remote);

      expect(merged[BackupKeys.preferredBibleVersion], equals('KJV'));
    });
  });
}
