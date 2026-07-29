import 'package:devocional_nuevo/blocs/note_event.dart';
import 'package:devocional_nuevo/blocs/note_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devotional_note.dart';
import 'package:devocional_nuevo/repositories/i_notes_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final INotesRepository _notesRepository;

  NoteBloc({required INotesRepository notesRepository})
      : _notesRepository = notesRepository,
        super(NoteInitial()) {
    on<LoadNotes>(_onLoadNotes);
    on<SaveNoteForDevocional>(_onSaveNoteForDevocional);
    on<RefreshNotes>(_onRefreshNotes);
  }

  Future<void> _onLoadNotes(
    LoadNotes event,
    Emitter<NoteState> emit,
  ) async {
    emit(NoteLoading());
    await _loadNotes(emit);
  }

  Future<void> _onRefreshNotes(
    RefreshNotes event,
    Emitter<NoteState> emit,
  ) {
    return _loadNotes(emit);
  }

  Future<void> _loadNotes(Emitter<NoteState> emit) async {
    try {
      emit(NoteLoaded(notes: await _notesRepository.loadNotes()));
    } catch (_) {
      emit(NoteError('notes.loading_error'.tr()));
    }
  }

  Future<void> _onSaveNoteForDevocional(
    SaveNoteForDevocional event,
    Emitter<NoteState> emit,
  ) async {
    if (event.devocionalId.isEmpty) return;

    try {
      final text = event.text?.trim();
      if (text == null || text.isEmpty) {
        await _notesRepository.deleteNote(event.devocionalId);
      } else {
        await _notesRepository.saveNote(
          DevotionalNote(
            devocionalId: event.devocionalId,
            text: text,
            lastModifiedDate: DateTime.now(),
          ),
        );
      }
      emit(NoteLoaded(notes: await _notesRepository.loadNotes()));
    } catch (_) {
      emit(NoteError('notes.save_error'.tr()));
    }
  }
}
