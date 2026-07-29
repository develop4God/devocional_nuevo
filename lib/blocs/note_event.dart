abstract class NoteEvent {}

/// Loads every devotional note from persistence.
class LoadNotes extends NoteEvent {}

/// Creates, updates, or deletes a note. A null or blank [text] deletes it.
class SaveNoteForDevocional extends NoteEvent {
  final String devocionalId;
  final String? text;

  SaveNoteForDevocional(this.devocionalId, this.text);
}

/// Refreshes the in-memory notes after an external data restore.
class RefreshNotes extends NoteEvent {}
