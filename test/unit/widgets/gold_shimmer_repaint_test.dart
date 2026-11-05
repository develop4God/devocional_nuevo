@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/widgets/gold_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('child sits in its own repaint boundary', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: GoldShimmer(
            child: SizedBox(key: ValueKey('child'), width: 50, height: 50)),
      ),
    );
    await t.pump();
    // Without a boundary the animated ring repaints the whole child each frame.
    final boundary = find.descendant(
      of: find.byType(GoldShimmer),
      matching: find.byType(RepaintBoundary),
    );
    expect(boundary, findsOneWidget);
    expect(
      find.descendant(
          of: boundary, matching: find.byKey(const ValueKey('child'))),
      findsOneWidget,
    );
  });

  testWidgets('filled variant also isolates its child', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: GoldShimmer(
          filled: true,
          child: SizedBox(key: ValueKey('child'), width: 50, height: 50),
        ),
      ),
    );
    await t.pump();
    expect(
      find.descendant(
          of: find.byType(GoldShimmer), matching: find.byType(RepaintBoundary)),
      findsOneWidget,
    );
  });
}
