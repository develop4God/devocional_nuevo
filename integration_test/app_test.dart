import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:devocional_nuevo/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches and shows home page', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Cambia este texto si tu pantalla principal usa otro título
    expect(find.text('Preparando tu espacio con Dios...'), findsOneWidget);
  });
}
