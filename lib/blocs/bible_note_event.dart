abstract class BibleNoteEvent {}

/// Loads every Bible verse note from persistence.
class LoadBibleNotes extends BibleNoteEvent {}

/// Creates, updates, or deletes the note for a verse range. A null or blank
/// [text] deletes it.
class SaveBibleNoteForRange extends BibleNoteEvent {
  final String bookName;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final String? text;

  SaveBibleNoteForRange({
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.text,
  });
}

/// Refreshes the in-memory Bible notes after an external data restore.
class RefreshBibleNotes extends BibleNoteEvent {}
