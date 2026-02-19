// test/helpers/widget_pump_helper.dart
//
// Helpers for pumping widget pages in tests that contain Lottie animations
// or AnimationController.forward() calls in initState.
//
// The standard `tester.pumpWidget()` would block indefinitely for pages that
// call AnimationController.forward() with a TickerProviderStateMixin because
// the animation ticker keeps scheduling frames.
//
// Usage:
//   final bloc = SupporterBloc(iapService: fakeIap, profileRepository: fakeRepo);
//   await pumpSupporterPage(tester, bloc);
//   expect(find.byType(Scaffold), findsOneWidget);

import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/pages/supporter_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a [SupporterPage] with the given [bloc] inside a minimal [MaterialApp].
///
/// Calls [tester.pump(Duration.zero)] after pumping to drain the first frame
/// and complete the initial animation tick without running the full animation.
///
/// The [SupporterBloc] is NOT automatically closed after this helper — the
/// caller is responsible for calling `bloc.close()` in tearDown.
Future<void> pumpSupporterPage(
  WidgetTester tester,
  SupporterBloc bloc,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<SupporterBloc>.value(
        value: bloc,
        child: const SupporterPage(),
      ),
    ),
  );
  // Drain the first animation frame without running the full animation.
  await tester.pump(Duration.zero);
}
