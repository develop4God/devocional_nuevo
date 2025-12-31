// lib/blocs/onboarding/onboarding_models.dart
import 'package:equatable/equatable.dart';

/// Configuration types for onboarding operations
enum OnboardingConfigurationType {
  themeSelection,
  backupConfiguration,
  languageSelection,
  notificationSettings,
}

/// Error categories for proper handling
enum OnboardingErrorCategory {
  serviceUnavailable,
  networkError,
  invalidConfiguration,
  permissionDenied,
  unknown,
}

/// Step types in onboarding flow
enum OnboardingStepType {
  welcome,
  themeSelection,
  backupConfiguration,
  completion,
}

/// Information about an onboarding step
class OnboardingStepInfo extends Equatable {
  final OnboardingStepType type;
  final String title;
  final String subtitle;
  final bool isRequired;
  final bool isSkippable;
  final Map<String, dynamic> metadata;

  const OnboardingStepInfo({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.isRequired,
    required this.isSkippable,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [
        type,
        title,
        subtitle,
        isRequired,
        isSkippable,
        metadata,
      ];
}

/// Progress tracking for onboarding flow
class OnboardingProgress extends Equatable {
  final int totalSteps;
  final int completedSteps;
  final List<bool> stepCompletionStatus;
  final double progressPercentage;

  const OnboardingProgress({
    required this.totalSteps,
    required this.completedSteps,
    required this.stepCompletionStatus,
    required this.progressPercentage,
  });

  @override
  List<Object?> get props => [
        totalSteps,
        completedSteps,
        stepCompletionStatus,
        progressPercentage,
      ];

  /// Create progress with updated completion status
  OnboardingProgress copyWith({
    int? totalSteps,
    int? completedSteps,
    List<bool>? stepCompletionStatus,
    double? progressPercentage,
  }) {
    return OnboardingProgress(
      totalSteps: totalSteps ?? this.totalSteps,
      completedSteps: completedSteps ?? this.completedSteps,
      stepCompletionStatus: stepCompletionStatus ?? this.stepCompletionStatus,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }

  /// Calculate progress percentage from completion status
  factory OnboardingProgress.fromStepCompletion(
    List<bool> stepCompletionStatus,
  ) {
    final totalSteps = stepCompletionStatus.length;
    final completedSteps =
        stepCompletionStatus.where((completed) => completed).length;
    final progressPercentage =
        totalSteps > 0 ? (completedSteps / totalSteps) * 100 : 0.0;

    return OnboardingProgress(
      totalSteps: totalSteps,
      completedSteps: completedSteps,
      stepCompletionStatus: stepCompletionStatus,
      progressPercentage: progressPercentage,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'totalSteps': totalSteps,
      'completedSteps': completedSteps,
      'stepCompletionStatus': stepCompletionStatus,
      'progressPercentage': progressPercentage,
    };
  }

  /// Create from JSON for restoration
  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    return OnboardingProgress(
      totalSteps: json['totalSteps'] as int,
      completedSteps: json['completedSteps'] as int,
      stepCompletionStatus: List<bool>.from(
        json['stepCompletionStatus'] as List,
      ),
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
    );
  }
}

/// Configuration data for onboarding
class OnboardingConfiguration extends Equatable {
  final String? selectedThemeFamily;
  final bool? backupEnabled;
  final String? selectedLanguage;
  final bool? notificationsEnabled;
  final Map<String, dynamic> additionalSettings;
  final DateTime lastUpdated;

  const OnboardingConfiguration({
    this.selectedThemeFamily,
    this.backupEnabled,
    this.selectedLanguage,
    this.notificationsEnabled,
    this.additionalSettings = const {},
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        selectedThemeFamily,
        backupEnabled,
        selectedLanguage,
        notificationsEnabled,
        additionalSettings,
        lastUpdated,
      ];

  /// Create a copy with updated values
  OnboardingConfiguration copyWith({
    String? selectedThemeFamily,
    bool? backupEnabled,
    String? selectedLanguage,
    bool? notificationsEnabled,
    Map<String, dynamic>? additionalSettings,
    DateTime? lastUpdated,
  }) {
    return OnboardingConfiguration(
      selectedThemeFamily: selectedThemeFamily ?? this.selectedThemeFamily,
      backupEnabled: backupEnabled ?? this.backupEnabled,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      additionalSettings: additionalSettings ?? this.additionalSettings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'selectedThemeFamily': selectedThemeFamily,
      'backupEnabled': backupEnabled,
      'selectedLanguage': selectedLanguage,
      'notificationsEnabled': notificationsEnabled,
      'additionalSettings': additionalSettings,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from JSON for restoration
  factory OnboardingConfiguration.fromJson(Map<String, dynamic> json) {
    return OnboardingConfiguration(
      selectedThemeFamily: json['selectedThemeFamily'] as String?,
      backupEnabled: json['backupEnabled'] as bool?,
      selectedLanguage: json['selectedLanguage'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool?,
      additionalSettings: Map<String, dynamic>.from(
        json['additionalSettings'] ?? {},
      ),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

/// Default step configurations
class OnboardingSteps {
  static const List<OnboardingStepInfo> defaultSteps = [
    OnboardingStepInfo(
      type: OnboardingStepType.welcome,
      title: 'Welcome to your spiritual space',
      subtitle: 'Start your spiritual journey with us',
      isRequired: true,
      isSkippable: false,
    ),
    OnboardingStepInfo(
      type: OnboardingStepType.themeSelection,
      title: 'Choose your theme',
      subtitle: 'Select the color theme that resonates with you',
      isRequired: false,
      isSkippable: true,
    ),
    OnboardingStepInfo(
      type: OnboardingStepType.backupConfiguration,
      title: 'Protect your spiritual progress',
      subtitle: 'Keep your data safe with automatic backups',
      isRequired: false,
      isSkippable: true,
    ),
    OnboardingStepInfo(
      type: OnboardingStepType.completion,
      title: 'Everything is ready!',
      subtitle: 'You are all set to begin your spiritual journey',
      isRequired: true,
      isSkippable: false,
    ),
  ];
}
