import 'package:devocional_nuevo/pages/onboarding/onboarding_complete_page.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('OnboardingCompletePage Tests', () {
    late bool startAppCalled;

    setUp(() {
      startAppCalled = false;
    });

    Widget createTestWidget() {
      return ChangeNotifierProvider(
        create: (_) => LocalizationProvider(),
        child: MaterialApp(
          home: OnboardingCompletePage(onStartApp: () => startAppCalled = true),
        ),
      );
    }

    testWidgets('should display completion elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for completion title
      expect(find.text('Everything is ready!'), findsOneWidget);

      // Check for completion subtitle
      expect(
        find.text(
          'Your spiritual space has been configured. Start your devotional journey with confidence.',
        ),
        findsOneWidget,
      );

      // Check for start button
      expect(find.text('Start Your Journey'), findsOneWidget);

      // Check for setup summary
      expect(find.text('Your Setup'), findsOneWidget);
    });

    testWidgets('should display celebration check icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Initial frame

      // Check for celebration check icon
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Let animation complete
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('should display setup items', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for setup items icons
      expect(find.byIcon(Icons.palette), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.byIcon(Icons.security), findsOneWidget);

      // Check for setup check icons
      expect(find.byIcon(Icons.check_circle), findsNWidgets(3));

      // Check for setup item texts
      expect(find.textContaining('Tema personalizado'), findsOneWidget);
      expect(find.textContaining('Google Drive'), findsOneWidget);
      expect(find.textContaining('seguros y encriptados'), findsOneWidget);
    });

    testWidgets('should call onStartApp when button is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final startButton = find.text('Start Your Journey');
      expect(startButton, findsOneWidget);

      await tester.tap(startButton);
      await tester.pumpAndSettle();

      expect(startAppCalled, true);
    });

    testWidgets('should animate elements properly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Initial frame - elements should not be visible yet
      await tester.pump();

      // Fast forward through animation
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Elements should be visible now
      expect(find.text('Everything is ready!'), findsOneWidget);
      expect(find.text('Start Your Journey'), findsOneWidget);
    });

    testWidgets('should have proper button styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the start button
      final startButton = find.byType(ElevatedButton);
      expect(startButton, findsOneWidget);

      final buttonWidget = tester.widget<ElevatedButton>(startButton);
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('should show setup summary container', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for setup summary container with proper decoration
      final summaryContainer = find.byWidgetPredicate(
        (widget) => widget is Container && widget.padding != null,
      );
      expect(summaryContainer, findsWidgets);
    });

    testWidgets('should have accessibility support', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check that the button is accessible
      final startButton = find.text('Start Your Journey');
      expect(startButton, findsOneWidget);

      // Verify button is tappable
      await tester.tap(startButton);
      expect(startAppCalled, true);
    });
  });
}
