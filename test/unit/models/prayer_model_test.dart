@Tags(['unit', 'models'])
library;

import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Prayer Model Tests', () {
    test('should create prayer with required fields', () {
      final prayer = Prayer(
        id: 'prayer_123',
        text: 'Señor, ayúdame en este día especial.',
        createdDate: DateTime(2024, 1, 15, 10, 30),
        status: PrayerStatus.active,
      );

      expect(prayer.id, equals('prayer_123'));
      expect(prayer.text, equals('Señor, ayúdame en este día especial.'));
      expect(prayer.createdDate, equals(DateTime(2024, 1, 15, 10, 30)));
      expect(prayer.status, equals(PrayerStatus.active));
      expect(prayer.answeredDate, isNull);
    });

    test('should serialize and deserialize prayer correctly', () {
      final createdDate = DateTime(2024, 1, 15, 10, 30);
      final answeredDate = DateTime(2024, 1, 20, 14, 45);

      final prayer = Prayer(
        id: 'prayer_456',
        text: 'Gracias por tu bendición, Señor.',
        createdDate: createdDate,
        status: PrayerStatus.answered,
        answeredDate: answeredDate,
      );

      // Test serialization
      final json = prayer.toJson();
      final prayerFromJson = Prayer.fromJson(json);

      expect(prayerFromJson.id, equals(prayer.id));
      expect(prayerFromJson.text, equals(prayer.text));
      expect(prayerFromJson.createdDate, equals(prayer.createdDate));
      expect(prayerFromJson.status, equals(prayer.status));
      expect(prayerFromJson.answeredDate, equals(prayer.answeredDate));
    });

    test('should copy prayer with updated fields', () {
      final original = Prayer(
        id: 'prayer_789',
        text: 'Original prayer',
        createdDate: DateTime(2024, 1, 10),
        status: PrayerStatus.active,
      );

      final answeredDate = DateTime(2024, 1, 15);
      final updated = original.copyWith(
        status: PrayerStatus.answered,
        answeredDate: answeredDate,
      );

      expect(updated.id, equals(original.id)); // unchanged
      expect(updated.text, equals(original.text)); // unchanged
      expect(updated.createdDate, equals(original.createdDate)); // unchanged
      expect(updated.status, equals(PrayerStatus.answered)); // changed
      expect(updated.answeredDate, equals(answeredDate)); // changed
    });
  });
}
