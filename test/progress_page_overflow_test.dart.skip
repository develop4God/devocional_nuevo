// test/progress_page_overflow_test.dart

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

    testWidgets(
      'Progress page should not overflow on medium screen (375x667)',
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
      },
    );

    testWidgets('Progress page should not overflow on large screen (414x896)', (
      WidgetTester tester,
    ) async {
      // iPhone 11 Pro Max size
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
    });

    testWidgets(
      'Progress page should not overflow on tablet screen (768x1024)',
      (WidgetTester tester) async {
        // iPad size
        const tabletScreenSize = Size(768, 1024);

        final List<FlutterError> errors = [];
        FlutterError.onError = (details) {
          if (details.exception.toString().contains('overflowed')) {
            errors.add(details as FlutterError);
          }
        };

        await tester.pumpWidget(
          createProgressPageWithProvider(screenSize: tabletScreenSize),
        );

        await tester.pumpAndSettle();

        expect(
          errors,
          isEmpty,
          reason:
              'Progress page should not have overflow errors on tablet screen',
        );
      },
    );

    testWidgets('Progress page should not overflow on landscape orientation', (
      WidgetTester tester,
    ) async {
      // Landscape orientation (small height)
      const landscapeSize = Size(667, 375);

      final List<FlutterError> errors = [];
      FlutterError.onError = (details) {
        if (details.exception.toString().contains('overflowed')) {
          errors.add(details as FlutterError);
        }
      };

      await tester.pumpWidget(
        createProgressPageWithProvider(screenSize: landscapeSize),
      );

      await tester.pumpAndSettle();

      expect(
        errors,
        isEmpty,
        reason: 'Progress page should not have overflow errors in landscape',
      );
    });

    testWidgets(
      'All achievements should be properly displayed without overflow',
      (WidgetTester tester) async {
        const testScreenSize = Size(320, 568); // Small screen for stress test

        final List<FlutterError> errors = [];
        FlutterError.onError = (details) {
          if (details.exception.toString().contains('overflowed')) {
            errors.add(details as FlutterError);
          }
        };

        await tester.pumpWidget(
          createProgressPageWithProvider(screenSize: testScreenSize),
        );

        await tester.pumpAndSettle();

        // Verify all predefined achievements are displayed
        expect(find.text('Primer Paso'), findsOneWidget);
        expect(find.text('Lector Semanal'), findsOneWidget);
        expect(find.text('Lector Mensual'), findsOneWidget);
        expect(find.text('Constancia'), findsOneWidget);
        expect(find.text('Semana Espiritual'), findsOneWidget);
        expect(find.text('Guerrero Espiritual'), findsOneWidget);
        expect(find.text('Primer Favorito'), findsOneWidget);
        expect(find.text('Coleccionista'), findsOneWidget);

        expect(
          errors,
          isEmpty,
          reason: 'All achievements should display without overflow',
        );
      },
    );

    testWidgets('SingleChildScrollView should handle content overflow', (
      WidgetTester tester,
    ) async {
      const verySmallScreenSize = Size(280, 400); // Very constrained screen

      final List<FlutterError> errors = [];
      FlutterError.onError = (details) {
        if (details.exception.toString().contains('overflowed')) {
          errors.add(details as FlutterError);
        }
      };

      await tester.pumpWidget(
        createProgressPageWithProvider(screenSize: verySmallScreenSize),
      );

      await tester.pumpAndSettle();

      // Verify SingleChildScrollView is present and working
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Try to scroll to verify scrollability
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200), // Scroll up
      );
      await tester.pumpAndSettle();

      expect(
        errors,
        isEmpty,
        reason:
            'Content should be scrollable without overflow on very small screen',
      );
    });
  });
}
