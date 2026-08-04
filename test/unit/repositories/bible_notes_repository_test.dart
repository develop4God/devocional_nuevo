@Tags(['unit', 'repositories', 'notes'])
library;

import 'dart:convert';

import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:devocional_nuevo/repositories/bible_notes_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BibleNotesRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = BibleNotesRepository(
      prefsFactory: SharedPreferences.getInstance,
    );
  });

  test('saves, loads, and deletes a Bible note', () async {
    final note = BibleNote(
      bookName: 'Juan',
      chapter: 3,
      startVerse: 16,
      endVerse: 16,
      text: 'A personal reflection',
      lastModifiedDate: DateTime(2026, 7, 29),
    );

    await repository.saveNote(note);

    expect(await repository.loadNotes(), [note]);

    await repository.deleteNote(note.id);

    expect(await repository.loadNotes(), isEmpty);
  });

  test('saving a note with the same range replaces it', () async {
    await repository.saveNote(
      BibleNote(
        bookName: 'Juan',
        chapter: 3,
        startVerse: 16,
        endVerse: 16,
        text: 'Original',
        lastModifiedDate: DateTime(2026, 7, 28),
      ),
    );
    final replacement = BibleNote(
      bookName: 'Juan',
      chapter: 3,
      startVerse: 16,
      endVerse: 16,
      text: 'Updated',
      lastModifiedDate: DateTime(2026, 7, 29),
    );

    await repository.saveNote(replacement);

    expect(await repository.loadNotes(), [replacement]);
  });

  test('serializes concurrent saves and deletes without losing writes',
      () async {
    await repository.saveNote(
      BibleNote(
        bookName: 'DeleteMe',
        chapter: 1,
        startVerse: 1,
        endVerse: 1,
        text: 'Existing note',
        lastModifiedDate: DateTime(2026, 7, 29),
      ),
    );

    final saves = List.generate(
      10,
      (index) => repository.saveNote(
        BibleNote(
          bookName: 'Juan',
          chapter: 3,
          startVerse: index,
          endVerse: index,
          text: 'Note $index',
          lastModifiedDate: DateTime(2026, 7, 29, 0, 0, index),
        ),
      ),
    );

    await Future.wait([
      ...saves,
      repository.deleteNote('DeleteMe|1|1-1'),
    ]);

    final notes = await repository.loadNotes();
    expect(notes, hasLength(10));
    expect(
      {for (final note in notes) note.startVerse: note.text},
      {for (var index = 0; index < 10; index++) index: 'Note $index'},
    );
    expect(notes.any((note) => note.bookName == 'DeleteMe'), isFalse);
  });

  test('returns no notes when stored JSON is malformed', () async {
    SharedPreferences.setMockInitialValues({
      'bible_notes': '{not valid JSON',
    });

    expect(await repository.loadNotes(), isEmpty);
  });

  test('returns no notes when stored JSON has an invalid field value',
      () async {
    SharedPreferences.setMockInitialValues({
      'bible_notes': json.encode([
        {
          'bookName': 'Juan',
          'chapter': 3,
          'startVerse': 16,
          'endVerse': 16,
          'text': 'Invalid date',
          'lastModifiedDate': 'not-a-date',
        },
      ]),
    });

    expect(await repository.loadNotes(), isEmpty);
  });

  test('propagates preference access failures', () async {
    final failingRepository = BibleNotesRepository(
      prefsFactory: () async => throw StateError('Preferences unavailable'),
    );

    await expectLater(failingRepository.loadNotes(), throwsStateError);
  });
}
