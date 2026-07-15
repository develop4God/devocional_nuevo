@Tags(['unit'])
library;

import 'package:devocional_nuevo/debug/sections/debug_onboarding_section.dart';
import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockOnboardingService extends Mock implements OnboardingService {}

void main() {
  late MockOnboardingService mockOnboardingService;

  setUp(() {
    mockOnboardingService = MockOnboardingService();
  });

  Future<void> pumpSection(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DebugOnboardingSection(
            onboardingService: mockOnboardingService,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'shows current completion status from OnboardingService',
    (tester) async {
      when(
        () => mockOnboardingService.isOnboardingComplete(),
      ).thenAnswer((_) async => true);

      await pumpSection(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Complete: true'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping Reset Onboarding State calls resetOnboarding and refreshes status',
    (tester) async {
      when(
        () => mockOnboardingService.isOnboardingComplete(),
      ).thenAnswer((_) async => true);
      when(
        () => mockOnboardingService.resetOnboarding(),
      ).thenAnswer((_) async {});

      await pumpSection(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Complete: true'), findsOneWidget);

      // After reset, isOnboardingComplete should report false.
      when(
        () => mockOnboardingService.isOnboardingComplete(),
      ).thenAnswer((_) async => false);

      await tester.tap(find.text('Reset Onboarding State'));
      await tester.pumpAndSettle();

      verify(() => mockOnboardingService.resetOnboarding()).called(1);
      expect(find.textContaining('Complete: false'), findsOneWidget);
    },
  );

  testWidgets(
    'shows error snackbar when resetOnboarding throws',
    (tester) async {
      when(
        () => mockOnboardingService.isOnboardingComplete(),
      ).thenAnswer((_) async => false);
      when(
        () => mockOnboardingService.resetOnboarding(),
      ).thenThrow(Exception('reset failed'));

      await pumpSection(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset Onboarding State'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error'), findsOneWidget);
    },
  );
}
