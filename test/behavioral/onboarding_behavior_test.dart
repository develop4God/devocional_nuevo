@Tags(['unit', 'blocs', 'onboarding', 'behavioral'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_bloc.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_event.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_state.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_models.dart';
import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';

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
      () => mockOnboardingService.saveConfiguration(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockOnboardingService.saveProgress(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockOnboardingService.loadConfiguration(),
    ).thenAnswer((_) async => {});
    when(
      () => mockOnboardingService.loadProgress(),
    ).thenAnswer((_) async => null);
    when(
      () => mockOnboardingService.clearConfiguration(),
    ).thenAnswer((_) async {});
    when(() => mockOnboardingService.clearProgress()).thenAnswer((_) async {});

    // Provide a default state for BackupBloc to avoid "Null is not a subtype of BackupState"
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

  group('OnboardingBloc Behavioral Tests', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'initializes onboarding and emits first step',
      build: () => onboardingBloc,
      act: (bloc) => bloc.add(const InitializeOnboarding()),
      expect: () => [
        isA<OnboardingLoading>(),
        isA<OnboardingStepActive>().having(
          (s) => s.currentStepIndex,
          'stepIndex',
          0,
        ),
      ],
      verify: (_) {
        verify(
          () => mockOnboardingService.setOnboardingInProgress(true),
        ).called(1);
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'progresses to next step when ProgressToStep is added',
      build: () => onboardingBloc,
      seed: () => OnboardingStepActive(
        currentStepIndex: 0,
        currentStep: OnboardingSteps.defaultSteps[0],
        userSelections: const {},
        stepConfiguration: const {},
        canProgress: true,
        canGoBack: false,
        progress: OnboardingProgress.fromStepCompletion(const [
          true,
          false,
          false,
          false,
        ]),
      ),
      act: (bloc) => bloc.add(const ProgressToStep(1)),
      expect: () => [
        isA<OnboardingStepActive>().having(
          (s) => s.currentStepIndex,
          'stepIndex',
          1,
        ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'selects theme and updates state',
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
          true,
          false,
          false,
        ]),
      ),
      act: (bloc) => bloc.add(const SelectTheme('Blue')),
      expect: () => [
        isA<OnboardingConfiguring>().having(
          (s) => s.configurationType,
          'type',
          OnboardingConfigurationType.themeSelection,
        ),
        isA<OnboardingStepActive>().having(
          (s) => s.userSelections['selectedThemeFamily'],
          'themeFamily',
          'Blue',
        ),
      ],
      verify: (_) {
        verify(
          () => mockThemeBloc.add(any(that: isA<ChangeThemeFamily>())),
        ).called(1);
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'completes onboarding and marks it as complete in service',
      build: () => onboardingBloc,
      seed: () => OnboardingStepActive(
        currentStepIndex: 3,
        currentStep: OnboardingSteps.defaultSteps[3],
        userSelections: const {
          'selectedThemeFamily': 'Blue',
          'backupEnabled': true,
        },
        stepConfiguration: const {},
        canProgress: true,
        canGoBack: true,
        progress: OnboardingProgress.fromStepCompletion(const [
          true,
          true,
          true,
          true,
        ]),
      ),
      act: (bloc) => bloc.add(const CompleteOnboarding()),
      expect: () => [isA<OnboardingLoading>(), isA<OnboardingCompleted>()],
      verify: (_) {
        verify(() => mockOnboardingService.setOnboardingComplete()).called(1);
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'skips backup and updates selections',
      build: () => onboardingBloc,
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
          true,
          false,
        ]),
      ),
      act: (bloc) => bloc.add(const SkipBackupForNow()),
      expect: () => [
        isA<OnboardingStepActive>().having(
          (s) => s.userSelections['backupSkipped'],
          'backupSkipped',
          true,
        ),
      ],
    );

    group('Step Navigation', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'goes back to previous step',
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
            true,
            false,
            false,
          ]),
        ),
        act: (bloc) => bloc.add(const GoToPreviousStep()),
        expect: () => [
          isA<OnboardingStepActive>().having(
            (s) => s.currentStepIndex,
            'stepIndex',
            0,
          ),
        ],
      );

      blocTest<OnboardingBloc, OnboardingState>(
        'skips current step if skippable',
        build: () => onboardingBloc,
        seed: () => OnboardingStepActive(
          currentStepIndex: 1,
          currentStep:
              OnboardingSteps.defaultSteps[1], // Theme selection is skippable
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
        act: (bloc) => bloc.add(const SkipCurrentStep()),
        expect: () => [
          isA<OnboardingStepActive>().having(
            (s) => s.currentStepIndex,
            'stepIndex',
            2,
          ),
        ],
      );

      blocTest<OnboardingBloc, OnboardingState>(
        'ignores a duplicate ProgressToStep dispatched while the first is '
        'still in flight',
        build: () => onboardingBloc,
        seed: () => OnboardingStepActive(
          currentStepIndex: 0,
          currentStep: OnboardingSteps.defaultSteps[0],
          userSelections: const {},
          stepConfiguration: const {},
          canProgress: true,
          canGoBack: false,
          progress: OnboardingProgress.fromStepCompletion(const [
            true,
            false,
            false,
            false,
          ]),
        ),
        act: (bloc) {
          bloc.add(const ProgressToStep(1));
          bloc.add(const ProgressToStep(1));
        },
        expect: () => [
          isA<OnboardingStepActive>().having(
            (s) => s.currentStepIndex,
            'stepIndex',
            1,
          ),
        ],
      );
    });
  });
}
