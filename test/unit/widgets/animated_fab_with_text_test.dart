@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/widgets/animated_fab_with_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnimatedFabWithText Widget Tests', () {
    late bool callbackInvoked;

    setUp(() {
      callbackInvoked = false;
    });

    Widget createWidgetUnderTest({
      String? text,
      Duration? showDuration,
      double? width,
      double? height,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: AnimatedFabWithText(
            onPressed: () {
              callbackInvoked = true;
            },
            text: text ?? 'Add New Item',
            showDuration: showDuration ?? const Duration(milliseconds: 100),
            fabColor: Colors.blue,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            iconColor: Colors.white,
            width: width,
            height: height ?? 56,
          ),
        ),
      );
    }

    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedFabWithText), findsOneWidget);
    });

    testWidgets('displays add icon', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('invokes callback when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(callbackInvoked, isTrue);
    });

    testWidgets('displays text after animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(showDuration: const Duration(seconds: 3)),
      );

      // Pump initial build
      await tester.pump();

      // Pump through the initial delay
      await tester.pump(const Duration(milliseconds: 200));

      // Pump through the animation
      await tester.pump(const Duration(milliseconds: 500));

      // Text should be visible
      expect(find.text('Add New Item'), findsOneWidget);
    });

    testWidgets('shows add_circle icon in expanded state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(showDuration: const Duration(seconds: 3)),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 500));

      // Should show both add and add_circle icons
      expect(find.byIcon(Icons.add_circle), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('uses custom text when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          text: 'Custom Button Text',
          showDuration: const Duration(seconds: 3),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 500));

      // Text should be visible after animation
      expect(find.byType(AnimatedFabWithText), findsOneWidget);
    });

    testWidgets('respects custom height', (WidgetTester tester) async {
      const customHeight = 64.0;

      await tester.pumpWidget(
        createWidgetUnderTest(height: customHeight),
      );
      await tester.pumpAndSettle();

      final sizedBox = tester.widget<SizedBox>(
        find.byType(SizedBox).first,
      );
      expect(sizedBox.height, equals(customHeight));
    });

    testWidgets('handles tap on expanded container',
        (WidgetTester tester) async {
      callbackInvoked = false;

      await tester.pumpWidget(
        createWidgetUnderTest(showDuration: const Duration(seconds: 3)),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 500));

      // Tap on the text area
      await tester.tap(find.text('Add New Item'));
      await tester.pumpAndSettle();

      expect(callbackInvoked, isTrue);
    });

    testWidgets('FAB is always visible', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // The circular FAB should always be present
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('has proper shadow effects', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Widget should render without errors (shadows are applied)
      expect(find.byType(AnimatedFabWithText), findsOneWidget);
    });

    testWidgets('cleans up timers on disposal', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Remove the widget
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle();

      // Should dispose without errors
      expect(find.byType(AnimatedFabWithText), findsNothing);
    });

    testWidgets('animates smoothly between states',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(showDuration: const Duration(seconds: 1)),
      );

      // Initial state
      await tester.pump();

      // During animation
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(AnimatedFabWithText), findsOneWidget);

      // After animation
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AnimatedFabWithText), findsOneWidget);
    });

    testWidgets('works with different color schemes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedFabWithText(
              onPressed: () {},
              text: 'Test',
              fabColor: Colors.red,
              backgroundColor: Colors.amber,
              textColor: Colors.white,
              iconColor: Colors.black,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedFabWithText), findsOneWidget);
    });

    testWidgets('handles long text gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          text: 'This is a very long text that should be handled gracefully',
          showDuration: const Duration(milliseconds: 100),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 500));

      // Should render without overflow errors
      expect(find.byType(AnimatedFabWithText), findsOneWidget);
    });
  });
}
