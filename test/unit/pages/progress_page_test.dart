@Tags(['unit', 'pages'])
library;

// test/unit/pages/progress_page_test.dart
//
// Genuinely DI-wired widget-mount coverage for ProgressPage. Pumps the real
// ProgressPage inside a MultiProvider tree (real ThemeBloc + real
// DevocionalProvider constructor-injected with a mocked repository), the
// same pattern used in devocionales_page_test.dart / encounter_intro_page_test.dart.
//
// ProgressPage's SpiritualStatsService is instantiated directly in the State
// (`SpiritualStatsService()`), not via ServiceLocator, so it can't be mocked
// — instead we let it run for real against the SharedPreferences mock that
// registerTestServicesWithFakes() already sets up.

import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/pages/progress_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart' show registerTestServicesWithFakes;

class MockDevocionalRepository extends Mock implements DevocionalRepository {}

/// Mirrors the FakeThemeBloc duplicated across several widget test files in
/// this repo — ProgressPage.build() unconditionally does
/// `context.watch<ThemeBloc>()`, so any host needs a ready ThemeLoaded state.
class FakeThemeBloc extends Fake implements ThemeBloc {
  @override
  Stream<ThemeState> get stream => Stream.value(
        ThemeLoaded.withThemeData(
          themeFamily: 'Deep Purple',
          brightness: Brightness.light,
        ),
      );

  @override
  ThemeState get state => ThemeLoaded.withThemeData(
        themeFamily: 'Deep Purple',
        brightness: Brightness.light,
      );

  @override
  void add(ThemeEvent event) {}

  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDevocionalRepository repository;

  setUp(() async {
    await registerTestServicesWithFakes();
    repository = MockDevocionalRepository();
  });

  Widget host({bool? isActive}) {
    final isActiveNotifier =
        isActive == null ? null : ValueNotifier<bool>(isActive);
    return MultiProvider(
      providers: [
        BlocProvider<ThemeBloc>(create: (_) => FakeThemeBloc()),
        ChangeNotifierProvider<DevocionalProvider>(
          create: (_) => DevocionalProvider(
            enableAudio: false,
            devocionalRepository: repository,
          ),
        ),
      ],
      child: MaterialApp(
        home: ProgressPage(isActive: isActiveNotifier),
      ),
    );
  }

  group('ProgressPage — initialization outcomes', () {
    testWidgets('shows a loading spinner, then renders loaded stats content',
        (tester) async {
      await tester.pumpWidget(host());

      // First frame: _isLoading starts true, spinner shows before the
      // real SpiritualStatsService async load resolves.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Real success: loading spinner is gone, real stats content rendered
      // (streak card + stat cards + achievements section from the real
      // SpiritualStatsService, backed by mocked SharedPreferences).
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('progress.title'.tr()), findsOneWidget);
      expect(find.text('progress.current_streak'.tr()), findsOneWidget);
      expect(find.text('progress.devotionals_completed'.tr()), findsOneWidget);
      expect(find.text('progress.favorites_saved'.tr()), findsOneWidget);
      expect(find.text('progress.achievements'.tr()), findsOneWidget);
    });
  });

  group('ProgressPage — pull to refresh', () {
    testWidgets('pull-to-refresh re-invokes stats loading without crashing',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Drag down inside the scrollable content to trigger RefreshIndicator.
      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Page is still healthy after refresh — no error scaffold, stats
      // content still present.
      expect(find.text('progress.title'.tr()), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('ProgressPage — achievement tip banner', () {
    testWidgets(
        'shows the achievement tip snackbar on first load, dismissible via '
        'the understood action', (tester) async {
      // tipShownCount defaults to 0 (< 2), so the tip fires after the
      // page's internal 1500ms delay per _showAchievementTipIfNeeded().
      await tester.pumpWidget(host(isActive: true));
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('progress.useful_tip'.tr()), findsOneWidget);
      expect(find.text('progress.achievement_tip'.tr()), findsOneWidget);

      await tester.tap(
        find.widgetWithText(
          SnackBarAction,
          'progress.understood'.tr(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('progress.useful_tip'.tr()), findsNothing);
    });

    testWidgets(
        'does not show the achievement tip when the tab is inactive on open',
        (tester) async {
      await tester.pumpWidget(host(isActive: false));
      await tester.pump(const Duration(milliseconds: 1600));

      expect(find.text('progress.useful_tip'.tr()), findsNothing);
    });

    testWidgets(
        'no longer shows the tip once achievement_tip_count has reached 2',
        (tester) async {
      SharedPreferences.setMockInitialValues({'achievement_tip_count': 2});

      await tester.pumpWidget(host(isActive: true));
      await tester.pump(const Duration(milliseconds: 1600));

      expect(find.text('progress.useful_tip'.tr()), findsNothing);
    });
  });
}
