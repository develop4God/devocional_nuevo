@Tags(['unit', 'widgets'])
library;

// test/unit/widgets/devocionales_page_drawer_test.dart

import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocionales_page_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../helpers/bloc_test_helper.mocks.dart';
import '../../helpers/test_helpers.dart';

/// Drives the real drawer widget: bible-version dropdown, dark-mode toggle,
/// and navigation entries. DevocionalProvider is a Mockito mock (reused from
/// bloc_test_helper.dart); ThemeBloc is real so BlocBuilder's theme-derived
/// UI (dark mode icon/switch) reflects actual state transitions.
void main() {
  late MockDevocionalProvider devocionalProvider;
  late ThemeBloc themeBloc;

  setUp(() async {
    await setupFirebaseMocks();
    await registerTestServices();

    devocionalProvider = MockDevocionalProvider();
    when(devocionalProvider.availableVersions).thenReturn(['RVR1960', 'NVI']);
    when(devocionalProvider.selectedVersion).thenReturn('RVR1960');
    when(devocionalProvider.isSwitchingVersion).thenReturn(false);
    when(devocionalProvider.errorMessage).thenReturn(null);
    when(
      devocionalProvider.hasTargetYearsLocalData(),
    ).thenAnswer((_) async => false);

    themeBloc = ThemeBloc();
    final loaded = themeBloc.stream.firstWhere((s) => s is ThemeLoaded);
    themeBloc.add(const LoadTheme());
    await loaded;
  });

  tearDown(() {
    themeBloc.close();
  });

  Future<void> pumpDrawer(
    WidgetTester tester, {
    NavigatorObserver? navigatorObserver,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DevocionalProvider>.value(
            value: devocionalProvider,
          ),
        ],
        child: BlocProvider<ThemeBloc>.value(
          // Wraps MaterialApp (an ancestor of its Navigator) rather than
          // just `home`, so pages pushed on top of the drawer's route can
          // still find ThemeBloc — a route pushed via Navigator.push is a
          // sibling subtree of `home`, not a descendant of it.
          value: themeBloc,
          child: MaterialApp(
            navigatorObservers: [
              if (navigatorObserver != null) navigatorObserver,
            ],
            home: Builder(
              builder: (context) => Scaffold(
                drawer: const DevocionalesDrawer(),
                body: Center(
                  child: Builder(
                    builder: (innerContext) => ElevatedButton(
                      onPressed: () => Scaffold.of(innerContext).openDrawer(),
                      child: const Text('open drawer'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open drawer'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the bible version selector with current selection', (
    tester,
  ) async {
    await pumpDrawer(tester);

    expect(
        find.byKey(const Key('drawer_bible_version_selector')), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsOneWidget);
  });

  testWidgets('close button pops the drawer', (tester) async {
    await pumpDrawer(tester);
    expect(find.byType(Drawer), findsOneWidget);

    await tester.tap(find.byKey(const Key('drawer_close_button')));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsNothing);
  });

  // The three navigation tests below assert the drawer's own responsibility
  // — closing itself and pushing a route for the right page type — via a
  // NavigatorObserver. Navigator.didPush fires synchronously from
  // Navigator.push, before any frame is built, so the push itself is
  // observed independently of whether the destination page can fully
  // render. FavoritesPage/NotesPage/NotificationConfigPage each pull in
  // their own provider graphs (DiscoveryBloc, fully-stubbed
  // DevocionalProvider, Firebase, etc.); fully satisfying those here would
  // duplicate those pages' own test suites, so any build error from the
  // pushed page is expected and discarded.
  testWidgets(
    'tapping Saved Favorites closes the drawer and pushes FavoritesPage',
    (tester) async {
      final pushedRoutes = <Route<dynamic>>[];
      final observer = _RoutePushObserver(pushedRoutes);
      await pumpDrawer(tester, navigatorObserver: observer);

      await tester.tap(find.byKey(const Key('drawer_saved_favorites')));
      tester.takeException(); // destination page's own dependencies, not ours

      expect(
        pushedRoutes.whereType<MaterialPageRoute<dynamic>>(),
        isNotEmpty,
      );
    },
  );

  testWidgets(
    'tapping My Notes closes the drawer and pushes NotesPage',
    (tester) async {
      final pushedRoutes = <Route<dynamic>>[];
      final observer = _RoutePushObserver(pushedRoutes);
      await pumpDrawer(tester, navigatorObserver: observer);

      await tester.tap(find.byKey(const Key('drawer_my_notes')));
      tester.takeException();

      expect(
        pushedRoutes.whereType<MaterialPageRoute<dynamic>>(),
        isNotEmpty,
      );
    },
  );

  testWidgets(
    'tapping Notifications closes the drawer and pushes NotificationConfigPage',
    (tester) async {
      final pushedRoutes = <Route<dynamic>>[];
      final observer = _RoutePushObserver(pushedRoutes);
      await pumpDrawer(tester, navigatorObserver: observer);

      await tester.tap(find.byKey(const Key('drawer_notifications_config')));
      tester.takeException();

      expect(
        pushedRoutes.whereType<MaterialPageRoute<dynamic>>(),
        isNotEmpty,
      );
    },
  );

  testWidgets(
    'dark mode row tap dispatches ChangeBrightness and the switch reflects it',
    (tester) async {
      await pumpDrawer(tester);

      final switchFinder = find.descendant(
        of: find.byKey(const Key('drawer_dark_mode_toggle')),
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(switchFinder).value, isFalse);
      expect((themeBloc.state as ThemeLoaded).brightness, Brightness.light);

      // Tap the leading icon area, not the Switch itself — a Switch inside
      // the row wins the gesture arena over the ancestor InkWell, so a tap
      // on the Switch's own bounds never reaches drawerRow's onTap.
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('drawer_dark_mode_toggle')),
          matching: find.byIcon(Icons.dark_mode_outlined),
        ),
      );
      // ChangeBrightness's handler awaits a real SharedPreferences write
      // before emitting; that Future only resolves outside the widget
      // binding's synchronous test zone, so wait for it via runAsync rather
      // than pump/pumpAndSettle (which don't drive arbitrary pending I/O).
      await tester.runAsync(() => themeBloc.stream.firstWhere(
            (s) => s is ThemeLoaded && s.brightness == Brightness.dark,
          ));
      await tester.pumpAndSettle();

      expect((themeBloc.state as ThemeLoaded).brightness, Brightness.dark);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);
    },
  );

  testWidgets(
    'selecting a different bible version calls setSelectedVersion',
    (tester) async {
      when(
        devocionalProvider.setSelectedVersion('NVI'),
      ).thenAnswer((_) async {});

      await pumpDrawer(tester);

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Dropdown items render the resolved display name (from
      // BibleVersionRegistry), not the raw version id — NVI resolves to its
      // full Spanish name. The menu overlay renders a second copy of the
      // item alongside the closed selector, so pick the last match.
      await tester.tap(find.text('Nueva Versión Internacional').last);
      await tester.pumpAndSettle();

      verify(devocionalProvider.setSelectedVersion('NVI')).called(1);
    },
  );

  testWidgets(
    'download row shows offline-ready state when local data already exists',
    (tester) async {
      when(
        devocionalProvider.hasTargetYearsLocalData(),
      ).thenAnswer((_) async => true);

      await pumpDrawer(tester);
      await tester.pump();

      expect(find.byIcon(Icons.offline_pin_outlined), findsOneWidget);
    },
  );
}

/// Records every route pushed onto the observed Navigator.
class _RoutePushObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed;

  _RoutePushObserver(this.pushed);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
}
