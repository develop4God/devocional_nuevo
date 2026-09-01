// test/helpers/google_drive_backup_mock_helper.dart
//
// Shared mocktail mocks for GoogleDriveBackupService's injected
// dependencies. Reused by every test file that constructs a real
// GoogleDriveBackupService instance, so mock setup stays in one place.

import 'package:devocional_nuevo/repositories/i_bible_notes_repository.dart';
import 'package:devocional_nuevo/services/backup/i_backup_settings_service.dart';
import 'package:devocional_nuevo/services/backup/i_google_drive_auth_service.dart';
import 'package:devocional_nuevo/services/i_connectivity_service.dart';
import 'package:devocional_nuevo/services/i_localization_service.dart';
import 'package:devocional_nuevo/services/i_spiritual_stats_service.dart';
import 'package:mocktail/mocktail.dart';

class MockGoogleDriveAuthService extends Mock
    implements IGoogleDriveAuthService {}

class MockConnectivityService extends Mock implements IConnectivityService {}

class MockSpiritualStatsService extends Mock
    implements ISpiritualStatsService {}

class MockLocalizationService extends Mock implements ILocalizationService {}

class MockBackupSettingsService extends Mock
    implements IBackupSettingsService {}

class MockBibleNotesRepository extends Mock implements IBibleNotesRepository {}
