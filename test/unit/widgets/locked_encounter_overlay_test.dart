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
  LockedOverlayStyle style = LockedOverlayStyle.list,
  bool offersUnlock = true,
  String title = 'Prev',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LockedEncounterOverlay(
          prerequisiteTitle: title,
          offersUnlock: offersUnlock,
          highlight: highlight,
          style: style,
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
    await _pump(t, highlight: false, style: LockedOverlayStyle.grid);
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

  for (final highlight in [true, false]) {
    testWidgets(
        'grid overlay fits a small card at 1.5x text (highlight: '
        '$highlight)', (t) async {
      await t.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 120,
                height: 130,
                child: LockedEncounterOverlay(
                  prerequisiteTitle: 'The Night Peter Walked on Water',
                  highlight: highlight,
                  style: LockedOverlayStyle.grid,
                ),
              ),
            ),
          ),
        ),
      );
      await t.pump();
      // A RenderFlex overflow is reported as a test exception.
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('no pill and no hint when there is no unlock offer', (t) async {
    await _pump(t, highlight: true, offersUnlock: false);
    expect(find.byType(GoldLockBadge), findsOneWidget);
    expect(find.byType(GoldHintPill), findsNothing);
    await _pump(t, highlight: false, offersUnlock: false);
    expect(find.text('encounters.read_now_hint'), findsNothing);
  });

  testWidgets('plain hint uses the style hint size, not a hard-coded one', (
    t,
  ) async {
    await _pump(t, highlight: false);
    final hint = t.widget<Text>(find.text('encounters.read_now_hint'));
    expect(hint.style?.fontSize, LockedOverlayStyle.list.hintFontSize);
  });

  testWidgets('grid title is capped with an ellipsis, list is not', (t) async {
    const longTitle =
        'A very long prerequisite title that keeps going and going and going';
    await _pump(t,
        highlight: true, style: LockedOverlayStyle.grid, title: longTitle);
    var title = t.widget<Text>(find.text('encounters.complete_to_unlock'));
    expect(title.maxLines, LockedOverlayStyle.grid.titleMaxLines);
    expect(title.overflow, TextOverflow.ellipsis);
    await _pump(t, highlight: true, title: longTitle);
    title = t.widget<Text>(find.text('encounters.complete_to_unlock'));
    expect(title.maxLines, isNull);
  });
}
