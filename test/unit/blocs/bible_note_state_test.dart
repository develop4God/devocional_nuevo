@Tags(['unit', 'blocs', 'notes'])
library;

import 'package:devocional_nuevo/blocs/bible_note_state.dart';
import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BibleNoteLoaded.getNoteForRange', () {
    final note = BibleNote(
      bookName: 'Juan',
      chapter: 3,
      startVerse: 16,
      endVerse: 18,
      text: 'A saved reflection',
      lastModifiedDate: DateTime(2026, 1, 1),
    );
    final state = BibleNoteLoaded(notes: [note]);

    test('returns the note matching the exact book/chapter/range', () {
      expect(state.getNoteForRange('Juan', 3, 16, 18), same(note));
    });

    test('returns null when the range does not match exactly', () {
      expect(state.getNoteForRange('Juan', 3, 16, 17), isNull);
    });

    test('returns null when the book does not match', () {
      expect(state.getNoteForRange('Mateo', 3, 16, 18), isNull);
    });

    test('returns null when there are no notes', () {
      expect(BibleNoteLoaded(notes: []).getNoteForRange('Juan', 3, 16, 18),
          isNull);
    });
  });

  group('BibleNoteLoaded.getNoteForVerse', () {
    final note = BibleNote(
      bookName: 'Salmos',
      chapter: 23,
      startVerse: 1,
      endVerse: 3,
      text: 'A saved reflection',
      lastModifiedDate: DateTime(2026, 1, 1),
    );
    final state = BibleNoteLoaded(notes: [note]);

    test('returns the note covering a verse within its range', () {
      expect(state.getNoteForVerse('Salmos', 23, 2), same(note));
    });

    test('returns null for a verse outside the range', () {
      expect(state.getNoteForVerse('Salmos', 23, 4), isNull);
    });
  });
}
