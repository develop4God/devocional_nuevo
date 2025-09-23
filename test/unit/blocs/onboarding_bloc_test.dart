// test/unit/blocs/onboarding_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_bloc.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_event.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_models.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_state.dart';
import 'package:devocional_nuevo/providers/theme_provider.dart';
import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockOnboardingService extends Mock implements OnboardingService {}

class MockThemeProvider extends Mock implements ThemeProvider {}

class MockBackupBloc extends Mock implements BackupBloc {}

void main() {
  group('OnboardingBloc', () {
    late MockOnboardingService mockOnboardingService;
    late MockThemeProvider mockThemeProvider;
    late MockBackupBloc mockBackupBloc;
    late OnboardingBloc onboardingBloc;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockOnboardingService = MockOnboardingService();
      mockThemeProvider = MockThemeProvider();
      mockBackupBloc = MockBackupBloc();
      
      onboardingBloc = OnboardingBloc(
        onboardingService: mockOnboardingService,
        themeProvider: mockThemeProvider,
        backupBloc: mockBackupBloc,
      );
    });

    tearDown(() {
      onboardingBloc.close();
    });

    test('initial state is OnboardingInitial', () {
      expect(onboardingBloc.state, equals(const OnboardingInitial()));
    });

    group('InitializeOnboarding', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'emits [OnboardingLoading, OnboardingCompleted] when onboarding is already complete',
        build: () {
          when(() => mockOnboardingService.isOnboardingComplete())
              .thenAnswer((_) async => true);
          return onboardingBloc;
        },
        act: (bloc) => bloc.add(const InitializeOnboarding()),
        expect: () => [
          const OnboardingLoading(),
          isA<OnboardingCompleted>(),
        ],
        verify: (_) {
          verify(() => mockOnboardingService.isOnboardingComplete()).called(1);
        },
      );

      blocTest<OnboardingBloc, OnboardingState>(
        'emits [OnboardingLoading, OnboardingStepActive] when onboarding is not complete',
        build: () {
          when(() => mockOnboardingService.isOnboardingComplete())
              .thenAnswer((_) async => false);
          return onboardingBloc;
        },
        act: (bloc) => bloc.add(const InitializeOnboarding()),
        expect: () => [
          const OnboardingLoading(),
          isA<OnboardingStepActive>()
              .having((state) => state.currentStepIndex, 'currentStepIndex', 0)
              .having((state) => state.currentStep.type, 'currentStep.type',
                  OnboardingStepType.welcome)
              .having((state) => state.canProgress, 'canProgress', true)
              .having((state) => state.canGoBack, 'canGoBack', false),
        ],
        verify: (_) {
          verify(() => mockOnboardingService.isOnboardingComplete()).called(1);
        },
      );

      blocTest<OnboardingBloc, OnboardingState>(
        'emits [OnboardingLoading, OnboardingError] when initialization fails',
        build: () {
          when(() => mockOnboardingService.isOnboardingComplete())
              .thenThrow(Exception('Network error'));
          return onboardingBloc;
        },
        act: (bloc) => bloc.add(const InitializeOnboarding()),
        expect: () => [
          const OnboardingLoading(),
          isA<OnboardingError>().having(
              (state) => state.message, 'message', contains('Network error')),
        ],
      );
    });

    group('ProgressToStep', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'progresses to specified step and updates progress',
        build: () {
          when(() => mockOnboardingService.isOnboardingComplete())
              .thenAnswer((_) async => false);
          return onboardingBloc;
        },
        seed: () => OnboardingStepActive(
          currentStepIndex: 0,
          currentStep: OnboardingSteps.defaultSteps[0],
          userSelections: const {},
          stepConfiguration: const {},
          canProgress: true,
          canGoBack: false,
          progress: OnboardingProgress.fromStepCompletion([false, false, false, false]),
        ),
        act: (bloc) => bloc.add(const ProgressToStep(1)),
        expect: () => [
          isA<OnboardingStepActive>()
              .having((state) => state.currentStepIndex, 'currentStepIndex', 1)
              .having((state) => state.currentStep.type, 'currentStep.type',
                  OnboardingStepType.themeSelection)
              .having((state) => state.canProgress, 'canProgress', true)
              .having((state) => state.canGoBack, 'canGoBack', true),
        ],
      );

      blocTest<OnboardingBloc, OnboardingState>(
        'ignores invalid step index',
        build: () => onboardingBloc,
        seed: () => OnboardingStepActive(
          currentStepIndex: 0,
          currentStep: OnboardingSteps.defaultSteps[0],
          userSelections: const {},
          stepConfiguration: const {},
          canProgress: true,
          canGoBack: false,
          progress: OnboardingProgress.fromStepCompletion([false, false, false, false]),
        ),
        act: (bloc) => bloc.add(const ProgressToStep(999)),
        expect: () => [],
      );
    });

    group('SelectTheme', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'selects theme and applies it immediately',
        build: () {
          when(() => mockThemeProvider.setThemeFamily(any()))
              .thenAnswer((_) async {});
          return onboardingBloc;
        },
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
          isA<OnboardingConfiguring>()
              .having((state) => state.configurationType, 'configurationType',
                  OnboardingConfigurationType.themeSelection),
          isA<OnboardingStepActive>()
              .having((state) => state.userSelections['selectedThemeFamily'],
                  'selectedThemeFamily', 'Blue')
              .having((state) => state.stepConfiguration['themeApplied'],
                  'themeApplied', true),
        ],
        verify: (_) {
          verify(() => mockThemeProvider.setThemeFamily('Blue')).called(1);
        },
      );

      blocTest<OnboardingBloc, OnboardingState>(
        'emits error when theme selection fails',
        build: () {
          when(() => mockThemeProvider.setThemeFamily(any()))
              .thenThrow(Exception('Theme error'));
          return onboardingBloc;
        },
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
          isA<OnboardingError>().having(
              (state) => state.message, 'message', contains('Theme error')),
        ],
      );
    });

    group('ConfigureBackupOption', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'configures backup and coordinates with BackupBloc',
        build: () => onboardingBloc,
        seed: () => OnboardingStepActive(
          currentStepIndex: 2,
          currentStep: OnboardingSteps.defaultSteps[2],
          userSelections: const {},
          stepConfiguration: const {},
          canProgress: true,
          canGoBack: true,
          progress: OnboardingProgress.fromStepCompletion([true, true, false, false]),
        ),
        act: (bloc) => bloc.add(const ConfigureBackupOption(true)),
        expect: () => [
          isA<OnboardingConfiguring>()
              .having((state) => state.configurationType, 'configurationType',
                  OnboardingConfigurationType.backupConfiguration),
          isA<OnboardingStepActive>()
              .having((state) => state.userSelections['backupEnabled'],
                  'backupEnabled', true)
              .having((state) => state.stepConfiguration['backupConfigured'],
                  'backupConfigured', true),
        ],
      );
    });

    group('CompleteOnboarding', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'completes onboarding successfully',
        build: () {
          when(() => mockOnboardingService.setOnboardingComplete())
              .thenAnswer((_) async {});
          return onboardingBloc;
        },
        seed: () => OnboardingStepActive(
          currentStepIndex: 3,
          currentStep: OnboardingSteps.defaultSteps[3],
          userSelections: const {'selectedThemeFamily': 'Blue', 'backupEnabled': true},
          stepConfiguration: const {},
          canProgress: false,
          canGoBack: true,
          progress: OnboardingProgress.fromStepCompletion([true, true, true, false]),
        ),
        act: (bloc) => bloc.add(const CompleteOnboarding()),
        expect: () => [
          const OnboardingLoading(),
          isA<OnboardingCompleted>()
              .having((state) => state.appliedConfigurations['selectedThemeFamily'],
                  'selectedThemeFamily', 'Blue')
              .having((state) => state.appliedConfigurations['backupEnabled'],
                  'backupEnabled', true),
        ],
        verify: (_) {
          verify(() => mockOnboardingService.setOnboardingComplete()).called(1);
        },
      );

      blocTest<OnboardingBloc, OnboardingState>(
        'emits error when completion fails',
        build: () {
          when(() => mockOnboardingService.setOnboardingComplete())
              .thenThrow(Exception('Completion error'));
          return onboardingBloc;
        },
        act: (bloc) => bloc.add(const CompleteOnboarding()),
        expect: () => [
          const OnboardingLoading(),
          isA<OnboardingError>().having(
              (state) => state.message, 'message', contains('Completion error')),
        ],
      );
    });

    group('ResetOnboarding', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'resets onboarding successfully',
        build: () {
          when(() => mockOnboardingService.resetOnboarding())
              .thenAnswer((_) async {});
          return onboardingBloc;
        },
        act: (bloc) => bloc.add(const ResetOnboarding()),
        expect: () => [
          const OnboardingInitial(),
        ],
        verify: (_) {
          verify(() => mockOnboardingService.resetOnboarding()).called(1);
        },
      );
    });

    group('SkipCurrentStep', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'skips current step if skippable',
        build: () => onboardingBloc,
        seed: () => OnboardingStepActive(
          currentStepIndex: 1, // Theme selection step (skippable)
          currentStep: OnboardingSteps.defaultSteps[1],
          userSelections: const {},
          stepConfiguration: const {},
          canProgress: true,
          canGoBack: true,
          progress: OnboardingProgress.fromStepCompletion([true, false, false, false]),
        ),
        act: (bloc) => bloc.add(const SkipCurrentStep()),
        expect: () => [
          isA<OnboardingStepActive>()
              .having((state) => state.currentStepIndex, 'currentStepIndex', 2),
        ],
      );
    });

    group('GoToPreviousStep', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'goes to previous step when possible',
        build: () => onboardingBloc,
        seed: () => OnboardingStepActive(
          currentStepIndex: 2,
          currentStep: OnboardingSteps.defaultSteps[2],
          userSelections: const {},
          stepConfiguration: const {},
          canProgress: true,
          canGoBack: true,
          progress: OnboardingProgress.fromStepCompletion([true, true, false, false]),
        ),
        act: (bloc) => bloc.add(const GoToPreviousStep()),
        expect: () => [
          isA<OnboardingStepActive>()
              .having((state) => state.currentStepIndex, 'currentStepIndex', 1),
        ],
      );
    });

    group('UpdateStepConfiguration', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'updates step configuration',
        build: () => onboardingBloc,
        seed: () => OnboardingStepActive(
          currentStepIndex: 1,
          currentStep: OnboardingSteps.defaultSteps[1],
          userSelections: const {},
          stepConfiguration: const {'existing': 'value'},
          canProgress: true,
          canGoBack: true,
          progress: OnboardingProgress.fromStepCompletion([true, false, false, false]),
        ),
        act: (bloc) => bloc.add(const UpdateStepConfiguration({'new': 'config'})),
        expect: () => [
          isA<OnboardingStepActive>()
              .having((state) => state.stepConfiguration['existing'], 'existing', 'value')
              .having((state) => state.stepConfiguration['new'], 'new', 'config'),
        ],
      );
    });

    group('UpdatePreview', () {
      blocTest<OnboardingBloc, OnboardingState>(
        'updates preview configuration',
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
        act: (bloc) => bloc.add(const UpdatePreview('theme', 'Blue')),
        expect: () => [
          isA<OnboardingStepActive>()
              .having((state) => state.stepConfiguration['preview_theme'],
                  'preview_theme', 'Blue'),
        ],
      );
    });
  });
}