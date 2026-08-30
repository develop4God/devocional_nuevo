@Tags(['unit', 'controllers'])
library;

import 'package:devocional_nuevo/controllers/tts_scroll_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

void main() {
  group('ScrollControllerTarget', () {
    late ScrollController controller;

    setUp(() {
      controller = ScrollController();
    });

    tearDown(() {
      controller.dispose();
    });

    Future<void> pumpScrollable(WidgetTester tester) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: List.generate(
                  50,
                  (i) => SizedBox(height: 100, child: Text('Item $i')),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('scrollToFraction is a no-op when controller has no clients', (
      tester,
    ) async {
      final target = ScrollControllerTarget(
        controller,
        duration: const Duration(milliseconds: 1),
      );

      // Not pumped/attached yet.
      expect(() => target.scrollToFraction(0.5), returnsNormally);
    });

    testWidgets('scrollToFraction animates towards maxScrollExtent * fraction',
        (
      tester,
    ) async {
      await pumpScrollable(tester);
      final target = ScrollControllerTarget(
        controller,
        duration: const Duration(milliseconds: 50),
      );

      target.scrollToFraction(1.0);
      await tester.pumpAndSettle();

      expect(controller.position.pixels, controller.position.maxScrollExtent);
    });

    testWidgets('scrollToFraction(0.0) keeps the scroll position at the top', (
      tester,
    ) async {
      await pumpScrollable(tester);
      final target = ScrollControllerTarget(
        controller,
        duration: const Duration(milliseconds: 50),
      );

      target.scrollToFraction(0.0);
      await tester.pumpAndSettle();

      expect(controller.position.pixels, 0.0);
    });

    testWidgets('clamps fraction above 1.0 to maxScrollExtent', (
      tester,
    ) async {
      await pumpScrollable(tester);
      final target = ScrollControllerTarget(
        controller,
        duration: const Duration(milliseconds: 50),
      );

      target.scrollToFraction(5.0);
      await tester.pumpAndSettle();

      expect(controller.position.pixels, controller.position.maxScrollExtent);
    });

    testWidgets(
        'scrollToIndex maps index/itemCount onto the same fraction '
        'logic', (tester) async {
      await pumpScrollable(tester);
      final target = ScrollControllerTarget(
        controller,
        duration: const Duration(milliseconds: 50),
      );

      target.scrollToIndex(25, 50);
      await tester.pumpAndSettle();

      final expected = (0.5 * controller.position.maxScrollExtent).clamp(
        0.0,
        controller.position.maxScrollExtent,
      );
      expect(controller.position.pixels, expected);
    });

    testWidgets('scrollToIndex is a no-op when itemCount is zero', (
      tester,
    ) async {
      await pumpScrollable(tester);
      final target = ScrollControllerTarget(
        controller,
        duration: const Duration(milliseconds: 50),
      );

      target.scrollToIndex(0, 0);
      await tester.pumpAndSettle();

      expect(controller.position.pixels, 0.0);
    });

    testWidgets('does not auto-scroll while the user is manually dragging', (
      tester,
    ) async {
      await pumpScrollable(tester);
      final target = ScrollControllerTarget(
        controller,
        duration: const Duration(milliseconds: 50),
      );

      final gesture = await tester.startGesture(const Offset(200, 300));
      await gesture.moveBy(const Offset(0, -200));
      await tester.pump();

      final positionBeforeAutoScroll = controller.position.pixels;
      target.scrollToFraction(1.0);
      await tester.pump();

      // The programmatic call should not have started an animation because
      // the user's drag is still in progress.
      expect(controller.position.pixels, positionBeforeAutoScroll);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('ItemScrollControllerTarget', () {
    late ItemScrollController itemScrollController;

    setUp(() {
      itemScrollController = ItemScrollController();
    });

    Future<void> pumpList(WidgetTester tester, {int itemCount = 30}) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollablePositionedList.builder(
              itemScrollController: itemScrollController,
              itemCount: itemCount,
              itemBuilder: (context, index) => SizedBox(
                height: 100,
                child: Text('Item $index'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('scrollToFraction is a no-op when controller is not attached', (
      tester,
    ) async {
      final target = ItemScrollControllerTarget(
        itemScrollController,
        itemCount: () => 30,
        duration: const Duration(milliseconds: 1),
      );

      expect(() => target.scrollToFraction(0.5), returnsNormally);
    });

    testWidgets('scrollToFraction is a no-op when itemCount is zero', (
      tester,
    ) async {
      await pumpList(tester, itemCount: 30);
      final target = ItemScrollControllerTarget(
        itemScrollController,
        itemCount: () => 0,
        duration: const Duration(milliseconds: 1),
      );

      expect(() => target.scrollToFraction(0.5), returnsNormally);
      await tester.pump();
    });

    testWidgets(
        'scrollToIndex scrolls to a clamped, leading-count-adjusted '
        'index without throwing', (tester) async {
      await pumpList(tester, itemCount: 30);
      final target = ItemScrollControllerTarget(
        itemScrollController,
        itemCount: () => 30,
        leadingCount: 1,
        duration: const Duration(milliseconds: 1),
      );

      // Index far beyond the list should clamp instead of throwing.
      expect(() => target.scrollToIndex(999, 30), returnsNormally);
      await tester.pumpAndSettle();

      expect(find.text('Item 29'), findsOneWidget);
    });

    testWidgets('scrollToFraction scrolls proportionally through the list', (
      tester,
    ) async {
      await pumpList(tester, itemCount: 30);
      final target = ItemScrollControllerTarget(
        itemScrollController,
        itemCount: () => 30,
        duration: const Duration(milliseconds: 1),
      );

      target.scrollToFraction(0.9);
      await tester.pumpAndSettle();

      expect(find.text('Item 27'), findsOneWidget);
    });

    testWidgets('scrollToIndex is a no-op when count is zero', (
      tester,
    ) async {
      await pumpList(tester, itemCount: 30);
      final target = ItemScrollControllerTarget(
        itemScrollController,
        itemCount: () => 30,
        duration: const Duration(milliseconds: 1),
      );

      expect(() => target.scrollToIndex(5, 0), returnsNormally);
      await tester.pump();
    });
  });
}
