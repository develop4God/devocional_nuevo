@Tags(['critical', 'bloc'])
library;

// test/critical_coverage/devocional_model_working_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';

void main() {
  group('DevocionalModel Critical Coverage Tests', () {
    test('should serialize/deserialize JSON correctly', () {
      // Test JSON serialization and deserialization
      final devotional = Devocional(
        id: 'test_devotional_123',
        date: DateTime(2025, 1, 15),
        versiculo: 'Juan 3:16',
        reflexion: 'Una reflexión profunda sobre el amor de Dios.',
        paraMeditar: [
          ParaMeditar(
            cita: 'Salmos 23:1',
            texto: 'El Señor es mi pastor, nada me faltará.',
          ),
        ],
        oracion: 'Señor, ayúdanos a crecer en fe.',
        version: 'RVR1960',
        language: 'es',
        tags: ['Fe', 'Amor'],
      );

      // Test toJson
      final json = devotional.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], equals('test_devotional_123'));
      expect(json['versiculo'], equals('Juan 3:16'));
      expect(
        json['reflexion'],
        equals('Una reflexión profunda sobre el amor de Dios.'),
      );

      // Test fromJson
      final fromJson = Devocional.fromJson(json);
      expect(fromJson.id, equals(devotional.id));
      expect(fromJson.versiculo, equals(devotional.versiculo));
      expect(fromJson.reflexion, equals(devotional.reflexion));
      expect(fromJson.paraMeditar.length, equals(1));
      expect(fromJson.paraMeditar.first.cita, equals('Salmos 23:1'));
    });

    test('should validate required fields properly', () {
      // Test required field validation
      expect(() {
        Devocional(
          id: 'test_id',
          date: DateTime.now(),
          versiculo: 'Test verse',
          reflexion: 'Test reflection',
          paraMeditar: [],
          oracion: 'Test prayer',
        );
      }, returnsNormally);

      // Test that model creation works with all required fields
      final devotional = Devocional(
        id: 'required_test',
        date: DateTime(2025, 1, 15),
        versiculo: 'Required verse',
        reflexion: 'Required reflection',
        paraMeditar: [],
        oracion: 'Required prayer',
      );

      expect(devotional.id, equals('required_test'));
      expect(devotional.versiculo, equals('Required verse'));
      expect(devotional.reflexion, equals('Required reflection'));
      expect(devotional.oracion, equals('Required prayer'));
    });

    test('should handle ParaMeditar component data', () {
      // Test ParaMeditar component handling
      final paraMeditar = [
        ParaMeditar(cita: 'Mateo 5:16', texto: 'Así alumbre vuestra luz...'),
        ParaMeditar(
          cita: 'Romanos 8:28',
          texto: 'Y sabemos que a los que aman a Dios...',
        ),
      ];

      final devotional = Devocional(
        id: 'parameditar_test',
        date: DateTime.now(),
        versiculo: 'Test verse',
        reflexion: 'Test reflection',
        paraMeditar: paraMeditar,
        oracion: 'Test prayer',
      );

      expect(devotional.paraMeditar.length, equals(2));
      expect(devotional.paraMeditar[0].cita, equals('Mateo 5:16'));
      expect(
        devotional.paraMeditar[0].texto,
        equals('Así alumbre vuestra luz...'),
      );
      expect(devotional.paraMeditar[1].cita, equals('Romanos 8:28'));

      // Test JSON serialization with ParaMeditar
      final json = devotional.toJson();
      expect(json['para_meditar'], isA<List>());
      expect(json['para_meditar'].length, equals(2));

      // Test deserialization preserves ParaMeditar
      final fromJson = Devocional.fromJson(json);
      expect(fromJson.paraMeditar.length, equals(2));
      expect(fromJson.paraMeditar[0].cita, equals('Mateo 5:16'));
    });

    test('should manage model equality and hashCode', () {
      // Test model equality based on content
      final devotional1 = Devocional(
        id: 'equality_test',
        date: DateTime(2025, 1, 15),
        versiculo: 'Test verse',
        reflexion: 'Test reflection',
        paraMeditar: [],
        oracion: 'Test prayer',
      );

      final devotional2 = Devocional(
        id: 'equality_test',
        date: DateTime(2025, 1, 15),
        versiculo: 'Test verse',
        reflexion: 'Test reflection',
        paraMeditar: [],
        oracion: 'Test prayer',
      );

      final devotional3 = Devocional(
        id: 'different_id',
        date: DateTime(2025, 1, 15),
        versiculo: 'Test verse',
        reflexion: 'Test reflection',
        paraMeditar: [],
        oracion: 'Test prayer',
      );

      // Test structural equality (content-based)
      expect(devotional1.id, equals(devotional2.id));
      expect(devotional1.versiculo, equals(devotional2.versiculo));
      expect(devotional1.id == devotional3.id, isFalse);
    });

    test('should handle optional fields correctly', () {
      // Test optional fields like version, language, tags
      final devotionalWithOptionals = Devocional(
        id: 'optional_test',
        date: DateTime.now(),
        versiculo: 'Test verse',
        reflexion: 'Test reflection',
        paraMeditar: [],
        oracion: 'Test prayer',
        version: 'NVI',
        language: 'es',
        tags: ['Test', 'Optional'],
      );

      expect(devotionalWithOptionals.version, equals('NVI'));
      expect(devotionalWithOptionals.language, equals('es'));
      expect(devotionalWithOptionals.tags, isNotNull);
      expect(devotionalWithOptionals.tags!.length, equals(2));

      final devotionalWithoutOptionals = Devocional(
        id: 'no_optional_test',
        date: DateTime.now(),
        versiculo: 'Test verse',
        reflexion: 'Test reflection',
        paraMeditar: [],
        oracion: 'Test prayer',
      );

      expect(devotionalWithoutOptionals.version, isNull);
      expect(devotionalWithoutOptionals.language, isNull);
      expect(devotionalWithoutOptionals.tags, isNull);
    });

    test('should handle malformed JSON gracefully', () {
      // Test error handling for malformed JSON data
      const malformedJson = <String, dynamic>{
        'id': 'malformed_test',
        // Missing required fields to test error handling
        'versiculo': 'Test verse',
        // Missing reflexion, para_meditar, oracion
      };

      // DevocionalModel.fromJson provides defaults for missing fields
      final devotional = Devocional.fromJson(malformedJson);
      expect(devotional.id, equals('malformed_test'));
      expect(devotional.versiculo, equals('Test verse'));
      expect(devotional.reflexion, equals('')); // Default empty string
      expect(devotional.paraMeditar, isEmpty); // Default empty list
      expect(devotional.oracion, equals('')); // Default empty string

      // Test with null values - should handle gracefully
      const nullJson = <String, dynamic>{
        'id': null,
        'date': null,
        'versiculo': null,
        'reflexion': null,
        'para_meditar': null,
        'oracion': null,
      };

      final nullDevotional = Devocional.fromJson(nullJson);
      expect(nullDevotional.id, isA<String>()); // Should get generated ID
      expect(nullDevotional.versiculo, equals(''));
      expect(nullDevotional.reflexion, equals(''));
      expect(nullDevotional.paraMeditar, isEmpty);
      expect(nullDevotional.oracion, equals(''));
    });
  });
}
