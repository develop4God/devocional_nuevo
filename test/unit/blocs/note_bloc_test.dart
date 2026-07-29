@Tags(['unit', 'blocs', 'notes'])
library;

import 'package:devocional_nuevo/blocs/note_bloc.dart';
import 'package:devocional_nuevo/blocs/note_event.dart';
import 'package:devocional_nuevo/blocs/note_state.dart';
import 'package:devocional_nuevo/models/devotional_note.dart';
import 'package:devocional_nuevo/repositories/i_notes_repository.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNotesRepository implements INotesRepository {
  final Map<String, DevotionalNote> _notes = {};
  bool shouldFail = false;

  @override
  Future<void> deleteNote(String devocionalId) async {
    _throwIfNeeded();
    _notes.remove(devocionalId);
  }

  @override
  Future<List<DevotionalNote>> loadNotes() async {
    _throwIfNeeded();
    return _notes.values.toList();
  }

  @override
  Future<void> saveNote(DevotionalNote note) async {
    _throwIfNeeded();
    _notes[note.devocionalId] = note;
  }

  void _throwIfNeeded() {
    if (shouldFail) throw StateError('Repository failure');
  }
}

void main() {
  group('NoteBloc', () {
    late FakeNotesRepository repository;
    late NoteBloc bloc;

    setUp(() {
      ServiceLocator().reset();
      ServiceLocator().registerSingleton<LocalizationService>(
        LocalizationService(),
      );
      repository = FakeNotesRepository();
      bloc = NoteBloc(notesRepository: repository);
    });

    tearDown(() async {
      await bloc.close();
      ServiceLocator().reset();
    });

    test('loads persisted notes', () async {
      await repository.saveNote(
        DevotionalNote(
          devocionalId: 'devotional-1',
          text: 'Persisted note',
          lastModifiedDate: DateTime(2026, 7, 29),
        ),
      );

      bloc.add(LoadNotes());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<NoteLoading>(),
          isA<NoteLoaded>().having(
            (state) => state.getNoteForDevocional('devotional-1'),
            'persisted note',
            'Persisted note',
          ),
        ]),
      );
    });

    test('refreshes notes from the repository', () async {
      await repository.saveNote(
        DevotionalNote(
          devocionalId: 'devotional-1',
          text: 'Restored note',
          lastModifiedDate: DateTime(2026, 7, 29),
        ),
      );

      bloc.add(RefreshNotes());

      await expectLater(
        bloc.stream,
        emits(
          isA<NoteLoaded>().having(
            (state) => state.getNoteForDevocional('devotional-1'),
            'refreshed note',
            'Restored note',
          ),
        ),
      );
    });

    test('saves a trimmed note and makes it available in state', () async {
      bloc.add(SaveNoteForDevocional('devotional-1', '  My note  '));

      await expectLater(
        bloc.stream,
        emits(
          isA<NoteLoaded>().having(
            (state) => state.getNoteForDevocional('devotional-1'),
            'saved note',
            'My note',
          ),
        ),
      );
    });

    test('deletes a note when text is blank', () async {
      await repository.saveNote(
        DevotionalNote(
          devocionalId: 'devotional-1',
          text: 'Existing note',
          lastModifiedDate: DateTime(2026, 7, 29),
        ),
      );

      bloc.add(SaveNoteForDevocional('devotional-1', '  '));

      await expectLater(
        bloc.stream,
        emits(
          isA<NoteLoaded>().having(
            (state) => state.getNoteForDevocional('devotional-1'),
            'deleted note',
            isNull,
          ),
        ),
      );
    });

    test('emits an error when repository persistence fails', () async {
      repository.shouldFail = true;
      bloc.add(SaveNoteForDevocional('devotional-1', 'My note'));

      await expectLater(
        bloc.stream,
        emits(isA<NoteError>()),
      );
    });
  });
}
