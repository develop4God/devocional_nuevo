@Tags(['unit', 'widgets', 'onboarding'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_bloc.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_event.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_models.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_state.dart';
import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_backup_configuration_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/i_spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_helpers.dart';

class MockOnboardingBloc extends MockBloc<OnboardingEvent, OnboardingState>
    implements OnboardingBloc {}

class MockBackupBloc extends MockBloc<BackupEvent, BackupState>
    implements BackupBloc {}

class MockDevocionalProvider extends Mock implements DevocionalProvider {}

/// Covers the safeguard added to OnboardingBackupConfigurationPage: once
/// the user is already connected to Google Drive backup, a persistent
/// "Next" button must always be visible and tappable — independent of the
/// one-shot auto-advance timer and independent of whether Back/Skip are
/// disabled or hidden. This prevents the user from ever being stranded on
/// this step with no way forward (e.g. re-entering an already-configured
/// step where the auto-advance guard no longer fires).
void main() {
  late MockOnboardingBloc mockOnboardingBloc;
  late MockBackupBloc mockBackupBloc;
  late MockDevocionalProvider mockDevocionalProvider;

  setUp(() async {
    await setupFirebaseMocks();
    await registerTestServices();

    mockDevocionalProvider = MockDevocionalProvider();
    when(
      () => mockDevocionalProvider.waitUntilInitialized(),
    ).thenAnswer((_) async {});

    mockOnboardingBloc = MockOnboardingBloc();
    when(() => mockOnboardingBloc.state).thenReturn(
      OnboardingStepActive(
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
    );
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    required bool isAuthenticated,
    VoidCallback? onNext,
  }) async {
    mockBackupBloc = MockBackupBloc();
    when(() => mockBackupBloc.state).thenReturn(
      BackupLoaded(
        isAuthenticated: isAuthenticated,
        autoBackupEnabled: true,
        wifiOnlyEnabled: false,
        compressionEnabled: false,
        backupFrequency: 'daily',
        backupOptions: const {},
        lastBackupTime: null,
        nextBackupTime: null,
        estimatedSize: 0,
        userEmail: isAuthenticated ? 'user@example.com' : null,
      ),
    );
    whenListen(mockBackupBloc, const Stream<BackupState>.empty());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DevocionalProvider>.value(
            value: mockDevocionalProvider,
          ),
          BlocProvider<PrayerBloc>(
            create: (_) =>
                PrayerBloc(statsService: getService<ISpiritualStatsService>()),
          ),
          BlocProvider<OnboardingBloc>.value(value: mockOnboardingBloc),
          BlocProvider<BackupBloc>.value(value: mockBackupBloc),
        ],
        child: MaterialApp(
          home: OnboardingBackupConfigurationPage(
            onNext: onNext ?? () {},
            onBack: () {},
            onSkip: () {},
          ),
        ),
      ),
    );
    // Let LoadBackupSettings resolve without pumpAndSettle, which would
    // hang on this page's internal Future.delayed(2s) auto-advance timer.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('shows the safeguard Next button when already connected', (
    tester,
  ) async {
    await pumpPage(tester, isAuthenticated: true);

    final nextText = 'onboarding.onboarding_next'.tr();
    expect(find.widgetWithText(ElevatedButton, nextText), findsOneWidget);
  });

  testWidgets('hides the safeguard Next button when not yet connected', (
    tester,
  ) async {
    await pumpPage(tester, isAuthenticated: false);

    final nextText = 'onboarding.onboarding_next'.tr();
    expect(find.widgetWithText(ElevatedButton, nextText), findsNothing);
  });

  testWidgets('tapping the safeguard Next button calls onNext', (tester) async {
    var nextCalled = false;

    await pumpPage(
      tester,
      isAuthenticated: true,
      onNext: () => nextCalled = true,
    );

    final nextText = 'onboarding.onboarding_next'.tr();
    final nextButton = find.widgetWithText(ElevatedButton, nextText);
    expect(nextButton, findsOneWidget);

    await tester.tap(nextButton);
    await tester.pump();

    expect(nextCalled, isTrue);
  });

  testWidgets(
    'reuses the ancestor BackupBloc instead of constructing a second one — '
    'a second instance would re-fire CheckStartupBackup and race against '
    'SignInToGoogleDrive, duplicating the Drive backup upload',
    (tester) async {
      late BackupBloc capturedBloc;

      await pumpPage(tester, isAuthenticated: true);

      final capturingContext = tester.element(
        find.byType(OnboardingBackupConfigurationPage),
      );
      capturedBloc = capturingContext.read<BackupBloc>();

      expect(
        identical(capturedBloc, mockBackupBloc),
        isTrue,
        reason: 'OnboardingBackupConfigurationPage must reuse the '
            'app-level BackupBloc found in its ancestor context rather '
            'than creating its own instance',
      );

      // The only BackupBloc interaction the page itself should trigger is
      // LoadBackupSettings on that same shared instance — never a second
      // bloc's constructor-fired CheckStartupBackup.
      verify(() => mockBackupBloc.add(const LoadBackupSettings())).called(1);
    },
  );
}
