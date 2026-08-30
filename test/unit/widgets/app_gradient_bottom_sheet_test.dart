@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/widgets/app_gradient_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    Widget child = const Text('content'),
    double maxWidth = double.infinity,
    double maxHeight = 420,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
    Color? backgroundColor,
    List<Color>? gradientColors,
    double borderRadius = 28,
    Color? borderColor,
    double borderWidth = 2,
    bool useMaterial = true,
    double bottomSpacing = 12.0,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppGradientBottomSheet(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            padding: padding,
            backgroundColor: backgroundColor,
            gradientColors: gradientColors,
            borderRadius: borderRadius,
            borderColor: borderColor,
            borderWidth: borderWidth,
            useMaterial: useMaterial,
            bottomSpacing: bottomSpacing,
            child: child,
          ),
        ),
      ),
    );
  }

  group('AppGradientBottomSheet', () {
    testWidgets('renders its child', (tester) async {
      await pumpSheet(tester, child: const Text('Hello sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Hello sheet'), findsOneWidget);
    });

    testWidgets('wraps content in a Material when useMaterial is true', (
      tester,
    ) async {
      await pumpSheet(tester, useMaterial: true);
      await tester.pumpAndSettle();

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(AppGradientBottomSheet),
          matching: find.byType(Material),
        ),
      );
      expect(material.type, MaterialType.transparency);
    });

    testWidgets('does not add an extra Material when useMaterial is false', (
      tester,
    ) async {
      await pumpSheet(tester, useMaterial: false);
      await tester.pumpAndSettle();

      // Only ambient Materials from MaterialApp/Scaffold remain, none added
      // by AppGradientBottomSheet itself.
      final materialsInsideSheet = find.descendant(
        of: find.byType(AppGradientBottomSheet),
        matching: find.byType(Material),
      );
      expect(materialsInsideSheet, findsNothing);
    });

    testWidgets('applies custom border radius to the container decoration', (
      tester,
    ) async {
      await pumpSheet(tester, borderRadius: 40);
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AppGradientBottomSheet),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(
        decoration.borderRadius,
        BorderRadius.vertical(top: const Radius.circular(40)),
      );
    });

    testWidgets('applies a custom gradient when gradientColors is provided', (
      tester,
    ) async {
      const colors = [Colors.red, Colors.blue];
      await pumpSheet(tester, gradientColors: colors);
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AppGradientBottomSheet),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors, colors);
    });

    testWidgets('respects the maxWidth constraint', (tester) async {
      await pumpSheet(tester, maxWidth: 300);
      await tester.pumpAndSettle();

      final constrainedBox = tester.widget<ConstrainedBox>(
        find
            .descendant(
              of: find.byType(AppGradientBottomSheet),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(constrainedBox.constraints.maxWidth, 300);
    });

    testWidgets('is scrollable when content overflows', (tester) async {
      await pumpSheet(
        tester,
        maxHeight: 100,
        child: Column(
          children: List.generate(
            30,
            (i) => Text('Line $i', key: ValueKey('line_$i')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
