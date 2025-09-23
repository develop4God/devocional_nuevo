import 'package:devocional_nuevo/pages/onboarding/onboarding_theme_selection_page.dart';
import 'package:devocional_nuevo/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingThemeSelectionPage UI Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: OnboardingThemeSelectionPage(
            onNext: () {},
            onBack: () {},
            onSkip: () {},
          ),
        ),
      );
    }

    testWidgets('should not have UI overflow in theme selection grid', (
      WidgetTester tester,
    ) async {
      // Set a constrained screen size to test overflow scenarios
      await tester.binding.setSurfaceSize(const Size(400, 600));
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify no overflow exceptions occurred
      expect(tester.takeException(), isNull);

      // Verify the GridView is present and scrollable
      expect(find.byType(GridView), findsOneWidget);
      
      // Test scrolling to ensure no overflow during interaction
      await tester.drag(find.byType(GridView), const Offset(0, -100));
      await tester.pumpAndSettle();
      
      // Verify no exceptions after scrolling
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle small screen sizes without overflow', (
      WidgetTester tester,
    ) async {
      // Test with very small screen size
      await tester.binding.setSurfaceSize(const Size(320, 480));
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify no overflow exceptions occurred
      expect(tester.takeException(), isNull);
      
      // Verify content is still accessible
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should properly constrain text in grid items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify GridView is present
      expect(find.byType(GridView), findsOneWidget);
      
      // Verify there are theme selection items (circles)
      expect(find.byType(Container), findsWidgets);
    });
  });
}