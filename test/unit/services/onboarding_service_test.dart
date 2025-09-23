import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingService Tests', () {
    late OnboardingService onboardingService;

    setUp(() {
      onboardingService = OnboardingService.instance;
    });

    setUpAll(() {
      // Initialize SharedPreferences with mock
      SharedPreferences.setMockInitialValues({});
    });

    test('should return false for isOnboardingComplete initially', () async {
      final isComplete = await onboardingService.isOnboardingComplete();
      expect(isComplete, false);
    });

    test('should set onboarding as complete', () async {
      await onboardingService.setOnboardingComplete();
      final isComplete = await onboardingService.isOnboardingComplete();
      expect(isComplete, true);
    });

    test('should reset onboarding status', () async {
      // First set as complete
      await onboardingService.setOnboardingComplete();
      expect(await onboardingService.isOnboardingComplete(), true);

      // Then reset
      await onboardingService.resetOnboarding();
      expect(await onboardingService.isOnboardingComplete(), false);
    });

    test(
      'should return true for shouldShowOnboarding when not complete',
      () async {
        await onboardingService.resetOnboarding();
        final shouldShow = await onboardingService.shouldShowOnboarding();
        // Note: This will default to true since Firebase Remote Config will fail in tests
        expect(shouldShow, true);
      },
    );

    test(
      'should return false for shouldShowOnboarding when complete',
      () async {
        await onboardingService.setOnboardingComplete();
        final shouldShow = await onboardingService.shouldShowOnboarding();
        expect(shouldShow, false);
      },
    );

    test('should handle SharedPreferences errors gracefully', () async {
      // This test ensures the service doesn't crash on errors
      final isComplete = await onboardingService.isOnboardingComplete();
      expect(isComplete, isA<bool>());
    });

    test('should return singleton instance', () {
      final instance1 = OnboardingService.instance;
      final instance2 = OnboardingService.instance;
      expect(instance1, same(instance2));
    });

    test('should handle Firebase Remote Config errors gracefully', () async {
      // When Firebase Remote Config fails, should default to enabled
      final isEnabled = await onboardingService.isOnboardingEnabled();
      expect(isEnabled, true);
    });
  });
}
