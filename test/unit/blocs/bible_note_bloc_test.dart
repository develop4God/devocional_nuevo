@Tags(['unit', 'blocs', 'notes'])
library;

import 'package:devocional_nuevo/blocs/bible_note_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_note_event.dart';
import 'package:devocional_nuevo/blocs/bible_note_state.dart';
import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:devocional_nuevo/repositories/i_bible_notes_repository.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBibleNotesRepository implements IBibleNotesRepository {
  final Map<String, BibleNote> _notes = {};
  bool shouldFail = false;

  @override
  Future<void> deleteNote(String noteId) async {
    _throwIfNeeded();
    _notes.remove(noteId);
  }

  @override
  Future<List<BibleNote>> loadNotes() async {
    _throwIfNeeded();
    return _notes.values.toList();
  }

  @override
  Future<void> saveNote(BibleNote note) async {
    _throwIfNeeded();
    _notes[note.id] = note;
  }

  void _throwIfNeeded() {
    if (shouldFail) throw StateError('Repository failure');
  }
}

void main() {
  group('BibleNoteBloc', () {
    late FakeBibleNotesRepository repository;
    late BibleNoteBloc bloc;

    setUp(() {
      ServiceLocator().reset();
      ServiceLocator().registerSingleton<LocalizationService>(
        LocalizationService(),
      );
      repository = FakeBibleNotesRepository();
      bloc = BibleNoteBloc(bibleNotesRepository: repository);
    });

    tearDown(() async {
      await bloc.close();
      ServiceLocator().reset();
    });

    test('loads persisted notes', () async {
      await repository.saveNote(
        BibleNote(
          bookName: 'Juan',
          chapter: 3,
          startVerse: 16,
          endVerse: 16,
          text: 'Persisted note',
          lastModifiedDate: DateTime(2026, 7, 29),
        ),
      );

      bloc.add(LoadBibleNotes());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<BibleNoteLoading>(),
          isA<BibleNoteLoaded>().having(
            (state) => state.getNoteForVerse('Juan', 3, 16)?.text,
            'persisted note',
            'Persisted note',
          ),
        ]),
      );
    });

    test('refreshes notes from the repository', () async {
      await repository.saveNote(
        BibleNote(
          bookName: 'Juan',
          chapter: 3,
          startVerse: 16,
          endVerse: 16,
          text: 'Restored note',
          lastModifiedDate: DateTime(2026, 7, 29),
        ),
      );

      bloc.add(RefreshBibleNotes());

      await expectLater(
        bloc.stream,
        emits(
          isA<BibleNoteLoaded>().having(
            (state) => state.getNoteForVerse('Juan', 3, 16)?.text,
            'refreshed note',
            'Restored note',
          ),
        ),
      );
    });

    test('saves a trimmed note covering the whole selected range', () async {
      bloc.add(
        SaveBibleNoteForRange(
          bookName: 'Juan',
          chapter: 3,
          startVerse: 16,
          endVerse: 18,
          text: '  My note  ',
        ),
      );

      await expectLater(
        bloc.stream,
        emits(
          isA<BibleNoteLoaded>()
              .having(
                (state) => state.getNoteForVerse('Juan', 3, 16)?.text,
                'note at start verse',
                'My note',
              )
              .having(
                (state) => state.getNoteForVerse('Juan', 3, 18)?.text,
                'note at end verse',
                'My note',
              ),
        ),
      );
    });

    test('deletes a note when text is blank', () async {
      await repository.saveNote(
        BibleNote(
          bookName: 'Juan',
          chapter: 3,
          startVerse: 16,
          endVerse: 16,
          text: 'Existing note',
          lastModifiedDate: DateTime(2026, 7, 29),
        ),
      );

      bloc.add(
        SaveBibleNoteForRange(
          bookName: 'Juan',
          chapter: 3,
          startVerse: 16,
          endVerse: 16,
          text: '  ',
        ),
      );

      await expectLater(
        bloc.stream,
        emits(
          isA<BibleNoteLoaded>().having(
            (state) => state.getNoteForVerse('Juan', 3, 16),
            'deleted note',
            isNull,
          ),
        ),
      );
    });

    test('emits an error when repository persistence fails', () async {
      repository.shouldFail = true;
      bloc.add(
        SaveBibleNoteForRange(
          bookName: 'Juan',
          chapter: 3,
          startVerse: 16,
          endVerse: 16,
          text: 'My note',
        ),
      );

      await expectLater(
        bloc.stream,
        emits(isA<BibleNoteError>()),
      );
    });
  });
}
