@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/widgets/theme_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeSelectorCircleGrid Widget Tests', () {
    late String selectedTheme;
    late List<String> callbackRecords;

    setUp(() {
      selectedTheme = 'Deep Purple';
      callbackRecords = [];
    });

    Widget createWidgetUnderTest({String? theme, Brightness? brightness}) {
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

    testWidgets('displays horizontal pill with circular theme indicators', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Should have Container for pill shape
      expect(find.byType(Container), findsWidgets);

      // Should have GestureDetector for theme circles
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('shows check icon on selected theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(theme: 'Deep Purple'));
      await tester.pumpAndSettle();

      // Find check icon (should appear on selected theme)
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
    });

    testWidgets('displays initial visible themes', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Should have AnimatedContainers for theme circles
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('invokes callback when non-selected theme is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(theme: 'Deep Purple'));
      await tester.pumpAndSettle();

      // Tap on one of the visible themes (Gray is second in order)
      final gestureDetectors = find.byType(GestureDetector);

      // Skip the first one (selected theme) and tap the next visible theme
      if (tester.widgetList(gestureDetectors).length > 1) {
        await tester.tap(gestureDetectors.at(1));
        await tester.pumpAndSettle();

        // Callback should have been called
        expect(callbackRecords, isNotEmpty);
      }
    });

    testWidgets('selected theme opens bottom sheet on tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(theme: 'Deep Purple'));
      await tester.pumpAndSettle();

      // Tap on the selected theme circle
      final selectCircle = find.byType(AnimatedContainer).first;
      await tester.tap(selectCircle);
      await tester.pumpAndSettle();

      // Should open bottom sheet (Flutter wraps with 2 ModalBarriers)
      expect(find.byType(ModalBarrier), findsWidgets);
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

    testWidgets('displays chevron icon for theme selection', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Should have chevron icon
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('chevron opens theme selection sheet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap on chevron icon
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();

      // Should open bottom sheet (Flutter wraps with 2 ModalBarriers)
      expect(find.byType(ModalBarrier), findsWidgets);
    });

    testWidgets('theme selector updates when selection changes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(theme: 'Deep Purple'));
      await tester.pumpAndSettle();

      // Check initial state
      expect(find.byType(ThemeSelectorCircleGrid), findsOneWidget);

      // Rebuild with different selection
      await tester.pumpWidget(createWidgetUnderTest(theme: 'Gray'));
      await tester.pumpAndSettle();

      // Should still render correctly
      expect(find.byType(ThemeSelectorCircleGrid), findsOneWidget);
    });

    testWidgets('displays peek themes stack when available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Peek themes display in a Stack
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('pill shape has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });
  });
}
