@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/widgets/bible/kjv_kj2000_banner.dart';
import 'package:devocional_nuevo/widgets/green_banner_card.dart';
import 'package:devocional_nuevo/widgets/update_ready_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  BoxDecoration cardDecoration(WidgetTester tester) {
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(GreenBannerCard),
            matching: find.byType(Container),
          )
          .first,
    );
    return container.decoration! as BoxDecoration;
  }

  testWidgets('renders its child and reports taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(GreenBannerCard(onTap: () => taps++, child: const Text('hello'))),
    );

    await tester.tap(find.text('hello'));

    expect(find.text('hello'), findsOneWidget);
    expect(taps, 1);
  });

  testWidgets('uses the shared green tint and border', (tester) async {
    await tester.pumpWidget(
      host(GreenBannerCard(onTap: () {}, child: const Text('x'))),
    );

    final decoration = cardDecoration(tester);
    expect(decoration.color, kBannerGreen.withValues(alpha: 0.14));
    expect(
      (decoration.border! as Border).top.color,
      kBannerGreen.withValues(alpha: 0.6),
    );
  });

  testWidgets('KJV banner is built on the green card', (tester) async {
    await tester.pumpWidget(
      host(KjvKj2000Banner(onDismiss: () {}, onOpenDrawer: () {})),
    );

    expect(find.byType(GreenBannerCard), findsOneWidget);
    expect(cardDecoration(tester).color, kBannerGreen.withValues(alpha: 0.14));
  });

  testWidgets('update banner is built on the green card', (tester) async {
    final ready = ValueNotifier(true);
    addTearDown(ready.dispose);
    await tester.pumpWidget(
      host(
        UpdateReadyBanner(
          updateReady: ready,
          onRestart: () {},
          title: 'Update ready',
          message: 'Tap to restart',
          closeTooltip: 'Close',
          child: const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.byType(GreenBannerCard), findsOneWidget);
    expect(cardDecoration(tester).color, kBannerGreen.withValues(alpha: 0.14));
  });

  group('each banner keeps its own action on the shared card', () {
    testWidgets('KJV banner: card opens the drawer, close only dismisses',
        (tester) async {
      var drawer = 0;
      var dismissed = 0;
      await tester.pumpWidget(
        host(
          KjvKj2000Banner(
            onDismiss: () => dismissed++,
            onOpenDrawer: () => drawer++,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.info_outline_rounded));
      expect((drawer, dismissed), (1, 0));

      await tester.tap(find.byIcon(Icons.close));
      expect((drawer, dismissed), (1, 1));
    });

    testWidgets('update banner: card restarts, close never restarts',
        (tester) async {
      var restarts = 0;
      final ready = ValueNotifier(true);
      addTearDown(ready.dispose);
      await tester.pumpWidget(
        host(
          UpdateReadyBanner(
            updateReady: ready,
            onRestart: () => restarts++,
            title: 'Update ready',
            message: 'Tap to restart',
            closeTooltip: 'Close',
            child: const SizedBox.shrink(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.download_done_outlined));
      expect(restarts, 1);

      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      expect(restarts, 1);
    });
  });
}
