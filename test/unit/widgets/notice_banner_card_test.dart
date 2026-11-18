@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/services/i_update_service.dart';
import 'package:devocional_nuevo/widgets/bible/kjv_kj2000_banner.dart';
import 'package:devocional_nuevo/widgets/notice_banner_card.dart';
import 'package:devocional_nuevo/widgets/update_ready_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  BoxDecoration cardDecoration(WidgetTester tester) {
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(NoticeBannerCard),
            matching: find.byType(Container),
          )
          .first,
    );
    return container.decoration! as BoxDecoration;
  }

  testWidgets('renders its child and reports taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(NoticeBannerCard(onTap: () => taps++, child: const Text('hello'))),
    );

    await tester.tap(find.text('hello'));

    expect(find.text('hello'), findsOneWidget);
    expect(taps, 1);
  });

  for (final theme in [ThemeData.light(), ThemeData.dark()]) {
    testWidgets(
        'fill is the opaque theme surface '
        '(${theme.brightness.name})', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: NoticeBannerCard(onTap: () {}, child: const Text('x')),
          ),
        ),
      );

      final color = cardDecoration(tester).color!;
      expect(color.a, 1.0);
      expect(color, theme.colorScheme.surface);
    });
  }

  testWidgets('has a shadow, a hairline outline and a green accent edge',
      (tester) async {
    await tester.pumpWidget(
      host(NoticeBannerCard(onTap: () {}, child: const Text('x'))),
    );

    final decoration = cardDecoration(tester);
    expect(decoration.border, isNotNull);
    expect(decoration.boxShadow, isNotEmpty);
    expect(
      find.descendant(
        of: find.byType(NoticeBannerCard),
        matching: find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == kNoticeAccent,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('KJV banner is built on the green card', (tester) async {
    await tester.pumpWidget(
      host(KjvKj2000Banner(onDismiss: () {}, onOpenDrawer: () {})),
    );

    expect(find.byType(NoticeBannerCard), findsOneWidget);
    expect(
      cardDecoration(tester).color,
      ThemeData.light().colorScheme.surface,
    );
  });

  testWidgets('update banner is built on the green card', (tester) async {
    final ready = ValueNotifier(true);
    addTearDown(ready.dispose);
    await tester.pumpWidget(
      host(
        UpdateReadyBanner(
          updateReady: ready,
          onRestart: () async => UpdateInstallResult.installing,
          title: 'Update ready',
          message: 'Tap to restart',
          closeTooltip: 'Close',
          restartFailedMessage: 'Could not restart',
          child: const SizedBox.expand(),
        ),
      ),
    );

    expect(find.byType(NoticeBannerCard), findsOneWidget);
    expect(
      cardDecoration(tester).color,
      ThemeData.light().colorScheme.surface,
    );
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
            onRestart: () async {
              restarts++;
              return UpdateInstallResult.installing;
            },
            title: 'Update ready',
            message: 'Tap to restart',
            closeTooltip: 'Close',
            restartFailedMessage: 'Could not restart',
            child: const SizedBox.expand(),
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
