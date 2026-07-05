@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/services/remote_config_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

// Use a minimal fake that implements all required members
class FakeRemoteConfigService implements RemoteConfigService {
  final bool supporterEnabled;

  FakeRemoteConfigService({this.supporterEnabled = true});

  @override
  bool get featureSupporter => supporterEnabled;

  @override
  bool get showBackupSection => true;

  @override
  bool get featureLegacy => false;

  @override
  bool get featureBloc => false;

  @override
  bool get isReady => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> refresh() async {}

  @override
  void resetForTesting() {}
}

void main() {
  group('AppBottomNavBar Widget Tests', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      registerTestServices();
    });

    void overrideRemoteConfig({bool supporterEnabled = true}) {
      final locator = ServiceLocator();
      if (locator.isRegistered<RemoteConfigService>()) {
        locator.unregister<RemoteConfigService>();
      }
      locator.registerSingleton<RemoteConfigService>(
        FakeRemoteConfigService(supporterEnabled: supporterEnabled),
      );
    }

    Widget createWidgetUnderTest({
      AppTab currentTab = AppTab.home,
      ValueChanged<AppTab>? onSelectTab,
    }) {
      return MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNavBar(
            currentTab: currentTab,
            onSelectTab: onSelectTab ?? (_) {},
          ),
        ),
      );
    }

    testWidgets('renders without errors', (WidgetTester tester) async {
      overrideRemoteConfig();
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(find.byType(BottomAppBar), findsOneWidget);
    });

    testWidgets('renders bar inside SafeArea', (WidgetTester tester) async {
      overrideRemoteConfig();
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(
        find.ancestor(
          of: find.byType(BottomAppBar),
          matching: find.byType(SafeArea),
        ),
        findsOneWidget,
      );
    });

    testWidgets('handles rapid taps without errors', (
      WidgetTester tester,
    ) async {
      overrideRemoteConfig();
      final selections = <AppTab>[];
      await tester.pumpWidget(
        createWidgetUnderTest(onSelectTab: selections.add),
      );
      await tester.pumpAndSettle();

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('bottom_appbar_prayers_icon')));
        await tester.tap(find.byKey(const Key('bottom_appbar_settings_icon')));
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(selections.length, 6);
    });

    testWidgets('displays all navigation icon keys', (
      WidgetTester tester,
    ) async {
      overrideRemoteConfig();
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bottom_appbar_home_icon')), findsOneWidget);
      expect(
        find.byKey(const Key('bottom_appbar_prayers_icon')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('bottom_appbar_bible_icon')), findsOneWidget);
      expect(
        find.byKey(const Key('bottom_appbar_discovery_icon')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('bottom_appbar_encounters_icon')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('bottom_appbar_progress_icon')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('bottom_appbar_settings_icon')),
        findsOneWidget,
      );
    });

    testWidgets('shows supporter icon when remote config enables it', (
      WidgetTester tester,
    ) async {
      overrideRemoteConfig(supporterEnabled: true);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('bottom_appbar_supporter_icon')),
        findsOneWidget,
      );
    });

    testWidgets('hides supporter icon when remote config disables it', (
      WidgetTester tester,
    ) async {
      overrideRemoteConfig(supporterEnabled: false);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('bottom_appbar_supporter_icon')),
        findsNothing,
      );
    });

    testWidgets('tapping home icon selects home tab', (
      WidgetTester tester,
    ) async {
      overrideRemoteConfig();
      AppTab? selected;
      await tester.pumpWidget(
        createWidgetUnderTest(
          currentTab: AppTab.prayers,
          onSelectTab: (tab) => selected = tab,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_appbar_home_icon')));
      await tester.pumpAndSettle();

      expect(selected, AppTab.home);
    });

    testWidgets('tapping prayers icon selects prayers tab', (
      WidgetTester tester,
    ) async {
      overrideRemoteConfig();
      AppTab? selected;
      await tester.pumpWidget(
        createWidgetUnderTest(onSelectTab: (tab) => selected = tab),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_appbar_prayers_icon')));
      await tester.pumpAndSettle();

      expect(selected, AppTab.prayers);
    });

    testWidgets('tapping bible icon selects bible tab', (
      WidgetTester tester,
    ) async {
      overrideRemoteConfig();
      AppTab? selected;
      await tester.pumpWidget(
        createWidgetUnderTest(onSelectTab: (tab) => selected = tab),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_appbar_bible_icon')));
      await tester.pumpAndSettle();

      expect(selected, AppTab.bible);
    });

    testWidgets('tapping discovery icon selects discovery tab', (
      WidgetTester tester,
    ) async {
      overrideRemoteConfig();
      AppTab? selected;
      await tester.pumpWidget(
        createWidgetUnderTest(onSelectTab: (tab) => selected = tab),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_appbar_discovery_icon')));
      await tester.pumpAndSettle();

      expect(selected, AppTab.discovery);
    });

    testWidgets('tapping progress icon selects progress tab', (
      WidgetTester tester,
    ) async {
      overrideRemoteConfig();
      AppTab? selected;
      await tester.pumpWidget(
        createWidgetUnderTest(onSelectTab: (tab) => selected = tab),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_appbar_progress_icon')));
      await tester.pumpAndSettle();

      expect(selected, AppTab.progress);
    });

    testWidgets('tapping encounters icon selects encounters tab', (
      WidgetTester tester,
    ) async {
      overrideRemoteConfig();
      AppTab? selected;
      await tester.pumpWidget(
        createWidgetUnderTest(onSelectTab: (tab) => selected = tab),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_appbar_encounters_icon')));
      await tester.pumpAndSettle();

      expect(selected, AppTab.encounters);
    });

    testWidgets('tapping settings icon selects settings tab', (
      WidgetTester tester,
    ) async {
      overrideRemoteConfig();
      AppTab? selected;
      await tester.pumpWidget(
        createWidgetUnderTest(onSelectTab: (tab) => selected = tab),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_appbar_settings_icon')));
      await tester.pumpAndSettle();

      expect(selected, AppTab.settings);
    });

    testWidgets('tapping supporter icon selects supporter tab', (
      WidgetTester tester,
    ) async {
      overrideRemoteConfig();
      AppTab? selected;
      await tester.pumpWidget(
        createWidgetUnderTest(onSelectTab: (tab) => selected = tab),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_appbar_supporter_icon')));
      await tester.pumpAndSettle();

      expect(selected, AppTab.supporter);
    });

    testWidgets('current tab uses filled home icon when home is selected', (
      WidgetTester tester,
    ) async {
      overrideRemoteConfig();
      await tester.pumpWidget(createWidgetUnderTest(currentTab: AppTab.home));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsNothing);
    });

    testWidgets('home icon is outlined when another tab is selected', (
      WidgetTester tester,
    ) async {
      overrideRemoteConfig();
      await tester.pumpWidget(
        createWidgetUnderTest(currentTab: AppTab.prayers),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.home), findsNothing);
    });
  });
}
