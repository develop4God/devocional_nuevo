import 'package:devocional_nuevo/models/discovery_section_model.dart';
import 'package:flutter_test/flutter_test.dart';

@Tags(['unit', 'models'])
void main() {
  group('DiscoverySection Model Tests', () {
    test('should create natural section with required fields', () {
      final section = DiscoverySection(
        tipo: 'natural',
        icono: '🔭',
        titulo: 'El Heraldo de la Luz',
        contenido: 'Venus, conocido como la "Estrella de la Mañana"...',
      );

      expect(section.tipo, equals('natural'));
      expect(section.icono, equals('🔭'));
      expect(section.titulo, equals('El Heraldo de la Luz'));
      expect(section.contenido, isNotEmpty);
      expect(section.isNatural, isTrue);
      expect(section.isScripture, isFalse);
    });

    test('should create scripture section with passages', () {
      final passage = ScripturePassage(
        referencia: 'Apocalipsis 22:16',
        texto: 'Yo soy la raíz y el linaje de David...',
        aplicacion: 'Cristo es nuestra esperanza...',
      );

      final section = DiscoverySection(
        tipo: 'scripture',
        pasajes: [passage],
      );

      expect(section.tipo, equals('scripture'));
      expect(section.isScripture, isTrue);
      expect(section.isNatural, isFalse);
      expect(section.pasajes, hasLength(1));
      expect(section.pasajes!.first.referencia, equals('Apocalipsis 22:16'));
    });

    test('should serialize and deserialize natural section correctly', () {
      final section = DiscoverySection(
        tipo: 'natural',
        icono: '🌟',
        titulo: 'Test Section',
        contenido: 'Test content',
      );

      final json = section.toJson();
      final sectionFromJson = DiscoverySection.fromJson(json);

      expect(sectionFromJson.tipo, equals(section.tipo));
      expect(sectionFromJson.icono, equals(section.icono));
      expect(sectionFromJson.titulo, equals(section.titulo));
      expect(sectionFromJson.contenido, equals(section.contenido));
    });

    test('should serialize and deserialize scripture section correctly', () {
      final passage = ScripturePassage(
        referencia: 'Juan 3:16',
        texto: 'Porque de tal manera amó Dios al mundo...',
        aplicacion: 'El amor de Dios es incondicional',
      );

      final section = DiscoverySection(
        tipo: 'scripture',
        pasajes: [passage],
      );

      final json = section.toJson();
      final sectionFromJson = DiscoverySection.fromJson(json);

      expect(sectionFromJson.tipo, equals('scripture'));
      expect(sectionFromJson.pasajes, hasLength(1));
      expect(sectionFromJson.pasajes!.first.referencia, equals('Juan 3:16'));
      expect(sectionFromJson.pasajes!.first.texto, isNotEmpty);
      expect(sectionFromJson.pasajes!.first.aplicacion, isNotEmpty);
    });
  });

  group('ScripturePassage Model Tests', () {
    test('should create passage with required fields', () {
      final passage = ScripturePassage(
        referencia: 'Mateo 5:14',
        texto: 'Vosotros sois la luz del mundo...',
      );

      expect(passage.referencia, equals('Mateo 5:14'));
      expect(passage.texto, isNotEmpty);
      expect(passage.aplicacion, isNull);
    });

    test('should serialize and deserialize passage correctly', () {
      final passage = ScripturePassage(
        referencia: 'Salmo 23:1',
        texto: 'El Señor es mi pastor...',
        aplicacion: 'Dios cuida de nosotros',
      );

      final json = passage.toJson();
      final passageFromJson = ScripturePassage.fromJson(json);

      expect(passageFromJson.referencia, equals(passage.referencia));
      expect(passageFromJson.texto, equals(passage.texto));
      expect(passageFromJson.aplicacion, equals(passage.aplicacion));
    });

    test('should handle missing aplicacion field', () {
      final json = {
        'referencia': 'Romanos 8:28',
        'texto': 'Y sabemos que a los que aman a Dios...',
      };

      final passage = ScripturePassage.fromJson(json);

      expect(passage.referencia, equals('Romanos 8:28'));
      expect(passage.texto, isNotEmpty);
      expect(passage.aplicacion, isNull);
    });
  });
}
