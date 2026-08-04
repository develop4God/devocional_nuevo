@Tags(['unit'])
library;

import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:devocional_nuevo/repositories/i_bible_notes_repository.dart';
import 'package:devocional_nuevo/services/backup/google_drive_backup_service.dart';
import 'package:devocional_nuevo/services/backup/i_backup_settings_service.dart';
import 'package:devocional_nuevo/services/backup/i_google_drive_auth_service.dart';
import 'package:devocional_nuevo/services/i_connectivity_service.dart';
import 'package:devocional_nuevo/services/i_localization_service.dart';
import 'package:devocional_nuevo/services/i_spiritual_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements IGoogleDriveAuthService {}

class _MockConnectivityService extends Mock implements IConnectivityService {}

class _MockStatsService extends Mock implements ISpiritualStatsService {}

class _MockLocalizationService extends Mock implements ILocalizationService {}

class _MockSettingsService extends Mock implements IBackupSettingsService {}

/// Records every call instead of touching real storage, so the test asserts
/// the wiring between GoogleDriveBackupService and the repository directly.
class FakeBibleNotesRepository implements IBibleNotesRepository {
  final List<BibleNote> saved = [];
  final List<String> deleted = [];

  /// When set, [saveNote] throws for a note whose id equals this value —
  /// used to simulate one entry failing to persist.
  String? failSaveForId;

  @override
  Future<List<BibleNote>> loadNotes() async => saved;

  @override
  Future<void> saveNote(BibleNote note) async {
    if (note.id == failSaveForId) {
      throw StateError('simulated persist failure for ${note.id}');
    }
    saved.add(note);
  }

  @override
  Future<void> deleteNote(String noteId) async => deleted.add(noteId);
}

void main() {
  group('GoogleDriveBackupService.restoreBibleNotes', () {
    late FakeBibleNotesRepository fakeRepository;
    late GoogleDriveBackupService service;

    setUp(() {
      fakeRepository = FakeBibleNotesRepository();
      service = GoogleDriveBackupService(
        authService: _MockAuthService(),
        connectivityService: _MockConnectivityService(),
        statsService: _MockStatsService(),
        localizationService: _MockLocalizationService(),
        settingsService: _MockSettingsService(),
        bibleNotesRepository: fakeRepository,
      );
    });

    BibleNote note({
      String bookName = 'Juan',
      int chapter = 3,
      int startVerse = 16,
      int endVerse = 16,
      String text = 'Test note',
    }) {
      return BibleNote(
        bookName: bookName,
        chapter: chapter,
        startVerse: startVerse,
        endVerse: endVerse,
        text: text,
        lastModifiedDate: DateTime(2025, 1, 1),
      );
    }

    test('persists every valid entry through IBibleNotesRepository', () async {
      final rawNotes = [
        note(startVerse: 16, endVerse: 16).toJson(),
        note(startVerse: 17, endVerse: 17).toJson(),
      ];

      final restoredCount = await service.restoreBibleNotes(rawNotes);

      expect(restoredCount, 2);
      expect(fakeRepository.saved, hasLength(2));
      expect(fakeRepository.saved.map((n) => n.startVerse), [16, 17]);
    });

    test('skips a malformed entry and still restores the valid ones', () async {
      final rawNotes = [
        note(startVerse: 16, endVerse: 16).toJson(),
        {'unexpected': 'shape without required fields'},
        note(startVerse: 18, endVerse: 18).toJson(),
      ];

      final restoredCount = await service.restoreBibleNotes(rawNotes);

      // BibleNote.fromJson defaults missing fields rather than throwing, so
      // the malformed map still decodes — assert on what actually persists.
      expect(restoredCount, 3);
      expect(fakeRepository.saved, hasLength(3));
    });

    test('skips an entry that fails to persist and keeps the rest', () async {
      final failing = note(startVerse: 20, endVerse: 20);
      fakeRepository.failSaveForId = failing.id;

      final rawNotes = [
        note(startVerse: 16, endVerse: 16).toJson(),
        failing.toJson(),
        note(startVerse: 21, endVerse: 21).toJson(),
      ];

      final restoredCount = await service.restoreBibleNotes(rawNotes);

      expect(restoredCount, 2);
      expect(fakeRepository.saved.map((n) => n.startVerse), [16, 21]);
    });

    test('restores nothing for an empty list', () async {
      final restoredCount = await service.restoreBibleNotes(const []);

      expect(restoredCount, 0);
      expect(fakeRepository.saved, isEmpty);
    });
  });
}
