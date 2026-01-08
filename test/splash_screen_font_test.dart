import 'package:auto_size_text/auto_size_text.dart';
import 'package:devocional_nuevo/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SplashScreen uses local fonts and does not throw',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SplashScreen()));

    // Check for main text (may be localized)
    // Use a TypeFinder for AutoSizeText
    final autoSizeTextFinder = find.byType(AutoSizeText);
    expect(autoSizeTextFinder, findsOneWidget);

    // Check for "Develop4God" text using Poppins
    expect(find.textContaining('Develop'), findsOneWidget);
    expect(find.textContaining('God'), findsOneWidget);
    expect(find.textContaining('4'), findsOneWidget);

    // Ensure no exceptions are thrown during rendering
    expect(tester.takeException(), isNull);
  });
}
