// test/unit/blocs/onboarding_bloc_persistence_test.dart
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_bloc.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_event.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_models.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_state.dart';
import 'package:devocional_nuevo/providers/theme_provider.dart';
import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingBloc Persistence Tests', () {
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

    group('JSON Serialization', () {
      test('OnboardingProgress should serialize and deserialize correctly', () {
        final progress = OnboardingProgress(
          totalSteps: 4,
          completedSteps: 2,
          stepCompletionStatus: [true, true, false, false],
          progressPercentage: 50.0,
        );

        final json = progress.toJson();
        final restored = OnboardingProgress.fromJson(json);

        expect(restored.totalSteps, progress.totalSteps);
        expect(restored.completedSteps, progress.completedSteps);
        expect(restored.stepCompletionStatus, progress.stepCompletionStatus);
        expect(restored.progressPercentage, progress.progressPercentage);
      });

      test('OnboardingConfiguration should serialize and deserialize correctly', () {
        final config = OnboardingConfiguration(
          selectedThemeFamily: 'Blue',
          backupEnabled: true,
          selectedLanguage: 'es',
          notificationsEnabled: false,
          additionalSettings: {'testKey': 'testValue'},
          lastUpdated: DateTime.now(),
        );

        final json = config.toJson();
        final restored = OnboardingConfiguration.fromJson(json);

        expect(restored.selectedThemeFamily, config.selectedThemeFamily);
        expect(restored.backupEnabled, config.backupEnabled);
        expect(restored.selectedLanguage, config.selectedLanguage);
        expect(restored.notificationsEnabled, config.notificationsEnabled);
        expect(restored.additionalSettings, config.additionalSettings);
      });
    });

    group('Persistence Implementation', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'should save and load configuration correctly',
        build: () => onboardingBloc,
        act: (bloc) async {
          // Set up test data in SharedPreferences
          final testConfig = {'selectedThemeFamily': 'Blue', 'backupEnabled': true};
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('onboarding_configuration', jsonEncode(testConfig));
          
          bloc.add(const InitializeOnboarding());
        },
        wait: const Duration(milliseconds: 100),
        expect: () => [
          const OnboardingLoading(),
          isA<OnboardingStepActive>(),
        ],
      );

      blocTest<OnboardingBloc, OnboardingState>(
        'should save and load progress correctly',
        build: () => onboardingBloc,
        act: (bloc) async {
          // Set up test progress data
          final progress = OnboardingProgress(
            totalSteps: 4,
            completedSteps: 2,
            stepCompletionStatus: [true, true, false, false],
            progressPercentage: 50.0,
          );
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('onboarding_progress', jsonEncode(progress.toJson()));
          
          bloc.add(const InitializeOnboarding());
        },
        wait: const Duration(milliseconds: 100),
        expect: () => [
          const OnboardingLoading(),
          isA<OnboardingStepActive>()
              .having((state) => state.currentStepIndex, 'currentStepIndex', 2),
        ],
      );
    });

    group('Configuration Validation', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'should reject invalid theme family',
        build: () => onboardingBloc,
        seed: () => OnboardingStepActive(
          currentStepIndex: 1,
          currentStep: OnboardingSteps.defaultSteps[1],
          userSelections: const {},
          stepConfiguration: const {},
          canProgress: true,
          canGoBack: true,
          progress: OnboardingProgress.fromStepCompletion([true, false, false, false]),
        ),
        act: (bloc) => bloc.add(const SelectTheme('')), // Empty theme
        expect: () => [
          isA<OnboardingError>()
              .having((state) => state.category, 'category', 
                  OnboardingErrorCategory.invalidConfiguration),
        ],
      );

      blocTest<OnboardingBloc, OnboardingState>(
        'should accept valid theme family',
        build: () => onboardingBloc,
        seed: () => OnboardingStepActive(
          currentStepIndex: 1,
          currentStep: OnboardingSteps.defaultSteps[1],
          userSelections: const {},
          stepConfiguration: const {},
          canProgress: true,
          canGoBack: true,
          progress: OnboardingProgress.fromStepCompletion([true, false, false, false]),
        ),
        act: (bloc) => bloc.add(const SelectTheme('Blue')),
        expect: () => [
          isA<OnboardingConfiguring>(),
          isA<OnboardingStepActive>()
              .having((state) => state.userSelections['selectedThemeFamily'],
                  'selectedThemeFamily', 'Blue'),
        ],
      );
    });

    group('Error Handling', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'should handle configuration validation errors gracefully',
        build: () => onboardingBloc,
        seed: () => OnboardingStepActive(
          currentStepIndex: 1,
          currentStep: OnboardingSteps.defaultSteps[1],
          userSelections: const {},
          stepConfiguration: const {},
          canProgress: true,
          canGoBack: true,
          progress: OnboardingProgress.fromStepCompletion([true, false, false, false]),
        ),
        act: (bloc) => bloc.add(const SelectTheme('   ')), // Whitespace-only theme
        expect: () => [
          isA<OnboardingError>()
              .having((state) => state.message, 'message', contains('Invalid theme family')),
        ],
      );

      test('should handle malformed JSON gracefully', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('onboarding_configuration', '{invalid json}');
        
        // This should not throw an exception
        onboardingBloc.add(const InitializeOnboarding());
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Should handle the error gracefully and continue
        expect(onboardingBloc.state, isNot(isA<OnboardingError>()));
      });
    });

    group('ThemeProvider Fallback', () {
      test('should create fallback ThemeProvider with proper initialization', () {
        // This tests the fallback creation logic indirectly
        final fallbackProvider = ThemeProvider();
        fallbackProvider.initializeDefaults();
        
        expect(fallbackProvider.currentThemeFamily, isNotEmpty);
        expect(fallbackProvider.currentTheme, isNotNull);
      });
    });
  });
}