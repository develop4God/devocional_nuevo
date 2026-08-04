import 'package:devocional_nuevo/models/bible_note.dart';

abstract class BibleNoteState {}

class BibleNoteInitial extends BibleNoteState {}

class BibleNoteLoading extends BibleNoteState {}

class BibleNoteLoaded extends BibleNoteState {
  final List<BibleNote> notes;

  BibleNoteLoaded({required List<BibleNote> notes})
      : notes = List.unmodifiable(notes);

  /// The note covering [verse] in [bookName]/[chapter], if any.
  BibleNote? getNoteForVerse(String bookName, int chapter, int verse) {
    for (final note in notes) {
      if (note.coversVerse(bookName, chapter, verse)) return note;
    }
    return null;
  }

  /// The note for the exact range [bookName]/[chapter]/[startVerse]-[endVerse].
  BibleNote? getNoteForRange(
    String bookName,
    int chapter,
    int startVerse,
    int endVerse,
  ) {
    final id = BibleNote.idFor(bookName, chapter, startVerse, endVerse);
    for (final note in notes) {
      if (note.id == id) return note;
    }
    return null;
  }
}

class BibleNoteError extends BibleNoteState {
  final String message;

  BibleNoteError(this.message);
}
