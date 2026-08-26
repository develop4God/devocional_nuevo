@Tags(['unit', 'services', 'backup'])
library;

// test/unit/services/google_drive_backup_service_drive_io_test.dart
//
// Covers GoogleDriveBackupService paths that need a real drive.DriveApi —
// the gap google_drive_backup_service_test.dart documents and leaves out.
// Uses DriveApiStub (test/helpers/drive_api_test_helper.dart) to back a
// real DriveApi with http.MockClient, so no production code changes were
// needed: DriveApi already takes an http.Client in its constructor.

import 'dart:convert';

import 'package:devocional_nuevo/services/backup/google_drive_backup_service.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:devocional_nuevo/utils/constants/backup_keys_constants.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/drive_api_test_helper.dart';
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
    PackageInfo.setMockInitialValues(
      appName: 'Devocional',
      packageName: 'com.example.devocional',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

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

  group('checkForExistingBackup — with a real DriveApi', () {
    test('returns backup details when folder and file both exist', () async {
      final stub = DriveApiStub()
        ..onList(
          const DriveApiResponse.json({
            'files': [
              {'id': 'folder-1', 'name': 'app.title'},
            ],
          }),
        );
      when(() => authService.getDriveApi())
          .thenAnswer((_) async => stub.build());

      final result = await service.checkForExistingBackup();

      expect(result, isNotNull);
      expect(result!['found'], isTrue);
      expect(result['folderId'], 'folder-1');
    });

    test('returns null when no backup folder exists', () async {
      final stub = DriveApiStub()..onList(const DriveApiResponse.json({}));
      when(() => authService.getDriveApi())
          .thenAnswer((_) async => stub.build());

      final result = await service.checkForExistingBackup();

      expect(result, isNull);
    });
  });

  group('restoreExistingBackup — with a real DriveApi', () {
    test('restores stats from a valid uncompressed backup file', () async {
      final backupJson = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
        'spiritual_stats': {'streak': 5},
      };
      final stub = DriveApiStub()
        ..onGetMedia(
          DriveApiResponse.media(utf8.encode(json.encode(backupJson))),
        );
      when(() => authService.getDriveApi())
          .thenAnswer((_) async => stub.build());
      when(() => statsService.restoreStats(any())).thenAnswer((_) async {});
      when(() => settingsService.setLastBackupTime(any()))
          .thenAnswer((_) async {});

      final result = await service.restoreExistingBackup('file-1');

      expect(result, isTrue);
      verify(() => statsService.restoreStats({'streak': 5})).called(1);
    });

    test('returns false when the downloaded file is not valid backup data',
        () async {
      final stub = DriveApiStub()
        ..onGetMedia(
          DriveApiResponse.media(utf8.encode('not a backup at all')),
        );
      when(() => authService.getDriveApi())
          .thenAnswer((_) async => stub.build());

      final result = await service.restoreExistingBackup('file-1');

      expect(result, isFalse);
    });
  });

  group('createBackup — happy path with a real DriveApi', () {
    test('creates a new backup file when none exists yet', () async {
      when(() => authService.isSignedIn()).thenAnswer((_) async => true);
      when(() => settingsService.isWifiOnlyEnabled())
          .thenAnswer((_) async => false);
      when(() => connectivityService.shouldProceedWithBackup(false))
          .thenAnswer((_) async => true);
      when(() => settingsService.isCompressionEnabled())
          .thenAnswer((_) async => false);
      when(() => statsService.getAllStats())
          .thenAnswer((_) async => {'stats': <String, dynamic>{}});
      when(() => settingsService.setLastBackupTime(any()))
          .thenAnswer((_) async {});

      final stub = DriveApiStub()
        ..onList(const DriveApiResponse.json({'files': []}))
        ..onCreate(const DriveApiResponse.json({'id': 'created-id'}));
      when(() => authService.getDriveApi())
          .thenAnswer((_) async => stub.build());

      final result = await service.createBackup(null);

      expect(result, isTrue);
      verify(() => settingsService.setLastBackupTime(any())).called(1);
      // One POST creates the backup folder, one POST creates the backup
      // file — both routed through onCreate.
      final creates = stub.requests.where((r) => r.method == 'POST').toList();
      expect(creates, hasLength(2));
    });

    test('reuses a cached backup folder id instead of searching/creating one',
        () async {
      SharedPreferences.setMockInitialValues({
        'google_drive_backup_folder_id': 'cached-folder-id',
      });
      when(() => authService.isSignedIn()).thenAnswer((_) async => true);
      when(() => settingsService.isWifiOnlyEnabled())
          .thenAnswer((_) async => false);
      when(() => connectivityService.shouldProceedWithBackup(false))
          .thenAnswer((_) async => true);
      when(() => settingsService.isCompressionEnabled())
          .thenAnswer((_) async => false);
      when(() => statsService.getAllStats())
          .thenAnswer((_) async => {'stats': <String, dynamic>{}});
      when(() => settingsService.setLastBackupTime(any()))
          .thenAnswer((_) async {});

      final stub = DriveApiStub()
        // The cached-folder-id check does files.get(cachedFolderId) — a
        // metadata GET, not the list search. Returning it successfully is
        // what makes _getOrCreateBackupFolder short-circuit to the cache.
        ..onGetMetadata(
          const DriveApiResponse.json({
            'id': 'cached-folder-id',
            'name': 'app.title',
          }),
        )
        ..onList(const DriveApiResponse.json({'files': []}))
        ..onCreate(const DriveApiResponse.json({'id': 'new-backup-file-id'}));
      when(() => authService.getDriveApi())
          .thenAnswer((_) async => stub.build());

      final result = await service.createBackup(null);

      expect(result, isTrue);
      // The cached folder id is verified via files.get (a single-file GET,
      // not the list search) — proof _getOrCreateBackupFolder short-
      // circuited to the cache instead of running the folder-search query.
      final metadataGets = stub.requests
          .where((r) => r.method == 'GET' && !r.url.path.endsWith('/files'))
          .toList();
      expect(metadataGets, hasLength(1));
      expect(metadataGets.single.url.path, endsWith('/cached-folder-id'));
      // Only the backup file is created — no folder-create POST, since the
      // cache hit skipped folder creation entirely.
      final creates = stub.requests.where((r) => r.method == 'POST').toList();
      expect(creates, hasLength(1));
    });
  });

  group('_restoreBackupData resilience — one bad field does not block others',
      () {
    test(
        'a malformed spiritual_stats field is skipped but saved_prayers still restores',
        () async {
      final backupJson = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
        // Wrong type on purpose: restoreExistingBackup casts this to
        // Map<String, dynamic>, so a List here throws inside the
        // spiritual_stats try/catch — restoration should continue past it.
        'spiritual_stats': [1, 2, 3],
        'saved_prayers': [
          {'id': '1'},
        ],
      };
      final stub = DriveApiStub()
        ..onGetMedia(
          DriveApiResponse.media(utf8.encode(json.encode(backupJson))),
        );
      when(() => authService.getDriveApi())
          .thenAnswer((_) async => stub.build());
      when(() => settingsService.setLastBackupTime(any()))
          .thenAnswer((_) async {});

      final result = await service.restoreExistingBackup('file-1');

      expect(result, isTrue);
      verifyNever(() => statsService.restoreStats(any()));
      final prefs = await SharedPreferences.getInstance();
      final storedPrayers = prefs.getString('prayers');
      expect(storedPrayers, isNotNull);
      expect(json.decode(storedPrayers!), hasLength(1));
    });

    test('restores every remaining field from a full backup payload', () async {
      final backupJson = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
        'saved_thanksgivings': [
          {'id': 't1'},
        ],
        'devotional_notes': [
          {'devocionalId': 'd1'},
        ],
        'testimonies': [
          {'id': 'tm1'},
        ],
        'completed_encounters': ['enc1', 'enc2'],
        'discovery_progress': {
          '${DiscoveryProgressTracker.progressKeyPrefix}study1':
              '{"progress":50}',
        },
        'discovery_favorites': {
          'discovery_favorite_ids_es': '["study1"]',
        },
        'preferred_bible_version': 'NVI',
        'marked_bible_verses': ['Gen 1:1', 'Jn 3:16'],
        'favorite_devotionals': ['fav1', 'fav2'],
      };
      final stub = DriveApiStub()
        ..onGetMedia(
          DriveApiResponse.media(utf8.encode(json.encode(backupJson))),
        );
      when(() => authService.getDriveApi())
          .thenAnswer((_) async => stub.build());
      when(() => settingsService.setLastBackupTime(any()))
          .thenAnswer((_) async {});

      final result = await service.restoreExistingBackup('file-1');

      expect(result, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(json.decode(prefs.getString('thanksgivings')!), hasLength(1));
      expect(
        json.decode(prefs.getString(BackupKeys.devotionalNotes)!),
        hasLength(1),
      );
      expect(json.decode(prefs.getString('testimonies')!), hasLength(1));
      expect(
        prefs.getStringList('encounter_completed_ids'),
        ['enc1', 'enc2'],
      );
      expect(
        prefs.getString(
          '${DiscoveryProgressTracker.progressKeyPrefix}study1',
        ),
        '{"progress":50}',
      );
      expect(
        prefs.getString('discovery_favorite_ids_es'),
        '["study1"]',
      );
      expect(prefs.getString('selectedVersion'), 'NVI');
      expect(
        prefs.getStringList('bible_marked_verses')!.toSet(),
        {'Gen 1:1', 'Jn 3:16'},
      );
      expect(json.decode(prefs.getString('favorite_ids')!), ['fav1', 'fav2']);
    });
  });

  group('createBackup — full payload with a real DriveApi', () {
    test('includes every remaining field when its option is enabled', () async {
      when(() => authService.isSignedIn()).thenAnswer((_) async => true);
      when(() => settingsService.isWifiOnlyEnabled())
          .thenAnswer((_) async => false);
      when(() => connectivityService.shouldProceedWithBackup(false))
          .thenAnswer((_) async => true);
      when(() => settingsService.isCompressionEnabled())
          .thenAnswer((_) async => false);
      when(() => statsService.getAllStats())
          .thenAnswer((_) async => {'stats': <String, dynamic>{}});
      when(() => settingsService.setLastBackupTime(any()))
          .thenAnswer((_) async {});

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prayers', '[{"id":"p1"}]');
      await prefs.setString('thanksgivings', '[{"id":"t1"}]');
      await prefs.setString(BackupKeys.devotionalNotes, '[{"id":"n1"}]');
      await prefs.setString(BackupKeys.bibleNotes, '[{"id":"bn1"}]');
      await prefs.setString('testimonies', '[{"id":"tm1"}]');
      await prefs.setStringList('encounter_completed_ids', ['enc1']);
      await prefs.setString(
        '${DiscoveryProgressTracker.progressKeyPrefix}study1',
        '{"progress":50}',
      );
      await prefs.setString('discovery_favorite_ids_es', '["study1"]');
      await prefs.setString('selectedVersion', 'NVI');
      await prefs.setStringList('bible_marked_verses', ['Gen 1:1']);

      final stub = DriveApiStub()
        ..onList(const DriveApiResponse.json({'files': []}))
        ..onCreate(const DriveApiResponse.json({'id': 'created-id'}));
      when(() => authService.getDriveApi())
          .thenAnswer((_) async => stub.build());

      final result = await service.createBackup(null);

      expect(result, isTrue);
      // The backup file content is uploaded as a multipart/related request
      // whose media part is base64-encoded (see MultipartMediaUploader) —
      // decode it back to the original JSON payload to assert on it.
      const marker = 'Content-Transfer-Encoding: base64\r\n\r\n';
      final uploaded = stub.requests.firstWhere((r) => r.body.contains(marker));
      final base64Start = uploaded.body.indexOf(marker) + marker.length;
      final base64End = uploaded.body.indexOf('\r\n--', base64Start);
      final decoded = utf8.decode(
        base64.decode(uploaded.body.substring(base64Start, base64End)),
      );

      expect(decoded, contains('"id":"p1"'));
      expect(decoded, contains('"id":"t1"'));
      expect(decoded, contains('"id":"n1"'));
      expect(decoded, contains('"id":"bn1"'));
      expect(decoded, contains('"id":"tm1"'));
      expect(decoded, contains('enc1'));
      expect(decoded, contains('study1'));
      expect(decoded, contains('NVI'));
      expect(decoded, contains('Gen 1:1'));
    });
  });
}
