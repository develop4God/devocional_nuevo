import 'dart:convert';
import 'dart:developer' as developer;

import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:devocional_nuevo/repositories/i_bible_notes_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

/// SharedPreferences implementation of [IBibleNotesRepository].
class BibleNotesRepository implements IBibleNotesRepository {
  static const _notesKey = 'bible_notes';

  final Future<SharedPreferences> Function() _prefsFactory;
  final _lock = Lock();

  BibleNotesRepository({
    required Future<SharedPreferences> Function() prefsFactory,
  }) : _prefsFactory = prefsFactory;

  @override
  Future<List<BibleNote>> loadNotes() async {
    final prefs = await _prefsFactory();
    return _readNotes(prefs);
  }

  @override
  Future<void> saveNote(BibleNote note) {
    return _lock.synchronized(() async {
      final prefs = await _prefsFactory();
      final notes = await _readNotes(prefs);
      final notesById = {
        for (final existingNote in notes) existingNote.id: existingNote,
      }..[note.id] = note;
      await _writeNotes(prefs, notesById.values.toList());
    });
  }

  @override
  Future<void> deleteNote(String noteId) {
    return _lock.synchronized(() async {
      final prefs = await _prefsFactory();
      final notes = await _readNotes(prefs);
      await _writeNotes(
        prefs,
        notes.where((note) => note.id != noteId).toList(),
      );
    });
  }

  Future<List<BibleNote>> _readNotes(SharedPreferences prefs) async {
    final notesJson = prefs.getString(_notesKey);
    if (notesJson == null || notesJson.isEmpty) return [];

    List<dynamic> decodedNotes;
    try {
      decodedNotes = json.decode(notesJson) as List<dynamic>;
    } catch (error) {
      developer.log(
        '❌BIBLE_NOTES_ERROR: Failed decoding $_notesKey: $error',
        name: 'BibleNotes',
      );
      return [];
    }

    final notes = <BibleNote>[];
    for (final rawNote in decodedNotes) {
      try {
        notes.add(
          BibleNote.fromJson(Map<String, dynamic>.from(rawNote as Map)),
        );
      } catch (error) {
        developer.log(
          '❌BIBLE_NOTES_ERROR: Skipping corrupt note: $error',
          name: 'BibleNotes',
        );
      }
    }
    return notes;
  }

  Future<void> _writeNotes(
    SharedPreferences prefs,
    List<BibleNote> notes,
  ) {
    return prefs.setString(
      _notesKey,
      json.encode(notes.map((note) => note.toJson()).toList()),
    );
  }
}
