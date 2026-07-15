@Tags(['unit', 'pages', 'onboarding'])
library;

// test/unit/pages/onboarding_flow_back_navigation_test.dart
//
// Covers isBackNavigationBlocked() from
// lib/pages/onboarding/onboarding_flow.dart — the predicate that decides
// whether system back navigation is a no-op on the completion step once
// Google Drive backup is connected. This is a pure function extracted
// specifically so it can be unit-tested directly against real
// OnboardingStepActive instances, without spinning up a widget tree (which
// previously left onboarding_flow.dart at 0% coverage — the file
// constructs a real OnboardingBloc with Lottie-bearing child pages, making
// full-widget pumps slow and fragile for what is actually a two-line
// boolean decision).

import 'package:devocional_nuevo/blocs/onboarding/onboarding_models.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_state.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_flow.dart';
import 'package:flutter_test/flutter_test.dart';

OnboardingStepActive _stateAt(
  int stepIndex, {
  Map<String, dynamic> userSelections = const {},
}) {
  return OnboardingStepActive(
    currentStepIndex: stepIndex,
    currentStep: OnboardingSteps.defaultSteps[stepIndex],
    userSelections: userSelections,
    stepConfiguration: const {},
    canProgress: true,
    canGoBack: true,
    progress: OnboardingProgress.fromStepCompletion(
      List<bool>.filled(OnboardingSteps.defaultSteps.length, false),
    ),
  );
}

void main() {
  group('isBackNavigationBlocked', () {
    test('blocks back on the completion step once backup is connected', () {
      final state = _stateAt(3, userSelections: const {'backupEnabled': true});

      expect(isBackNavigationBlocked(state), isTrue);
    });

    test('allows back on the completion step when backup was never enabled',
        () {
      final state = _stateAt(3);

      expect(isBackNavigationBlocked(state), isFalse);
    });

    test(
        'allows back on the completion step when backup was explicitly '
        'skipped', () {
      final state = _stateAt(
        3,
        userSelections: const {'backupEnabled': false, 'backupSkipped': true},
      );

      expect(isBackNavigationBlocked(state), isFalse);
    });

    test(
        'does not block on the backup configuration step (index 2) even '
        'when backupEnabled is true — only the completion step is guarded', () {
      final state = _stateAt(2, userSelections: const {'backupEnabled': true});

      expect(isBackNavigationBlocked(state), isFalse);
    });

    test('does not block on the welcome step (index 0)', () {
      final state = _stateAt(0, userSelections: const {'backupEnabled': true});

      expect(isBackNavigationBlocked(state), isFalse);
    });

    test('does not block on the theme selection step (index 1)', () {
      final state = _stateAt(1, userSelections: const {'backupEnabled': true});

      expect(isBackNavigationBlocked(state), isFalse);
    });

    test(
        'treats a non-bool backupEnabled value as not connected — guards '
        'against unexpected persisted/migrated data shapes', () {
      final state =
          _stateAt(3, userSelections: const {'backupEnabled': 'true'});

      expect(isBackNavigationBlocked(state), isFalse);
    });
  });
}
