@Tags(['unit', 'repositories', 'notes'])
library;

import 'package:devocional_nuevo/models/devotional_note.dart';
import 'package:devocional_nuevo/repositories/notes_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NotesRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = NotesRepository(
      prefsFactory: SharedPreferences.getInstance,
    );
  });

  test('saves, loads, and deletes a devotional note', () async {
    final note = DevotionalNote(
      devocionalId: 'devotional-1',
      text: 'A personal reflection',
      lastModifiedDate: DateTime(2026, 7, 29),
    );

    await repository.saveNote(note);

    expect(await repository.loadNotes(), [note]);

    await repository.deleteNote(note.devocionalId);

    expect(await repository.loadNotes(), isEmpty);
  });

  test('saving a note with the same devotional ID replaces it', () async {
    await repository.saveNote(
      DevotionalNote(
        devocionalId: 'devotional-1',
        text: 'Original',
        lastModifiedDate: DateTime(2026, 7, 28),
      ),
    );
    final replacement = DevotionalNote(
      devocionalId: 'devotional-1',
      text: 'Updated',
      lastModifiedDate: DateTime(2026, 7, 29),
    );

    await repository.saveNote(replacement);

    expect(await repository.loadNotes(), [replacement]);
  });

  test('serializes concurrent saves and deletes without losing writes',
      () async {
    await repository.saveNote(
      DevotionalNote(
        devocionalId: 'delete-me',
        text: 'Existing note',
        lastModifiedDate: DateTime(2026, 7, 29),
      ),
    );

    final saves = List.generate(
      10,
      (index) => repository.saveNote(
        DevotionalNote(
          devocionalId: 'devotional-$index',
          text: 'Note $index',
          lastModifiedDate: DateTime(2026, 7, 29, 0, 0, index),
        ),
      ),
    );

    await Future.wait([
      ...saves,
      repository.deleteNote('delete-me'),
    ]);

    final notes = await repository.loadNotes();
    expect(notes, hasLength(10));
    expect(
      {for (final note in notes) note.devocionalId: note.text},
      {
        for (var index = 0; index < 10; index++)
          'devotional-$index': 'Note $index',
      },
    );
    expect(notes.any((note) => note.devocionalId == 'delete-me'), isFalse);
  });

  test('returns no notes when stored JSON is malformed', () async {
    SharedPreferences.setMockInitialValues({
      'devotional_notes': '{not valid JSON',
    });

    expect(await repository.loadNotes(), isEmpty);
  });

  test('propagates preference access failures', () async {
    final failingRepository = NotesRepository(
      prefsFactory: () async => throw StateError('Preferences unavailable'),
    );

    await expectLater(failingRepository.loadNotes(), throwsStateError);
  });
}
