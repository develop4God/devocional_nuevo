@Tags(['unit'])
library;

import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:devocional_nuevo/repositories/i_bible_notes_repository.dart';
import 'package:devocional_nuevo/services/backup/google_drive_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/google_drive_backup_mock_helper.dart';

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
        authService: MockGoogleDriveAuthService(),
        connectivityService: MockConnectivityService(),
        statsService: MockSpiritualStatsService(),
        localizationService: MockLocalizationService(),
        settingsService: MockBackupSettingsService(),
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

      expect(restoredCount, 2);
      expect(fakeRepository.saved, hasLength(2));
      expect(fakeRepository.saved.map((n) => n.startVerse), [16, 18]);
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
