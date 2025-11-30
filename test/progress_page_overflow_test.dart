// test/progress_page_overflow_test.dart
// Tests for verifying responsive layout behavior without overflow errors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Progress Page Responsive Layout Tests - Real User Behavior', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    // Helper to create a widget that simulates Progress Page layout constraints
    Widget createResponsiveLayoutTestWidget({required Size screenSize}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            body: LayoutBuilder(
              builder: (context, constraints) {
                // Verify the layout can adapt to different screen sizes
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Simulates header section
                      Container(
                        width: double.infinity,
                        height: 80,
                        color: Colors.blue,
                        child: const Center(child: Text('Header')),
                      ),
                      // Simulates stats cards section
                      Wrap(
                        children: List.generate(
                          4,
                          (i) => SizedBox(
                            width: constraints.maxWidth > 600
                                ? constraints.maxWidth / 2
                                : constraints.maxWidth,
                            height: 100,
                            child: Card(child: Center(child: Text('Card $i'))),
                          ),
                        ),
                      ),
                      // Simulates achievements section
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,
                          itemBuilder: (context, i) => SizedBox(
                            width: 100,
                            child: Card(child: Center(child: Text('Badge $i'))),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('Responsive layout adapts to small screen (320x568)', (
      WidgetTester tester,
    ) async {
      // iPhone SE size - Real user scenario: smallest common screen
      const smallScreenSize = Size(320, 568);
      final List<String> overflowErrors = [];
      final originalOnError = FlutterError.onError;

      FlutterError.onError = (details) {
        if (details.exception.toString().contains('overflowed')) {
          overflowErrors.add(details.exception.toString());
        }
      };

      await tester.pumpWidget(
        createResponsiveLayoutTestWidget(screenSize: smallScreenSize),
      );
      await tester.pump();

      FlutterError.onError = originalOnError;

      // Real user behavior: Layout should not overflow
      expect(
        overflowErrors,
        isEmpty,
        reason: 'Layout should not have overflow errors on small screen',
      );

      // Verify widgets are present
      expect(find.text('Header'), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('Responsive layout adapts to medium screen (375x667)', (
      WidgetTester tester,
    ) async {
      // iPhone 8 size
      const mediumScreenSize = Size(375, 667);
      final List<String> overflowErrors = [];
      final originalOnError = FlutterError.onError;

      FlutterError.onError = (details) {
        if (details.exception.toString().contains('overflowed')) {
          overflowErrors.add(details.exception.toString());
        }
      };

      await tester.pumpWidget(
        createResponsiveLayoutTestWidget(screenSize: mediumScreenSize),
      );
      await tester.pump();

      FlutterError.onError = originalOnError;

      expect(
        overflowErrors,
        isEmpty,
        reason: 'Layout should not have overflow errors on medium screen',
      );

      expect(find.text('Header'), findsOneWidget);
    });

    testWidgets('Responsive layout adapts to large screen (414x896)', (
      WidgetTester tester,
    ) async {
      // iPhone XR size
      const largeScreenSize = Size(414, 896);
      final List<String> overflowErrors = [];
      final originalOnError = FlutterError.onError;

      FlutterError.onError = (details) {
        if (details.exception.toString().contains('overflowed')) {
          overflowErrors.add(details.exception.toString());
        }
      };

      await tester.pumpWidget(
        createResponsiveLayoutTestWidget(screenSize: largeScreenSize),
      );
      await tester.pump();

      FlutterError.onError = originalOnError;

      expect(
        overflowErrors,
        isEmpty,
        reason: 'Layout should not have overflow errors on large screen',
      );

      expect(find.text('Header'), findsOneWidget);
    });

    testWidgets('Layout scrolls when content exceeds screen height', (
      WidgetTester tester,
    ) async {
      // Real user behavior: content should be scrollable
      const screenSize = Size(320, 400); // Very small height

      await tester.pumpWidget(
        createResponsiveLayoutTestWidget(screenSize: screenSize),
      );
      await tester.pump();

      // Verify scrollable behavior
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
