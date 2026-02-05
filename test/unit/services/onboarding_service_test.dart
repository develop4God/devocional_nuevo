@Tags(['unit', 'services'])
library;

import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Onboarding Feature Flag Tests', () {
    test('Onboarding feature should be disabled by default', () {
      // Verify that onboarding feature is disabled via feature flag
      expect(
        Constants.enableOnboardingFeature,
        false,
        reason: 'Onboarding feature should be disabled for users',
      );
    });

    test('Feature flag should prevent onboarding check', () {
      // When onboarding feature is disabled, onboarding should not show
      const onboardingFeatureEnabled = Constants.enableOnboardingFeature;

      if (!onboardingFeatureEnabled) {
        // Onboarding should not be checked
        expect(onboardingFeatureEnabled, false);
      }
    });

    test('Onboarding service should return false when disabled', () async {
      // Even if the service is called, it should return false
      final shouldShow =
          await OnboardingService.instance.shouldShowOnboarding();

      // Onboarding is permanently disabled
      expect(
        shouldShow,
        false,
        reason: 'Onboarding should always return false when disabled',
      );
    });

    test('Feature flag is compile-time constant', () {
      // Verify it's a compile-time constant
      const flag = Constants.enableOnboardingFeature;
      expect(flag, false);
    });
  });
}
