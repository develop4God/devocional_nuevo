@Tags(['unit', 'models'])
library;

import 'package:devocional_nuevo/models/discovery_card_model.dart';
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
        cards: [],
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
        cards: [],
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
        cards: [],
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
        cards: [],
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

    test('should parse new JSON format with cards', () {
      final json = {
        'id': 'morning_star_001',
        'type': 'discovery',
        'date': '2026-01-15',
        'title': 'El Heraldo de la Luz',
        'subtitle': 'La conexión eterna',
        'language': 'es',
        'version': 'RVR1960',
        'estimated_reading_minutes': 5,
        'key_verse': {
          'reference': '2 Pedro 1:19',
          'text': 'Tenemos también la palabra profética más segura',
        },
        'cards': [
          {
            'order': 1,
            'type': 'natural_revelation',
            'icon': '🔭',
            'title': 'El Testimonio de la Creación',
            'content': 'Venus es conocido como el Lucero del Alba',
            'revelation_key': 'Venus refleja la gloria del Sol',
          },
          {
            'order': 2,
            'type': 'discovery_activation',
            'title': 'Descubrimiento Personal',
            'discovery_questions': [
              {
                'category': 'Situación',
                'question': '¿En qué área sientes oscuridad?',
              },
            ],
            'prayer': {
              'title': 'Oración de Sellado',
              'content': 'Señor Jesús, mi Logos...',
            },
          },
        ],
        'tags': ['luz', 'esperanza', 'cristo'],
        'metadata': {
          'total_word_count': 850,
        },
      };

      final devotional = DiscoveryDevotional.fromJson(json);

      // Verify basic fields
      expect(devotional.id, equals('morning_star_001'));
      expect(devotional.reflexion, equals('El Heraldo de la Luz'));
      expect(devotional.subtitle, equals('La conexión eterna'));
      expect(devotional.estimatedReadingMinutes, equals(5));
      expect(devotional.language, equals('es'));
      expect(devotional.version, equals('RVR1960'));

      // Verify key verse
      expect(devotional.keyVerse, isNotNull);
      expect(devotional.keyVerse!.reference, equals('2 Pedro 1:19'));
      expect(devotional.keyVerse!.text, contains('palabra profética'));

      // Verify cards
      expect(devotional.cards, hasLength(2));
      expect(devotional.cards[0].type, equals('natural_revelation'));
      expect(devotional.cards[0].icon, equals('🔭'));
      expect(devotional.cards[1].type, equals('discovery_activation'));
      expect(devotional.cards[1].prayer, isNotNull);

      // Verify prayer extraction
      expect(devotional.oracion, equals('Señor Jesús, mi Logos...'));

      // Verify metadata
      expect(devotional.metadata, isNotNull);
      expect(devotional.metadata!['total_word_count'], equals(850));

      // Verify tags
      expect(devotional.tags, hasLength(3));
      expect(devotional.tags, contains('luz'));

      // Verify counts work with new format
      expect(devotional.totalSections, equals(2));
      expect(devotional.totalQuestions, equals(1));
    });

    test('should maintain backward compatibility with old secciones format',
        () {
      final json = {
        'id': 'old-format-001',
        'fecha': '2026-01-15',
        'titulo': 'Old Format Study',
        'versiculo_clave': 'Juan 1:1',
        'secciones': [
          {
            'tipo': 'natural',
            'titulo': 'Old Section',
            'contenido': 'Old content',
          },
        ],
        'preguntas_discovery': ['¿Pregunta antigua?'],
        'oracion': 'Oración antigua',
      };

      final devotional = DiscoveryDevotional.fromJson(json);

      // Should parse as old format
      expect(devotional.cards, isEmpty);
      expect(devotional.secciones, hasLength(1));
      expect(devotional.secciones![0].tipo, equals('natural'));
      expect(devotional.preguntasDiscovery, hasLength(1));
      expect(devotional.versiculoClave, equals('Juan 1:1'));
      expect(devotional.oracion, equals('Oración antigua'));
    });

    test('should serialize new format to JSON correctly', () {
      final devotional = DiscoveryDevotional(
        id: 'test-new-001',
        versiculo: 'Test verse',
        reflexion: 'Test Title',
        paraMeditar: [],
        oracion: 'Test prayer',
        date: DateTime(2026, 1, 15),
        subtitle: 'Test Subtitle',
        estimatedReadingMinutes: 5,
        keyVerse: KeyVerse(
          reference: 'Juan 1:1',
          text: 'En el principio',
        ),
        cards: [
          DiscoveryCard(
            order: 1,
            type: 'natural_revelation',
            title: 'Test Card',
          ),
        ],
        metadata: {'test': true},
        tags: ['test'],
      );

      final json = devotional.toJson();

      expect(json['type'], equals('discovery'));
      expect(json['title'], equals('Test Title'));
      expect(json['subtitle'], equals('Test Subtitle'));
      expect(json['estimated_reading_minutes'], equals(5));
      expect(json['key_verse'], isNotNull);
      expect(json['cards'], hasLength(1));
      expect(json['metadata'], isNotNull);
    });

    test('copyWith should work with new fields', () {
      final original = DiscoveryDevotional(
        id: 'original',
        versiculo: 'Original',
        reflexion: 'Original',
        paraMeditar: [],
        oracion: 'Original',
        date: DateTime(2026, 1, 1),
        cards: [],
        subtitle: 'Original Subtitle',
        estimatedReadingMinutes: 3,
      );

      final updated = original.copyWith(
        subtitle: 'Updated Subtitle',
        estimatedReadingMinutes: 5,
      );

      expect(updated.subtitle, equals('Updated Subtitle'));
      expect(updated.estimatedReadingMinutes, equals(5));
      expect(updated.reflexion, equals('Original')); // unchanged
    });

    test('should parse key_verse field when present in new format', () {
      // Example from the problem statement: ascension_victory_001
      final json = {
        'id': 'ascension_victory_001',
        'type': 'discovery',
        'date': '2026-01-30',
        'title': 'La Ascensión Victoriosa',
        'subtitle': 'Cuando el Rey conquista el trono y envía el Espíritu',
        'language': 'es',
        'version': 'RVR1960',
        'estimated_reading_minutes': 7,
        'key_verse': {
          'reference': 'Hechos 1:9',
          'text':
              'Y habiendo dicho estas cosas, viéndolo ellos, fue alzado, y le recibió una nube que le ocultó de sus ojos.',
        },
        'cards': [
          {
            'order': 1,
            'type': 'natural_revelation',
            'title': 'Test Card',
          },
        ],
      };

      final devotional = DiscoveryDevotional.fromJson(json);

      // Verify key verse is parsed
      expect(devotional.keyVerse, isNotNull);
      expect(devotional.keyVerse!.reference, equals('Hechos 1:9'));
      expect(devotional.keyVerse!.text, contains('fue alzado'));

      // Verify other fields
      expect(devotional.id, equals('ascension_victory_001'));
      expect(devotional.reflexion, equals('La Ascensión Victoriosa'));
      expect(devotional.subtitle,
          equals('Cuando el Rey conquista el trono y envía el Espíritu'));
      expect(devotional.estimatedReadingMinutes, equals(7));
      expect(devotional.cards, hasLength(1));
    });

    test('should serialize and access key_verse correctly', () {
      // Verifies key verse is accessible and properly serialized
      final devotional = DiscoveryDevotional(
        id: 'test-001',
        versiculo: '',
        reflexion: 'Test Study',
        paraMeditar: [],
        oracion: 'Test prayer',
        date: DateTime(2026, 1, 30),
        keyVerse: KeyVerse(
          reference: 'Juan 3:16',
          text: 'Porque de tal manera amó Dios al mundo...',
        ),
        cards: [
          DiscoveryCard(
            order: 1,
            type: 'natural_revelation',
            title: 'Test',
          ),
        ],
      );

      // Verify key verse is accessible for model usage
      expect(devotional.keyVerse, isNotNull);
      expect(devotional.keyVerse!.reference, isNotEmpty);
      expect(devotional.keyVerse!.text, isNotEmpty);

      // Should be part of serialization
      final json = devotional.toJson();
      expect(json['key_verse'], isNotNull);
      expect(json['key_verse']['reference'], equals('Juan 3:16'));
    });
  });
}
