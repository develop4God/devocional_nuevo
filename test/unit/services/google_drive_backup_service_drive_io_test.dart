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
import 'package:mockito/mockito.dart' as mockito;
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/bloc_test_helper.dart' show createMockDevocionalProvider;
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

    test('includes favorite devotionals from the provider when given one',
        () async {
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

      final provider = createMockDevocionalProvider();
      mockito.when(provider.favoriteIds).thenReturn({'fav-a', 'fav-b'});

      final stub = DriveApiStub()
        ..onList(const DriveApiResponse.json({'files': []}))
        ..onCreate(const DriveApiResponse.json({'id': 'created-id'}));
      when(() => authService.getDriveApi())
          .thenAnswer((_) async => stub.build());

      final result = await service.createBackup(provider);

      expect(result, isTrue);
      const marker = 'Content-Transfer-Encoding: base64\r\n\r\n';
      final uploaded = stub.requests.firstWhere((r) => r.body.contains(marker));
      final base64Start = uploaded.body.indexOf(marker) + marker.length;
      final base64End = uploaded.body.indexOf('\r\n--', base64Start);
      final decoded = utf8.decode(
        base64.decode(uploaded.body.substring(base64Start, base64End)),
      );

      expect(decoded, contains('fav-a'));
      expect(decoded, contains('fav-b'));
    });
  });

  group('createBackup — merges local and remote payloads (_mergePayloads)', () {
    test(
        'merges every field: union for lists/maps, newer-wins for id-keyed items',
        () async {
      when(() => authService.isSignedIn()).thenAnswer((_) async => true);
      when(() => settingsService.isWifiOnlyEnabled())
          .thenAnswer((_) async => false);
      when(() => connectivityService.shouldProceedWithBackup(false))
          .thenAnswer((_) async => true);
      when(() => settingsService.isCompressionEnabled())
          .thenAnswer((_) async => false);
      when(() => statsService.getAllStats()).thenAnswer(
        (_) async => {
          'stats': {
            'readDevocionalIds': ['local-id']
          },
        },
      );
      when(() => settingsService.setLastBackupTime(any()))
          .thenAnswer((_) async {});

      // Local state: one prayer (older edit), one devotional note, one
      // bible note, one testimony, plus a thanksgiving/encounter unique to
      // local — each id-keyed field also has a shared id with an older
      // lastModifiedDate than its remote counterpart.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('google_drive_backup_folder_id', 'folder-1');
      await prefs.setString(
        'prayers',
        json.encode([
          {
            'id': 'shared-1',
            'text': 'local version',
            'lastModifiedDate': '2020-01-01T00:00:00.000Z',
          },
        ]),
      );
      await prefs.setString('thanksgivings', json.encode([]));
      await prefs.setString(
        'devotional_notes',
        json.encode([
          {
            'devocionalId': 'dn-shared',
            'text': 'local note',
            'lastModifiedDate': '2020-01-01T00:00:00.000Z',
          },
        ]),
      );
      await prefs.setString(
        'bible_notes',
        json.encode([
          {
            'bookName': 'Gen',
            'chapter': 1,
            'startVerse': 1,
            'endVerse': 1,
            'text': 'local bible note',
            'lastModifiedDate': '2020-01-01T00:00:00.000Z',
          },
        ]),
      );
      await prefs.setString(
        'testimonies',
        json.encode([
          {
            'id': 'tm-shared',
            'text': 'local testimony',
            'lastModifiedDate': '2020-01-01T00:00:00.000Z',
          },
        ]),
      );
      await prefs.setStringList('encounter_completed_ids', ['local-enc']);

      // Remote payload (what's already on Drive): the SAME ids but NEWER
      // edits — merge must keep these, not the local ones — plus items
      // unique to remote. Union fields (encounters, stats IDs) must
      // contain both sides.
      final remotePayload = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
        'spiritual_stats': {
          'readDevocionalIds': ['remote-id'],
        },
        'saved_prayers': [
          {
            'id': 'shared-1',
            'text': 'remote version (newer)',
            'lastModifiedDate': '2025-06-01T00:00:00.000Z',
          },
        ],
        'saved_thanksgivings': [
          {'id': 'remote-only', 'text': 'remote thanksgiving'},
        ],
        'devotional_notes': [
          {
            'devocionalId': 'dn-shared',
            'text': 'remote note (newer)',
            'lastModifiedDate': '2025-06-01T00:00:00.000Z',
          },
        ],
        'bible_notes': [
          {
            'bookName': 'Gen',
            'chapter': 1,
            'startVerse': 1,
            'endVerse': 1,
            'text': 'remote bible note (newer)',
            'lastModifiedDate': '2025-06-01T00:00:00.000Z',
          },
        ],
        'testimonies': [
          {
            'id': 'tm-shared',
            'text': 'remote testimony (newer)',
            'lastModifiedDate': '2025-06-01T00:00:00.000Z',
          },
        ],
        'completed_encounters': ['remote-enc'],
      };

      final stub = DriveApiStub()
        ..onGetMetadata(
          const DriveApiResponse.json({'id': 'folder-1', 'name': 'app'}),
        )
        ..onList(
          const DriveApiResponse.json({
            'files': [
              {'id': 'remote-backup-file', 'name': 'backup.json'},
            ],
          }),
        )
        ..onGetMedia(
          DriveApiResponse.media(utf8.encode(json.encode(remotePayload))),
        )
        ..onUpdate(const DriveApiResponse.json({'id': 'remote-backup-file'}));
      when(() => authService.getDriveApi())
          .thenAnswer((_) async => stub.build());

      final result = await service.createBackup(null);

      expect(result, isTrue);
      const marker = 'Content-Transfer-Encoding: base64\r\n\r\n';
      final uploaded = stub.requests.firstWhere((r) => r.body.contains(marker));
      final base64Start = uploaded.body.indexOf(marker) + marker.length;
      final base64End = uploaded.body.indexOf('\r\n--', base64Start);
      final merged = json.decode(
        utf8.decode(
          base64.decode(uploaded.body.substring(base64Start, base64End)),
        ),
      ) as Map<String, dynamic>;

      // Newer-wins: the remote edit of the shared prayer id survives, not
      // the older local one.
      final prayers = merged['saved_prayers'] as List<dynamic>;
      expect(prayers, hasLength(1));
      expect((prayers.single as Map)['text'], 'remote version (newer)');

      // Union: thanksgiving unique to remote is present even though it
      // wasn't in the local payload.
      final thanksgivings = merged['saved_thanksgivings'] as List<dynamic>;
      expect(
        thanksgivings.map((t) => (t as Map)['id']),
        contains('remote-only'),
      );

      // Union: completed encounters combine both sides.
      expect(
        (merged['completed_encounters'] as List<dynamic>).toSet(),
        {'local-enc', 'remote-enc'},
      );

      // Newer-wins for devotional notes (keyed by devocionalId), bible
      // notes (keyed by book/chapter/verse range), and testimonies.
      final notes = merged['devotional_notes'] as List<dynamic>;
      expect(notes, hasLength(1));
      expect((notes.single as Map)['text'], 'remote note (newer)');

      final bibleNotes = merged['bible_notes'] as List<dynamic>;
      expect(bibleNotes, hasLength(1));
      expect((bibleNotes.single as Map)['text'], 'remote bible note (newer)');

      final testimonies = merged['testimonies'] as List<dynamic>;
      expect(testimonies, hasLength(1));
      expect((testimonies.single as Map)['text'], 'remote testimony (newer)');

      // Union for spiritual-stats read-devocional IDs.
      final mergedStats = merged['spiritual_stats'] as Map<String, dynamic>;
      expect(
        (mergedStats['readDevocionalIds'] as List<dynamic>).toSet(),
        {'local-id', 'remote-id'},
      );

      expect(merged['merge_source'], 'multi_device');
    });
  });

  group('migrateReadDatesBackupIfNeeded', () {
    test('skips entirely when already migrated', () async {
      SharedPreferences.setMockInitialValues({
        'read_dates_backup_migrated': true,
      });

      await service.migrateReadDatesBackupIfNeeded();

      // No Drive call was made at all — proof it returned before touching
      // auth/Drive.
      verifyNever(() => authService.getDriveApi());
    });

    test('marks migrated without uploading when there is no remote backup',
        () async {
      final stub = DriveApiStub()..onList(const DriveApiResponse.json({}));
      when(() => authService.getDriveApi())
          .thenAnswer((_) async => stub.build());

      await service.migrateReadDatesBackupIfNeeded();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('read_dates_backup_migrated'), isTrue);
      // Only the folder-search GET happened — no upload (POST/PATCH).
      final writes = stub.requests.where((r) => r.method != 'GET').toList();
      expect(writes, isEmpty);
    });

    test(
        'merges local read_dates into the stale remote backup while '
        'preserving every other remote field', () async {
      // Reproduces the bug fixed in 210a88d6: this remote payload predates
      // that fix and has no read_dates at all. The migration must add
      // read_dates without disturbing preferred_bible_version or any other
      // remote-only field (see issue on _mergePayloads field-parity gap).
      when(() => statsService.getAllStats()).thenAnswer(
        (_) async => {
          'stats': <String, dynamic>{},
          'read_dates': ['2026-08-01', '2026-08-02'],
        },
      );

      final remotePayload = {
        'timestamp': '2026-01-01T00:00:00.000Z',
        'version': '1.0',
        'app_version': '0.9.0',
        'preferred_bible_version': 'RVR1960',
        'marked_bible_verses': ['Gen 1:1'],
        'saved_prayers': [
          {'id': 'p1', 'text': 'remote prayer'},
        ],
        // No read_dates key at all — the pre-fix bug.
      };

      final stub = DriveApiStub()
        ..onGetMetadata(
          const DriveApiResponse.json({'id': 'folder-1', 'name': 'app'}),
        )
        ..onList(
          const DriveApiResponse.json({
            'files': [
              {'id': 'remote-backup-file', 'name': 'backup.json'},
            ],
          }),
        )
        ..onGetMedia(
          DriveApiResponse.media(utf8.encode(json.encode(remotePayload))),
        )
        ..onUpdate(const DriveApiResponse.json({'id': 'remote-backup-file'}));
      when(() => authService.getDriveApi())
          .thenAnswer((_) async => stub.build());
      when(() => settingsService.isCompressionEnabled())
          .thenAnswer((_) async => false);

      final prefsSetup = await SharedPreferences.getInstance();
      await prefsSetup.setString(
        'google_drive_backup_folder_id',
        'folder-1',
      );

      await service.migrateReadDatesBackupIfNeeded();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('read_dates_backup_migrated'), isTrue);

      const marker = 'Content-Transfer-Encoding: base64\r\n\r\n';
      final uploaded = stub.requests.firstWhere((r) => r.body.contains(marker));
      final base64Start = uploaded.body.indexOf(marker) + marker.length;
      final base64End = uploaded.body.indexOf('\r\n--', base64Start);
      final merged = json.decode(
        utf8.decode(
          base64.decode(uploaded.body.substring(base64Start, base64End)),
        ),
      ) as Map<String, dynamic>;

      // The bug this migration fixes: read_dates now present.
      expect(
        (merged['read_dates'] as List<dynamic>).toSet(),
        {'2026-08-01', '2026-08-02'},
      );
      // Every other remote-only field survives the merge untouched.
      expect(merged['preferred_bible_version'], 'RVR1960');
      expect(merged['marked_bible_verses'], ['Gen 1:1']);
      expect(
        (merged['saved_prayers'] as List<dynamic>).single['id'],
        'p1',
      );
    });

    test('leaves the flag unset when the upload fails, so it retries later',
        () async {
      when(() => statsService.getAllStats()).thenAnswer(
        (_) async => {'stats': <String, dynamic>{}, 'read_dates': []},
      );

      final remotePayload = {
        'timestamp': '2026-01-01T00:00:00.000Z',
        'version': '1.0',
      };

      final stub = DriveApiStub()
        ..onGetMetadata(
          const DriveApiResponse.json({'id': 'folder-1', 'name': 'app'}),
        )
        ..onList(
          const DriveApiResponse.json({
            'files': [
              {'id': 'remote-backup-file', 'name': 'backup.json'},
            ],
          }),
        )
        ..onGetMedia(
          DriveApiResponse.media(utf8.encode(json.encode(remotePayload))),
        )
        ..onUpdate(
          const DriveApiResponse.json({'error': 'server error'},
              statusCode: 500),
        );
      when(() => authService.getDriveApi())
          .thenAnswer((_) async => stub.build());
      when(() => settingsService.isCompressionEnabled())
          .thenAnswer((_) async => false);

      final prefsSetup = await SharedPreferences.getInstance();
      await prefsSetup.setString(
        'google_drive_backup_folder_id',
        'folder-1',
      );

      await service.migrateReadDatesBackupIfNeeded();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('read_dates_backup_migrated'), isNot(true));
    });
  });
}
