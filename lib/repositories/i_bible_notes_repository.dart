import 'package:devocional_nuevo/models/bible_note.dart';

/// Contract for Bible verse note persistence.
///
/// The Bible note BLoC depends on this abstraction instead of a storage
/// mechanism.
abstract class IBibleNotesRepository {
  /// Loads every saved Bible verse note.
  Future<List<BibleNote>> loadNotes();

  /// Creates or updates [note].
  Future<void> saveNote(BibleNote note);

  /// Removes the note identified by [noteId] (see [BibleNote.id]).
  Future<void> deleteNote(String noteId);
}
