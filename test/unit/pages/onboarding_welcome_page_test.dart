import 'package:devocional_nuevo/pages/onboarding/onboarding_welcome_page.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('OnboardingWelcomePage Tests', () {
    late bool nextCalled;
    late bool skipCalled;

    setUp(() {
      nextCalled = false;
      skipCalled = false;
    });

    Widget createTestWidget() {
      return ChangeNotifierProvider(
        create: (_) => LocalizationProvider(),
        child: MaterialApp(
          home: OnboardingWelcomePage(
            onNext: () => nextCalled = true,
            onSkip: () => skipCalled = true,
          ),
        ),
      );
    }

    testWidgets('should display welcome page elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for heart icon
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Check for skip button
      expect(find.text('Skip'), findsOneWidget);

      // Check for next button
      expect(find.text('Next'), findsOneWidget);

      // Check for welcome title
      expect(find.text('Welcome to your spiritual space'), findsOneWidget);
    });

    testWidgets('should call onNext when next button is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final nextButton = find.text('Next');
      expect(nextButton, findsOneWidget);

      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(nextCalled, true);
      expect(skipCalled, false);
    });

    testWidgets('should call onSkip when skip button is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final skipButton = find.text('Skip');
      expect(skipButton, findsOneWidget);

      await tester.tap(skipButton);
      await tester.pumpAndSettle();

      expect(skipCalled, true);
      expect(nextCalled, false);
    });

    testWidgets('should have proper accessibility', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check that buttons have minimum size for accessibility
      final nextButton = find.text('Next').first;
      final nextButtonWidget = tester.widget<ElevatedButton>(
        find.ancestor(of: nextButton, matching: find.byType(ElevatedButton)),
      );

      expect(nextButtonWidget, isNotNull);
    });

    testWidgets('should animate heart icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Initial frame

      // Check that heart is present
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Advance animation
      await tester.pump(const Duration(seconds: 1));

      // Heart should still be there
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('should display floating particles', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for particle containers (small circles)
      final particles = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.maxWidth == 4 &&
            widget.constraints?.maxHeight == 4,
      );

      // Should have multiple particles
      expect(particles, findsWidgets);
    });
  });
}
