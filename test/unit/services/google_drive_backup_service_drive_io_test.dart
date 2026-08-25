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
  });
}
