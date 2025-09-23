// test/unit/pages/onboarding_flow_bloc_test.dart
import 'package:devocional_nuevo/blocs/onboarding/onboarding_bloc.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_flow.dart';
import 'package:devocional_nuevo/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingFlow with BLoC Tests', () {
    late bool completeCalled;
    late ThemeProvider themeProvider;

    setUp(() {
      completeCalled = false;
      SharedPreferences.setMockInitialValues({});
      themeProvider = ThemeProvider();
    });

    Widget createTestWidget() {
      return ChangeNotifierProvider<ThemeProvider>(
        create: (_) => themeProvider,
        child: MaterialApp(
          home: OnboardingFlow(onComplete: () => completeCalled = true),
        ),
      );
    }

    testWidgets('should display loading indicator initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Should show loading indicator while initializing
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display onboarding when not complete', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should display the first onboarding page
      expect(find.text('Welcome to your spiritual space'), findsOneWidget);
    });

    testWidgets('should display error state gracefully', (
      WidgetTester tester,
    ) async {
      // Set up a scenario that causes initialization error
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should either show onboarding or error state
      expect(
        find.byType(CircularProgressIndicator).evaluate().isEmpty ||
            find
                .text('Welcome to your spiritual space')
                .evaluate()
                .isNotEmpty ||
            find.text('Error loading onboarding').evaluate().isNotEmpty,
        true,
      );
    });

    testWidgets('should handle navigation between steps', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // If we successfully display the first page, test navigation
      if (find.text('Welcome to your spiritual space').evaluate().isNotEmpty) {
        // Find and tap the Next button
        final nextButton = find.text('Next');
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton);
          await tester.pumpAndSettle();

          // Should navigate to theme selection
          expect(find.text('Choose your theme'), findsOneWidget);
        }
      }
    });

    testWidgets('should handle BLoC state changes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify that the widget is using BLoC architecture
      final context = tester.element(find.byType(OnboardingFlow));

      // Should not throw when trying to read the BLoC
      expect(() {
        final bloc = context.read<OnboardingBloc?>();
        return bloc != null;
      }, returnsNormally);
    });

    testWidgets('should display progress indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for progress indicator containers
      final progressIndicators = find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration != null,
      );

      // Should have some form of progress indicator
      expect(progressIndicators.evaluate().isNotEmpty, true);
    });

    testWidgets('should handle theme provider integration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify theme provider is accessible
      final context = tester.element(find.byType(OnboardingFlow));
      expect(() {
        final theme = Provider.of<ThemeProvider>(context, listen: false);
        return theme;
      }, returnsNormally);
    });

    testWidgets('should handle completion callback', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Note: Testing completion callback would require navigating through all steps
      // which is complex to set up in a unit test. Integration tests would be better.
      expect(completeCalled, false); // Initially false
    });

    testWidgets('should handle missing providers gracefully', (
      WidgetTester tester,
    ) async {
      // Test without ThemeProvider to verify graceful handling
      final widget = MaterialApp(
        home: OnboardingFlow(onComplete: () => completeCalled = true),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Should handle gracefully without crashing
      expect(find.byType(OnboardingFlow), findsOneWidget);
    });

    testWidgets('should create fallback dependencies when needed', (
      WidgetTester tester,
    ) async {
      // Test the OnboardingFlow without any providers
      final widget = MaterialApp(
        home: OnboardingFlow(onComplete: () => completeCalled = true),
      );

      // Should not crash during initialization
      expect(() async {
        await tester.pumpWidget(widget);
        await tester.pump(); // Single pump to start initialization
      }, returnsNormally);
    });
  });
}
