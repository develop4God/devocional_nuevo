import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:devocional_nuevo/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches and shows home page', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // Esperar tiempo suficiente para que las animaciones se completen
    await tester.pump(const Duration(seconds: 6));

    // El texto está en splash_screen.dart línea 113
    expect(find.text('Preparando tu espacio con Dios...'), findsOneWidget);
  });
}
