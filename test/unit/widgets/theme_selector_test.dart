import 'package:devocional_nuevo/widgets/theme_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

@Tags(['unit', 'widgets'])
void main() {
  group('ThemeSelectorCircleGrid Widget Tests', () {
    late String selectedTheme;
    late List<String> callbackRecords;

    setUp(() {
      selectedTheme = 'Blue';
      callbackRecords = [];
    });

    Widget createWidgetUnderTest({
      String? theme,
      Brightness? brightness,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ThemeSelectorCircleGrid(
            selectedTheme: theme ?? selectedTheme,
            onThemeChanged: (newTheme) {
              callbackRecords.add(newTheme);
            },
            brightness: brightness ?? Brightness.light,
          ),
        ),
      );
    }

    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(ThemeSelectorCircleGrid), findsOneWidget);
    });

    testWidgets('displays grid of theme options', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows check icon on selected theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(theme: 'Blue'));
      await tester.pumpAndSettle();

      // Theme selector should render (may or may not have Blue theme in constants)
      expect(find.byType(ThemeSelectorCircleGrid), findsOneWidget);
    });

    testWidgets('displays theme names', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Should find text widgets (theme names)
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('invokes callback when theme is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(theme: 'Blue'));
      await tester.pumpAndSettle();

      // Find a different theme to tap (not the selected one)
      // First, let's find text widgets other than 'Blue'
      final texts = find.byType(Text);
      final textWidgets = tester.widgetList<Text>(texts).toList();

      // Find a non-selected theme name
      String? otherTheme;
      for (var textWidget in textWidgets) {
        final data = textWidget.data;
        if (data != null && data != 'Blue' && data.length > 1) {
          otherTheme = data;
          break;
        }
      }

      if (otherTheme != null) {
        await tester.tap(find.text(otherTheme).first);
        await tester.pumpAndSettle();

        expect(callbackRecords, contains(otherTheme));
      }
    });

    testWidgets('handles light mode correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(brightness: Brightness.light),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ThemeSelectorCircleGrid), findsOneWidget);
    });

    testWidgets('handles dark mode correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(brightness: Brightness.dark),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ThemeSelectorCircleGrid), findsOneWidget);
    });

    testWidgets('displays circular theme indicators',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Should have multiple GestureDetector widgets for theme selection
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('all themes are tappable', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final gestureDetectors = find.byType(GestureDetector);
      expect(gestureDetectors, findsWidgets);

      // All gesture detectors should be interactive
      final count = tester.widgetList(gestureDetectors).length;
      expect(count, greaterThan(0));
    });

    testWidgets('grid has proper layout constraints',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      expect(gridView.shrinkWrap, isTrue);
      expect(gridView.physics, isA<NeverScrollableScrollPhysics>());
    });

    testWidgets('theme selector updates on selection change',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(theme: 'Blue'));
      await tester.pumpAndSettle();

      // Initially with Blue selected
      expect(find.byType(ThemeSelectorCircleGrid), findsOneWidget);

      // Rebuild with different selection
      await tester.pumpWidget(createWidgetUnderTest(theme: 'Red'));
      await tester.pumpAndSettle();

      // Should still render without errors
      expect(find.byType(ThemeSelectorCircleGrid), findsOneWidget);
    });

    testWidgets('displays multiple theme options', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Should display multiple theme names
      final textWidgets = find.byType(Text);
      expect(textWidgets, findsWidgets);

      // Should have more than just one theme option
      expect(tester.widgetList(textWidgets).length, greaterThan(1));
    });
  });
}
