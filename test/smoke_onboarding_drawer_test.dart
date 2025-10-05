import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  testWidgets('Real smoke test: onboarding + drawer with waits', (WidgetTester tester) async {
    // Step 0: Start app and wait for Firebase and localization
    print('[DEBUG] 🟢 Starting app (main)');
    app.main();
    await tester.pump(); // Initial frame

    // Step 1: Wait for splash and initial async setup (Firebase, localization, Remote Config)
    print('[DEBUG] ⏳ Waiting for splash and async initialization...');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle(const Duration(seconds: 2)); // Extra settle for slow devices

    // Step 2: Wait for either SplashScreen or OnboardingWelcomePage
    if (find.textContaining('Bienvenido').evaluate().isEmpty) {
      // Keep waiting for onboarding to appear
      var waitCycles = 0;
      while (find.textContaining('Bienvenido').evaluate().isEmpty && waitCycles < 15) {
        await tester.pump(const Duration(milliseconds: 500));
        waitCycles++;
      }
      print('[DEBUG] 🟣 Onboarding welcome visible after $waitCycles cycles');
    } else {
      print('[DEBUG] 🟣 Onboarding welcome already visible');
    }
    expect(find.textContaining('Bienvenido'), findsOneWidget);

    // Step 3: Tap "Siguiente" for welcome, wait for transition
    print('[DEBUG] 👉 Tapping Siguiente on welcome');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Siguiente'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Step 4: Wait for theme selection
    print('[DEBUG] ⏳ Waiting for theme selection page...');
    var waitTheme = 0;
    while (find.textContaining('Elige tu Ambiente').evaluate().isEmpty && waitTheme < 10) {
      await tester.pump(const Duration(milliseconds: 500));
      waitTheme++;
    }
    expect(find.textContaining('Elige tu Ambiente'), findsOneWidget);

    // Step 5: Select a theme and tap "Siguiente"
    print('[DEBUG] 👉 Selecting theme and tapping Siguiente');
    // You may need to adjust the finder if your theme tiles use a more specific key/type
    final themeTiles = find.byType(GestureDetector);
    expect(themeTiles, findsWidgets);
    await tester.tap(themeTiles.first);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Siguiente'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Step 6: Wait for backup config page
    print('[DEBUG] ⏳ Waiting for backup configuration page...');
    var waitBackup = 0;
    while (
      find.textContaining('Sincronización').evaluate().isEmpty &&
      find.textContaining('Configurar luego').evaluate().isEmpty &&
      waitBackup < 12
    ) {
      await tester.pump(const Duration(milliseconds: 500));
      waitBackup++;
    }
    expect(find.textContaining('Configurar luego'), findsOneWidget);

    // Step 7: Tap "Configurar luego"/"Omitir"
    print('[DEBUG] 👉 Tapping Configurar luego (skip backup)');
    await tester.tap(find.widgetWithText(TextButton, 'Configurar luego'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Step 8: Wait for completion page
    print('[DEBUG] ⏳ Waiting for onboarding complete page...');
    var waitComplete = 0;
    while (
      find.textContaining('¡Todo Listo!').evaluate().isEmpty &&
      waitComplete < 10
    ) {
      await tester.pump(const Duration(milliseconds: 500));
      waitComplete++;
    }
    expect(find.textContaining('¡Todo Listo!'), findsWidgets);

    // Step 9: Tap "Comenzar mi espacio con Dios"
    print('[DEBUG] 👉 Tapping start app');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Comenzar mi espacio con Dios'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Step 10: Wait for main splash and DevocionalesPage to load
    print('[DEBUG] ⏳ Waiting for main app splash and content...');
    var waitMain = 0;
    while (
      find.byIcon(Icons.menu).evaluate().isEmpty &&
      waitMain < 15
    ) {
      await tester.pump(const Duration(milliseconds: 500));
      waitMain++;
    }
    expect(find.byIcon(Icons.menu), findsOneWidget);

    // Step 11: Tap drawer (hamburger icon)
    print('[DEBUG] 👉 Tapping drawer menu icon');
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Step 12: Wait for drawer content
    print('[DEBUG] ⏳ Waiting for drawer to open...');
    var waitDrawer = 0;
    while (
      find.text('Tu Biblia, tu estilo').evaluate().isEmpty &&
      waitDrawer < 8
    ) {
      await tester.pump(const Duration(milliseconds: 400));
      waitDrawer++;
    }
    expect(find.text('Tu Biblia, tu estilo'), findsOneWidget);

    print('[DEBUG] ✅ Smoke test completed successfully.');
  });
}
