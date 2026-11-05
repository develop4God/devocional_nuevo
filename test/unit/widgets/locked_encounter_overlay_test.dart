@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/encounter/locked_encounter_overlay.dart';
import 'package:devocional_nuevo/widgets/gold_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool highlight,
  bool compact = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LockedEncounterOverlay(
          prerequisiteTitle: 'Prev',
          highlight: highlight,
          compact: compact,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  setUpAll(setupServiceLocator);

  testWidgets('highlight shows badge and gold pill', (t) async {
    await _pump(t, highlight: true);
    expect(find.byType(GoldLockBadge), findsOneWidget);
    expect(find.byType(GoldHintPill), findsOneWidget);
  });

  testWidgets('plain full-size shows white lock and plain hint text', (
    t,
  ) async {
    await _pump(t, highlight: false);
    expect(find.byType(GoldLockBadge), findsNothing);
    expect(find.byType(GoldHintPill), findsNothing);
    expect(find.text('encounters.read_now_hint'), findsOneWidget);
    expect(t.widget<Icon>(find.byIcon(Icons.lock_rounded)).color, Colors.white);
  });

  testWidgets('plain compact omits the hint entirely', (t) async {
    await _pump(t, highlight: false, compact: true);
    expect(find.text('encounters.read_now_hint'), findsNothing);
    expect(find.byType(GoldHintPill), findsNothing);
  });

  testWidgets('plain overlay uses the dark fill, highlight the gradient',
      (t) async {
    await _pump(t, highlight: false);
    var deco = t.widget<Container>(find.byType(Container).first).decoration
        as BoxDecoration;
    expect(deco.gradient, isNull);
    expect(deco.color, isNotNull);
    await _pump(t, highlight: true);
    deco = t.widget<Container>(find.byType(Container).first).decoration
        as BoxDecoration;
    expect(deco.gradient, goldLockOverlayGradient);
    expect(deco.color, isNull);
  });
}
