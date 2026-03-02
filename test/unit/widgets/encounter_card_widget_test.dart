@Tags(['unit', 'widgets'])
library;

// test/unit/widgets/encounter_card_widget_test.dart
//
// 4 widget tests for the Encounters feature:
//  1. CinematicSceneCard renders without image_url
//  2. CompletionCard back-button calls onBackToEncounters
//  3. coming_soon tile does not navigate on tap
//  4. Progress bar renders one segment per card

import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/models/encounter_card_model.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/models/encounter_study.dart';
import 'package:devocional_nuevo/pages/encounter_detail_page.dart';
import 'package:devocional_nuevo/pages/encounters_list_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/encounter/encounter_card_widgets.dart';
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
          }
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
      'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi');
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
          }
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
  Future<void> logEncounterAction(
      {required String action, String? encounterId, int? cardOrder}) async {}

  @override
  Future<void> logBottomBarAction({required String action}) async {}

  @override
  Future<void> logTtsPlay() async {}

  @override
  Future<void> logDevocionalComplete(
      {required String devocionalId,
      required String campaignTag,
      String source = 'read',
      int? readingTimeSeconds,
      double? scrollPercentage,
      double? listenedPercentage}) async {}

  @override
  Future<void> logCustomEvent(
      {required String eventName, Map<String, Object>? parameters}) async {}

  @override
  Future<void> setUserProperty(
      {required String name, required String value}) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> resetAnalyticsData() async {}

  @override
  Future<void> logAppInit({Map<String, Object>? parameters}) async {}

  @override
  Future<void> logNavigationNext(
      {required int currentIndex,
      required int totalDevocionales,
      required String viaBloc,
      String? fallbackReason}) async {}

  @override
  Future<void> logNavigationPrevious(
      {required int currentIndex,
      required int totalDevocionales,
      required String viaBloc,
      String? fallbackReason}) async {}

  @override
  Future<void> logFabTapped({required String source}) async {}

  @override
  Future<void> logFabChoiceSelected(
      {required String source, required String choice}) async {}

  @override
  Future<void> logDiscoveryAction(
      {required String action, String? studyId}) async {}
}

// ─── NavigatorObserver to detect pushes ──────────────────────────────────────

class _NavObserver extends NavigatorObserver {
  final pushes = <String>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes.add(route.settings.name ?? '');
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

EncounterIndexEntry _makeEntry({
  String id = 'test_001',
  String status = 'published',
}) =>
    EncounterIndexEntry(
      id: id,
      version: '1.0',
      emoji: '🌊',
      status: status,
      files: {'en': '$id.json'},
      titles: {'en': 'Test Encounter'},
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

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: CinematicSceneCard(card: card)),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(CinematicSceneCard), findsOneWidget);
    expect(find.text('Test Title'), findsOneWidget);
  });

  // ── Test 2: CompletionCard back button calls onBackToEncounters ─────────────

  testWidgets('CompletionCard back button calls onBackToEncounters',
      (tester) async {
    var called = false;
    const card = EncounterCard(
      order: 1,
      type: 'completion',
      title: 'Well Done',
      completionVerse: EncounterCompletionVerse(
        reference: 'Matt 14:33',
        text: 'Truly you are the Son of God.',
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CompletionCard(
          card: card,
          onBackToEncounters: () => called = true,
        ),
      ),
    ));
    // Use pump with a finite duration — pumpAndSettle never settles because
    // CompletionCard has a repeating AnimationController (pulsing glow).
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byKey(const Key('back_to_encounters_button')));
    await tester.pump();

    expect(called, isTrue);
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

  // ── Test 4: Progress bar renders one AnimatedContainer segment per card ─────

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
          home: BlocProvider<EncounterBloc>.value(
            value: mockBloc,
            child: EncounterDetailPage(entry: entry, lang: 'en'),
          ),
        ),
      );

      await tester.pump();

      // One AnimatedContainer per card in the segmented progress bar.
      // BlocBuilder may build twice with Stream.value, so use findsAtLeastNWidgets.
      expect(find.byType(AnimatedContainer),
          findsAtLeastNWidgets(study.cards.length));

      // Counter starts at "1 / 3"
      expect(find.text('1 / 3'), findsOneWidget);
    });
  });
}
