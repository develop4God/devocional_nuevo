import 'package:devocional_nuevo/pages/onboarding/onboarding_flow.dart';
import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingFlow Tests', () {
    late bool completeCalled;

    setUp(() {
      completeCalled = false;
      SharedPreferences.setMockInitialValues({});
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: OnboardingFlow(onComplete: () => completeCalled = true),
      );
    }

    testWidgets('should display progress indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for progress indicator containers
      final progressBars = find.byWidgetPredicate(
        (widget) => widget is Container,
      );
      expect(progressBars, findsWidgets);
    });

    testWidgets('should start with welcome page', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show welcome page content
      expect(find.text('Welcome to your spiritual space'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('should navigate to next page when next is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap next button on welcome page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should be on theme selection page
      expect(find.text('Choose your theme'), findsOneWidget);
    });

    testWidgets('should navigate back when back is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to second page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Choose your theme'), findsOneWidget);

      // Navigate back
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to your spiritual space'), findsOneWidget);
    });

    testWidgets('should skip to end when skip is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap skip button on welcome page
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Should be on completion page
      expect(find.text('Everything is ready!'), findsOneWidget);
    });

    testWidgets('should complete onboarding flow', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Skip to completion page
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Tap start app button
      await tester.tap(find.text('Start Your Journey'));
      await tester.pumpAndSettle();

      expect(completeCalled, true);
    });

    testWidgets('should update progress indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate through pages and check progress
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should have progressed through multiple pages
      expect(find.text('Protect your spiritual progress'), findsOneWidget);
    });

    testWidgets('should handle page controller properly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check that PageView is present
      expect(find.byType(PageView), findsOneWidget);

      // Check that pages are not scrollable (physics disabled)
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.physics, isA<NeverScrollableScrollPhysics>());
    });

    testWidgets('should mark onboarding as complete', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Skip to end
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Complete onboarding
      await tester.tap(find.text('Start Your Journey'));
      await tester.pumpAndSettle();

      // Check that onboarding service marked as complete
      final isComplete =
          await OnboardingService.instance.isOnboardingComplete();
      expect(isComplete, true);
    });

    testWidgets('should hide progress indicator on completion page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Skip to completion page
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Progress indicator should not be visible on completion page
      final progressContainer = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.padding != null &&
            widget.child is Row,
      );

      // The progress container should not be shown on completion page
      expect(find.text('Everything is ready!'), findsOneWidget);
    });

    testWidgets('should navigate through all pages sequentially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Page 1: Welcome
      expect(find.text('Welcome to your spiritual space'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Page 2: Theme Selection
      expect(find.text('Choose your theme'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Page 3: Backup Configuration
      expect(find.text('Protect your spiritual progress'), findsOneWidget);

      await tester.tap(find.text('Configure later'));
      await tester.pumpAndSettle();

      // Page 4: Completion
      expect(find.text('Everything is ready!'), findsOneWidget);
    });
  });
}
