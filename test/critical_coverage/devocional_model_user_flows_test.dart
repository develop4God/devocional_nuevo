// test/critical_coverage/devocional_model_user_flows_test.dart
// High-value user behavior tests for Devocional model

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Devocional Model - User Behavior Tests', () {
    // SCENARIO 1: User loads devocional from API response
    test('parses complete devocional from JSON', () {
      final json = {
        'id': 'dev-2025-01-15',
        'versiculo':
            'Porque de tal manera amó Dios al mundo - Juan 3:16 (RVR1960)',
        'reflexion':
            'Este versículo nos recuerda el amor infinito de Dios por nosotros.',
        'para_meditar': [
          {'cita': 'Juan 3:16', 'texto': '¿Cómo experimentas el amor de Dios?'},
          {'cita': 'Juan 3:17', 'texto': '¿Cómo respondes a este amor?'},
        ],
        'oracion':
            'Señor, gracias por tu amor infinito. Ayúdame a compartirlo.',
        'date': '2025-01-15',
        'version': 'RVR1960',
        'language': 'es',
        'tags': ['amor', 'salvacion', 'gracia'],
      };

      final devocional = Devocional.fromJson(json);

      expect(devocional.id, equals('dev-2025-01-15'));
      expect(devocional.versiculo, contains('Juan 3:16'));
      expect(devocional.reflexion, contains('amor infinito'));
      expect(devocional.paraMeditar.length, equals(2));
      expect(devocional.oracion, contains('Señor'));
      expect(devocional.date, equals(DateTime(2025, 1, 15)));
      expect(devocional.version, equals('RVR1960'));
      expect(devocional.language, equals('es'));
      expect(devocional.tags, contains('amor'));
    });

    // SCENARIO 2: User saves devocional as favorite
    test('devocional serializes to JSON for favorites storage', () {
      final devocional = Devocional(
        id: 'fav-001',
        versiculo: 'Salmo 23:1 - El Señor es mi pastor',
        reflexion: 'Dios cuida de nosotros como un buen pastor.',
        paraMeditar: [
          ParaMeditar(
            cita: 'Salmo 23:1',
            texto: '¿En qué áreas necesitas el cuidado de Dios?',
          ),
        ],
        oracion: 'Señor, sé mi pastor hoy.',
        date: DateTime(2025, 1, 15),
        version: 'NVI',
        language: 'es',
        tags: ['confianza', 'provision'],
      );

      final json = devocional.toJson();

      expect(json['id'], equals('fav-001'));
      expect(json['versiculo'], contains('Salmo 23:1'));
      expect(json['para_meditar'], isA<List>());
      expect((json['para_meditar'] as List).length, equals(1));
      expect(json['version'], equals('NVI'));
      expect(json['tags'], contains('confianza'));
    });

    // SCENARIO 3: Handle incomplete JSON from API
    test('handles missing optional fields gracefully', () {
      final minimalJson = {
        'id': 'minimal-001',
        'versiculo': 'Test verse',
        'reflexion': 'Test reflection',
        'oracion': 'Test prayer',
        // Missing: para_meditar, date, version, language, tags
      };

      final devocional = Devocional.fromJson(minimalJson);

      expect(devocional.id, equals('minimal-001'));
      expect(devocional.paraMeditar, isEmpty);
      expect(devocional.version, isNull);
      expect(devocional.language, isNull);
      expect(devocional.tags, isNull);
      expect(devocional.date.year, equals(DateTime.now().year));
    });

    // SCENARIO 4: Handle malformed date in JSON
    test('handles invalid date format gracefully', () {
      final badDateJson = {
        'id': 'bad-date',
        'versiculo': 'Test',
        'reflexion': 'Test',
        'oracion': 'Test',
        'date': 'not-a-valid-date',
      };

      final devocional = Devocional.fromJson(badDateJson);

      // Should fallback to current date
      expect(devocional.date.year, equals(DateTime.now().year));
    });

    // SCENARIO 5: JSON round-trip preserves data
    test('survives JSON serialization round-trip', () {
      final original = Devocional(
        id: 'roundtrip-001',
        versiculo: 'Test: ñ, é, 日本語',
        reflexion: 'Reflexión con acentos',
        paraMeditar: [ParaMeditar(cita: 'Test cita', texto: 'Texto con ñ')],
        oracion: 'Oración especial',
        date: DateTime(2025, 6, 15),
        version: 'RVR1960',
        language: 'es',
        tags: ['test', 'unicode'],
      );

      final json = original.toJson();
      final restored = Devocional.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.versiculo, equals(original.versiculo));
      expect(restored.reflexion, equals(original.reflexion));
      expect(restored.paraMeditar.length, equals(original.paraMeditar.length));
      expect(restored.oracion, equals(original.oracion));
      expect(restored.version, equals(original.version));
      expect(restored.language, equals(original.language));
    });

    // SCENARIO 6: Handle empty para_meditar list
    test('handles empty para_meditar list', () {
      final json = {
        'id': 'empty-meditar',
        'versiculo': 'Test',
        'reflexion': 'Test',
        'oracion': 'Test',
        'para_meditar': [],
      };

      final devocional = Devocional.fromJson(json);

      expect(devocional.paraMeditar, isEmpty);
    });

    // SCENARIO 7: Handle null para_meditar
    test('handles null para_meditar', () {
      final json = {
        'id': 'null-meditar',
        'versiculo': 'Test',
        'reflexion': 'Test',
        'oracion': 'Test',
        'para_meditar': null,
      };

      final devocional = Devocional.fromJson(json);

      expect(devocional.paraMeditar, isEmpty);
    });
  });

  group('ParaMeditar Model Tests', () {
    test('parses ParaMeditar from JSON', () {
      final json = {'cita': 'Juan 3:16', 'texto': '¿Qué significa para ti?'};

      final paraMeditar = ParaMeditar.fromJson(json);

      expect(paraMeditar.cita, equals('Juan 3:16'));
      expect(paraMeditar.texto, equals('¿Qué significa para ti?'));
    });

    test('serializes ParaMeditar to JSON', () {
      final paraMeditar = ParaMeditar(cita: 'Test cita', texto: 'Test texto');

      final json = paraMeditar.toJson();

      expect(json['cita'], equals('Test cita'));
      expect(json['texto'], equals('Test texto'));
    });

    test('handles missing fields in ParaMeditar', () {
      final emptyJson = <String, dynamic>{};

      final paraMeditar = ParaMeditar.fromJson(emptyJson);

      expect(paraMeditar.cita, equals(''));
      expect(paraMeditar.texto, equals(''));
    });
  });

  group('Devocional Sorting & Filtering - User Flows', () {
    late List<Devocional> devocionales;

    setUp(() {
      devocionales = [
        Devocional(
          id: 'dev-1',
          versiculo: 'Verso 1',
          reflexion: 'Reflexión sobre el amor',
          paraMeditar: [],
          oracion: 'Oración 1',
          date: DateTime(2025, 1, 15),
          language: 'es',
          tags: ['amor', 'fe'],
        ),
        Devocional(
          id: 'dev-2',
          versiculo: 'Verse 2',
          reflexion: 'Reflection on hope',
          paraMeditar: [],
          oracion: 'Prayer 2',
          date: DateTime(2025, 1, 16),
          language: 'en',
          tags: ['hope', 'faith'],
        ),
        Devocional(
          id: 'dev-3',
          versiculo: 'Verso 3',
          reflexion: 'Reflexión sobre la paz',
          paraMeditar: [],
          oracion: 'Oración 3',
          date: DateTime(2025, 1, 14),
          language: 'es',
          tags: ['paz', 'amor'],
        ),
      ];
    });

    test('user sorts devocionales by date (newest first)', () {
      final sorted = List<Devocional>.from(devocionales)
        ..sort((a, b) => b.date.compareTo(a.date));

      expect(sorted.first.id, equals('dev-2'));
      expect(sorted.last.id, equals('dev-3'));
    });

    test('user filters devocionales by language', () {
      final spanishDevocionales =
          devocionales.where((d) => d.language == 'es').toList();

      expect(spanishDevocionales.length, equals(2));
    });

    test('user searches devocionales by content', () {
      final searchResults = devocionales
          .where(
            (d) => d.reflexion.toLowerCase().contains('amor'.toLowerCase()),
          )
          .toList();

      expect(searchResults.length, equals(1));
      expect(searchResults.first.id, equals('dev-1'));
    });

    test('user filters devocionales by tag', () {
      final amorDevocionales =
          devocionales.where((d) => d.tags?.contains('amor') ?? false).toList();

      expect(amorDevocionales.length, equals(2));
    });

    test('user finds devocional by specific date', () {
      final targetDate = DateTime(2025, 1, 15);
      final found = devocionales.firstWhere(
        (d) =>
            d.date.year == targetDate.year &&
            d.date.month == targetDate.month &&
            d.date.day == targetDate.day,
        orElse: () => devocionales.first,
      );

      expect(found.id, equals('dev-1'));
    });

    test('user groups devocionales by month', () {
      final extendedList = [
        ...devocionales,
        Devocional(
          id: 'dev-4',
          versiculo: 'Test',
          reflexion: 'Test',
          paraMeditar: [],
          oracion: 'Test',
          date: DateTime(2025, 2, 1),
        ),
      ];

      final byMonth = <String, List<Devocional>>{};
      for (final d in extendedList) {
        final key = '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}';
        byMonth.putIfAbsent(key, () => []).add(d);
      }

      expect(byMonth['2025-01']?.length, equals(3));
      expect(byMonth['2025-02']?.length, equals(1));
    });
  });

  group('Devocional Edge Cases', () {
    test('handles very long content', () {
      final longReflexion = 'Reflexión ' * 500;
      final devocional = Devocional(
        id: 'long',
        versiculo: 'Test verse ' * 10,
        reflexion: longReflexion,
        paraMeditar: List.generate(
          10,
          (i) => ParaMeditar(cita: 'Cita $i', texto: 'Texto largo ' * 50),
        ),
        oracion: 'Oración ' * 100,
        date: DateTime.now(),
      );

      final json = devocional.toJson();
      final restored = Devocional.fromJson(json);

      expect(restored.reflexion.length, equals(longReflexion.length));
      expect(restored.paraMeditar.length, equals(10));
    });

    test('handles special characters in all fields', () {
      final devocional = Devocional(
        id: 'special-chars',
        versiculo: 'Verso con "comillas" y \'apóstrofes\'',
        reflexion: 'Reflexión\ncon\nnuevas líneas\ty\ttabs',
        paraMeditar: [
          ParaMeditar(
            cita: 'Cita con @#\$% símbolos',
            texto: 'Texto con 日本語 unicode',
          ),
        ],
        oracion: 'Oración con emojis 🙏✝️📖',
        date: DateTime.now(),
        tags: ['tag-with-dash', 'tag_with_underscore'],
      );

      final json = devocional.toJson();
      final restored = Devocional.fromJson(json);

      expect(restored.versiculo, contains('"comillas"'));
      expect(restored.reflexion, contains('\n'));
      expect(restored.paraMeditar.first.texto, contains('日本語'));
      expect(restored.oracion, contains('🙏'));
    });

    test('handles date at year boundaries', () {
      final newYearsEve = Devocional(
        id: 'nye',
        versiculo: 'Test',
        reflexion: 'Test',
        paraMeditar: [],
        oracion: 'Test',
        date: DateTime(2024, 12, 31),
      );

      final newYearsDay = Devocional(
        id: 'nyd',
        versiculo: 'Test',
        reflexion: 'Test',
        paraMeditar: [],
        oracion: 'Test',
        date: DateTime(2025, 1, 1),
      );

      expect(newYearsEve.date.year, equals(2024));
      expect(newYearsDay.date.year, equals(2025));

      // Test serialization
      final nyeJson = newYearsEve.toJson();
      final restoredNye = Devocional.fromJson(nyeJson);
      expect(restoredNye.date.year, equals(2024));
      expect(restoredNye.date.month, equals(12));
      expect(restoredNye.date.day, equals(31));
    });
  });
}
