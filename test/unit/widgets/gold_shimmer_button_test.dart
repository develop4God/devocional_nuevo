@Tags(['unit', 'widgets'])
library;

// GoldShimmerButton: a gold shimmering call-to-action shared by the encounter
// unlock offer and the support page.

import 'package:devocional_nuevo/widgets/gold_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows its child and reports taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        GoldShimmerButton(
          key: const ValueKey('gold_button'),
          onPressed: () => taps++,
          child: const Text('Support'),
        ),
      ),
    );

    expect(find.text('Support'), findsOneWidget);
    expect(find.byType(GoldShimmer), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gold_button')));
    expect(taps, 1);
  });

  testWidgets('does nothing when disabled', (tester) async {
    await tester.pumpWidget(
      _host(
        const GoldShimmerButton(
          key: ValueKey('gold_button'),
          onPressed: null,
          child: Text('Support'),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
