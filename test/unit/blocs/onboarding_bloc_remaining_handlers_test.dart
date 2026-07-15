@Tags(['unit', 'blocs', 'onboarding'])
library;

// test/unit/blocs/onboarding_bloc_remaining_handlers_test.dart
//
// Covers the three OnboardingBloc event handlers that had zero test
// coverage: UpdateStepConfiguration, UpdatePreview, and ResetOnboarding.
//
// UpdateStepConfiguration and UpdatePreview are pure state-merge handlers —
// neither touches OnboardingService, so these tests assert only on the
// state transition, nothing persistence-related.
//
// ResetOnboarding calls OnboardingService.resetOnboarding()/
// clearConfiguration()/clearProgress(). Those methods' actual
// SharedPreferences behavior is already covered by
// test/unit/services/onboarding_service_test.dart — this test only asserts
// the bloc's own contract: it calls all three service methods and emits
// OnboardingInitial. It does not re-verify what clearing configuration/
// progress does to storage.

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_bloc.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_event.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_models.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockOnboardingService extends Mock implements OnboardingService {}

class MockThemeBloc extends MockBloc<ThemeEvent, ThemeState>
    implements ThemeBloc {}

class MockBackupBloc extends MockBloc<BackupEvent, BackupState>
    implements BackupBloc {}

void main() {
  late OnboardingBloc onboardingBloc;
  late MockOnboardingService mockOnboardingService;
  late MockThemeBloc mockThemeBloc;
  late MockBackupBloc mockBackupBloc;

  setUpAll(() {
    registerFallbackValue(const ChangeThemeFamily('spirit'));
    registerFallbackValue(
      OnboardingProgress.fromStepCompletion(const [false, false, false, false]),
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockOnboardingService = MockOnboardingService();
    mockThemeBloc = MockThemeBloc();
    mockBackupBloc = MockBackupBloc();

    when(
      () => mockOnboardingService.isOnboardingComplete(),
    ).thenAnswer((_) async => false);
    when(
      () => mockOnboardingService.setOnboardingInProgress(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockOnboardingService.setOnboardingComplete(),
    ).thenAnswer((_) async {});
    when(
      () => mockOnboardingService.loadConfiguration(),
    ).thenAnswer((_) async => <String, dynamic>{});
    when(
      () => mockOnboardingService.loadProgress(),
    ).thenAnswer((_) async => null);
    when(
      () => mockOnboardingService.saveConfiguration(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockOnboardingService.saveProgress(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockOnboardingService.clearConfiguration(),
    ).thenAnswer((_) async {});
    when(
      () => mockOnboardingService.clearProgress(),
    ).thenAnswer((_) async {});
    when(
      () => mockOnboardingService.resetOnboarding(),
    ).thenAnswer((_) async {});

    when(() => mockBackupBloc.state).thenReturn(const BackupInitial());

    onboardingBloc = OnboardingBloc(
      onboardingService: mockOnboardingService,
      themeBloc: mockThemeBloc,
      backupBloc: mockBackupBloc,
    );
  });

  tearDown(() {
    onboardingBloc.close();
  });

  group('OnboardingBloc — UpdateStepConfiguration', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'merges the new configuration into stepConfiguration without '
      'touching userSelections or currentStepIndex',
      build: () => onboardingBloc,
      seed: () => OnboardingStepActive(
        currentStepIndex: 1,
        currentStep: OnboardingSteps.defaultSteps[1],
        userSelections: const {'selectedThemeFamily': 'Blue'},
        stepConfiguration: const {'existingKey': 'existingValue'},
        canProgress: true,
        canGoBack: true,
        progress: OnboardingProgress.fromStepCompletion(const [
          true,
          false,
          false,
          false,
        ]),
      ),
      act: (bloc) => bloc.add(
        const UpdateStepConfiguration({'newKey': 'newValue'}),
      ),
      expect: () => [
        isA<OnboardingStepActive>().having(
          (s) => s.stepConfiguration,
          'stepConfiguration',
          {'existingKey': 'existingValue', 'newKey': 'newValue'},
        ).having(
          (s) => s.userSelections,
          'userSelections',
          {'selectedThemeFamily': 'Blue'},
        ).having((s) => s.currentStepIndex, 'currentStepIndex', 1),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'overwrites a stepConfiguration key when the new configuration '
      'reuses the same key',
      build: () => onboardingBloc,
      seed: () => OnboardingStepActive(
        currentStepIndex: 1,
        currentStep: OnboardingSteps.defaultSteps[1],
        userSelections: const {},
        stepConfiguration: const {'themeApplied': false},
        canProgress: true,
        canGoBack: true,
        progress: OnboardingProgress.fromStepCompletion(const [
          true,
          false,
          false,
          false,
        ]),
      ),
      act: (bloc) => bloc.add(
        const UpdateStepConfiguration({'themeApplied': true}),
      ),
      expect: () => [
        isA<OnboardingStepActive>().having(
          (s) => s.stepConfiguration,
          'stepConfiguration',
          {'themeApplied': true},
        ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'is a no-op when not in OnboardingStepActive',
      build: () => onboardingBloc,
      seed: () => const OnboardingLoading(),
      act: (bloc) => bloc.add(
        const UpdateStepConfiguration({'key': 'value'}),
      ),
      expect: () => <OnboardingState>[],
    );
  });

  group('OnboardingBloc — UpdatePreview', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'stores the preview value under a preview_<type> key in '
      'stepConfiguration',
      build: () => onboardingBloc,
      seed: () => OnboardingStepActive(
        currentStepIndex: 1,
        currentStep: OnboardingSteps.defaultSteps[1],
        userSelections: const {},
        stepConfiguration: const {},
        canProgress: true,
        canGoBack: true,
        progress: OnboardingProgress.fromStepCompletion(const [
          true,
          false,
          false,
          false,
        ]),
      ),
      act: (bloc) => bloc.add(const UpdatePreview('themeFamily', 'Ocean')),
      expect: () => [
        isA<OnboardingStepActive>().having(
          (s) => s.stepConfiguration,
          'stepConfiguration',
          {'preview_themeFamily': 'Ocean'},
        ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'preserves existing stepConfiguration entries when adding a preview',
      build: () => onboardingBloc,
      seed: () => OnboardingStepActive(
        currentStepIndex: 1,
        currentStep: OnboardingSteps.defaultSteps[1],
        userSelections: const {},
        stepConfiguration: const {'themeApplied': true},
        canProgress: true,
        canGoBack: true,
        progress: OnboardingProgress.fromStepCompletion(const [
          true,
          false,
          false,
          false,
        ]),
      ),
      act: (bloc) => bloc.add(const UpdatePreview('brightness', 'dark')),
      expect: () => [
        isA<OnboardingStepActive>().having(
          (s) => s.stepConfiguration,
          'stepConfiguration',
          {'themeApplied': true, 'preview_brightness': 'dark'},
        ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'is a no-op when not in OnboardingStepActive',
      build: () => onboardingBloc,
      seed: () => const OnboardingLoading(),
      act: (bloc) => bloc.add(const UpdatePreview('themeFamily', 'Ocean')),
      expect: () => <OnboardingState>[],
    );
  });

  group('OnboardingBloc — ResetOnboarding', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'clears service-side state and emits OnboardingInitial',
      build: () => onboardingBloc,
      seed: () => OnboardingStepActive(
        currentStepIndex: 2,
        currentStep: OnboardingSteps.defaultSteps[2],
        userSelections: const {'backupEnabled': true},
        stepConfiguration: const {},
        canProgress: true,
        canGoBack: true,
        progress: OnboardingProgress.fromStepCompletion(const [
          true,
          true,
          false,
          false,
        ]),
      ),
      act: (bloc) => bloc.add(const ResetOnboarding()),
      expect: () => [isA<OnboardingInitial>()],
      verify: (_) {
        verify(() => mockOnboardingService.resetOnboarding()).called(1);
        verify(() => mockOnboardingService.clearConfiguration()).called(1);
        verify(() => mockOnboardingService.clearProgress()).called(1);
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'emits OnboardingError and does not crash when the service throws',
      build: () {
        when(
          () => mockOnboardingService.resetOnboarding(),
        ).thenThrow(Exception('SharedPreferences unavailable'));
        return onboardingBloc;
      },
      seed: () => OnboardingStepActive(
        currentStepIndex: 2,
        currentStep: OnboardingSteps.defaultSteps[2],
        userSelections: const {},
        stepConfiguration: const {},
        canProgress: true,
        canGoBack: true,
        progress: OnboardingProgress.fromStepCompletion(const [
          true,
          true,
          false,
          false,
        ]),
      ),
      act: (bloc) => bloc.add(const ResetOnboarding()),
      expect: () => [isA<OnboardingError>()],
    );
  });
}
