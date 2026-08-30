@Tags(['unit', 'blocs', 'onboarding'])
library;

import 'package:devocional_nuevo/blocs/onboarding/onboarding_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnboardingEvent equality', () {
    test('InitializeOnboarding instances are equal', () {
      expect(const InitializeOnboarding(), const InitializeOnboarding());
    });

    test('ProgressToStep is equal only for the same stepIndex', () {
      expect(const ProgressToStep(2), const ProgressToStep(2));
      expect(const ProgressToStep(2), isNot(const ProgressToStep(3)));
    });

    test('SelectTheme is equal only for the same themeFamily', () {
      expect(const SelectTheme('ocean'), const SelectTheme('ocean'));
      expect(const SelectTheme('ocean'), isNot(const SelectTheme('forest')));
    });

    test('ConfigureBackupOption is equal only for the same enableBackup', () {
      expect(
        const ConfigureBackupOption(true),
        const ConfigureBackupOption(true),
      );
      expect(
        const ConfigureBackupOption(true),
        isNot(const ConfigureBackupOption(false)),
      );
    });

    test('UpdateStepConfiguration compares by configuration map contents', () {
      expect(
        const UpdateStepConfiguration({'key': 'value'}),
        const UpdateStepConfiguration({'key': 'value'}),
      );
      expect(
        const UpdateStepConfiguration({'key': 'value'}),
        isNot(const UpdateStepConfiguration({'key': 'other'})),
      );
    });

    test('CompleteOnboarding instances are equal', () {
      expect(const CompleteOnboarding(), const CompleteOnboarding());
    });

    test('ResetOnboarding instances are equal', () {
      expect(const ResetOnboarding(), const ResetOnboarding());
    });

    test('SkipCurrentStep instances are equal', () {
      expect(const SkipCurrentStep(), const SkipCurrentStep());
    });

    test('GoToPreviousStep instances are equal', () {
      expect(const GoToPreviousStep(), const GoToPreviousStep());
    });

    test('UpdatePreview is equal only for the same type and value', () {
      expect(
        const UpdatePreview('theme', 'ocean'),
        const UpdatePreview('theme', 'ocean'),
      );
      expect(
        const UpdatePreview('theme', 'ocean'),
        isNot(const UpdatePreview('theme', 'forest')),
      );
      expect(
        const UpdatePreview('theme', 'ocean'),
        isNot(const UpdatePreview('backup', 'ocean')),
      );
    });

    test('SkipBackupForNow instances are equal', () {
      expect(const SkipBackupForNow(), const SkipBackupForNow());
    });

    test('different event types are never equal even with matching props', () {
      expect(
        const InitializeOnboarding(),
        isNot(const CompleteOnboarding()),
      );
    });
  });
}
