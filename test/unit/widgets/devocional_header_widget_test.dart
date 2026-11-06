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
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DevocionalHeaderWidget(
            date: date,
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
    return tester.getSize(find.text(date));
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

  testWidgets('short date keeps its full size (not scaled down)',
      (tester) async {
    final rendered = await pumpHeader(tester, date: 'Today', width: 392);
    final style = tester.widget<Text>(find.text('Today')).style;
    final unscaled = TextPainter(
      text: TextSpan(text: 'Today', style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    expect(rendered.height, closeTo(unscaled.height, 1));
  });
}
