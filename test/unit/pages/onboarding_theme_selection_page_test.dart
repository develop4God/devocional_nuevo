import 'package:devocional_nuevo/pages/onboarding/onboarding_theme_selection_page.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('OnboardingThemeSelectionPage Tests', () {
    late bool nextCalled;
    late bool backCalled;
    late bool skipCalled;

    setUp(() {
      nextCalled = false;
      backCalled = false;
      skipCalled = false;
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocalizationProvider()),
        ],
        child: MaterialApp(
          home: OnboardingThemeSelectionPage(
            onNext: () => nextCalled = true,
            onBack: () => backCalled = true,
            onSkip: () => skipCalled = true,
          ),
        ),
      );
    }

    testWidgets('should display theme selection elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for navigation buttons
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Check for theme title
      expect(find.text('Choose your theme'), findsOneWidget);

      // Check for theme grid
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should call navigation callbacks', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Test back button
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(backCalled, true);

      // Reset and test skip button
      backCalled = false;
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(skipCalled, true);

      // Reset and test next button (should be enabled by default since theme is selected)
      skipCalled = false;
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(nextCalled, true);
    });

    testWidgets('should display theme options', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for theme names (in Spanish as per theme constants)
      expect(find.text('Realeza'), findsOneWidget); // Deep Purple
      expect(find.text('Vida'), findsOneWidget); // Green
      expect(find.text('Pureza'), findsOneWidget); // Pink
      expect(find.text('Obediencia'), findsOneWidget); // Cyan
      expect(find.text('Celestial'), findsOneWidget); // Light Blue
    });

    testWidgets('should allow theme selection', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap a theme option
      final themeOption = find.text('Vida').first;
      await tester.tap(themeOption);
      await tester.pumpAndSettle();

      // Check that check icon appears for selected theme
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('should enable next button when theme is selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Next button should be enabled by default (theme is pre-selected)
      final nextButton = find.text('Next');
      expect(nextButton, findsOneWidget);

      // Should be able to tap it
      await tester.tap(nextButton);
      await tester.pumpAndSettle();
      expect(nextCalled, true);
    });

    testWidgets('should apply theme immediately when selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the Green theme (Vida)
      final greenTheme = find.text('Vida');
      expect(greenTheme, findsOneWidget);

      // Tap to select it
      await tester.tap(greenTheme);
      await tester.pumpAndSettle();

      // Theme should be applied (we can check by looking for the theme provider changes)
      final themeProvider = Provider.of<ThemeProvider>(
        tester.element(find.byType(OnboardingThemeSelectionPage)),
        listen: false,
      );
      expect(themeProvider.currentThemeFamily, 'Green');
    });

    testWidgets('should show visual feedback for selected theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // All themes should be displayed
      expect(find.byType(GestureDetector), findsNWidgets(5));

      // Check that at least one theme has selection indicator
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });
  });
}
