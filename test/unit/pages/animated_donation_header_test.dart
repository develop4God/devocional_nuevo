// test/widgets/animated_donation_header_test.dart
import 'package:devocional_nuevo/widgets/donate/animated_donation_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock para la extensión de strings
class MockStringExtensions {
  static String tr(String key) {
    final translations = {
      'donate.gratitude_title': 'Gracias por tu apoyo',
      // Agrega más traducciones si las necesitas para testing
    };
    return translations[key] ?? key;
  }
}

// Extensión mock para testing
extension StringExtensionsTest on String {
  String tr() => MockStringExtensions.tr(this);
}

void main() {
  group('AnimatedDonationHeader Screen Size Tests', () {
    // Definir diferentes tamaños de pantalla para testing
    final screenSizes = {
      'iPhone SE (1st gen)': const Size(320, 568),
      'iPhone SE (2022)': const Size(375, 667),
      'iPhone 12 Mini': const Size(360, 780),
      'iPhone 12/13/14': const Size(390, 844),
      'iPhone 12/13/14 Pro Max': const Size(428, 926),
      'Samsung Galaxy S8': const Size(360, 740),
      'Samsung Galaxy S21': const Size(384, 854),
      'Google Pixel 5': const Size(393, 851),
      'Very Small Android': const Size(280, 480),
      'Small Android': const Size(320, 534),
      'Medium Android': const Size(360, 640),
      'Large Android': const Size(411, 823),
      'Tablet Small': const Size(768, 1024),
      'Tablet Medium': const Size(820, 1180),
      'Landscape Phone': const Size(667, 375),
      'Landscape Small': const Size(568, 320),
    };

    // Mock TextTheme y ColorScheme
    const mockTextTheme = TextTheme(
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );

    const mockColorScheme = ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.purple,
      tertiary: Colors.pink,
    );

    for (final entry in screenSizes.entries) {
      final deviceName = entry.key;
      final screenSize = entry.value;

      testWidgets(
          '$deviceName (${screenSize.width.toInt()}x${screenSize.height.toInt()}) - No Overflow',
          (WidgetTester tester) async {
        // Configurar el tamaño de pantalla específico
        await tester.binding.setSurfaceSize(screenSize);

        // Widget de prueba
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    AnimatedDonationHeader(
                      height: 240,
                      textTheme: mockTextTheme,
                      colorScheme: mockColorScheme,
                    ),
                    const SizedBox(height: 50),
                    Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Center(
                        child: Text(
                          'Contenido siguiente\n(${screenSize.width.toInt()}x${screenSize.height.toInt()})',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Esperar que todas las animaciones se inicialicen
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verificar que el widget se renderiza sin errores
        expect(find.byType(AnimatedDonationHeader), findsOneWidget);
        expect(find.byIcon(Icons.favorite), findsOneWidget);

        // Verificar que no hay RenderFlex overflow
        expect(tester.takeException(), isNull);

        // Probar diferentes alturas para este tamaño de pantalla
        final testHeights = [180.0, 200.0, 240.0, 280.0, 320.0];

        for (final height in testHeights) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: AnimatedDonationHeader(
                    height: height,
                    textTheme: mockTextTheme,
                    colorScheme: mockColorScheme,
                  ),
                ),
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull,
              reason:
                  'Height $height failed on $deviceName (${screenSize.width}x${screenSize.height})');
        }

        // Resetear el tamaño de pantalla
        await tester.binding.setSurfaceSize(null);
      });
    }

    testWidgets('Accessibility - Large Text Scale',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
              size: Size(375, 667),
            ),
            child: Scaffold(
              body: AnimatedDonationHeader(
                height: 240,
                textTheme: mockTextTheme,
                colorScheme: mockColorScheme,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AnimatedDonationHeader), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Animation Stress Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedDonationHeader(
              height: 240,
              textTheme: mockTextTheme,
              colorScheme: mockColorScheme,
            ),
          ),
        ),
      );

      // Simular múltiples frames de animación
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull,
            reason: 'Animation frame $i caused overflow');
      }
    });

    testWidgets('Extreme Small Screen Test', (WidgetTester tester) async {
      // Pantalla extremadamente pequeña
      await tester.binding.setSurfaceSize(const Size(240, 320));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnimatedDonationHeader(
                height: 120, // Altura mínima según clamp
                textTheme: mockTextTheme,
                colorScheme: mockColorScheme,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AnimatedDonationHeader), findsOneWidget);

      // Verificar que el clamp funciona correctamente
      final headerWidget = tester
          .widget<AnimatedDonationHeader>(find.byType(AnimatedDonationHeader));
      expect(headerWidget.height, equals(120.0));

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Height Clamp Test', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));

      // Test altura mínima
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedDonationHeader(
              height: 100, // Menor al mínimo
              textTheme: mockTextTheme,
              colorScheme: mockColorScheme,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AnimatedDonationHeader), findsOneWidget);

      // Test altura máxima relativa
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedDonationHeader(
              height: 1000, // Mayor al máximo permitido
              textTheme: mockTextTheme,
              colorScheme: mockColorScheme,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AnimatedDonationHeader), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(null);
    });

    group('Performance Tests', () {
      testWidgets('Multiple Instances', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: AnimatedDonationHeader(
                        height: 200,
                        textTheme: mockTextTheme,
                        colorScheme: mockColorScheme,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.byType(AnimatedDonationHeader), findsNWidgets(3));
        expect(tester.takeException(), isNull);

        // Test animaciones múltiples
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.takeException(), isNull);
        }
      });
    });
  });
}
