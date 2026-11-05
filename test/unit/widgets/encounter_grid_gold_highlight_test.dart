import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/encounter/encounter_grid_overlay.dart';
import 'package:devocional_nuevo/widgets/encounter/locked_encounter_overlay.dart';
import 'package:devocional_nuevo/widgets/gold_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

EncounterIndexEntry _entry(String id, {String status = 'published'}) =>
    EncounterIndexEntry(
      id: id,
      version: '1.0',
      emoji: '🌊',
      status: status,
      files: {'en': '$id.json'},
      titles: {'en': id},
      subtitles: {'en': 'Sub'},
      scriptureReference: {'en': 'John 1:1'},
      estimatedReadingMinutes: {'en': 5},
    );

Future<void> _pumpGrid(
  WidgetTester tester,
  List<EncounterIndexEntry> entries, {
  Set<String> completed = const {},
  bool allUnlocked = false,
  Size size = const Size(1080, 2400),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final controller = AnimationController(
    vsync: tester,
    value: 1.0,
    duration: const Duration(milliseconds: 300),
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: EncounterGridOverlay(
          state: EncounterLoaded(index: entries, completedIds: completed),
          entries: entries,
          currentIndex: 0,
          lang: 'en',
          allUnlocked: allUnlocked,
          onEncounterSelected: (_, __) {},
          onClose: () {},
          animation: controller,
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Card-border shimmers only (the hint pill uses a filled shimmer).
List<GoldShimmer> _ringShimmers(WidgetTester t) => t
    .widgetList<GoldShimmer>(find.byType(GoldShimmer))
    .where((w) => !w.filled)
    .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUpAll(setupServiceLocator);

  testWidgets('only the next waiting card gets the gold shimmer', (t) async {
    await _pumpGrid(t, [_entry('a'), _entry('b'), _entry('c')]);
    // b is the next locked card; c is locked but not next.
    expect(_ringShimmers(t), hasLength(1));
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(2));
  });

  testWidgets('next waiting card shows a gold lock icon', (t) async {
    await _pumpGrid(t, [_entry('a'), _entry('b'), _entry('c')]);
    final colors = t
        .widgetList<Icon>(find.byIcon(Icons.lock_rounded))
        .map((i) => i.color)
        .toList();
    expect(colors.where((c) => c == goldLockIconColor), hasLength(1));
    expect(colors.where((c) => c == Colors.white), hasLength(1));
  });

  testWidgets('gold gradient overlay is applied only to the next card',
      (t) async {
    await _pumpGrid(t, [_entry('a'), _entry('b'), _entry('c')]);
    final decorations = t
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>();
    expect(
      decorations.where((d) => d.gradient == goldLockOverlayGradient),
      hasLength(1),
    );
    // The other locked card keeps the plain dark overlay.
    expect(
      decorations.where((d) => d.color == Colors.black.withValues(alpha: 0.65)),
      hasLength(1),
    );
  });

  testWidgets('glow badge and hint pill appear only on the next card',
      (t) async {
    await _pumpGrid(t, [_entry('a'), _entry('b'), _entry('c')]);
    expect(find.byType(GoldLockBadge), findsOneWidget);
    expect(find.byType(GoldHintPill), findsOneWidget);
  });

  testWidgets('no badge or hint pill when nothing is waiting', (t) async {
    await _pumpGrid(t, [_entry('a'), _entry('b')], completed: {'a'});
    expect(find.byType(GoldLockBadge), findsNothing);
    expect(find.byType(GoldHintPill), findsNothing);
  });

  testWidgets('no gold when every encounter is unlocked', (t) async {
    await _pumpGrid(t, [_entry('a'), _entry('b')], allUnlocked: true);
    expect(_ringShimmers(t), isEmpty);
  });

  testWidgets('no gold when nothing is waiting', (t) async {
    await _pumpGrid(t, [_entry('a'), _entry('b')], completed: {'a'});
    expect(_ringShimmers(t), isEmpty);
  });

  testWidgets('coming-soon entries never get gold', (t) async {
    await _pumpGrid(t, [_entry('a'), _entry('b', status: 'coming_soon')]);
    expect(_ringShimmers(t), isEmpty);
  });

  testWidgets('gold moves to the following card after completing one',
      (t) async {
    await _pumpGrid(
      t,
      [_entry('a'), _entry('b'), _entry('c')],
      completed: {'a'},
    );
    expect(_ringShimmers(t), hasLength(1));
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
  });

  testWidgets('gold ring hugs the visible card edge', (t) async {
    await _pumpGrid(t, [_entry('a'), _entry('b'), _entry('c')]);
    final ring = t.getRect(find.byType(GoldShimmer).first);
    // Card insets its Material by its margin; that Material is the visible edge.
    final card = t.getRect(
      find
          .descendant(
            of: find.byType(GoldShimmer).first,
            matching: find.byType(Material),
          )
          .first,
    );
    expect(ring, card);
  });

  testWidgets('grid hint pill is static: only the ring animates', (t) async {
    await _pumpGrid(t, [_entry('a'), _entry('b'), _entry('c')]);
    final animated = t
        .widgetList<GoldShimmer>(find.byType(GoldShimmer))
        .where((w) => w.filled);
    expect(animated, isEmpty);
  });
}
