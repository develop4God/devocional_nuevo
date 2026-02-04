import 'package:devocional_nuevo/models/discovery_section_model.dart';
import 'package:devocional_nuevo/widgets/discovery_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

@Tags(['unit', 'widgets'])
void main() {
  group('DiscoverySectionCard Widget Tests', () {
    late DiscoverySection testSection;

    setUp(() {
      testSection = DiscoverySection(
        tipo: 'natural',
        titulo: 'Test Title',
        contenido: 'Test content for the section',
        icono: '📖',
        pasajes: null,
      );
    });

    Widget createWidgetUnderTest({
      DiscoverySection? section,
      String? studyId,
      int? sectionIndex,
      bool isDark = false,
      String? versiculoClave,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: DiscoverySectionCard(
            section: section ?? testSection,
            studyId: studyId ?? 'test_study_id',
            sectionIndex: sectionIndex ?? 0,
            isDark: isDark,
            versiculoClave: versiculoClave,
          ),
        ),
      );
    }

    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(DiscoverySectionCard), findsOneWidget);
    });

    testWidgets('displays section title when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('displays section content when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Test content for the section'), findsOneWidget);
    });

    testWidgets('displays section icon when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('📖'), findsOneWidget);
    });

    testWidgets('displays versiculo clave when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(versiculoClave: 'John 3:16'),
      );
      await tester.pumpAndSettle();

      expect(find.text('John 3:16'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
    });

    testWidgets('hides versiculo clave when not provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Versiculo clave section should not be visible
      expect(find.byIcon(Icons.menu_book), findsNothing);
    });

    testWidgets('handles section without title', (WidgetTester tester) async {
      final sectionNoTitle = DiscoverySection(
        tipo: 'natural',
        titulo: null,
        contenido: 'Content only',
        icono: null,
        pasajes: null,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(section: sectionNoTitle),
      );
      await tester.pumpAndSettle();

      expect(find.text('Content only'), findsOneWidget);
    });

    testWidgets('handles section without icon', (WidgetTester tester) async {
      final sectionNoIcon = DiscoverySection(
        tipo: 'natural',
        titulo: 'Title only',
        contenido: 'Content',
        icono: null,
        pasajes: null,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(section: sectionNoIcon),
      );
      await tester.pumpAndSettle();

      expect(find.text('Title only'), findsOneWidget);
    });

    testWidgets('displays scripture passages when provided',
        (WidgetTester tester) async {
      final sectionWithPassage = DiscoverySection(
        tipo: 'scripture',
        titulo: 'Scripture Section',
        contenido: null,
        icono: null,
        pasajes: [
          ScripturePassage(
            referencia: 'John 3:16',
            texto: 'For God so loved the world...',
            aplicacion: 'Application text',
          ),
        ],
      );

      await tester.pumpWidget(
        createWidgetUnderTest(section: sectionWithPassage),
      );
      await tester.pumpAndSettle();

      expect(find.text('John 3:16'), findsOneWidget);
      expect(find.text('For God so loved the world...'), findsOneWidget);
      expect(find.text('Application text'), findsOneWidget);
    });

    testWidgets('displays multiple scripture passages',
        (WidgetTester tester) async {
      final sectionWithPassages = DiscoverySection(
        tipo: 'scripture',
        titulo: 'Multiple Passages',
        contenido: null,
        icono: null,
        pasajes: [
          ScripturePassage(
            referencia: 'John 3:16',
            texto: 'For God so loved...',
            aplicacion: null,
          ),
          ScripturePassage(
            referencia: 'Romans 8:28',
            texto: 'All things work together...',
            aplicacion: 'Trust in God',
          ),
        ],
      );

      await tester.pumpWidget(
        createWidgetUnderTest(section: sectionWithPassages),
      );
      await tester.pumpAndSettle();

      expect(find.text('John 3:16'), findsOneWidget);
      expect(find.text('Romans 8:28'), findsOneWidget);
      expect(find.text('For God so loved...'), findsOneWidget);
      expect(find.text('All things work together...'), findsOneWidget);
      expect(find.text('Trust in God'), findsOneWidget);
    });

    testWidgets('is scrollable for long content', (WidgetTester tester) async {
      final longContent = 'Lorem ipsum ' * 100;
      final sectionLongContent = DiscoverySection(
        tipo: 'natural',
        titulo: 'Long Section',
        contenido: longContent,
        icono: null,
        pasajes: null,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(section: sectionLongContent),
      );
      await tester.pumpAndSettle();

      // Should have a SingleChildScrollView
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('renders correctly in dark mode', (WidgetTester tester) async {
      final sectionWithPassage = DiscoverySection(
        tipo: 'scripture',
        titulo: 'Dark Mode Test',
        contenido: null,
        icono: null,
        pasajes: [
          ScripturePassage(
            referencia: 'Psalm 23:1',
            texto: 'The Lord is my shepherd',
            aplicacion: null,
          ),
        ],
      );

      await tester.pumpWidget(
        createWidgetUnderTest(section: sectionWithPassage, isDark: true),
      );
      await tester.pumpAndSettle();

      // Widget should render without errors in dark mode
      expect(find.byType(DiscoverySectionCard), findsOneWidget);
      expect(find.text('Psalm 23:1'), findsOneWidget);
    });

    testWidgets('handles empty passage list', (WidgetTester tester) async {
      final sectionEmptyPassages = DiscoverySection(
        tipo: 'scripture',
        titulo: 'No Passages',
        contenido: 'Some content',
        icono: null,
        pasajes: [],
      );

      await tester.pumpWidget(
        createWidgetUnderTest(section: sectionEmptyPassages),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Passages'), findsOneWidget);
      expect(find.text('Some content'), findsOneWidget);
    });
  });
}
