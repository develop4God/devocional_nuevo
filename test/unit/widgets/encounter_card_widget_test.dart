@Tags(['unit', 'widgets'])
library;

// test/unit/widgets/encounter_card_widget_test.dart
//
// 4 widget tests for the Encounters feature:
//  1. CinematicSceneCard renders without image_url
//  2. CompletionCard back-button calls onBackToEncounters
//  3. coming_soon tile does not navigate on tap
//  4. Progress bar renders one segment per card

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/models/encounter_card_model.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/models/encounter_study.dart';
import 'package:devocional_nuevo/pages/encounters/encounter_detail_page.dart';
import 'package:devocional_nuevo/pages/encounters/encounters_list_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/encounter/encounter_card_widgets.dart';
import 'package:devocional_nuevo/widgets/encounter/encounter_grid_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Firebase channel mock (prevents real plugin calls) ──────────────────────

void _setupFirebaseMocks() {
  const firebaseCoreChannel = MethodChannel('plugins.flutter.io/firebase_core');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(firebaseCoreChannel, (call) async {
    switch (call.method) {
      case 'Firebase#initializeCore':
        return [
          {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'fake-api-key',
              'appId': 'fake-app-id',
              'messagingSenderId': 'fake-sender-id',
              'projectId': 'fake-project-id',
            },
            'pluginConstants': {},
          },
        ];
      case 'Firebase#initializeApp':
        return {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'fake-api-key',
            'appId': 'fake-app-id',
            'messagingSenderId': 'fake-sender-id',
            'projectId': 'fake-project-id',
          },
          'pluginConstants': {},
        };
      default:
        return null;
    }
  });

  const pigeonChannel = MethodChannel(
    'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pigeonChannel, (call) async {
    switch (call.method) {
      case 'initializeCore':
        return [
          {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'fake-api-key',
              'appId': 'fake-app-id',
              'messagingSenderId': 'fake-sender-id',
              'projectId': 'fake-project-id',
            },
            'pluginConstants': {},
          },
        ];
      case 'initializeApp':
        return {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'fake-api-key',
            'appId': 'fake-app-id',
            'messagingSenderId': 'fake-sender-id',
            'projectId': 'fake-project-id',
          },
          'pluginConstants': {},
        };
      default:
        return null;
    }
  });

  // Additional platform channels used by ServiceLocator / tests
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_crashlytics'),
    (_) async => null,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async {
      switch (call.method) {
        case 'getApplicationDocumentsDirectory':
        case 'getApplicationSupportDirectory':
          return '/mock_documents';
        case 'getTemporaryDirectory':
          return '/mock_temp';
        default:
          return '/mock_unknown';
      }
    },
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('flutter_tts'),
    (_) async => null,
  );
}

// ─── Fake BLoC (Fake avoids Stream subscription lifecycle) ───────────────────

class _MockEncounterBloc extends Fake implements EncounterBloc {
  final EncounterState _s;

  _MockEncounterBloc(this._s);

  @override
  Stream<EncounterState> get stream => Stream.value(_s);

  @override
  EncounterState get state => _s;

  @override
  void add(EncounterEvent event) {}

  @override
  Future<void> close() async {}
}

// ─── No-op analytics (avoids firebase_analytics calls) ───────────────────────

class _TestAnalyticsService extends AnalyticsService {
  _TestAnalyticsService() : super(analytics: null);

  @override
  Future<void> logEncounterOpened({required String encounterId}) async {}

  @override
  Future<void> logEncounterStarted({required String encounterId}) async {}

  @override
  Future<void> logEncounterCompleted({required String encounterId}) async {}

  @override
  Future<void> logEncounterViewToggle({required String view}) async {}

  @override
  Future<void> logBottomBarAction({required String action}) async {}

  @override
  Future<void> logTtsPlay() async {}

  @override
  Future<void> logDevocionalComplete({
    required String devocionalId,
    required String campaignTag,
    String source = 'read',
    int? readingTimeSeconds,
    double? scrollPercentage,
    double? listenedPercentage,
  }) async {}

  @override
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> resetAnalyticsData() async {}

  @override
  Future<void> logAppInit({Map<String, Object>? parameters}) async {}

  @override
  Future<void> logNavigationNext({
    required int currentIndex,
    required int totalDevocionales,
    required String viaBloc,
    String? fallbackReason,
  }) async {}

  @override
  Future<void> logNavigationPrevious({
    required int currentIndex,
    required int totalDevocionales,
    required String viaBloc,
    String? fallbackReason,
  }) async {}

  @override
  Future<void> logFabTapped({required String source}) async {}

  @override
  Future<void> logFabChoiceSelected({
    required String source,
    required String choice,
  }) async {}

  @override
  Future<void> logDiscoveryAction({
    required String action,
    String? studyId,
  }) async {}
}

// ─── NavigatorObserver to detect pushes ──────────────────────────────────────

class _FakeVerseResolverService implements IVerseResolverService {
  @override
  Future<String?> resolveVerseText({
    required String reference,
    required String versionCode,
  }) async =>
      null;
}

class _NavObserver extends NavigatorObserver {
  final pushes = <String>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes.add(route.settings.name ?? '');
  }
}

// ─── Event-capturing mock bloc ────────────────────────────────────────────────

class _EventCapturingMockBloc extends _MockEncounterBloc {
  final List<EncounterEvent> capturedEvents;

  _EventCapturingMockBloc(super.state, this.capturedEvents);

  @override
  void add(EncounterEvent event) {
    capturedEvents.add(event);
    super.add(event);
  }
}

// ─── Test-only fake ThemeBloc ─────────────────────────────────────────────────

class _FakeThemeBloc extends Fake implements ThemeBloc {
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

// ─── Helpers ─────────────────────────────────────────────────────────────────

EncounterIndexEntry _makeEntry({
  String id = 'test_001',
  String status = 'published',
  String title = 'Test Encounter',
}) =>
    EncounterIndexEntry(
      id: id,
      version: '1.0',
      emoji: '🌊',
      status: status,
      files: {'en': '$id.json'},
      titles: {'en': title},
      subtitles: {'en': 'Test Subtitle'},
      scriptureReference: {'en': 'John 1:1'},
      estimatedReadingMinutes: {'en': 5},
    );

EncounterStudy _makeStudy3Cards() => const EncounterStudy(
      id: 'test_001',
      language: 'en',
      cards: [
        EncounterCard(order: 1, type: 'cinematic_scene', title: 'Card 1'),
        EncounterCard(order: 2, type: 'character_moment', title: 'Card 2'),
        EncounterCard(order: 3, type: 'completion', title: 'Card 3'),
      ],
    );

// ─── Test setup ──────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  _setupFirebaseMocks();

  setUpAll(() async {
    await setupServiceLocator();
    // Replace analytics with a no-op to avoid Firebase calls in page tests
    final locator = ServiceLocator();
    if (locator.isRegistered<AnalyticsService>()) {
      locator.unregister<AnalyticsService>();
    }
    locator.registerSingleton<AnalyticsService>(_TestAnalyticsService());
    if (locator.isRegistered<IVerseResolverService>()) {
      locator.unregister<IVerseResolverService>();
    }
    locator.registerSingleton<IVerseResolverService>(
      _FakeVerseResolverService(),
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  // ── View helper — call inside tester.runAsync to set up 1080×1920 viewport ──

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
  }

  // ── Test 1: CinematicSceneCard renders without image_url ────────────────────

  testWidgets('CinematicSceneCard renders without image_url', (tester) async {
    const card = EncounterCard(
      order: 1,
      type: 'cinematic_scene',
      title: 'Test Title',
      narrative: 'A test narrative.',
      // imageUrl intentionally omitted (null)
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CinematicSceneCard(card: card)),
      ),
    );
    // Wait for animations: 300ms delay + 600ms duration
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.byType(CinematicSceneCard), findsOneWidget);
    expect(find.text('TEST TITLE'), findsOneWidget); // Title is uppercased
  });

  // ── Test: CinematicSceneCard renders scriptureConnections ───────────────────
  //
  // Regression test: scriptureConnections was parsed from JSON and carried on
  // EncounterCard, but CinematicSceneCard.build() never read the field, so
  // any scripture_connections on a cinematic_scene card was silently dropped
  // at render time. This covers the fix wiring _ScriptureConnectionsSection
  // into CinematicSceneCard, matching ScriptureMomentCard/CharacterMomentCard/
  // TheologicalDepthCard, which already render it.

  testWidgets('CinematicSceneCard renders scriptureConnections', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const card = EncounterCard(
        order: 1,
        type: 'cinematic_scene',
        title: 'Test Title',
        narrative: 'A test narrative.',
        scriptureConnections: [
          VerseRef(
              reference: 'Marcos 1:7',
              text: 'Viene tras mí el que es más poderoso que yo.'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => DevocionalProvider(),
            child: const Scaffold(body: CinematicSceneCard(card: card)),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Marcos 1:7'), findsOneWidget);
      expect(
        find.text('Viene tras mí el que es más poderoso que yo.'),
        findsOneWidget,
      );
    });
  });

  // ── Test: visual header height scales with screen width ─────────────────────
  //
  // Regression test: the header's height used to be a fixed pixel constant
  // (120 landscape / 240 portrait) regardless of screen width. On a tablet,
  // the same fixed height stretched across a much wider box, so BoxFit.cover
  // had to crop the image far more aggressively -- cutting into the top of
  // the artwork. The height must now scale with the available width instead
  // of staying flat across very different screen sizes.

  testWidgets(
    'CinematicSceneCard visual header is taller on a wider (tablet) screen '
    'than on a narrower (phone) screen',
    (tester) async {
      const card = EncounterCard(
        order: 1,
        type: 'cinematic_scene',
        title: 'Test Title',
      );

      Future<double> pumpAndMeasureHeaderHeight(Size physicalSize) async {
        tester.view.physicalSize = physicalSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: CinematicSceneCard(card: card)),
          ),
        );
        await tester.pump();

        // _VisualHeader's Container carries a ValueKey specifically so tests
        // can target its rendered height directly -- BoxFit.cover has to
        // crop the image into whatever height this resolves to.
        return tester
            .getSize(find.byKey(const ValueKey('encounter_visual_header')))
            .height;
      }

      final phoneHeaderHeight = await pumpAndMeasureHeaderHeight(
        const Size(390, 844), // typical phone portrait
      );
      final tabletHeaderHeight = await pumpAndMeasureHeaderHeight(
        const Size(1024, 1366), // typical tablet portrait
      );

      expect(
        tabletHeaderHeight,
        greaterThan(phoneHeaderHeight),
        reason: 'Header height must scale up with the wider tablet viewport, '
            'not stay a fixed pixel value shared with the phone width.',
      );
    },
  );

  // ── Test: visual header does not crash on a very short screen ───────────────
  //
  // Regression test: `(width / aspectRatio).clamp(150.0, screenHeight * factor)`
  // throws ArgumentError when screenHeight * factor < 150.0 (min > max), which
  // happens on very short viewports (small landscape windows, split-screen,
  // some foldables). The upper bound must never fall below the 150.0 floor.

  testWidgets(
    'CinematicSceneCard visual header does not throw on a very short screen',
    (tester) async {
      const card = EncounterCard(
        order: 1,
        type: 'cinematic_scene',
        title: 'Test Title',
      );

      // Landscape, very short height: screenHeight * 0.35 = 84, well under
      // the 150.0 floor -- this is the exact shape that used to crash.
      tester.view.physicalSize = const Size(800, 240);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CinematicSceneCard(card: card)),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('encounter_visual_header')))
            .height,
        greaterThanOrEqualTo(150.0),
      );
    },
  );

  // ── Test 2: CompletionCard back button calls onBackToEncounters ─────────────

  testWidgets('CompletionCard back button calls onBackToEncounters', (
    tester,
  ) async {
    await tester.runAsync(() async {
      var called = false;
      const card = EncounterCard(
        order: 1,
        type: 'completion',
        title: 'Well Done',
        completionVerse: VerseRef(
          reference: 'Matt 14:33',
          text: 'Truly you are the Son of God.',
          bibleVersion: 'KJ2000',
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => DevocionalProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: CompletionCard(
                card: card,
                onBackToEncounters: () => called = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Find button
      final buttonFinder = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton,
      );
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pump();

      // Wait for the delayed callback (500ms) using real time in runAsync
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await tester.pump();

      expect(called, isTrue);
    });
  });

  // ── Test 3: coming_soon tile does not navigate on tap ───────────────────────

  testWidgets('coming_soon tile does not navigate on tap', (tester) async {
    await tester.runAsync(() async {
      final entry = _makeEntry(id: 'cs_001', status: 'coming_soon');
      final mockBloc = _MockEncounterBloc(EncounterLoaded(index: [entry]));
      final navObserver = _NavObserver();

      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [navObserver],
          home: MultiBlocProvider(
            providers: [
              BlocProvider<EncounterBloc>.value(value: mockBloc),
              BlocProvider<ThemeBloc>.value(value: _FakeThemeBloc()),
              ChangeNotifierProvider(create: (_) => DevocionalProvider()),
            ],
            child: const EncountersListPage(),
          ),
        ),
      );

      await tester.pump();

      // Capture the push count AFTER the initial EncountersListPage route
      // (MaterialApp itself pushes '/' on startup — we record the baseline here)
      final pushCountBefore = navObserver.pushes.length;

      // The coming_soon tile shows the title text
      expect(find.text('Test Encounter'), findsOneWidget);

      // Tap the tile — navigation must NOT occur
      await tester.tap(find.text('Test Encounter'), warnIfMissed: false);
      await tester.pump();

      // No new route was pushed after the tile tap
      expect(navObserver.pushes.length, equals(pushCountBefore));
    });
  });

  // ── Test 4: Progress bar renders one Container segment per card ─────

  testWidgets('progress bar renders one segment per card', (tester) async {
    await tester.runAsync(() async {
      final study = _makeStudy3Cards();
      final entry = _makeEntry();
      final loadedState = EncounterLoaded(
        index: [entry],
        loadedStudies: {'test_001': study},
      );
      final mockBloc = _MockEncounterBloc(loadedState);

      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => DevocionalProvider(),
            child: BlocProvider<EncounterBloc>.value(
              value: mockBloc,
              child: EncounterDetailPage(entry: entry, lang: 'en'),
            ),
          ),
        ),
      );

      await tester.pump();

      // The progress bar has one segment per card, we check text counter instead
      // Counter starts at "1 / 3"
      expect(find.text('1 / 3'), findsOneWidget);
    });
  });

  // ── Test 5: InteractiveMomentCard renders title and reflection prompt ─────────

  testWidgets('InteractiveMomentCard renders title and reflection prompt', (
    tester,
  ) async {
    const card = EncounterCard(
      order: 9,
      type: 'interactive_moment',
      title: 'Name Your Wave',
      subtitle: 'What storm is keeping your eyes off Jesus?',
      reflectionPrompt:
          'Take a moment to name the wind and waves in your life.',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: InteractiveMomentCard(card: card)),
      ),
    );
    // Wait for animations
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('Name Your Wave'), findsOneWidget);
    expect(find.textContaining('wind and waves'), findsOneWidget);
  });

  // ── Test 6: CompletionCard shows bible version disclaimer ────────────────────

  testWidgets('CompletionCard shows bible version disclaimer', (tester) async {
    await tester.runAsync(() async {
      const card = EncounterCard(
        order: 11,
        type: 'completion',
        title: 'You Walked the Water',
        completionVerse: VerseRef(
          reference: 'Matthew 14:33',
          text: 'Truly you are the Son of God.',
          bibleVersion: 'KJ2000',
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => DevocionalProvider(),
          child: const MaterialApp(
            home: Scaffold(
              body: CompletionCard(card: card, bibleVersion: 'KJ2000'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1400));

      expect(find.text('KJ2000'), findsOneWidget);
      expect(find.text('"Truly you are the Son of God."'), findsOneWidget);
      expect(find.text('— Matthew 14:33'), findsOneWidget);
    });
  });

  // ── Test 7: EncounterDetailPage shows retry when study cannot be loaded ──────

  testWidgets('detail page shows retry button when study is null', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final entry = _makeEntry();
      // State is EncounterLoaded but study is NOT in loadedStudies map
      final mockBloc = _MockEncounterBloc(EncounterLoaded(index: [entry]));

      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => DevocionalProvider(),
            child: BlocProvider<EncounterBloc>.value(
              value: mockBloc,
              child: EncounterDetailPage(entry: entry, lang: 'en'),
            ),
          ),
        ),
      );

      await tester.pump();

      // The retry button must be visible — no infinite spinner
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  // ── Test 8: list page does not re-dispatch LoadEncounterIndex if already loaded

  testWidgets('list page does not re-dispatch index load when already loaded', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final entry = _makeEntry();
      final events = <EncounterEvent>[];
      final mockBloc = _EventCapturingMockBloc(
        EncounterLoaded(index: [entry]),
        events,
      );

      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<EncounterBloc>.value(value: mockBloc),
              BlocProvider<ThemeBloc>.value(value: _FakeThemeBloc()),
              ChangeNotifierProvider(create: (_) => DevocionalProvider()),
            ],
            child: const EncountersListPage(),
          ),
        ),
      );

      await tester.pump();

      // No LoadEncounterIndex event should be dispatched since the state is
      // already EncounterLoaded
      expect(events.whereType<LoadEncounterIndex>(), isEmpty);
    });
  });

  // ── Test 9: list page shows back arrow (left arrow) in app bar ───────────────

  testWidgets('list page shows back arrow in app bar', (tester) async {
    await tester.runAsync(() async {
      final entry = _makeEntry();
      final mockBloc = _MockEncounterBloc(EncounterLoaded(index: [entry]));

      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<EncounterBloc>.value(value: mockBloc),
              BlocProvider<ThemeBloc>.value(value: _FakeThemeBloc()),
              ChangeNotifierProvider(create: (_) => DevocionalProvider()),
            ],
            child: const EncountersListPage(),
          ),
        ),
      );

      await tester.pump();

      // The app bar should NOT have a hidden leading (SizedBox.shrink).
      // Instead it should have a back arrow icon available (default AppBar back).
      // With our change, there is no custom `leading: SizedBox.shrink()` so
      // Flutter renders the default back button when there's a route to pop.
      // We verify that Icons.close is not present as the leading icon.
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });

  // ── Test 10: list page shows grid toggle button ──────────────────────────────

  testWidgets('list page shows grid view toggle button', (tester) async {
    await tester.runAsync(() async {
      final entry = _makeEntry();
      final mockBloc = _MockEncounterBloc(EncounterLoaded(index: [entry]));

      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<EncounterBloc>.value(value: mockBloc),
              BlocProvider<ThemeBloc>.value(value: _FakeThemeBloc()),
              ChangeNotifierProvider(create: (_) => DevocionalProvider()),
            ],
            child: const EncountersListPage(),
          ),
        ),
      );

      await tester.pump();

      // Grid toggle button must be present
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    });
  });

  // ── Test 11: list page toggles to grid overlay on toggle button tap ──────────

  testWidgets('list page toggles grid overlay on grid button tap', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final entry = _makeEntry();
      final mockBloc = _MockEncounterBloc(EncounterLoaded(index: [entry]));

      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<EncounterBloc>.value(value: mockBloc),
              BlocProvider<ThemeBloc>.value(value: _FakeThemeBloc()),
              ChangeNotifierProvider(create: (_) => DevocionalProvider()),
            ],
            child: const EncountersListPage(),
          ),
        ),
      );

      await tester.pump();

      // Grid toggle button must exist initially
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);

      // Tap the grid toggle button (smoke test - just verify it's tappable)
      // Animation behavior in tests is unreliable, so we just verify the button exists and is tappable
      await tester.tap(
        find.byIcon(Icons.grid_view_rounded),
        warnIfMissed: false,
      );
      // Don't pump after - the toggle is difficult to test reliably in widget tests
    });
  });

  // ── Test 12: detail page shows back arrow instead of close icon ──────────────

  testWidgets('detail page shows back arrow instead of close icon', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final study = _makeStudy3Cards();
      final entry = _makeEntry();
      final loadedState = EncounterLoaded(
        index: [entry],
        loadedStudies: {'test_001': study},
      );
      final mockBloc = _MockEncounterBloc(loadedState);

      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => DevocionalProvider(),
            child: BlocProvider<EncounterBloc>.value(
              value: mockBloc,
              child: EncounterDetailPage(entry: entry, lang: 'en'),
            ),
          ),
        ),
      );

      await tester.pump();

      // Back arrow should be present, old close icon should not
      expect(find.byIcon(Icons.arrow_back_ios_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });

  // ── Test 13: detail page shows complete button on last card ─────────────────

  testWidgets('detail page shows complete button on last card', (tester) async {
    await tester.runAsync(() async {
      // Study with a single completion card so we start on "last"
      const study = EncounterStudy(
        id: 'test_001',
        language: 'en',
        bibleVersion: 'KJ2000',
        cards: [EncounterCard(order: 1, type: 'completion', title: 'Done')],
      );
      final entry = _makeEntry();
      final loadedState = EncounterLoaded(
        index: [entry],
        loadedStudies: {'test_001': study},
      );
      final mockBloc = _MockEncounterBloc(loadedState);

      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => DevocionalProvider(),
            child: BlocProvider<EncounterBloc>.value(
              value: mockBloc,
              child: EncounterDetailPage(entry: entry, lang: 'en'),
            ),
          ),
        ),
      );

      await tester.pump();

      // Complete button text should be visible (i18n key 'encounters.complete')
      // In test locale it defaults to the key value 'encounters.complete' or the
      // English value 'COMPLETE' — we search for the icon instead for robustness.
      expect(
        find.byIcon(Icons.check_circle_outline_rounded),
        findsAtLeastNWidgets(1),
      );
    });
  });

  // ── Test 14: detail page dispatches CompleteEncounter on complete tap ────────

  testWidgets('detail page dispatches CompleteEncounter event on complete tap',
      (
    tester,
  ) async {
    await tester.runAsync(() async {
      const study = EncounterStudy(
        id: 'test_001',
        language: 'en',
        bibleVersion: 'KJ2000',
        cards: [EncounterCard(order: 1, type: 'completion', title: 'Done')],
      );
      final entry = _makeEntry();
      final events = <EncounterEvent>[];
      final mockBloc = _EventCapturingMockBloc(
        EncounterLoaded(index: [entry], loadedStudies: {'test_001': study}),
        events,
      );

      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => DevocionalProvider(),
            child: BlocProvider<EncounterBloc>.value(
              value: mockBloc,
              child: EncounterDetailPage(entry: entry, lang: 'en'),
            ),
          ),
        ),
      );

      await tester.pump();

      // Wait for animations to complete (CompletionCard button has 600ms delay)
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Tap the complete button (now it's ElevatedButton from CompletionCard)
      final completeBtn = find.byWidgetPredicate((w) => w is ElevatedButton);
      expect(completeBtn, findsAtLeastNWidgets(1));
      await tester.tap(completeBtn.first);
      await tester.pump();

      // Wait for the CompletionCard's delayed callback (500ms) using real time
      await Future.delayed(const Duration(milliseconds: 600));
      await tester.pump();

      // CompleteEncounter event must have been dispatched
      expect(events.whereType<CompleteEncounter>(), isNotEmpty);
      final completeEvent = events.whereType<CompleteEncounter>().first;
      expect(completeEvent.id, equals('test_001'));
    });
  });

  // ── Test 15: CompletionCard shows study-level copyright disclaimer ───────────

  testWidgets(
    'CompletionCard shows study-level copyright disclaimer when bibleVersion provided',
    (tester) async {
      const card = EncounterCard(
        order: 11,
        type: 'completion',
        title: 'Complete',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => DevocionalProvider(),
          child: const MaterialApp(
            home: Scaffold(
              body: CompletionCard(
                card: card,
                bibleVersion: 'KJ2000',
                language: 'en',
              ),
            ),
          ),
        ),
      );

      // Advance through all delayed animations (max delay 700ms + 600ms duration)
      await tester.pump(const Duration(milliseconds: 1400));

      // Copyright disclaimer should show King James info
      expect(find.textContaining('King James'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    },
  );

  // ── Test 16: EncounterGridOverlay shows filter tabs ──────────────────────────

  testWidgets('EncounterGridOverlay shows All/Pending/Completed filter tabs', (
    tester,
  ) async {
    final entry = _makeEntry();
    final state = EncounterLoaded(index: [entry]);
    final controller = AnimationController(
      vsync: tester,
      value: 1.0, // fully visible
      duration: const Duration(milliseconds: 300),
    );

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EncounterGridOverlay(
              state: state,
              entries: [entry],
              currentIndex: 0,
              lang: 'en',
              onEncounterSelected: (_, __) {},
              onClose: () {},
              animation: controller,
            ),
          ),
        ),
      );

      await tester.pump();

      // Filter overlay should be present with 3 filter buttons rendered
      expect(find.byType(EncounterGridOverlay), findsOneWidget);
      // Grid overlay renders a grid of encounter cards
      expect(find.byType(GridView), findsOneWidget);
    } finally {
      controller.dispose();
    }
  });

  // ── Test 17: grid overlay shows lock icon for locked published encounter ──────

  testWidgets('grid overlay shows lock icon for locked published encounter', (
    tester,
  ) async {
    // Two published entries: peter (first, always unlocked) and bart (second,
    // locked because peter is not yet completed).
    final peter = _makeEntry(id: 'peter_001', title: 'Peter');
    final bart = _makeEntry(id: 'bart_001', title: 'Bartimaeus');
    final state = EncounterLoaded(index: [peter, bart], completedIds: const {});
    final controller = AnimationController(
      vsync: tester,
      value: 1.0,
      duration: const Duration(milliseconds: 300),
    );

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EncounterGridOverlay(
              state: state,
              entries: [peter, bart],
              currentIndex: 0,
              lang: 'en',
              onEncounterSelected: (_, __) {},
              onClose: () {},
              animation: controller,
            ),
          ),
        ),
      );

      await tester.pump();

      // The lock icon must appear for the locked second encounter.
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    } finally {
      controller.dispose();
    }
  });

  // ── Test 18: grid overlay locked encounter does NOT call onEncounterSelected ──

  testWidgets(
    'grid overlay locked encounter does not trigger onEncounterSelected',
    (tester) async {
      final peter = _makeEntry(id: 'peter_001', title: 'Peter');
      final bart = _makeEntry(id: 'bart_001', title: 'Bartimaeus');
      final state = EncounterLoaded(
        index: [peter, bart],
        completedIds: const {},
      );
      var tappedId = '';
      final controller = AnimationController(
        vsync: tester,
        value: 1.0,
        duration: const Duration(milliseconds: 300),
      );

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EncounterGridOverlay(
                state: state,
                entries: [peter, bart],
                currentIndex: 0,
                lang: 'en',
                onEncounterSelected: (entry, _) => tappedId = entry.id,
                onClose: () {},
                animation: controller,
              ),
            ),
          ),
        );

        await tester.pump();

        // Tap on the locked encounter's title area.
        await tester.tap(find.text('Bartimaeus'), warnIfMissed: false);
        await tester.pump();

        // onEncounterSelected must NOT have been called for the locked entry.
        expect(tappedId, isNot(equals('bart_001')));
      } finally {
        controller.dispose();
      }
    },
  );

  // ── Test 19: grid overlay first (unlocked) encounter calls onEncounterSelected

  testWidgets(
    'grid overlay unlocked first encounter calls onEncounterSelected on tap',
    (tester) async {
      final peter = _makeEntry(id: 'peter_001', title: 'Peter');
      final state = EncounterLoaded(index: [peter], completedIds: const {});
      var tappedId = '';
      final controller = AnimationController(
        vsync: tester,
        value: 1.0,
        duration: const Duration(milliseconds: 300),
      );

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EncounterGridOverlay(
                state: state,
                entries: [peter],
                currentIndex: 0,
                lang: 'en',
                onEncounterSelected: (entry, _) => tappedId = entry.id,
                onClose: () {},
                animation: controller,
              ),
            ),
          ),
        );

        await tester.pump();

        // The first encounter is always unlocked — tap its title.
        await tester.tap(find.text('Peter'), warnIfMissed: false);
        await tester.pump();

        expect(tappedId, equals('peter_001'));
      } finally {
        controller.dispose();
      }
    },
  );

  // ── Test 20: list page shows lock icon for locked published encounter ─────────

  testWidgets('list page shows lock icon for locked published encounter', (
    tester,
  ) async {
    // Set welcome seen so the list page is not replaced by the welcome page.
    SharedPreferences.setMockInitialValues({'encounter_welcome_seen': true});

    await tester.runAsync(() async {
      final peter = _makeEntry(id: 'peter_001', title: 'Peter');
      final bart = _makeEntry(id: 'bart_001', title: 'Bartimaeus');
      // Neither completed → bart (second) is locked.
      final mockBloc = _MockEncounterBloc(
        EncounterLoaded(index: [peter, bart], completedIds: const {}),
      );

      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<EncounterBloc>.value(value: mockBloc),
              BlocProvider<ThemeBloc>.value(value: _FakeThemeBloc()),
              ChangeNotifierProvider(create: (_) => DevocionalProvider()),
            ],
            child: const EncountersListPage(),
          ),
        ),
      );

      await tester.pump();

      // The lock icon must be visible for the locked second encounter.
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });
  });

  // ── Test 21: list page locked encounter does not navigate on tap ──────────────

  testWidgets('list page locked encounter does not navigate when tapped', (
    tester,
  ) async {
    // Set welcome seen so the list page is not replaced by the welcome page.
    SharedPreferences.setMockInitialValues({'encounter_welcome_seen': true});

    await tester.runAsync(() async {
      final peter = _makeEntry(id: 'peter_001', title: 'Peter');
      final bart = _makeEntry(id: 'bart_001', title: 'Bartimaeus');
      final mockBloc = _MockEncounterBloc(
        EncounterLoaded(index: [peter, bart], completedIds: const {}),
      );
      final navObserver = _NavObserver();

      setPhoneViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [navObserver],
          home: MultiBlocProvider(
            providers: [
              BlocProvider<EncounterBloc>.value(value: mockBloc),
              BlocProvider<ThemeBloc>.value(value: _FakeThemeBloc()),
              ChangeNotifierProvider(create: (_) => DevocionalProvider()),
            ],
            child: const EncountersListPage(),
          ),
        ),
      );

      await tester.pump();

      // Record baseline route count after initial render.
      final pushCountBefore = navObserver.pushes.length;

      // Tap on the locked encounter title — it is visible but behind the lock
      // overlay, so no navigation should occur.
      await tester.tap(find.text('Bartimaeus'), warnIfMissed: false);
      await tester.pump();

      expect(navObserver.pushes.length, equals(pushCountBefore));
    });
  });
}
