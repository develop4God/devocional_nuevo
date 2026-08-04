@Tags(['unit', 'models', 'notes'])
library;

import 'package:devocional_nuevo/models/devotional_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DevotionalNote serializes and deserializes without data loss', () {
    final note = DevotionalNote(
      devocionalId: 'devocional-123',
      text: 'A personal reflection.',
      lastModifiedDate: DateTime(2026, 7, 29, 10, 30),
    );

    final restored = DevotionalNote.fromJson(note.toJson());

    expect(restored, equals(note));
  });

  test('copyWith overrides only the given fields', () {
    final note = DevotionalNote(
      devocionalId: 'devocional-123',
      text: 'Original text',
      lastModifiedDate: DateTime(2026, 7, 29, 10, 30),
    );

    final updated = note.copyWith(text: 'Updated text');

    expect(updated.devocionalId, note.devocionalId);
    expect(updated.text, 'Updated text');
    expect(updated.lastModifiedDate, note.lastModifiedDate);
  });

  test('copyWith with no arguments returns an equal note', () {
    final note = DevotionalNote(
      devocionalId: 'devocional-123',
      text: 'Original text',
      lastModifiedDate: DateTime(2026, 7, 29, 10, 30),
    );

    expect(note.copyWith(), equals(note));
  });
}
