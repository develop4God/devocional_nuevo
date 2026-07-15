@Tags(['unit', 'blocs', 'onboarding'])
library;

// test/unit/blocs/onboarding_backup_navigation_bloc_test.dart
//
// OnboardingBloc scenarios for the "backup already connected" back-navigation
// safeguard. Covers the bloc-level preconditions that the widget layer
// (OnboardingFlow's PopScope guard and OnboardingBackupConfigurationPage's
// disabled Back button / safeguard Next button) relies on:
//   1. GoToPreviousStep is a no-op when canGoBack is false.
//   2. GoToPreviousStep still navigates normally when backup was configured
//      earlier in the flow but the user is no longer on that step.
//   3. userSelections['backupEnabled'] persists across step navigation, so
//      widgets re-reading OnboardingBloc.state after a back-then-forward
//      still see the flag that gates the safeguard UI.

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

  group('OnboardingBloc — back-navigation safeguard preconditions', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'GoToPreviousStep is a no-op when canGoBack is false '
      '(e.g. widget-level guard already blocked the system back gesture)',
      build: () => onboardingBloc,
      seed: () => OnboardingStepActive(
        currentStepIndex: 2,
        currentStep: OnboardingSteps.defaultSteps[2],
        userSelections: const {'backupEnabled': true},
        stepConfiguration: const {},
        canProgress: true,
        canGoBack: false,
        progress: OnboardingProgress.fromStepCompletion(const [
          true,
          true,
          false,
          false,
        ]),
      ),
      act: (bloc) => bloc.add(const GoToPreviousStep()),
      expect: () => <OnboardingState>[],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'GoToPreviousStep from the backup step still navigates back to theme '
      'selection when canGoBack is true, preserving backupEnabled',
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
          true,
          false,
        ]),
      ),
      act: (bloc) => bloc.add(const GoToPreviousStep()),
      expect: () => [
        isA<OnboardingStepActive>()
            .having((s) => s.currentStepIndex, 'stepIndex', 1)
            .having(
              (s) => s.userSelections['backupEnabled'],
              'backupEnabled',
              true,
            ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'ProgressToStep back onto the backup step (index 2) keeps a previously '
      'set backupEnabled flag visible in userSelections, so a widget reading '
      'state on re-entry can seed its "already configured" guard correctly',
      build: () => onboardingBloc,
      seed: () => OnboardingStepActive(
        currentStepIndex: 1,
        currentStep: OnboardingSteps.defaultSteps[1],
        userSelections: const {'backupEnabled': true},
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
      act: (bloc) => bloc.add(const ProgressToStep(2)),
      expect: () => [
        isA<OnboardingStepActive>()
            .having((s) => s.currentStepIndex, 'stepIndex', 2)
            .having(
              (s) => s.userSelections['backupEnabled'],
              'backupEnabled',
              true,
            ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'ConfigureBackupOption(true) marks backupEnabled true and clears '
      'backupSkipped, the exact flag the back-navigation guard checks',
      build: () => onboardingBloc,
      seed: () => OnboardingStepActive(
        currentStepIndex: 2,
        currentStep: OnboardingSteps.defaultSteps[2],
        userSelections: const {'backupSkipped': false},
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
      act: (bloc) => bloc.add(const ConfigureBackupOption(true)),
      expect: () => [
        isA<OnboardingStepActive>()
            .having(
              (s) => s.userSelections['backupEnabled'],
              'backupEnabled',
              true,
            )
            .having(
              (s) => s.userSelections['backupSkipped'],
              'backupSkipped',
              false,
            ),
      ],
      verify: (_) {
        verify(() => mockBackupBloc.add(const ToggleAutoBackup(true)))
            .called(1);
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'SkipBackupForNow clears backupEnabled even if it was previously true, '
      'so the safeguard UI does not linger after the user opts out',
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
      act: (bloc) => bloc.add(const SkipBackupForNow()),
      expect: () => [
        isA<OnboardingStepActive>().having(
          (s) => s.userSelections['backupEnabled'],
          'backupEnabled',
          false,
        ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'CompleteOnboarding from the backup step preserves a connected backup '
      'flag in the emitted OnboardingCompleted configuration when BackupBloc '
      'independently confirms authentication and auto-backup are on',
      build: () {
        when(() => mockBackupBloc.state).thenReturn(
          const BackupLoaded(
            autoBackupEnabled: true,
            backupFrequency: 'daily',
            wifiOnlyEnabled: false,
            compressionEnabled: false,
            backupOptions: {},
            estimatedSize: 0,
            isAuthenticated: true,
          ),
        );
        return onboardingBloc;
      },
      seed: () => OnboardingStepActive(
        currentStepIndex: 3,
        currentStep: OnboardingSteps.defaultSteps[3],
        userSelections: const {'backupEnabled': true},
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
      expect: () => [
        isA<OnboardingLoading>(),
        isA<OnboardingCompleted>().having(
          (s) => s.appliedConfigurations['backupEnabled'],
          'backupEnabled',
          true,
        ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'CompleteOnboarding keeps a stale backupEnabled:true selection as-is '
      'when BackupBloc reports the session is no longer authenticated — '
      'documents the known gap (flagged in review) where a previously-set '
      'backupEnabled flag is NOT cleared just because BackupBloc later '
      'disagrees; the enrichment step only clears it when it was not '
      'already true (see _onCompleteOnboarding\'s "!= true" guard)',
      build: () {
        when(() => mockBackupBloc.state).thenReturn(
          const BackupLoaded(
            autoBackupEnabled: false,
            backupFrequency: 'daily',
            wifiOnlyEnabled: false,
            compressionEnabled: false,
            backupOptions: {},
            estimatedSize: 0,
            isAuthenticated: false,
          ),
        );
        return onboardingBloc;
      },
      seed: () => OnboardingStepActive(
        currentStepIndex: 3,
        currentStep: OnboardingSteps.defaultSteps[3],
        userSelections: const {'backupEnabled': true},
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
      expect: () => [
        isA<OnboardingLoading>(),
        isA<OnboardingCompleted>().having(
          (s) => s.appliedConfigurations['backupEnabled'],
          'backupEnabled',
          true,
        ),
      ],
    );
  });
}
