// test/unit/models/devocional_model_simple_test.dart

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DevocionalModel Simple Tests', () {
    test('should create devotional model with required fields', () {
      final devotional = Devocional(
        id: 'test_dev',
        versiculo: 'Test verse',
        reflexion: 'Test reflection',
        paraMeditar: [
          ParaMeditar(cita: 'Test 1:1', texto: 'Test meditation'),
        ],
        oracion: 'Test prayer',
        date: DateTime(2025, 1, 15),
      );

      expect(devotional.id, equals('test_dev'));
      expect(devotional.versiculo, equals('Test verse'));
      expect(devotional.reflexion, equals('Test reflection'));
      expect(devotional.oracion, equals('Test prayer'));
      expect(devotional.date, equals(DateTime(2025, 1, 15)));
      expect(devotional.paraMeditar, hasLength(1));
      expect(devotional.paraMeditar.first.cita, equals('Test 1:1'));
      expect(devotional.paraMeditar.first.texto, equals('Test meditation'));
    });

    test('should handle optional fields correctly', () {
      final devotional = Devocional(
        id: 'optional_test',
        versiculo: 'Test verse',
        reflexion: 'Test reflection',
        paraMeditar: [],
        oracion: 'Test prayer',
        date: DateTime.now(),
        version: 'RVR1960',
        language: 'es',
        tags: ['tag1', 'tag2'],
      );

      expect(devotional.version, equals('RVR1960'));
      expect(devotional.language, equals('es'));
      expect(devotional.tags, equals(['tag1', 'tag2']));
      expect(devotional.paraMeditar, isEmpty);
    });

    test('should create JSON representation', () {
      final devotional = Devocional(
        id: 'json_test',
        versiculo: 'JSON test verse',
        reflexion: 'JSON test reflection',
        paraMeditar: [
          ParaMeditar(cita: 'JSON 1:1', texto: 'JSON meditation'),
        ],
        oracion: 'JSON test prayer',
        date: DateTime(2025, 1, 15),
        version: 'KJV',
        language: 'en',
      );

      final json = devotional.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], equals('json_test'));
      expect(json['versiculo'], equals('JSON test verse'));
      expect(json['reflexion'], equals('JSON test reflection'));
      expect(json['oracion'], equals('JSON test prayer'));
      expect(json['version'], equals('KJV'));
      expect(json['language'], equals('en'));
      expect(json['para_meditar'], isA<List>());
    });

    test('should create from JSON with basic data', () {
      final json = {
        'id': 'from_json_test',
        'versiculo': 'From JSON verse',
        'reflexion': 'From JSON reflection',
        'para_meditar': [
          {'cita': 'JSON 2:2', 'texto': 'JSON meditation 2'}
        ],
        'oracion': 'From JSON prayer',
        'date': '2025-01-15',
        'version': 'NIV',
        'language': 'en',
      };

      final devotional = Devocional.fromJson(json);

      expect(devotional.id, equals('from_json_test'));
      expect(devotional.versiculo, equals('From JSON verse'));
      expect(devotional.reflexion, equals('From JSON reflection'));
      expect(devotional.oracion, equals('From JSON prayer'));
      expect(devotional.version, equals('NIV'));
      expect(devotional.language, equals('en'));
      expect(devotional.paraMeditar, hasLength(1));
    });

    test('should handle ParaMeditar creation and serialization', () {
      final paraMeditar = ParaMeditar(
        cita: 'Test Citation 3:3',
        texto: 'Test meditation text',
      );

      expect(paraMeditar.cita, equals('Test Citation 3:3'));
      expect(paraMeditar.texto, equals('Test meditation text'));

      final json = paraMeditar.toJson();
      expect(json['cita'], equals('Test Citation 3:3'));
      expect(json['texto'], equals('Test meditation text'));

      final fromJson = ParaMeditar.fromJson(json);
      expect(fromJson.cita, equals(paraMeditar.cita));
      expect(fromJson.texto, equals(paraMeditar.texto));
    });

    test('should handle missing JSON fields gracefully', () {
      final incompleteJson = {
        'id': 'incomplete',
        // Missing other fields
      };

      final devotional = Devocional.fromJson(incompleteJson);
      expect(devotional.id, equals('incomplete'));
      expect(devotional.versiculo, equals(''));
      expect(devotional.reflexion, equals(''));
      expect(devotional.oracion, equals(''));
      expect(devotional.paraMeditar, isEmpty);
      expect(devotional.date, isA<DateTime>());
    });
  });
}
