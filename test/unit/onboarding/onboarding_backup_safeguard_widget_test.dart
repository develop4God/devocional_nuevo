@Tags(['unit', 'onboarding'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_bloc.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_event.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_models.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_state.dart';
import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/backup_content_summary.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_backup_configuration_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/backup/i_google_drive_backup_service.dart';
import 'package:devocional_nuevo/services/i_spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_helpers.dart';

class MockGoogleDriveBackupService extends Mock
    implements IGoogleDriveBackupService {}

class MockOnboardingBloc extends MockBloc<OnboardingEvent, OnboardingState>
    implements OnboardingBloc {}

class MockDevocionalProvider extends Mock implements DevocionalProvider {}

/// Covers the safeguard added to OnboardingBackupConfigurationPage: once
/// the user is already connected to Google Drive backup, a persistent
/// "Next" button must always be visible and tappable — independent of the
/// one-shot auto-advance timer and independent of whether Back/Skip are
/// disabled or hidden. This prevents the user from ever being stranded on
/// this step with no way forward (e.g. re-entering an already-configured
/// step where the auto-advance guard no longer fires).
void main() {
  late MockGoogleDriveBackupService mockBackupService;
  late MockOnboardingBloc mockOnboardingBloc;
  late MockDevocionalProvider mockDevocionalProvider;

  setUp(() async {
    await setupFirebaseMocks();
    await registerTestServices();

    mockBackupService = MockGoogleDriveBackupService();
    final locator = ServiceLocator();
    if (locator.isRegistered<IGoogleDriveBackupService>()) {
      locator.unregister<IGoogleDriveBackupService>();
    }
    locator.registerSingleton<IGoogleDriveBackupService>(mockBackupService);

    when(
      () => mockBackupService.isAutoBackupEnabled(),
    ).thenAnswer((_) async => true);
    when(
      () => mockBackupService.getBackupFrequency(),
    ).thenAnswer((_) async => 'daily');
    when(
      () => mockBackupService.isWifiOnlyEnabled(),
    ).thenAnswer((_) async => false);
    when(
      () => mockBackupService.isCompressionEnabled(),
    ).thenAnswer((_) async => false);
    when(
      () => mockBackupService.getBackupOptions(),
    ).thenAnswer((_) async => <String, bool>{});
    when(
      () => mockBackupService.getLastBackupTime(),
    ).thenAnswer((_) async => null);
    when(
      () => mockBackupService.getNextBackupTime(),
    ).thenAnswer((_) async => null);
    when(
      () => mockBackupService.getEstimatedBackupSize(any()),
    ).thenAnswer((_) async => 0);
    when(
      () => mockBackupService.getUserEmail(),
    ).thenAnswer((_) async => 'user@example.com');
    when(() => mockBackupService.getBackupContentSummary()).thenAnswer(
      (_) async => const BackupContentSummary(
        prayersCount: 0,
        thanksgivingsCount: 0,
        testimoniesCount: 0,
        favoritesCount: 0,
        encountersCount: 0,
        discoveryCount: 0,
        versesCount: 0,
      ),
    );

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
    when(
      () => mockBackupService.isAuthenticated(),
    ).thenAnswer((_) async => isAuthenticated);

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

  testWidgets(
    'shows the safeguard Next button when already connected',
    (tester) async {
      await pumpPage(tester, isAuthenticated: true);

      final nextText = 'onboarding.onboarding_next'.tr();
      expect(find.widgetWithText(ElevatedButton, nextText), findsOneWidget);
    },
  );

  testWidgets(
    'hides the safeguard Next button when not yet connected',
    (tester) async {
      await pumpPage(tester, isAuthenticated: false);

      final nextText = 'onboarding.onboarding_next'.tr();
      expect(find.widgetWithText(ElevatedButton, nextText), findsNothing);
    },
  );

  testWidgets(
    'tapping the safeguard Next button calls onNext',
    (tester) async {
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
    },
  );
}
