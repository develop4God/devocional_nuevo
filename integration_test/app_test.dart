import 'package:flutter/material.dart'; // Add this import for Scaffold
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:devocional_nuevo/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App muestra un Scaffold al finalizar el splash', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Espera tiempo suficiente para que las animaciones y navegaciones se completen
    await tester.pump(const Duration(seconds: 15));

    // Verifica que hay al menos un Scaffold en la pantalla
    expect(find.byType(Scaffold), findsWidgets);
  });
}