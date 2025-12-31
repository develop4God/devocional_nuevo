import 'package:devocional_nuevo/models/thanksgiving_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Thanksgiving Model Tests', () {
    test('should create thanksgiving with required fields', () {
      final thanksgiving = Thanksgiving(
        id: 'thanksgiving_123',
        text: 'Gracias Señor por tu amor y fidelidad.',
        createdDate: DateTime(2024, 1, 15, 10, 30),
      );

      expect(thanksgiving.id, equals('thanksgiving_123'));
      expect(
        thanksgiving.text,
        equals('Gracias Señor por tu amor y fidelidad.'),
      );
      expect(thanksgiving.createdDate, equals(DateTime(2024, 1, 15, 10, 30)));
    });

    test('should serialize and deserialize thanksgiving correctly', () {
      final createdDate = DateTime(2024, 1, 15, 10, 30);

      final thanksgiving = Thanksgiving(
        id: 'thanksgiving_456',
        text: 'Estoy agradecido por mi familia.',
        createdDate: createdDate,
      );

      // Test serialization
      final json = thanksgiving.toJson();
      final thanksgivingFromJson = Thanksgiving.fromJson(json);

      expect(thanksgivingFromJson.id, equals(thanksgiving.id));
      expect(thanksgivingFromJson.text, equals(thanksgiving.text));
      expect(
        thanksgivingFromJson.createdDate,
        equals(thanksgiving.createdDate),
      );
    });

    test('should copy thanksgiving with updated fields', () {
      final original = Thanksgiving(
        id: 'thanksgiving_789',
        text: 'Original thanksgiving',
        createdDate: DateTime(2024, 1, 10),
      );

      final updated = original.copyWith(text: 'Updated thanksgiving');

      expect(updated.id, equals(original.id)); // unchanged
      expect(updated.text, equals('Updated thanksgiving')); // changed
      expect(updated.createdDate, equals(original.createdDate)); // unchanged
    });

    test('should calculate daysOld correctly', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final thanksgiving = Thanksgiving(
        id: 'thanksgiving_test',
        text: 'Test thanksgiving',
        createdDate: yesterday,
      );

      expect(thanksgiving.daysOld, equals(1));
    });

    test('should calculate daysOld correctly for today', () {
      final today = DateTime.now();
      final thanksgiving = Thanksgiving(
        id: 'thanksgiving_test',
        text: 'Test thanksgiving',
        createdDate: today,
      );

      expect(thanksgiving.daysOld, equals(0));
    });

    test('should handle malformed date gracefully in fromJson', () {
      final json = {
        'id': 'thanksgiving_bad_date',
        'text': 'Test thanksgiving',
        'createdDate': 'invalid-date',
      };

      final thanksgiving = Thanksgiving.fromJson(json);

      expect(thanksgiving.id, equals('thanksgiving_bad_date'));
      expect(thanksgiving.text, equals('Test thanksgiving'));
      // Should default to now, so just check it's not null
      expect(thanksgiving.createdDate, isNotNull);
    });

    test('should handle missing date in fromJson', () {
      final json = {'id': 'thanksgiving_no_date', 'text': 'Test thanksgiving'};

      final thanksgiving = Thanksgiving.fromJson(json);

      expect(thanksgiving.id, equals('thanksgiving_no_date'));
      expect(thanksgiving.text, equals('Test thanksgiving'));
      // Should default to now
      expect(thanksgiving.createdDate, isNotNull);
    });

    test('should handle missing fields with defaults', () {
      final json = <String, dynamic>{};

      final thanksgiving = Thanksgiving.fromJson(json);

      expect(thanksgiving.id, isNotEmpty); // Generated ID
      expect(thanksgiving.text, equals(''));
      expect(thanksgiving.createdDate, isNotNull);
    });
  });
}
