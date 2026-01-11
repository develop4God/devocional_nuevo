import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/models/discovery_section_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiscoveryDevotional Model Tests', () {
    test('should create Discovery devotional with required fields', () {
      final section = DiscoverySection(
        tipo: 'natural',
        icono: '🔭',
        titulo: 'Test Section',
        contenido: 'Test content',
      );

      final devotional = DiscoveryDevotional(
        id: 'estrella-manana-001',
        versiculo: 'Apocalipsis 22:16',
        reflexion: 'El Heraldo de la Luz',
        paraMeditar: [],
        oracion: 'Señor, ayúdanos...',
        date: DateTime(2026, 1, 15),
        secciones: [section],
        preguntasDiscovery: ['¿Qué te llama la atención?'],
        versiculoClave: 'Apocalipsis 22:16',
      );

      expect(devotional.id, equals('estrella-manana-001'));
      expect(devotional.reflexion, equals('El Heraldo de la Luz'));
      expect(devotional.versiculoClave, equals('Apocalipsis 22:16'));
      expect(devotional.totalSections, equals(1));
      expect(devotional.totalQuestions, equals(1));
    });

    test('should serialize and deserialize Discovery devotional correctly', () {
      final json = {
        'id': 'estrella-manana-001',
        'tipo': 'discovery',
        'fecha': '2026-01-15',
        'titulo': 'El Heraldo de la Luz',
        'versiculo_clave': 'Apocalipsis 22:16',
        'secciones': [
          {
            'tipo': 'natural',
            'icono': '🔭',
            'titulo': 'La Estrella Matutina',
            'contenido': 'Venus brilla antes del amanecer...',
          }
        ],
        'preguntas_discovery': ['¿Qué observas?', '¿Qué te enseña?'],
        'oracion': 'Señor, ilumina nuestro camino...',
        'tags': ['luz', 'esperanza'],
      };

      final devotional = DiscoveryDevotional.fromJson(json);

      expect(devotional.id, equals('estrella-manana-001'));
      expect(devotional.versiculoClave, equals('Apocalipsis 22:16'));
      expect(devotional.reflexion, equals('El Heraldo de la Luz'));
      expect(devotional.secciones, hasLength(1));
      expect(devotional.preguntasDiscovery, hasLength(2));
      expect(devotional.tags, hasLength(2));
      expect(devotional.date, equals(DateTime(2026, 1, 15)));
    });

    test('should handle serialization to JSON', () {
      final section = DiscoverySection(
        tipo: 'natural',
        icono: '🌟',
        titulo: 'Test',
        contenido: 'Content',
      );

      final devotional = DiscoveryDevotional(
        id: 'test-001',
        versiculo: 'Juan 1:1',
        reflexion: 'Test Title',
        paraMeditar: [],
        oracion: 'Test prayer',
        date: DateTime(2026, 1, 1),
        secciones: [section],
        preguntasDiscovery: ['Test question?'],
        versiculoClave: 'Juan 1:1',
        tags: ['test'],
      );

      final json = devotional.toJson();

      expect(json['id'], equals('test-001'));
      expect(json['tipo'], equals('discovery'));
      expect(json['fecha'], equals('2026-01-01'));
      expect(json['versiculo_clave'], equals('Juan 1:1'));
      expect(json['secciones'], hasLength(1));
      expect(json['preguntas_discovery'], hasLength(1));
      expect(json['tags'], hasLength(1));
    });

    test('should handle copyWith method', () {
      final original = DiscoveryDevotional(
        id: 'original-001',
        versiculo: 'Original verse',
        reflexion: 'Original title',
        paraMeditar: [],
        oracion: 'Original prayer',
        date: DateTime(2026, 1, 1),
        secciones: [],
        preguntasDiscovery: [],
        versiculoClave: 'Original key',
      );

      final updated = original.copyWith(
        id: 'updated-001',
        reflexion: 'Updated title',
      );

      expect(updated.id, equals('updated-001'));
      expect(updated.reflexion, equals('Updated title'));
      expect(updated.versiculo, equals(original.versiculo)); // unchanged
      expect(updated.oracion, equals(original.oracion)); // unchanged
    });

    test('should count sections and questions correctly', () {
      final devotional = DiscoveryDevotional(
        id: 'test-001',
        versiculo: 'Test',
        reflexion: 'Test',
        paraMeditar: [],
        oracion: 'Test',
        date: DateTime(2026, 1, 1),
        secciones: [
          DiscoverySection(tipo: 'natural', contenido: 'Test 1'),
          DiscoverySection(tipo: 'scripture', pasajes: []),
          DiscoverySection(tipo: 'natural', contenido: 'Test 2'),
        ],
        preguntasDiscovery: [
          '¿Pregunta 1?',
          '¿Pregunta 2?',
          '¿Pregunta 3?',
        ],
        versiculoClave: 'Test',
      );

      expect(devotional.totalSections, equals(3));
      expect(devotional.totalQuestions, equals(3));
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'id': 'minimal-001',
        'fecha': '2026-01-15',
        'titulo': 'Minimal',
        'versiculo_clave': 'Test verse',
      };

      final devotional = DiscoveryDevotional.fromJson(json);

      expect(devotional.id, equals('minimal-001'));
      expect(devotional.versiculoClave, equals('Test verse'));
      expect(devotional.secciones, isEmpty);
      expect(devotional.preguntasDiscovery, isEmpty);
      expect(devotional.tags, isNull);
    });

    test('should handle invalid date format gracefully', () {
      final json = {
        'id': 'invalid-date-001',
        'fecha': 'invalid-date-format',
        'versiculo_clave': 'Test',
      };

      final devotional = DiscoveryDevotional.fromJson(json);

      expect(devotional.id, equals('invalid-date-001'));
      // Should default to current date when parsing fails
      expect(devotional.date, isNotNull);
    });
  });
}
