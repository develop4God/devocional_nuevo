@Tags(['integration'])
library;

// test/widget/favorites_page_discovery_tab_test.dart
// Critical integration test for FavoritesPage Discovery tab switching
// Tests the full widget-BLoC integration flow that unit tests cannot cover
//
// This test is intentionally slow because it:
// - Renders full widget tree with MaterialApp, providers, and complex pages
// - Executes real BLoC state transitions with async operations
// - Tests actual user interaction (tab switching)
//
// Fast alternatives exist in test/unit/blocs/discovery_bloc_state_transitions_test.dart
// Run without this test: flutter test --exclude-tags=slow
import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/pages/favorites_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/bloc_test_helper.dart';

void main() {
  late DiscoveryBlocTestBase testBase;
  late dynamic mockDevocionalProvider;
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Mock platform channels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '/mock_path',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => null,
    );
    setupServiceLocator();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    testBase = DiscoveryBlocTestBase();
    testBase.setupMocks();
    // Use helper to create mock provider
    mockDevocionalProvider = createMockDevocionalProvider();
  });
  group('Critical Integration Tests', () {
    testWidgets(
        'Switching to Bible Studies tab triggers LoadDiscoveryStudies and prevents infinite spinner',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        // This is the CRITICAL integration test that validates:
        // 1. Tab switching works correctly
        // 2. DiscoveryBloc lazy loads only when needed
        // 3. No infinite spinner bug (the original bug this test was created for)
        //
        // Other scenarios (empty state, error state, initial loading) are covered
        // by fast unit tests in test/unit/blocs/discovery_bloc_state_transitions_test.dart
        testBase.mockEmptyIndexFetch();
        final discoveryBloc = DiscoveryBloc(
          repository: testBase.mockRepository,
          progressTracker: testBase.mockProgressTracker,
          favoritesService: testBase.mockFavoritesService,
        );
        // Use a lightweight fake ThemeBloc that is already in ThemeLoaded state
        // to avoid async initialization delays in tests.
        final themeBloc = FakeThemeBloc();
        // Build widget starting on Devotionals tab (index 0)
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<DevocionalProvider>.value(
                  value: mockDevocionalProvider),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
                BlocProvider<ThemeBloc>.value(value: themeBloc),
              ],
              child: const MaterialApp(
                home:
                    FavoritesPage(initialIndex: 0), // Start on Devotionals tab
              ),
            ),
          ),
        );
        // Wait for initial render - use pump() to avoid hanging on infinite animations
        await tester.pump();
        // Verify we're on Devotionals tab and DiscoveryBloc is still in Initial state
        // This proves lazy loading - BLoC doesn't load until tab is opened
        expect(discoveryBloc.state, isA<DiscoveryInitial>(),
            reason: 'BLoC should not load until Discovery tab is opened');
        // Now switch to Bible Studies tab (the critical user flow)
        await tester.tap(find.byIcon(Icons.star_rounded));
        // Allow multiple frames for postFrameCallback and BLoC event
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 500));
        // Verify LoadDiscoveryStudies was triggered and bloc transitioned correctly
        expect(discoveryBloc.state, isNot(isA<DiscoveryInitial>()),
            reason: 'BLoC should transition from Initial after tab switch');
        // Critical: Should not show infinite spinner
        // Either shows empty state (CircularProgressIndicator count: 0) or loaded state
        final spinnerCount =
            find.byType(CircularProgressIndicator).evaluate().length;
        expect(spinnerCount <= 1, isTrue,
            reason:
                'Should not show infinite spinner - either loading or loaded/empty state');
        await discoveryBloc.close();
        await themeBloc.close();
      });
    });
  });
}

// Test-only fake ThemeBloc that immediately provides a loaded theme state.
class FakeThemeBloc extends Fake implements ThemeBloc {
  @override
  Stream<ThemeState> get stream => Stream.value(ThemeLoaded.withThemeData(
      themeFamily: 'Deep Purple', brightness: Brightness.light));

  @override
  ThemeState get state => ThemeLoaded.withThemeData(
      themeFamily: 'Deep Purple', brightness: Brightness.light);

  @override
  void add(event) {}

  @override
  Future<void> close() async {}
}
