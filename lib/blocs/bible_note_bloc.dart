import 'package:devocional_nuevo/blocs/bible_note_event.dart';
import 'package:devocional_nuevo/blocs/bible_note_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:devocional_nuevo/repositories/i_bible_notes_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BibleNoteBloc extends Bloc<BibleNoteEvent, BibleNoteState> {
  final IBibleNotesRepository _bibleNotesRepository;

  BibleNoteBloc({required IBibleNotesRepository bibleNotesRepository})
      : _bibleNotesRepository = bibleNotesRepository,
        super(BibleNoteInitial()) {
    on<LoadBibleNotes>(_onLoadBibleNotes);
    on<SaveBibleNoteForRange>(_onSaveBibleNoteForRange);
    on<RefreshBibleNotes>(_onRefreshBibleNotes);
  }

  Future<void> _onLoadBibleNotes(
    LoadBibleNotes event,
    Emitter<BibleNoteState> emit,
  ) async {
    emit(BibleNoteLoading());
    await _loadNotes(emit);
  }

  Future<void> _onRefreshBibleNotes(
    RefreshBibleNotes event,
    Emitter<BibleNoteState> emit,
  ) {
    return _loadNotes(emit);
  }

  Future<void> _loadNotes(Emitter<BibleNoteState> emit) async {
    try {
      emit(BibleNoteLoaded(notes: await _bibleNotesRepository.loadNotes()));
    } catch (_) {
      emit(BibleNoteError('notes.loading_error'.tr()));
    }
  }

  Future<void> _onSaveBibleNoteForRange(
    SaveBibleNoteForRange event,
    Emitter<BibleNoteState> emit,
  ) async {
    if (event.bookName.isEmpty) return;

    try {
      final text = event.text?.trim();
      final noteId = BibleNote.idFor(
        event.bookName,
        event.chapter,
        event.startVerse,
        event.endVerse,
      );
      if (text == null || text.isEmpty) {
        await _bibleNotesRepository.deleteNote(noteId);
      } else {
        await _bibleNotesRepository.saveNote(
          BibleNote(
            bookName: event.bookName,
            chapter: event.chapter,
            startVerse: event.startVerse,
            endVerse: event.endVerse,
            text: text,
            lastModifiedDate: DateTime.now(),
          ),
        );
      }
      emit(BibleNoteLoaded(notes: await _bibleNotesRepository.loadNotes()));
    } catch (_) {
      emit(BibleNoteError('notes.save_error'.tr()));
    }
  }
}
