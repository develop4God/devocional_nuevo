import 'package:devocional_nuevo/pages/progress_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Progress Page Overflow Tests', () {
    setUp(() {
      // Initialize Flutter binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();
      // Initialize SharedPreferences mock for each test
      SharedPreferences.setMockInitialValues({});
    });

    Widget createProgressPageWithProvider({required Size screenSize}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: ChangeNotifierProvider(
            create: (_) => DevocionalProvider(),
            child: const ProgressPage(),
          ),
        ),
      );
    }

    testWidgets('Progress page should not overflow on small screen (320x568)', (
      WidgetTester tester,
    ) async {
      // iPhone SE size (smallest common screen)
      const smallScreenSize = Size(320, 568);

      // Capture any overflow errors
      final List<FlutterError> errors = [];
      FlutterError.onError = (details) {
        if (details.exception.toString().contains('overflowed')) {
          errors.add(details as FlutterError);
        }
      };

      await tester.pumpWidget(
        createProgressPageWithProvider(screenSize: smallScreenSize),
      );

      // Wait for the page to fully load
      await tester.pumpAndSettle();

      // Verify no overflow errors occurred
      expect(
        errors,
        isEmpty,
        reason: 'Progress page should not have overflow errors on small screen',
      );

      // Verify key elements are present
      expect(find.text('Mi Progreso Espiritual'), findsOneWidget);
      expect(find.text('Racha Actual'), findsOneWidget);
      expect(find.text('Logros'), findsOneWidget);
      expect(find.text('Acciones Rápidas'), findsOneWidget);
    });

    testWidgets('Progress page should not overflow on medium screen (375x667)',
        (WidgetTester tester) async {
      // iPhone 8 size
      const mediumScreenSize = Size(375, 667);

      final List<FlutterError> errors = [];
      FlutterError.onError = (details) {
        if (details.exception.toString().contains('overflowed')) {
          errors.add(details as FlutterError);
        }
      };

      await tester.pumpWidget(
        createProgressPageWithProvider(screenSize: mediumScreenSize),
      );
      await tester.pumpAndSettle();

      expect(
        errors,
        isEmpty,
        reason:
            'Progress page should not have overflow errors on medium screen',
      );
      expect(find.text('Mi Progreso Espiritual'), findsOneWidget);
      expect(find.text('Racha Actual'), findsOneWidget);
      expect(find.text('Logros'), findsOneWidget);
      expect(find.text('Acciones Rápidas'), findsOneWidget);
    });

    testWidgets('Progress page should not overflow on large screen (414x896)',
        (WidgetTester tester) async {
      // iPhone XR size (large screen)
      const largeScreenSize = Size(414, 896);

      final List<FlutterError> errors = [];
      FlutterError.onError = (details) {
        if (details.exception.toString().contains('overflowed')) {
          errors.add(details as FlutterError);
        }
      };

      await tester.pumpWidget(
        createProgressPageWithProvider(screenSize: largeScreenSize),
      );
      await tester.pumpAndSettle();

      expect(
        errors,
        isEmpty,
        reason: 'Progress page should not have overflow errors on large screen',
      );
      expect(find.text('Mi Progreso Espiritual'), findsOneWidget);
      expect(find.text('Racha Actual'), findsOneWidget);
      expect(find.text('Logros'), findsOneWidget);
      expect(find.text('Acciones Rápidas'), findsOneWidget);
    });
  });
}
