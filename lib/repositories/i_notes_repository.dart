import 'package:devocional_nuevo/models/devotional_note.dart';

/// Contract for devotional note persistence.
///
/// The note BLoC depends on this abstraction instead of a storage mechanism.
abstract class INotesRepository {
  /// Loads every saved devotional note.
  Future<List<DevotionalNote>> loadNotes();

  /// Creates or updates [note].
  Future<void> saveNote(DevotionalNote note);

  /// Removes the note associated with [devocionalId].
  Future<void> deleteNote(String devocionalId);
}
