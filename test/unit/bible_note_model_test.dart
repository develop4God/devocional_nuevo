@Tags(['unit', 'models'])
library;

import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BibleNote serializes and deserializes without data loss', () {
    final note = BibleNote(
      bookName: 'Juan',
      chapter: 3,
      startVerse: 16,
      endVerse: 18,
      text: 'A personal reflection.',
      lastModifiedDate: DateTime(2026, 7, 29, 10, 30),
    );

    final restored = BibleNote.fromJson(note.toJson());

    expect(restored, equals(note));
  });

  test('id combines book, chapter, and verse range', () {
    final note = BibleNote(
      bookName: 'Juan',
      chapter: 3,
      startVerse: 16,
      endVerse: 18,
      text: 'Text',
      lastModifiedDate: DateTime(2026, 7, 29),
    );

    expect(note.id, 'Juan|3|16-18');
  });

  test('coversVerse is true only within the same book/chapter/range', () {
    final note = BibleNote(
      bookName: 'Juan',
      chapter: 3,
      startVerse: 16,
      endVerse: 18,
      text: 'Text',
      lastModifiedDate: DateTime(2026, 7, 29),
    );

    expect(note.coversVerse('Juan', 3, 16), isTrue);
    expect(note.coversVerse('Juan', 3, 17), isTrue);
    expect(note.coversVerse('Juan', 3, 18), isTrue);
    expect(note.coversVerse('Juan', 3, 19), isFalse);
    expect(note.coversVerse('Juan', 3, 15), isFalse);
    expect(note.coversVerse('Juan', 4, 16), isFalse);
    expect(note.coversVerse('Mateo', 3, 16), isFalse);
  });
}
