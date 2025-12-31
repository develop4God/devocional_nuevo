// lib/blocs/onboarding/onboarding_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'onboarding_models.dart';

/// States for onboarding flow functionality
abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

/// Loading state for asynchronous operations
class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

/// Active step state with current configuration
class OnboardingStepActive extends OnboardingState {
  final int currentStepIndex;
  final OnboardingStepInfo currentStep;
  final Map<String, dynamic> userSelections;
  final Map<String, dynamic> stepConfiguration;
  final bool canProgress;
  final bool canGoBack;
  final OnboardingProgress progress;

  const OnboardingStepActive({
    required this.currentStepIndex,
    required this.currentStep,
    required this.userSelections,
    required this.stepConfiguration,
    required this.canProgress,
    required this.canGoBack,
    required this.progress,
  });

  @override
  List<Object?> get props => [
        currentStepIndex,
        currentStep,
        userSelections,
        stepConfiguration,
        canProgress,
        canGoBack,
        progress,
      ];

  /// Create a copy with updated values
  OnboardingStepActive copyWith({
    int? currentStepIndex,
    OnboardingStepInfo? currentStep,
    Map<String, dynamic>? userSelections,
    Map<String, dynamic>? stepConfiguration,
    bool? canProgress,
    bool? canGoBack,
    OnboardingProgress? progress,
  }) {
    debugPrint(
      '[ONBOARDING_STATE] OnboardingStepActive.copyWith: userSelections=${userSelections ?? this.userSelections}',
    );
    return OnboardingStepActive(
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      currentStep: currentStep ?? this.currentStep,
      userSelections: userSelections ?? this.userSelections,
      stepConfiguration: stepConfiguration ?? this.stepConfiguration,
      canProgress: canProgress ?? this.canProgress,
      canGoBack: canGoBack ?? this.canGoBack,
      progress: progress ?? this.progress,
    );
  }
}

/// Configuration state for specific operations
class OnboardingConfiguring extends OnboardingState {
  final OnboardingConfigurationType configurationType;
  final Map<String, dynamic> configurationData;

  const OnboardingConfiguring({
    required this.configurationType,
    required this.configurationData,
  });

  @override
  List<Object?> get props => [configurationType, configurationData];
}

/// Completed state with summary
class OnboardingCompleted extends OnboardingState {
  final Map<String, dynamic> appliedConfigurations;
  final DateTime completionTimestamp;

  const OnboardingCompleted({
    required this.appliedConfigurations,
    required this.completionTimestamp,
  });

  @override
  List<Object?> get props => [appliedConfigurations, completionTimestamp];
}

/// Error state with descriptive messages
class OnboardingError extends OnboardingState {
  final String message;
  final OnboardingErrorCategory category;
  final Map<String, dynamic>? errorContext;

  const OnboardingError({
    required this.message,
    required this.category,
    this.errorContext,
  });

  @override
  List<Object?> get props => [message, category, errorContext];
}
