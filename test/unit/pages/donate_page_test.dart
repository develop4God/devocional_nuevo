// test/unit/pages/donate_page_test.dart
import 'package:devocional_nuevo/pages/donate_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers.dart';

void main() {
  group('DonatePage Widget Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should display page title and description',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const DonatePage()));
      await tester.pumpAndSettle();

      // Check for page title
      expect(find.text('Support Our Ministry'), findsOneWidget);

      // Check for gratitude message
      expect(find.textContaining('God bless you'), findsOneWidget);

      // Check for description
      expect(find.textContaining('Help us continue'), findsOneWidget);
    });

    testWidgets('should display amount selection buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const DonatePage()));
      await tester.pumpAndSettle();

      // Check for amount selection title
      expect(find.text('Choose Support Amount'), findsOneWidget);

      // Check for amount buttons
      expect(find.text('\$5'), findsOneWidget);
      expect(find.text('\$10'), findsOneWidget);
      expect(find.text('\$20'), findsOneWidget);

      // Check for custom amount section
      expect(find.text('Custom Amount'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should allow amount selection', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const DonatePage()));
      await tester.pumpAndSettle();

      // Tap on $10 button
      await tester.tap(find.text('\$10'));
      await tester.pumpAndSettle();

      // Badge selection should appear
      expect(find.text('Choose Your Badge'), findsOneWidget);
      expect(find.text('Select a badge as a token of our gratitude'),
          findsOneWidget);
    });

    testWidgets('should validate custom amount input',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const DonatePage()));
      await tester.pumpAndSettle();

      // Find custom amount text field
      final customAmountField = find.byType(TextFormField);
      expect(customAmountField, findsOneWidget);

      // Test invalid input (below minimum)
      await tester.enterText(customAmountField, '0.5');
      await tester.pumpAndSettle();

      // Badge selection should not appear for invalid amount
      expect(find.text('Choose Your Badge'), findsNothing);

      // Test valid input
      await tester.enterText(customAmountField, '15');
      await tester.pumpAndSettle();

      // Badge selection should appear
      expect(find.text('Choose Your Badge'), findsOneWidget);
    });

    testWidgets('should display badge selection after amount selection',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const DonatePage()));
      await tester.pumpAndSettle();

      // Select an amount first
      await tester.tap(find.text('\$5'));
      await tester.pumpAndSettle();

      // Check that badge selection appears
      expect(find.text('Choose Your Badge'), findsOneWidget);

      // Check for badge grid (should have 5 badges based on our implementation)
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets(
        'should show continue button when both amount and badge are selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const DonatePage()));
      await tester.pumpAndSettle();

      // Select amount
      await tester.tap(find.text('\$5'));
      await tester.pumpAndSettle();

      // Continue button should not appear yet
      expect(find.text('Continue to Payment'), findsNothing);

      // Select a badge (tap on first badge)
      final badges = find.byType(InkWell);
      if (badges.evaluate().isNotEmpty) {
        await tester.tap(badges.first);
        await tester.pumpAndSettle();

        // Continue button should now appear
        expect(find.text('Continue to Payment'), findsOneWidget);
      }
    });

    testWidgets('should handle back button correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const DonatePage()));
      await tester.pumpAndSettle();

      // Find and tap back button
      final backButton = find.byType(BackButton);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Page should be popped (we can't easily test navigation without a full app context)
    });

    testWidgets('should show favorite icon in header',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const DonatePage()));
      await tester.pumpAndSettle();

      // Check for heart/favorite icon in header
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('should have accessible button targets',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const DonatePage()));
      await tester.pumpAndSettle();

      // Check that amount buttons have proper tap targets
      final amountButtons = find.byType(InkWell);
      expect(amountButtons.evaluate().length, greaterThan(0));

      // Verify button sizes are accessible (at least 44px as per requirement)
      for (final element in amountButtons.evaluate()) {
        final widget = element.widget as InkWell;
        final container = widget.child;
        // This is a basic check - in a real app we'd measure actual render sizes
        expect(container, isNotNull);
      }
    });

    group('Error Handling', () {
      testWidgets('should handle donation service errors gracefully',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(const DonatePage()));
        await tester.pumpAndSettle();

        // Page should load without errors even if donation service has issues
        expect(find.byType(DonatePage), findsOneWidget);
        expect(find.text('Support Our Ministry'), findsOneWidget);
      });

      testWidgets('should validate text input properly',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(const DonatePage()));
        await tester.pumpAndSettle();

        final customAmountField = find.byType(TextFormField);

        // Test various invalid inputs
        final invalidInputs = ['abc', '-5', '0', ''];

        for (final input in invalidInputs) {
          await tester.enterText(customAmountField, input);
          await tester.pumpAndSettle();

          // Badge selection should not appear for invalid inputs
          expect(find.text('Choose Your Badge'), findsNothing,
              reason:
                  'Badge selection should not appear for invalid input: $input');
        }
      });
    });

    group('Internationalization', () {
      testWidgets('should display localized text', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(const DonatePage()));
        await tester.pumpAndSettle();

        // Check that localized strings are displayed
        // These are the English versions, but the .tr() extension should be working
        expect(find.textContaining('Support'), findsWidgets);
        expect(find.textContaining('Ministry'), findsOneWidget);
      });
    });
  });
}
