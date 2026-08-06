@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/widgets/bible/kjv_kj2000_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpBanner(
    WidgetTester tester, {
    required VoidCallback onDismiss,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KjvKj2000Banner(onDismiss: onDismiss),
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
}
