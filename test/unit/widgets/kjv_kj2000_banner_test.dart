@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/widgets/bible/kjv_kj2000_banner.dart';
import 'package:devocional_nuevo/widgets/notice_banner_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpBanner(
    WidgetTester tester, {
    required VoidCallback onDismiss,
    VoidCallback? onOpenDrawer,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KjvKj2000Banner(
            onDismiss: onDismiss,
            onOpenDrawer: onOpenDrawer ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows the KJV/KJ2000 explanation message', (tester) async {
    await pumpBanner(tester, onDismiss: () {});

    expect(
      find.textContaining('KJV now shows the authentic King James Version'),
      findsOneWidget,
    );
  });

  testWidgets('tapping the close icon invokes onDismiss', (tester) async {
    var dismissed = false;
    await pumpBanner(tester, onDismiss: () => dismissed = true);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(dismissed, isTrue);
  });

  testWidgets('tapping the banner invokes onOpenDrawer', (tester) async {
    var opened = false;
    await pumpBanner(
      tester,
      onDismiss: () {},
      onOpenDrawer: () => opened = true,
    );

    await tester.tap(
      find.textContaining('KJV now shows the authentic King James Version'),
    );
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('is built on the shared green notice card', (tester) async {
    await pumpBanner(tester, onDismiss: () {});

    expect(find.byType(NoticeBannerCard), findsOneWidget);
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

  testWidgets('close does not open the drawer', (tester) async {
    var opened = false;
    var dismissed = false;
    await pumpBanner(
      tester,
      onDismiss: () => dismissed = true,
      onOpenDrawer: () => opened = true,
    );

    await tester.tap(find.byIcon(Icons.close));

    expect((opened, dismissed), (false, true));
  });
}
