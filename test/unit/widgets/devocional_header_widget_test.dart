@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/widgets/devocionales/devocional_header_widget.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';

import '../../helpers/test_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await registerTestServicesWithFakes();
    await getService<LocalizationService>().initialize();
  });

  Future<Size> pumpHeader(
    WidgetTester tester, {
    required String date,
    required double width,
    int streak = 1,
    double textScale = 1.0,
    bool showDate = true,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: DevocionalHeaderWidget(
            date: date,
            showDate: showDate,
            currentStreak: streak,
            streakFuture: Future.value(streak),
            isFavorite: false,
            onFavoriteToggle: () {},
            onShare: () {},
            onStreakTap: () {},
            onHeroImage: true,
          ),
        ),
      ),
    );
    await tester.pump();
    return showDate ? tester.getSize(find.text(date)) : Size.zero;
  }

  Finder header() => find.byType(DevocionalHeaderWidget);

  Finder dateText(String date) =>
      find.descendant(of: header(), matching: find.text(date));

  Finder dateFittedBox(String date) => find.ancestor(
        of: dateText(date),
        matching: find.descendant(
          of: header(),
          matching: find.byType(FittedBox),
        ),
      );

  Finder dateSlot() => find.descendant(
        of: header(),
        matching: find.byType(Expanded),
      );

  /// One-line width of [date] in the style the header actually uses.
  double oneLineWidth(WidgetTester tester, String date) {
    final style = tester.widget<Text>(dateText(date)).style;
    final painter = TextPainter(
      text: TextSpan(text: date, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  testWidgets('long date stays on one line next to streak badge and buttons',
      (tester) async {
    // The test font is wider than the real one: 560px leaves this date about
    // 0.85 of the width it needs, i.e. shrinkable within the legible range.
    final shortHeight = await pumpHeader(tester, date: 'Today', width: 560);
    final longHeight = await pumpHeader(
      tester,
      date: 'Thursday, November 5',
      width: 560,
    );

    expect(longHeight.height, lessThanOrEqualTo(shortHeight.height + 1));
  });

  testWidgets('a date too long to shrink legibly wraps to two lines instead',
      (tester) async {
    final shortHeight = await pumpHeader(tester, date: 'Today', width: 392);
    final longHeight = await pumpHeader(
      tester,
      date: 'Wednesday, the twenty-fifth of September',
      width: 392,
    );

    expect(longHeight.height, greaterThan(shortHeight.height * 1.5));
  });

  testWidgets('short date renders at full size on one line (not scaled)',
      (tester) async {
    await pumpHeader(tester, date: 'Today', width: 392);

    // getRect applies the FittedBox transform, unlike getSize.
    final rendered = tester.getRect(dateText('Today'));
    expect(rendered.width, closeTo(oneLineWidth(tester, 'Today'), 0.5));
    expect(tester.widget<Text>(dateText('Today')).maxLines, 1);
  });

  testWidgets('long date that fits at >= 0.7 is scaled down into its slot',
      (tester) async {
    const date = 'Thursday, November 5';
    await pumpHeader(tester, date: date, width: 560);

    expect(dateFittedBox(date), findsOneWidget);
    final slot = tester.getRect(dateSlot());
    final rendered = tester.getRect(dateText(date));
    expect(oneLineWidth(tester, date), greaterThan(slot.width));
    expect(rendered.width, lessThanOrEqualTo(slot.width + 0.01));
  });

  testWidgets('a slot just at the 0.7 ratio takes the one-line FittedBox path',
      (tester) async {
    const date = 'Wednesday, the twenty-fifth of September';
    const probeWidth = 1600.0;
    await pumpHeader(tester, date: date, width: probeWidth);
    final nonSlotWidth = probeWidth - tester.getRect(dateSlot()).width;
    final needed = oneLineWidth(tester, date);

    // Smallest whole-pixel slot whose ratio is >= 0.7.
    final slotWidth = (needed * 0.7).ceilToDouble();
    await pumpHeader(tester, date: date, width: slotWidth + nonSlotWidth);
    expect(tester.getRect(dateSlot()).width, closeTo(slotWidth, 0.01));
    expect(dateFittedBox(date), findsOneWidget);
    expect(tester.widget<Text>(dateText(date)).maxLines, 1);

    // Two pixels narrower drops below 0.7 and wraps instead.
    await pumpHeader(tester, date: date, width: slotWidth + nonSlotWidth - 2);
    expect(dateFittedBox(date), findsNothing);
    expect(tester.widget<Text>(dateText(date)).maxLines, 2);
  });

  testWidgets('long Spanish date at 360 px renders without overflow',
      (tester) async {
    const date = 'miércoles, 30 de septiembre de 2026';
    await pumpHeader(tester, date: date, width: 360);

    expect(tester.takeException(), isNull);
    expect(dateText(date), findsOneWidget);
    final slot = tester.getRect(dateSlot());
    final rendered = tester.getRect(dateText(date));
    expect(rendered.left, greaterThanOrEqualTo(slot.left - 0.01));
    expect(rendered.right, lessThanOrEqualTo(slot.right + 0.01));
  });

  testWidgets('text scale 2.0 sends a medium date to the two-line path',
      (tester) async {
    const date = 'Thursday, November 5';
    await pumpHeader(tester,
        date: date,
        width: 360,
        textScale: 2.0,
        // Streak 0 isolates the date path: at 2.0 the streak badge itself
        // overflows the header row at 360 px (flagged separately).
        streak: 0);

    expect(tester.takeException(), isNull);
    expect(dateFittedBox(date), findsNothing);
    final text = tester.widget<Text>(dateText(date));
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('empty date renders without crashing', (tester) async {
    await pumpHeader(tester, date: '', width: 360);

    expect(tester.takeException(), isNull);
    expect(header(), findsOneWidget);
  });

  testWidgets('showDate false renders no date text', (tester) async {
    const date = 'Thursday, November 5';
    await pumpHeader(tester, date: date, width: 360, showDate: false);

    expect(tester.takeException(), isNull);
    expect(dateText(date), findsNothing);
  });
}
