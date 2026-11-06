@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/widgets/encounter/responsive_card_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  int itemCount = 6,
  double height = 1200,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final controller = ScrollController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ResponsiveCardGrid(
          controller: controller,
          header: const SizedBox(key: ValueKey('header'), height: 60),
          itemCount: itemCount,
          itemBuilder: (context, i) => ColoredBox(
            key: ValueKey('card_$i'),
            color: Colors.teal,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Rect _card(WidgetTester t, int i) => t.getRect(find.byKey(ValueKey('card_$i')));

int _columns(WidgetTester t, int count) {
  final firstRowTop = _card(t, 0).top;
  var columns = 0;
  for (var i = 0; i < count; i++) {
    if ((_card(t, i).top - firstRowTop).abs() < 1) columns++;
  }
  return columns;
}

void main() {
  group('column count follows the available width', () {
    testWidgets('narrow phone: one full-width column', (t) async {
      await _pump(t, width: 360);
      expect(_columns(t, 4), 1);
      expect(_card(t, 0).width, 360 - 2 * 20);
    });

    testWidgets('portrait tablet: several columns', (t) async {
      await _pump(t, width: 800);
      expect(_columns(t, 6), greaterThanOrEqualTo(2));
    });

    testWidgets('landscape tablet: more columns than portrait', (t) async {
      await _pump(t, width: 800);
      final portrait = _columns(t, 6);
      await _pump(t, width: 1280);
      expect(_columns(t, 6), greaterThan(portrait));
    });
  });

  group('card geometry', () {
    for (final width in [
      200.0,
      360.0,
      411.0,
      499.0,
      520.0,
      600.0,
      699.0,
      700.0,
      800.0,
      1280.0,
      2560.0,
    ]) {
      testWidgets('width $width: fixed height, never narrower than the min', (
        t,
      ) async {
        await _pump(t, width: width);
        final available = width - 40;
        for (var i = 0; i < 3; i++) {
          final r = _card(t, i);
          expect(r.height, encounterCardHeight);
          expect(r.width, greaterThan(0));
          if (available >= encounterCardMinWidth) {
            expect(r.width, greaterThanOrEqualTo(encounterCardMinWidth - 0.01));
          }
        }
      });
    }

    for (final width in [499.0, 520.0, 600.0, 699.0]) {
      testWidgets('width $width: stays one column instead of two narrow ones', (
        t,
      ) async {
        await _pump(t, width: width);
        expect(_columns(t, 4), 1);
        expect(_card(t, 0).width, width - 40);
      });
    }

    testWidgets('cards never overflow the screen horizontally', (t) async {
      await _pump(t, width: 1280);
      for (var i = 0; i < 6; i++) {
        final r = _card(t, i);
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(1280));
      }
    });
  });

  group('structure', () {
    testWidgets('header sits above the first row', (t) async {
      await _pump(t, width: 800);
      final header = t.getRect(find.byKey(const ValueKey('header')));
      expect(header.bottom, lessThanOrEqualTo(_card(t, 0).top));
      expect(find.byKey(const ValueKey('header')), findsOneWidget);
    });

    testWidgets('empty list renders only the header', (t) async {
      await _pump(t, width: 800, itemCount: 0);
      expect(find.byKey(const ValueKey('header')), findsOneWidget);
      expect(find.byKey(const ValueKey('card_0')), findsNothing);
    });

    testWidgets('last card is reachable by scrolling', (t) async {
      await _pump(t, width: 360, itemCount: 12, height: 700);
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('card_11')),
        300,
        scrollable: find.byType(Scrollable),
      );
      expect(find.byKey(const ValueKey('card_11')), findsOneWidget);
    });
  });

  testWidgets('keeps 48 of space under the last card', (t) async {
    await _pump(t, width: 360, itemCount: 3, height: 900);
    final viewportBottom = t.getRect(find.byType(Scrollable)).bottom;
    await t.drag(find.byType(Scrollable), const Offset(0, -2000));
    await t.pumpAndSettle();
    expect(viewportBottom - _card(t, 2).bottom, closeTo(48, 0.5));
  });
}
