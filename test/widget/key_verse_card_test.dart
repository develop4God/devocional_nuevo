import 'package:devocional_nuevo/models/discovery_card_model.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/key_verse_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    setupServiceLocator();
  });
  group('KeyVerseCard Widget Tests', () {
    testWidgets('should display key verse reference and text',
        (WidgetTester tester) async {
      // Arrange
      final keyVerse = KeyVerse(
        reference: 'Hechos 1:9',
        text:
            'Y habiendo dicho estas cosas, viéndolo ellos, fue alzado, y le recibió una nube que le ocultó de sus ojos.',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyVerseCard(keyVerse: keyVerse),
          ),
        ),
      );

      // Assert
      expect(find.text('VERSÍCULO CLAVE'), findsOneWidget);
      expect(find.text('Hechos 1:9'), findsOneWidget);
      expect(find.textContaining('fue alzado'), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
    });

    testWidgets('should display formatted verse text with quotes',
        (WidgetTester tester) async {
      // Arrange
      final keyVerse = KeyVerse(
        reference: 'Juan 3:16',
        text: 'Porque de tal manera amó Dios al mundo...',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyVerseCard(keyVerse: keyVerse),
          ),
        ),
      );

      // Assert - text should be wrapped in quotes
      expect(find.textContaining('"'), findsWidgets);
      expect(find.textContaining('Porque de tal manera'), findsOneWidget);
    });

    testWidgets('should have proper styling and layout',
        (WidgetTester tester) async {
      // Arrange
      final keyVerse = KeyVerse(
        reference: '2 Pedro 1:19',
        text: 'Tenemos también la palabra profética más segura',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyVerseCard(keyVerse: keyVerse),
          ),
        ),
      );

      // Assert - find containers and verify structure
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Icon), findsOneWidget);
      expect(find.text('2 Pedro 1:19'), findsOneWidget);
    });

    testWidgets('should render in dark mode', (WidgetTester tester) async {
      // Arrange
      final keyVerse = KeyVerse(
        reference: 'Mateo 5:16',
        text: 'Así alumbre vuestra luz delante de los hombres',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: KeyVerseCard(keyVerse: keyVerse),
          ),
        ),
      );

      // Assert - should render without errors
      expect(find.text('VERSÍCULO CLAVE'), findsOneWidget);
      expect(find.text('Mateo 5:16'), findsOneWidget);
    });

    testWidgets('should handle long verse text', (WidgetTester tester) async {
      // Arrange
      final keyVerse = KeyVerse(
        reference: 'Juan 1:1-3',
        text:
            'En el principio era el Verbo, y el Verbo era con Dios, y el Verbo era Dios. Este era en el principio con Dios. Todas las cosas por él fueron hechas, y sin él nada de lo que ha sido hecho, fue hecho.',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KeyVerseCard(keyVerse: keyVerse),
            ),
          ),
        ),
      );

      // Assert - should render without overflow
      expect(find.text('Juan 1:1-3'), findsOneWidget);
      expect(find.textContaining('En el principio'), findsOneWidget);
    });
  });
}
