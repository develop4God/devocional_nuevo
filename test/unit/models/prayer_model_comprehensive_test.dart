import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Prayer Model Unit Tests', () {
    group('Constructor and Basic Properties', () {
      test('should create prayer with required fields', () {
        // Arrange & Act
        final prayer = Prayer(
          id: 'prayer_123',
          text: 'Señor, ayúdame en este día especial.',
          createdDate: DateTime(2024, 1, 15, 10, 30),
          status: PrayerStatus.active,
        );

        // Assert
        expect(prayer.id, equals('prayer_123'));
        expect(prayer.text, equals('Señor, ayúdame en este día especial.'));
        expect(prayer.createdDate, equals(DateTime(2024, 1, 15, 10, 30)));
        expect(prayer.status, equals(PrayerStatus.active));
        expect(prayer.answeredDate, isNull);
      });

      test('should create prayer with answered date', () {
        // Arrange & Act
        final createdDate = DateTime(2024, 1, 15, 10, 30);
        final answeredDate = DateTime(2024, 1, 20, 14, 45);

        final prayer = Prayer(
          id: 'prayer_456',
          text: 'Gracias por tu bendición, Señor.',
          createdDate: createdDate,
          status: PrayerStatus.answered,
          answeredDate: answeredDate,
        );

        // Assert
        expect(prayer.id, equals('prayer_456'));
        expect(prayer.text, equals('Gracias por tu bendición, Señor.'));
        expect(prayer.createdDate, equals(createdDate));
        expect(prayer.status, equals(PrayerStatus.answered));
        expect(prayer.answeredDate, equals(answeredDate));
      });

      test('should handle empty and special character texts', () {
        // Arrange & Act - Empty text
        final emptyPrayer = Prayer(
          id: 'empty_prayer',
          text: '',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        );

        // Special characters and unicode
        final specialPrayer = Prayer(
          id: 'special_prayer',
          text:
              'Señor, ayúdame con estos símbolos: @#\$%^&*()_+{}[]|\\:";\'<>?,./ 🙏✝️❤️',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        );

        // Assert
        expect(emptyPrayer.text, equals(''));
        expect(specialPrayer.text, contains('🙏✝️❤️'));
        expect(specialPrayer.text, contains('Señor'));
      });
    });

    group('JSON Serialization', () {
      test('should serialize prayer to JSON correctly', () {
        // Arrange
        final prayer = Prayer(
          id: 'prayer_json_test',
          text: 'Oración de prueba para JSON',
          createdDate: DateTime(2024, 1, 15, 10, 30, 45),
          status: PrayerStatus.active,
        );

        // Act
        final json = prayer.toJson();

        // Assert
        expect(json, isA<Map<String, dynamic>>());
        expect(json['id'], equals('prayer_json_test'));
        expect(json['text'], equals('Oración de prueba para JSON'));
        expect(json['createdDate'], equals('2024-01-15T10:30:45.000'));
        expect(json['status'], equals('active'));
        expect(json['answeredDate'], isNull);
      });

      test('should serialize answered prayer to JSON correctly', () {
        // Arrange
        final createdDate = DateTime(2024, 1, 15, 10, 30);
        final answeredDate = DateTime(2024, 1, 20, 14, 45);

        final prayer = Prayer(
          id: 'answered_prayer_json',
          text: 'Oración respondida para JSON',
          createdDate: createdDate,
          status: PrayerStatus.answered,
          answeredDate: answeredDate,
        );

        // Act
        final json = prayer.toJson();

        // Assert
        expect(json['id'], equals('answered_prayer_json'));
        expect(json['text'], equals('Oración respondida para JSON'));
        expect(json['createdDate'], equals('2024-01-15T10:30:00.000'));
        expect(json['status'], equals('answered'));
        expect(json['answeredDate'], equals('2024-01-20T14:45:00.000'));
      });

      test('should handle unicode and special characters in JSON', () {
        // Arrange
        final prayer = Prayer(
          id: 'unicode_prayer',
          text:
              'Oración con unicode: 你好世界, emojis: 🙏📖✝️❤️, y acentos: ñáéíóú',
          createdDate: DateTime(2024, 1, 15),
          status: PrayerStatus.active,
        );

        // Act
        final json = prayer.toJson();

        // Assert
        expect(
            json['text'],
            equals(
                'Oración con unicode: 你好世界, emojis: 🙏📖✝️❤️, y acentos: ñáéíóú'));
        expect(json['text'], contains('你好世界'));
        expect(json['text'], contains('🙏📖✝️❤️'));
        expect(json['text'], contains('ñáéíóú'));
      });
    });

    group('JSON Deserialization', () {
      test('should deserialize prayer from valid JSON', () {
        // Arrange
        final json = {
          'id': 'deserialized_prayer',
          'text': 'Oración deserializada desde JSON',
          'createdDate': '2024-01-15T10:30:45.000',
          'status': 'active',
        };

        // Act
        final prayer = Prayer.fromJson(json);

        // Assert
        expect(prayer.id, equals('deserialized_prayer'));
        expect(prayer.text, equals('Oración deserializada desde JSON'));
        expect(prayer.createdDate, equals(DateTime(2024, 1, 15, 10, 30, 45)));
        expect(prayer.status, equals(PrayerStatus.active));
        expect(prayer.answeredDate, isNull);
      });

      test('should deserialize answered prayer from JSON', () {
        // Arrange
        final json = {
          'id': 'answered_deserialized',
          'text': 'Oración respondida desde JSON',
          'createdDate': '2024-01-15T10:30:00.000',
          'status': 'answered',
          'answeredDate': '2024-01-20T14:45:00.000',
        };

        // Act
        final prayer = Prayer.fromJson(json);

        // Assert
        expect(prayer.id, equals('answered_deserialized'));
        expect(prayer.status, equals(PrayerStatus.answered));
        expect(prayer.answeredDate, equals(DateTime(2024, 1, 20, 14, 45)));
      });

      test('should handle missing fields gracefully', () {
        // Arrange - JSON with missing optional fields
        final json = {
          'id': 'minimal_prayer',
          'text': 'Oración mínima',
          'createdDate': '2024-01-15T10:30:00.000',
          'status': 'active',
          // answeredDate is missing
        };

        // Act
        final prayer = Prayer.fromJson(json);

        // Assert
        expect(prayer.id, equals('minimal_prayer'));
        expect(prayer.text, equals('Oración mínima'));
        expect(prayer.status, equals(PrayerStatus.active));
        expect(prayer.answeredDate, isNull);
      });

      test('should handle invalid date formats gracefully', () {
        // Arrange - JSON with invalid date format
        final json = {
          'id': 'invalid_date_prayer',
          'text': 'Oración con fecha inválida',
          'createdDate': 'invalid_date_format',
          'status': 'active',
          'answeredDate': 'also_invalid_date',
        };

        // Act
        final prayer = Prayer.fromJson(json);

        // Assert - Should use current time as fallback
        expect(prayer.id, equals('invalid_date_prayer'));
        expect(prayer.text, equals('Oración con fecha inválida'));
        expect(prayer.status, equals(PrayerStatus.active));
        expect(prayer.createdDate, isA<DateTime>());
        // answeredDate should be null when invalid
        expect(prayer.answeredDate, isNull);
      });

      test('should handle empty and null values', () {
        // Arrange - JSON with empty/null values
        final json = {
          'id': 'empty_values_prayer',
          'text': '',
          'createdDate': '',
          'status': 'active',
          'answeredDate': null,
        };

        // Act
        final prayer = Prayer.fromJson(json);

        // Assert
        expect(prayer.id, equals('empty_values_prayer'));
        expect(prayer.text, equals(''));
        expect(prayer.createdDate, isA<DateTime>()); // Should default to now
        expect(prayer.answeredDate, isNull);
      });

      test('should handle unknown status values gracefully', () {
        // Arrange - JSON with unknown status
        final json = {
          'id': 'unknown_status_prayer',
          'text': 'Oración con estado desconocido',
          'createdDate': '2024-01-15T10:30:00.000',
          'status': 'unknown_status',
        };

        // Act
        final prayer = Prayer.fromJson(json);

        // Assert - Should default to active
        expect(prayer.id, equals('unknown_status_prayer'));
        expect(prayer.status, equals(PrayerStatus.active));
      });
    });

    group('copyWith Method', () {
      test('should create copy with updated status', () {
        // Arrange
        final originalPrayer = Prayer(
          id: 'original_prayer',
          text: 'Oración original',
          createdDate: DateTime(2024, 1, 15, 10, 30),
          status: PrayerStatus.active,
        );

        // Act
        final updatedPrayer = originalPrayer.copyWith(
          status: PrayerStatus.answered,
          answeredDate: DateTime(2024, 1, 20, 14, 45),
        );

        // Assert
        expect(updatedPrayer.id, equals(originalPrayer.id));
        expect(updatedPrayer.text, equals(originalPrayer.text));
        expect(updatedPrayer.createdDate, equals(originalPrayer.createdDate));
        expect(updatedPrayer.status, equals(PrayerStatus.answered));
        expect(
            updatedPrayer.answeredDate, equals(DateTime(2024, 1, 20, 14, 45)));
      });

      test('should create copy with updated text', () {
        // Arrange
        final originalPrayer = Prayer(
          id: 'text_update_prayer',
          text: 'Texto original',
          createdDate: DateTime(2024, 1, 15),
          status: PrayerStatus.active,
        );

        // Act
        final updatedPrayer = originalPrayer.copyWith(
          text: 'Texto actualizado con nuevas palabras',
        );

        // Assert
        expect(updatedPrayer.text,
            equals('Texto actualizado con nuevas palabras'));
        expect(updatedPrayer.id, equals(originalPrayer.id));
        expect(updatedPrayer.createdDate, equals(originalPrayer.createdDate));
        expect(updatedPrayer.status, equals(originalPrayer.status));
      });

      test('should preserve original values when no updates provided', () {
        // Arrange
        final originalPrayer = Prayer(
          id: 'preserve_test',
          text: 'Texto a preservar',
          createdDate: DateTime(2024, 1, 15, 10, 30),
          status: PrayerStatus.answered,
          answeredDate: DateTime(2024, 1, 20, 14, 45),
        );

        // Act - copyWith with no parameters
        final copiedPrayer = originalPrayer.copyWith();

        // Assert
        expect(copiedPrayer.id, equals(originalPrayer.id));
        expect(copiedPrayer.text, equals(originalPrayer.text));
        expect(copiedPrayer.createdDate, equals(originalPrayer.createdDate));
        expect(copiedPrayer.status, equals(originalPrayer.status));
        expect(copiedPrayer.answeredDate, equals(originalPrayer.answeredDate));

        // Should be different instances
        expect(identical(copiedPrayer, originalPrayer), isFalse);
      });

      test('should handle null answeredDate assignment correctly', () {
        // Arrange
        final prayerWithAnswer = Prayer(
          id: 'null_answer_test',
          text: 'Oración con respuesta',
          createdDate: DateTime(2024, 1, 15),
          status: PrayerStatus.answered,
          answeredDate: DateTime(2024, 1, 20),
        );

        // Act - Set answeredDate back to null using clearAnsweredDate flag
        final prayerWithoutAnswer = prayerWithAnswer.copyWith(
          status: PrayerStatus.active,
          clearAnsweredDate: true,
        );

        // Assert
        expect(prayerWithoutAnswer.status, equals(PrayerStatus.active));
        expect(prayerWithoutAnswer.answeredDate, isNull);
      });
    });

    group('Prayer Status Enum', () {
      test('should have correct string values for PrayerStatus', () {
        // Assert
        expect(PrayerStatus.active.toString(), contains('active'));
        expect(PrayerStatus.answered.toString(), contains('answered'));
      });

      test('should handle status conversion correctly', () {
        // Test that the JSON serialization/deserialization works with enum
        final activePrayer = Prayer(
          id: 'status_test_active',
          text: 'Prueba estado activo',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        );

        final answeredPrayer = Prayer(
          id: 'status_test_answered',
          text: 'Prueba estado respondido',
          createdDate: DateTime.now(),
          status: PrayerStatus.answered,
        );

        // Act - Convert to JSON and back
        final activeJson = activePrayer.toJson();
        final answeredJson = answeredPrayer.toJson();

        final activeFromJson = Prayer.fromJson(activeJson);
        final answeredFromJson = Prayer.fromJson(answeredJson);

        // Assert
        expect(activeFromJson.status, equals(PrayerStatus.active));
        expect(answeredFromJson.status, equals(PrayerStatus.answered));
        expect(activeJson['status'], equals('active'));
        expect(answeredJson['status'], equals('answered'));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle extremely long prayer text', () {
        // Arrange - Very long text
        final longText =
            'Esta es una oración muy larga que contiene muchas palabras repetidas. ' *
                1000;

        final prayer = Prayer(
          id: 'long_text_prayer',
          text: longText,
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        );

        // Act - Convert to JSON and back
        final json = prayer.toJson();
        final deserializedPrayer = Prayer.fromJson(json);

        // Assert
        expect(deserializedPrayer.text.length, equals(longText.length));
        expect(deserializedPrayer.text, equals(longText));
      });

      test('should handle prayers with very old and future dates', () {
        // Arrange - Very old date
        final oldPrayer = Prayer(
          id: 'old_prayer',
          text: 'Oración muy antigua',
          createdDate: DateTime(1900, 1, 1),
          status: PrayerStatus.active,
        );

        // Future date
        final futurePrayer = Prayer(
          id: 'future_prayer',
          text: 'Oración del futuro',
          createdDate: DateTime(2100, 12, 31),
          status: PrayerStatus.active,
        );

        // Act - Convert to JSON and back
        final oldJson = oldPrayer.toJson();
        final futureJson = futurePrayer.toJson();

        final oldFromJson = Prayer.fromJson(oldJson);
        final futureFromJson = Prayer.fromJson(futureJson);

        // Assert
        expect(oldFromJson.createdDate.year, equals(1900));
        expect(futureFromJson.createdDate.year, equals(2100));
      });

      test('should handle rapid succession of copyWith operations', () {
        // Arrange
        final originalPrayer = Prayer(
          id: 'rapid_copy_test',
          text: 'Original text',
          createdDate: DateTime(2024, 1, 15),
          status: PrayerStatus.active,
        );

        // Act - Multiple rapid copyWith operations
        Prayer current = originalPrayer;
        for (int i = 0; i < 100; i++) {
          current = current.copyWith(
            text: 'Updated text $i',
          );
        }

        // Assert
        expect(current.text, equals('Updated text 99'));
        expect(current.id, equals(originalPrayer.id));
        expect(current.createdDate, equals(originalPrayer.createdDate));
      });
    });
  });
}
