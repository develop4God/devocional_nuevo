import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_theme_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() async {
    await registerTestServices();
  });

  Future<void> pumpPage(
    WidgetTester tester,
    Size physicalSize, {
    VoidCallback? onNext,
    VoidCallback? onBack,
    VoidCallback? onSkip,
  }) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ThemeBloc>(
          create: (_) => ThemeBloc(),
          child: OnboardingThemeSelectionPage(
            onNext: onNext ?? () {},
            onBack: onBack ?? () {},
            onSkip: onSkip ?? () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'renders the theme carousel without overflow on a small phone',
    (tester) async {
      await pumpPage(tester, const Size(720, 1280));

      expect(tester.takeException(), isNull);
      expect(find.byType(ListView), findsOneWidget);
    },
  );

  testWidgets('renders the theme carousel without overflow on a tablet', (
    tester,
  ) async {
    await pumpPage(tester, const Size(1600, 2560));

    expect(tester.takeException(), isNull);
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('theme cards are visible with a nonzero size', (tester) async {
    await pumpPage(tester, const Size(1080, 2400));

    final cardFinder = find.byType(AnimatedContainer).first;
    expect(cardFinder, findsOneWidget);

    final size = tester.getSize(cardFinder);
    expect(size.width, greaterThan(0));
    expect(size.height, greaterThan(0));
  });

  testWidgets('Skip button triggers onSkip without triggering onNext', (
    tester,
  ) async {
    var nextCalled = false;
    var skipCalled = false;

    await pumpPage(
      tester,
      const Size(1080, 2400),
      onNext: () => nextCalled = true,
      onSkip: () => skipCalled = true,
    );

    final skipText = 'onboarding.onboarding_skip'.tr();
    final skipButton = find.widgetWithText(TextButton, skipText);
    expect(skipButton, findsOneWidget);

    await tester.tap(skipButton);
    await tester.pump();

    expect(skipCalled, isTrue);
    expect(nextCalled, isFalse);
  });
}
