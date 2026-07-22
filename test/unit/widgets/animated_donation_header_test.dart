@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/widgets/donate/animated_donation_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() async {
    await registerTestServices();
  });

  Future<void> pumpHeader(
    WidgetTester tester, {
    required Size physicalSize,
    double height = 200,
  }) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => AnimatedDonationHeader(
            height: height,
            textTheme: Theme.of(context).textTheme,
            colorScheme: Theme.of(context).colorScheme,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  // Regression test: with the old `widget.height.clamp(120.0, screenHeight *
  // 0.3)`, any window shorter than ~400 logical px made the upper bound drop
  // below 120, and clamp() threw `Invalid argument(s): 120.0`. This covers
  // that exact crash condition (e.g. split-screen, keyboard open, short
  // landscape windows).
  testWidgets('does not crash on a very short window', (tester) async {
    await pumpHeader(tester, physicalSize: const Size(800, 300));

    expect(tester.takeException(), isNull);
  });

  testWidgets('does not crash on a tablet-sized window', (tester) async {
    await pumpHeader(tester, physicalSize: const Size(1600, 2560));

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders on a typical phone window', (tester) async {
    await pumpHeader(tester, physicalSize: const Size(1080, 2400));

    expect(tester.takeException(), isNull);
    expect(find.byType(AnimatedDonationHeader), findsOneWidget);
  });
}
