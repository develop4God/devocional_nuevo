// lib/blocs/onboarding/onboarding_event.dart
import 'package:equatable/equatable.dart';

/// Events for onboarding flow functionality
abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize onboarding flow and determine starting point
class InitializeOnboarding extends OnboardingEvent {
  const InitializeOnboarding();
}

/// Progress to specific step in onboarding
class ProgressToStep extends OnboardingEvent {
  final int stepIndex;

  const ProgressToStep(this.stepIndex);

  @override
  List<Object?> get props => [stepIndex];
}

/// Select theme during onboarding
class SelectTheme extends OnboardingEvent {
  final String themeFamily;

  const SelectTheme(this.themeFamily);

  @override
  List<Object?> get props => [themeFamily];
}

/// Configure backup option during onboarding
class ConfigureBackupOption extends OnboardingEvent {
  final bool enableBackup;

  const ConfigureBackupOption(this.enableBackup);

  @override
  List<Object?> get props => [enableBackup];
}

/// Update configuration within current step
class UpdateStepConfiguration extends OnboardingEvent {
  final Map<String, dynamic> configuration;

  const UpdateStepConfiguration(this.configuration);

  @override
  List<Object?> get props => [configuration];
}

/// Complete onboarding flow
class CompleteOnboarding extends OnboardingEvent {
  const CompleteOnboarding();
}

/// Reset onboarding (for testing/debugging)
class ResetOnboarding extends OnboardingEvent {
  const ResetOnboarding();
}

/// Skip current step
class SkipCurrentStep extends OnboardingEvent {
  const SkipCurrentStep();
}

/// Go back to previous step
class GoToPreviousStep extends OnboardingEvent {
  const GoToPreviousStep();
}

/// Update temporary preview (for theme selection)
class UpdatePreview extends OnboardingEvent {
  final String previewType;
  final dynamic previewValue;

  const UpdatePreview(this.previewType, this.previewValue);

  @override
  List<Object?> get props => [previewType, previewValue];
}

/// Skip backup configuration for now (configure later)
class SkipBackupForNow extends OnboardingEvent {
  const SkipBackupForNow();
}
