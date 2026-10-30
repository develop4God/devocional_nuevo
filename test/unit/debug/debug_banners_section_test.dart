@Tags(['unit', 'debug'])
library;

import 'package:devocional_nuevo/debug/sections/debug_banners_section.dart';
import 'package:devocional_nuevo/widgets/bible/kjv_kj2000_banner.dart';
import 'package:devocional_nuevo/widgets/update_ready_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpSection(WidgetTester tester) {
    return tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DebugBannersSection(
              updateTitle: 'Update ready',
              updateMessage: 'Tap to restart and get the latest improvements.',
              updateCloseTooltip: 'Close',
              updateRestartFailedMessage: 'Could not restart',
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows nothing until a banner is requested', (tester) async {
    await pumpSection(tester);

    expect(find.byType(UpdateReadyBanner), findsNothing);
    expect(find.byType(KjvKj2000Banner), findsNothing);
    expect(find.text('Show update banner'), findsOneWidget);
    expect(find.text('Show KJV banner'), findsOneWidget);
  });

  testWidgets('update button shows the real update banner', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.text('Show update banner'));
    await tester.pump();

    expect(find.byType(UpdateReadyBanner), findsOneWidget);
    expect(find.text('Update ready'), findsOneWidget);
    expect(find.byType(KjvKj2000Banner), findsNothing);
  });

  testWidgets('KJV button shows the real KJV banner', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.text('Show KJV banner'));
    await tester.pump();

    expect(find.byType(KjvKj2000Banner), findsOneWidget);
    expect(find.byType(UpdateReadyBanner), findsNothing);
  });

  testWidgets('both banners can be shown together', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.text('Show update banner'));
    await tester.tap(find.text('Show KJV banner'));
    await tester.pump();

    expect(find.byType(UpdateReadyBanner), findsOneWidget);
    expect(find.byType(KjvKj2000Banner), findsOneWidget);
  });

  testWidgets('pressing a shown banner button again hides it', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.text('Show update banner'));
    await tester.pump();
    await tester.tap(find.text('Hide update banner'));
    await tester.pump();

    expect(find.byType(UpdateReadyBanner), findsNothing);
  });

  testWidgets('tapping the update banner only reports, never installs',
      (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Show update banner'));
    await tester.pump();

    await tester.tap(find.text('Update ready'));
    await tester.pump();

    expect(find.textContaining('Restart tapped'), findsOneWidget);
  });

  testWidgets('tapping the KJV banner reports the drawer action',
      (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Show KJV banner'));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pump();

    expect(find.textContaining('Open drawer tapped'), findsOneWidget);
  });

  testWidgets('closing the KJV banner hides it and shows the button again',
      (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Show KJV banner'));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(find.byType(KjvKj2000Banner), findsNothing);
    expect(find.text('Show KJV banner'), findsOneWidget);
  });
}
