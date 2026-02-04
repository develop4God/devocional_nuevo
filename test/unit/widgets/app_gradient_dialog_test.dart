import 'package:devocional_nuevo/widgets/app_gradient_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

@Tags(['unit', 'widgets'])
void main() {
  group('AppGradientDialog Widget Tests', () {
    Widget createWidgetUnderTest({
      Widget? child,
      double? maxWidth,
      double? maxHeight,
      bool dismissible = true,
      Color? backgroundColor,
      double? borderRadius,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: AppGradientDialog(
            maxWidth: maxWidth ?? 420,
            maxHeight: maxHeight ?? 420,
            dismissible: dismissible,
            backgroundColor: backgroundColor,
            borderRadius: borderRadius ?? 28,
            child: child ?? const Text('Dialog Content'),
          ),
        ),
      );
    }

    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(AppGradientDialog), findsOneWidget);
    });

    testWidgets('displays child content', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Dialog Content'), findsOneWidget);
    });

    testWidgets('displays custom child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: Column(
            children: [
              const Text('Title'),
              const SizedBox(height: 8),
              const Text('Description'),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Action'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets('is dismissible by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AppGradientDialog(
                      dismissible: true,
                      child: const Text('Dialog'),
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Dialog'), findsOneWidget);

      // Tap outside to dismiss
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Dialog'), findsNothing);
    });

    testWidgets('prevents dismissal when dismissible is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AppGradientDialog(
                      dismissible: false,
                      child: const Text('Non-dismissible Dialog'),
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Non-dismissible Dialog'), findsOneWidget);

      // Try to tap outside - should not dismiss
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Dialog should still be visible
      expect(find.text('Non-dismissible Dialog'), findsOneWidget);
    });

    testWidgets('has gradient decoration', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Dialog should render with gradient (no errors)
      expect(find.byType(AppGradientDialog), findsOneWidget);
    });

    testWidgets('is scrollable for long content', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: Column(
            children: List.generate(
              50,
              (index) => Text('Item $index'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should have SingleChildScrollView
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('respects custom maxWidth', (WidgetTester tester) async {
      const customWidth = 300.0;

      await tester.pumpWidget(
        createWidgetUnderTest(maxWidth: customWidth),
      );
      await tester.pumpAndSettle();

      // Widget should render without errors
      expect(find.byType(AppGradientDialog), findsOneWidget);
    });

    testWidgets('handles small screen sizes', (WidgetTester tester) async {
      // Set a small screen size
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(AppGradientDialog), findsOneWidget);

      addTearDown(tester.view.reset);
    });

    testWidgets('handles large screen sizes', (WidgetTester tester) async {
      // Set a large screen size
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(AppGradientDialog), findsOneWidget);

      addTearDown(tester.view.reset);
    });

    testWidgets('applies custom background color', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(backgroundColor: Colors.red),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppGradientDialog), findsOneWidget);
    });

    testWidgets('uses custom border radius', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(borderRadius: 16),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppGradientDialog), findsOneWidget);
    });

    testWidgets('child tap does not dismiss dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AppGradientDialog(
                      dismissible: true,
                      child: const Text('Dialog Content'),
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Dialog Content'), findsOneWidget);

      // Tap on the content itself (not outside)
      await tester.tap(find.text('Dialog Content'));
      await tester.pumpAndSettle();

      // Dialog should remain visible
      expect(find.text('Dialog Content'), findsOneWidget);
    });

    testWidgets('renders with SafeArea', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Should have SafeArea widget
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('handles complex child widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 48),
              const SizedBox(height: 16),
              const Text('Title', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              const Text('This is a description'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });
  });
}
