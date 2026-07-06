@Tags(['unit', 'widgets'])
library;

// test/unit/widgets/favorites_page_bottom_nav_test.dart
// FavoritesPage is pushed over AppNavigationShell (from the drawer, progress
// page, and discovery list), so it must keep showing the persistent
// AppBottomNavBar and route taps back to the shell instead of stacking a
// second navigation surface.

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/pages/favorites_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/bloc_test_helper.dart';
import '../../helpers/test_helpers.dart';

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
  void add(event) {}

  @override
  Future<void> close() async {}
}

void main() {
  group('FavoritesPage bottom navigation', () {
    late DiscoveryBlocTestBase testBase;
    late dynamic mockDevocionalProvider;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (call) async => null,
      );
      await registerTestServices();
      overrideRemoteConfigService(supporterEnabled: false);
      testBase = DiscoveryBlocTestBase();
      testBase.setupMocks();
      testBase.mockEmptyIndexFetch();
      mockDevocionalProvider = createMockDevocionalProvider();
    });

    Future<void> pumpFavoritesPushedOverShell(WidgetTester tester) async {
      final discoveryBloc = DiscoveryBloc(
        repository: testBase.mockRepository,
        progressTracker: testBase.mockProgressTracker,
        favoritesService: testBase.mockFavoritesService,
      );
      final themeBloc = FakeThemeBloc();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DevocionalProvider>.value(
              value: mockDevocionalProvider,
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<ThemeBloc>.value(value: themeBloc),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: discoveryBloc,
                            child: const FavoritesPage(),
                          ),
                        ),
                      ),
                      child: const Text('Open favorites'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open favorites'));
      // The Discovery favorites tab is built eagerly by TabBarView and shows
      // a CircularProgressIndicator with a repeating animation, so
      // pumpAndSettle would never settle here — pump discrete frames instead,
      // same pattern as favorites_page_discovery_tab_test.dart.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('shows the persistent shell bottom nav bar', (
      WidgetTester tester,
    ) async {
      await pumpFavoritesPushedOverShell(tester);

      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(find.byKey(const Key('bottom_appbar_home_icon')), findsOneWidget);
    });

    testWidgets('tapping a nav icon pops back to the shell', (
      WidgetTester tester,
    ) async {
      await pumpFavoritesPushedOverShell(tester);
      expect(find.byType(FavoritesPage), findsOneWidget);

      await tester.tap(find.byKey(const Key('bottom_appbar_home_icon')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FavoritesPage), findsNothing);
      expect(find.text('Open favorites'), findsOneWidget);
    });
  });
}
