import 'dart:convert';

import 'package:devocional_nuevo/models/devotional_note.dart';
import 'package:devocional_nuevo/repositories/i_notes_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

/// SharedPreferences implementation of [INotesRepository].
class NotesRepository implements INotesRepository {
  static const _notesKey = 'devotional_notes';

  final Future<SharedPreferences> Function() _prefsFactory;
  final _lock = Lock();

  NotesRepository({
    required Future<SharedPreferences> Function() prefsFactory,
  }) : _prefsFactory = prefsFactory;

  @override
  Future<List<DevotionalNote>> loadNotes() async {
    final prefs = await _prefsFactory();
    return _readNotes(prefs);
  }

  @override
  Future<void> saveNote(DevotionalNote note) {
    return _lock.synchronized(() async {
      final prefs = await _prefsFactory();
      final notes = await _readNotes(prefs);
      final notesByDevocionalId = {
        for (final existingNote in notes)
          existingNote.devocionalId: existingNote,
      }..[note.devocionalId] = note;
      await _writeNotes(prefs, notesByDevocionalId.values.toList());
    });
  }

  @override
  Future<void> deleteNote(String devocionalId) {
    return _lock.synchronized(() async {
      final prefs = await _prefsFactory();
      final notes = await _readNotes(prefs);
      await _writeNotes(
        prefs,
        notes.where((note) => note.devocionalId != devocionalId).toList(),
      );
    });
  }

  Future<List<DevotionalNote>> _readNotes(SharedPreferences prefs) async {
    final notesJson = prefs.getString(_notesKey);
    if (notesJson == null || notesJson.isEmpty) return [];

    final decodedNotes = json.decode(notesJson) as List<dynamic>;
    return decodedNotes
        .map(
          (note) => DevotionalNote.fromJson(
            Map<String, dynamic>.from(note as Map),
          ),
        )
        .toList();
  }

  Future<void> _writeNotes(
    SharedPreferences prefs,
    List<DevotionalNote> notes,
  ) {
    return prefs.setString(
      _notesKey,
      json.encode(notes.map((note) => note.toJson()).toList()),
    );
  }
}
