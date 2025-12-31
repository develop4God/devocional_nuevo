import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Language Initialization and Feature Flags Tests', () {
    test('Feature flags should be properly defined', () {
      // Verify that feature flags exist and are set to false as required
      expect(
        Constants.enableOnboardingFeature,
        false,
        reason: 'Onboarding feature should be disabled',
      );
      expect(
        Constants.enableBackupFeature,
        false,
        reason: 'Backup feature should be disabled',
      );
    });

    test('Feature flags should be compile-time constants', () {
      // Verify these are compile-time constants (const)
      const onboardingEnabled = Constants.enableOnboardingFeature;
      const backupEnabled = Constants.enableBackupFeature;

      expect(onboardingEnabled, false);
      expect(backupEnabled, false);
    });
  });
}
