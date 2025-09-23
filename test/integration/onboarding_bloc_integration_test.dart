// test/integration/onboarding_bloc_integration_test.dart
import 'package:devocional_nuevo/blocs/onboarding/onboarding_bloc.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_event.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_models.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_state.dart';
import 'package:devocional_nuevo/providers/theme_provider.dart';
import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingBloc Integration Tests', () {
    late OnboardingBloc onboardingBloc;
    late ThemeProvider themeProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      themeProvider = ThemeProvider();
      onboardingBloc = OnboardingBloc(
        onboardingService: OnboardingService.instance,
        themeProvider: themeProvider,
        backupBloc: null,
      );
    });

    tearDown(() {
      onboardingBloc.close();
    });

    test('should complete full onboarding flow', () async {
      // Start with initial state
      expect(onboardingBloc.state, const OnboardingInitial());

      // Track state changes
      final states = <OnboardingState>[];
      final subscription = onboardingBloc.stream.listen(states.add);

      // Initialize onboarding
      onboardingBloc.add(const InitializeOnboarding());
      
      // Wait for first state change
      await Future.delayed(const Duration(milliseconds: 100));

      // Should have loading and then active step state
      expect(states.length, greaterThan(0));
      expect(states[0], isA<OnboardingLoading>());
      
      if (states.length > 1) {
        expect(states[1], isA<OnboardingStepActive>());
        final activeState = states[1] as OnboardingStepActive;
        expect(activeState.currentStepIndex, 0);
        expect(activeState.currentStep.type, OnboardingStepType.welcome);
      }

      await subscription.cancel();
    });

    test('should handle theme selection correctly', () async {
      // Initialize to active state
      onboardingBloc.add(const InitializeOnboarding());
      await Future.delayed(const Duration(milliseconds: 100));

      // Progress to theme selection step
      onboardingBloc.add(const ProgressToStep(1));
      await Future.delayed(const Duration(milliseconds: 100));

      // Select a theme
      onboardingBloc.add(const SelectTheme('Blue'));
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify theme was applied
      expect(themeProvider.currentThemeFamily, 'Blue');
    });

    test('should handle backup configuration', () async {
      // Initialize and progress to backup step
      onboardingBloc.add(const InitializeOnboarding());
      await Future.delayed(const Duration(milliseconds: 100));

      onboardingBloc.add(const ProgressToStep(2));
      await Future.delayed(const Duration(milliseconds: 100));

      // Track states for backup configuration
      final states = <OnboardingState>[];
      final subscription = onboardingBloc.stream.listen(states.add);

      // Configure backup
      onboardingBloc.add(const ConfigureBackupOption(true));
      await Future.delayed(const Duration(milliseconds: 100));

      // Should have configuration states
      expect(states.any((state) => state is OnboardingConfiguring), true);
      
      await subscription.cancel();
    });

    test('should complete onboarding successfully', () async {
      // Initialize onboarding
      onboardingBloc.add(const InitializeOnboarding());
      await Future.delayed(const Duration(milliseconds: 100));

      // Track completion
      final states = <OnboardingState>[];
      final subscription = onboardingBloc.stream.listen(states.add);

      // Complete onboarding
      onboardingBloc.add(const CompleteOnboarding());
      await Future.delayed(const Duration(milliseconds: 100));

      // Should eventually reach completed state
      expect(states.any((state) => state is OnboardingCompleted), true);

      await subscription.cancel();
    });

    test('should handle navigation between steps', () async {
      // Initialize
      onboardingBloc.add(const InitializeOnboarding());
      await Future.delayed(const Duration(milliseconds: 100));

      // Test forward navigation
      onboardingBloc.add(const ProgressToStep(1));
      await Future.delayed(const Duration(milliseconds: 50));

      onboardingBloc.add(const ProgressToStep(2));
      await Future.delayed(const Duration(milliseconds: 50));

      // Test backward navigation
      onboardingBloc.add(const GoToPreviousStep());
      await Future.delayed(const Duration(milliseconds: 50));

      // Test skip functionality
      onboardingBloc.add(const SkipCurrentStep());
      await Future.delayed(const Duration(milliseconds: 50));

      // All operations should complete without errors
      expect(onboardingBloc.state, isNot(isA<OnboardingError>()));
    });

    test('should handle step configuration updates', () async {
      // Initialize and get to active state
      onboardingBloc.add(const InitializeOnboarding());
      await Future.delayed(const Duration(milliseconds: 100));

      // Update step configuration
      onboardingBloc.add(const UpdateStepConfiguration({
        'testKey': 'testValue',
        'anotherKey': 42,
      }));
      await Future.delayed(const Duration(milliseconds: 50));

      // Update preview
      onboardingBloc.add(const UpdatePreview('theme', 'Red'));
      await Future.delayed(const Duration(milliseconds: 50));

      // Should handle configuration updates without errors
      expect(onboardingBloc.state, isNot(isA<OnboardingError>()));
    });

    test('should reset onboarding correctly', () async {
      // Initialize and complete some steps
      onboardingBloc.add(const InitializeOnboarding());
      await Future.delayed(const Duration(milliseconds: 100));

      onboardingBloc.add(const ProgressToStep(1));
      await Future.delayed(const Duration(milliseconds: 50));

      // Reset onboarding
      onboardingBloc.add(const ResetOnboarding());
      await Future.delayed(const Duration(milliseconds: 100));

      // Should return to initial state
      expect(onboardingBloc.state, const OnboardingInitial());
    });

    test('should maintain state consistency during rapid events', () async {
      // Rapid fire events to test state consistency
      onboardingBloc.add(const InitializeOnboarding());
      onboardingBloc.add(const ProgressToStep(1));
      onboardingBloc.add(const SelectTheme('Green'));
      onboardingBloc.add(const ProgressToStep(2));
      onboardingBloc.add(const ConfigureBackupOption(false));
      onboardingBloc.add(const ProgressToStep(3));

      // Wait for all events to process
      await Future.delayed(const Duration(milliseconds: 200));

      // Should not end in error state
      expect(onboardingBloc.state, isNot(isA<OnboardingError>()));
    });

    test('should handle service integration properly', () async {
      // Test that the BLoC properly integrates with OnboardingService
      final service = OnboardingService.instance;
      
      // Reset to ensure clean state
      await service.resetOnboarding();
      
      // Initialize onboarding
      onboardingBloc.add(const InitializeOnboarding());
      await Future.delayed(const Duration(milliseconds: 100));

      // Complete onboarding
      onboardingBloc.add(const CompleteOnboarding());
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify service state is updated
      final isComplete = await service.isOnboardingComplete();
      expect(isComplete, true);
    });
  });
}