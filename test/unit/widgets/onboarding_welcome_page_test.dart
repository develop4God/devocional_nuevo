@Tags(['unit', 'widgets', 'onboarding'])
library;

import 'package:devocional_nuevo/pages/onboarding/onboarding_welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';
import '../../helpers/widget_pump_helper.dart';

void main() {
  setUp(() async {
    await registerTestServices();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    required Size physicalSize,
    required VoidCallback onNext,
    required VoidCallback onSkip,
  }) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: DefaultAssetBundle(
          bundle: TestAssetBundle(),
          child: OnboardingWelcomePage(onNext: onNext, onSkip: onSkip),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders without overflow on a small phone screen', (
    tester,
  ) async {
    await pumpPage(
      tester,
      // A small/compact device height (e.g. older or small-form phones).
      physicalSize: const Size(720, 1280),
      onNext: () {},
      onSkip: () {},
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Skip button triggers onSkip without triggering onNext', (
    tester,
  ) async {
    var nextCalled = false;
    var skipCalled = false;

    await pumpPage(
      tester,
      physicalSize: const Size(1080, 2400),
      onNext: () => nextCalled = true,
      onSkip: () => skipCalled = true,
    );

    final skipButton = find.byType(TextButton);
    expect(skipButton, findsOneWidget);

    await tester.tap(skipButton);
    await tester.pump();

    expect(skipCalled, isTrue);
    expect(nextCalled, isFalse);
  });
}
