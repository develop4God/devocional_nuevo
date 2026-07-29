@Tags(['unit', 'models'])
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
}
