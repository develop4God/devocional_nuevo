@Tags(['unit', 'widgets'])
library;

// test/unit/widgets/app_scrollbar_test.dart
import 'package:devocional_nuevo/widgets/app_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppScrollbar Tests', () {
    testWidgets(
      'two AppScrollbar-wrapped lists in the same tree, each with its own '
      'explicit controller, mount without PrimaryScrollController conflict',
      (WidgetTester tester) async {
        // Regression test for Crashlytics issue 2e0a0fe14b062c618827992e8d63914c:
        // "The PrimaryScrollController is attached to more than one
        // ScrollPosition." This happened when AppScrollbar (thumbVisibility:
        // true) was used with no explicit controller, silently falling back
        // to the implicit PrimaryScrollController — if more than one such
        // scrollable mounted in the same route scope at once, the shared
        // implicit controller ended up attached to two ScrollPositions.
        //
        // AppScrollbar.controller is now required (compile-time enforced),
        // so this scenario — two independently scrollable lists, each given
        // its own dedicated controller — is the only way to satisfy the API,
        // and it must not throw.
        final controllerA = ScrollController();
        final controllerB = ScrollController();
        addTearDown(controllerA.dispose);
        addTearDown(controllerB.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  Expanded(
                    child: AppScrollbar(
                      controller: controllerA,
                      child: ListView.builder(
                        controller: controllerA,
                        itemCount: 50,
                        itemBuilder: (context, index) =>
                            ListTile(title: Text('A $index')),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AppScrollbar(
                      controller: controllerB,
                      child: ListView.builder(
                        controller: controllerB,
                        itemCount: 50,
                        itemBuilder: (context, index) =>
                            ListTile(title: Text('B $index')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('A 0'), findsOneWidget);
        expect(find.text('B 0'), findsOneWidget);

        // Scroll each independently — if they secretly shared a controller,
        // scrolling one would move the other's position too.
        await tester.drag(find.text('A 0'), const Offset(0, -500));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(controllerA.offset, greaterThan(0));
        expect(controllerB.offset, 0);
      },
    );
  });
}
