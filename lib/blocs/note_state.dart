import 'package:devocional_nuevo/models/devotional_note.dart';

abstract class NoteState {}

class NoteInitial extends NoteState {}

class NoteLoading extends NoteState {}

class NoteLoaded extends NoteState {
  final List<DevotionalNote> notes;

  NoteLoaded({required List<DevotionalNote> notes})
      : notes = List.unmodifiable(notes);

  String? getNoteForDevocional(String devocionalId) {
    if (devocionalId.isEmpty) return null;
    for (final note in notes) {
      if (note.devocionalId == devocionalId) return note.text;
    }
    return null;
  }
}

class NoteError extends NoteState {
  final String message;

  NoteError(this.message);
}
