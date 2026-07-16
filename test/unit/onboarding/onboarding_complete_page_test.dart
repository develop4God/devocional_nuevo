@Tags(['unit', 'onboarding'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_bloc.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_event.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_complete_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class MockOnboardingBloc extends MockBloc<OnboardingEvent, OnboardingState>
    implements OnboardingBloc {}

class MockBackupBloc extends MockBloc<BackupEvent, BackupState>
    implements BackupBloc {}

/// OnboardingCompletePage's content Column uses two Spacer widgets sized
/// by its parent Expanded's remaining height. Adding the Back-button
/// header (needed so users can revisit earlier steps) shrinks that
/// remaining height, and on some devices the fixed-size content
/// (celebration icon, title, subtitle, summary card, button) no longer
/// fits — a real overflow this test caught (0.727px on a small screen).
/// The fix wraps the content in a scrollable, height-constrained layout
/// so it degrades gracefully instead of overflowing.
void main() {
  late MockOnboardingBloc mockOnboardingBloc;
  late MockBackupBloc mockBackupBloc;

  setUp(() async {
    await setupFirebaseMocks();
    await registerTestServices();

    mockOnboardingBloc = MockOnboardingBloc();
    when(() => mockOnboardingBloc.state).thenReturn(const OnboardingLoading());

    mockBackupBloc = MockBackupBloc();
    when(() => mockBackupBloc.state).thenReturn(const BackupInitial());
  });

  Future<void> pumpPage(
    WidgetTester tester,
    Size physicalSize, {
    VoidCallback? onBack,
  }) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<OnboardingBloc>.value(value: mockOnboardingBloc),
          BlocProvider<BackupBloc>.value(value: mockBackupBloc),
        ],
        child: MaterialApp(
          home: OnboardingCompletePage(
            onStartApp: () {},
            onBack: onBack ?? () {},
          ),
        ),
      ),
    );
    // Avoid pumpAndSettle: the celebration page has repeating animation
    // controllers (particles, pulse) that never settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('renders without overflow on a small phone screen', (
    tester,
  ) async {
    await pumpPage(tester, const Size(720, 1280));

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without overflow on a very short screen', (
    tester,
  ) async {
    // A short/landscape-ish height, closest to reproducing the reported
    // 0.727px overflow without relying on a specific device profile.
    await pumpPage(tester, const Size(1080, 1500));

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without overflow on a tablet', (tester) async {
    await pumpPage(tester, const Size(1600, 2560));

    expect(tester.takeException(), isNull);
  });

  group('Tap anywhere to continue — accessibility affordance', () {
    testWidgets(
        'tapping empty space on the page dispatches CompleteOnboarding, '
        'same as the Continue button', (tester) async {
      await pumpPage(tester, const Size(1080, 2400));

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      verify(() => mockOnboardingBloc.add(const CompleteOnboarding()))
          .called(1);
    });

    testWidgets(
        'tapping the Back button does not also dispatch '
        'CompleteOnboarding', (tester) async {
      await pumpPage(tester, const Size(1080, 2400));

      final backText = 'onboarding.onboarding_back'.tr();
      final backButton = find.widgetWithText(TextButton, backText);

      await tester.tap(backButton);
      await tester.pump();

      verifyNever(() => mockOnboardingBloc.add(const CompleteOnboarding()));
    });
  });

  group('Back button — gated on Google Drive backup connection', () {
    testWidgets(
        'is disabled once backup is connected, so the user cannot '
        're-trigger sign-in from the confirmation screen', (tester) async {
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

      var backCalled = false;
      await pumpPage(
        tester,
        const Size(1080, 2400),
        onBack: () => backCalled = true,
      );

      final backText = 'onboarding.onboarding_back'.tr();
      final backButton = find.widgetWithText(TextButton, backText);
      expect(backButton, findsOneWidget);

      final button = tester.widget<TextButton>(backButton);
      expect(button.onPressed, isNull);

      await tester.tap(backButton, warnIfMissed: false);
      await tester.pump();
      expect(backCalled, isFalse);
    });

    testWidgets(
      'stays enabled and calls onBack when backup is not yet connected',
      (tester) async {
        when(() => mockBackupBloc.state).thenReturn(
          const BackupLoaded(
            autoBackupEnabled: false,
            backupFrequency: 'deactivated',
            wifiOnlyEnabled: false,
            compressionEnabled: false,
            backupOptions: {},
            estimatedSize: 0,
            isAuthenticated: false,
          ),
        );

        var backCalled = false;
        await pumpPage(
          tester,
          const Size(1080, 2400),
          onBack: () => backCalled = true,
        );

        final backText = 'onboarding.onboarding_back'.tr();
        final backButton = find.widgetWithText(TextButton, backText);
        expect(backButton, findsOneWidget);

        final button = tester.widget<TextButton>(backButton);
        expect(button.onPressed, isNotNull);

        await tester.tap(backButton);
        await tester.pump();
        expect(backCalled, isTrue);
      },
    );
  });
}
