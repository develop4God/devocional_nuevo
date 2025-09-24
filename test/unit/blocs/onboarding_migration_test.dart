// test/unit/blocs/onboarding_migration_test.dart
import 'dart:convert';

import 'package:devocional_nuevo/blocs/onboarding/onboarding_bloc.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_event.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_state.dart';
import 'package:devocional_nuevo/providers/theme_provider.dart';
import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingBloc Migration Tests', () {
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

    group('Schema Version Migration', () {
      test('should handle missing schema version (v0 -> v1)', () async {
        // Simulate old configuration without schema version wrapper
        final oldConfig = {
          'selectedThemeFamily': 'Blue',
          'backupEnabled': true,
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'onboarding_configuration', jsonEncode(oldConfig));

        // Initialize onboarding which should trigger migration
        onboardingBloc.add(const InitializeOnboarding());
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify that configuration was migrated and loaded correctly
        final savedConfigJson = prefs.getString('onboarding_configuration');
        expect(savedConfigJson, isNotNull);

        final savedWrapper =
            jsonDecode(savedConfigJson!) as Map<String, dynamic>;
        expect(savedWrapper['schemaVersion'], equals(1));
        expect(savedWrapper['payload']['selectedThemeFamily'], equals('Blue'));
        expect(savedWrapper['payload']['backupEnabled'], equals(true));
      });

      test('should handle missing schema version in progress (v0 -> v1)',
          () async {
        // Simulate old progress without schema version wrapper
        final oldProgress = {
          'totalSteps': 4,
          'completedSteps': 2,
          'stepCompletionStatus': [true, true, false, false],
          'progressPercentage': 50.0,
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('onboarding_progress', jsonEncode(oldProgress));

        // Initialize onboarding which should trigger migration
        onboardingBloc.add(const InitializeOnboarding());
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify the state has correctly loaded migrated progress
        expect(onboardingBloc.state, isA<OnboardingStepActive>());
        final activeState = onboardingBloc.state as OnboardingStepActive;
        expect(activeState.currentStepIndex, equals(2));
        expect(activeState.progress.completedSteps, equals(2));
      });

      test('should handle malformed configuration gracefully', () async {
        // Set malformed JSON
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('onboarding_configuration', '{invalid json}');

        // Initialize onboarding - should not crash
        onboardingBloc.add(const InitializeOnboarding());
        await Future.delayed(const Duration(milliseconds: 100));

        // Should fallback to empty configuration and start from beginning
        expect(onboardingBloc.state, isA<OnboardingStepActive>());
        final activeState = onboardingBloc.state as OnboardingStepActive;
        expect(activeState.currentStepIndex, equals(0));
        expect(activeState.userSelections, isEmpty);
      });

      test('should handle malformed progress gracefully', () async {
        // Set malformed JSON for progress
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('onboarding_progress', 'invalid json');

        // Initialize onboarding - should not crash
        onboardingBloc.add(const InitializeOnboarding());
        await Future.delayed(const Duration(milliseconds: 100));

        // Should fallback to starting from beginning
        expect(onboardingBloc.state, isA<OnboardingStepActive>());
        final activeState = onboardingBloc.state as OnboardingStepActive;
        expect(activeState.currentStepIndex, equals(0));
      });

      test('should preserve current schema version data unchanged', () async {
        // Set up data with current schema version
        final currentConfig = {
          'schemaVersion': 1,
          'payload': {
            'selectedThemeFamily': 'Green',
            'backupEnabled': false,
          },
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'onboarding_configuration', jsonEncode(currentConfig));

        // Initialize onboarding
        onboardingBloc.add(const InitializeOnboarding());
        await Future.delayed(const Duration(milliseconds: 100));

        // Data should remain unchanged
        final savedConfigJson = prefs.getString('onboarding_configuration');
        final savedWrapper =
            jsonDecode(savedConfigJson!) as Map<String, dynamic>;
        expect(savedWrapper['schemaVersion'], equals(1));
        expect(savedWrapper['payload']['selectedThemeFamily'], equals('Green'));
        expect(savedWrapper['payload']['backupEnabled'], equals(false));
      });

      test('should handle empty configuration gracefully', () async {
        // No configuration set in SharedPreferences

        // Initialize onboarding
        onboardingBloc.add(const InitializeOnboarding());
        await Future.delayed(const Duration(milliseconds: 100));

        // Should start from beginning with empty configuration
        expect(onboardingBloc.state, isA<OnboardingStepActive>());
        final activeState = onboardingBloc.state as OnboardingStepActive;
        expect(activeState.currentStepIndex, equals(0));
        expect(activeState.userSelections, isEmpty);
      });

      test('should preserve progress data during migration', () async {
        // Set up old format progress with custom data
        final oldProgress = {
          'totalSteps': 4,
          'completedSteps': 3,
          'stepCompletionStatus': [true, true, true, false],
          'progressPercentage': 75.0,
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('onboarding_progress', jsonEncode(oldProgress));

        // Initialize onboarding
        onboardingBloc.add(const InitializeOnboarding());
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify all progress data is preserved
        expect(onboardingBloc.state, isA<OnboardingStepActive>());
        final activeState = onboardingBloc.state as OnboardingStepActive;
        expect(activeState.progress.totalSteps, equals(4));
        expect(activeState.progress.completedSteps, equals(3));
        expect(activeState.progress.progressPercentage, equals(75.0));
        expect(activeState.progress.stepCompletionStatus,
            equals([true, true, true, false]));
      });

      test('should handle partial configuration data', () async {
        // Set up configuration with only some fields
        final partialConfig = {
          'selectedThemeFamily': 'Purple',
          // Missing other fields intentionally
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'onboarding_configuration', jsonEncode(partialConfig));

        // Initialize onboarding
        onboardingBloc.add(const InitializeOnboarding());
        await Future.delayed(const Duration(milliseconds: 100));

        // Should handle partial data gracefully
        expect(onboardingBloc.state, isA<OnboardingStepActive>());
        final activeState = onboardingBloc.state as OnboardingStepActive;
        expect(activeState.userSelections['selectedThemeFamily'],
            equals('Purple'));
      });
    });

    group('Race Condition Protection', () {
      test('should ignore duplicate ProgressToStep events', () async {
        // Initialize to active state
        onboardingBloc.add(const InitializeOnboarding());
        await Future.delayed(const Duration(milliseconds: 50));

        // Send multiple rapid ProgressToStep events with minimal delay
        onboardingBloc.add(const ProgressToStep(1));
        onboardingBloc.add(const ProgressToStep(2)); // Should be ignored

        // Wait for processing to complete
        await Future.delayed(const Duration(milliseconds: 200));

        // Should only process the first event
        expect(onboardingBloc.state, isA<OnboardingStepActive>());
        final activeState = onboardingBloc.state as OnboardingStepActive;
        expect(activeState.currentStepIndex, equals(1));
      });

      test('should ignore duplicate CompleteOnboarding events', () async {
        // Initialize to active state
        onboardingBloc.add(const InitializeOnboarding());
        await Future.delayed(const Duration(milliseconds: 50));

        // Send multiple rapid CompleteOnboarding events
        onboardingBloc.add(const CompleteOnboarding());
        onboardingBloc.add(const CompleteOnboarding()); // Should be ignored

        // Wait for processing
        await Future.delayed(const Duration(milliseconds: 100));

        // Should only process the first event and reach completed state
        expect(onboardingBloc.state, isA<OnboardingCompleted>());
      });
    });

    group('JSON Validation & Corruption Handling', () {
      test('should handle corrupted configuration JSON gracefully', () async {
        // Set completely invalid JSON
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'onboarding_configuration', 'completely invalid json');

        // Initialize onboarding - should not crash
        onboardingBloc.add(const InitializeOnboarding());
        await Future.delayed(const Duration(milliseconds: 100));

        // Should fallback to clean state
        expect(onboardingBloc.state, isA<OnboardingStepActive>());

        // Configuration should be cleared from storage
        final savedConfig = prefs.getString('onboarding_configuration');
        expect(savedConfig, isNull);
      });

      test('should handle invalid configuration structure', () async {
        // Set JSON with invalid structure
        final invalidConfig = {
          'schemaVersion': 1,
          'payload': 'invalid_payload_should_be_map'
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'onboarding_configuration', jsonEncode(invalidConfig));

        // Initialize onboarding
        onboardingBloc.add(const InitializeOnboarding());
        await Future.delayed(const Duration(milliseconds: 100));

        // Should handle gracefully and clear invalid data
        expect(onboardingBloc.state, isA<OnboardingStepActive>());
        final savedConfig = prefs.getString('onboarding_configuration');
        expect(savedConfig, isNull);
      });

      test('should handle corrupted progress JSON gracefully', () async {
        // Set completely invalid JSON for progress
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('onboarding_progress', '{broken json');

        // Initialize onboarding - should not crash
        onboardingBloc.add(const InitializeOnboarding());
        await Future.delayed(const Duration(milliseconds: 100));

        // Should start from beginning
        expect(onboardingBloc.state, isA<OnboardingStepActive>());
        final activeState = onboardingBloc.state as OnboardingStepActive;
        expect(activeState.currentStepIndex, equals(0));

        // Progress should be cleared from storage
        final savedProgress = prefs.getString('onboarding_progress');
        expect(savedProgress, isNull);
      });

      test('should handle invalid progress structure', () async {
        // Set JSON with missing required fields
        final invalidProgress = {
          'schemaVersion': 1,
          'payload': {
            'totalSteps': 4,
            // Missing 'completedSteps', 'stepCompletionStatus', 'progressPercentage'
          }
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'onboarding_progress', jsonEncode(invalidProgress));

        // Initialize onboarding
        onboardingBloc.add(const InitializeOnboarding());
        await Future.delayed(const Duration(milliseconds: 100));

        // Should handle gracefully and clear invalid data
        expect(onboardingBloc.state, isA<OnboardingStepActive>());
        final activeState = onboardingBloc.state as OnboardingStepActive;
        expect(activeState.currentStepIndex, equals(0));
      });

      test('should handle unknown configuration keys', () async {
        // Set configuration with unknown keys (should be accepted but logged)
        final configWithUnknownKeys = {
          'selectedThemeFamily': 'Blue',
          'unknownKey1': 'value1',
          'unknownKey2': 'value2',
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'onboarding_configuration', jsonEncode(configWithUnknownKeys));

        // Initialize onboarding
        onboardingBloc.add(const InitializeOnboarding());
        await Future.delayed(const Duration(milliseconds: 100));

        // Should accept configuration but log warnings
        expect(onboardingBloc.state, isA<OnboardingStepActive>());
        final activeState = onboardingBloc.state as OnboardingStepActive;
        expect(
            activeState.userSelections['selectedThemeFamily'], equals('Blue'));
      });
    });

    group('SharedPreferences Mutex Protection', () {
      test('should handle rapid configuration saves without corruption',
          () async {
        // Initialize to active state
        onboardingBloc.add(const InitializeOnboarding());
        await Future.delayed(const Duration(milliseconds: 50));

        // Send multiple rapid theme selection events
        onboardingBloc.add(const SelectTheme('Blue'));
        onboardingBloc.add(const SelectTheme('Green'));
        onboardingBloc.add(const SelectTheme('Red'));

        // Wait for all operations to complete
        await Future.delayed(const Duration(milliseconds: 200));

        // Should end up in a valid state without corruption
        expect(onboardingBloc.state, isA<OnboardingStepActive>());
        final activeState = onboardingBloc.state as OnboardingStepActive;

        // Should have one of the theme values (order not guaranteed due to async)
        final selectedTheme = activeState.userSelections['selectedThemeFamily'];
        expect(['Blue', 'Green', 'Red'].contains(selectedTheme), isTrue);
      });
    });
  });
}
