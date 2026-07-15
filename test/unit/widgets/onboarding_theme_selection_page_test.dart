import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_theme_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() async {
    await registerTestServices();
  });

  Future<void> pumpPage(WidgetTester tester, Size physicalSize) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ThemeBloc>(
          create: (_) => ThemeBloc(),
          child: OnboardingThemeSelectionPage(onNext: () {}, onBack: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the theme grid without overflow on a small phone', (
    tester,
  ) async {
    await pumpPage(tester, const Size(720, 1280));

    expect(tester.takeException(), isNull);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('renders the theme grid without overflow on a tablet', (
    tester,
  ) async {
    await pumpPage(tester, const Size(1600, 2560));

    expect(tester.takeException(), isNull);
    expect(find.byType(GridView), findsOneWidget);
  });
}
