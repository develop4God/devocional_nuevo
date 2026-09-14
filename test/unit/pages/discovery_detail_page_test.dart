@Tags(['unit', 'pages'])
library;

// test/unit/pages/discovery_detail_page_test.dart

import 'dart:async';

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/models/discovery_card_model.dart';
import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/pages/discovery_bible_studies/discovery_detail_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

DiscoveryDevotional _studyWithCards(int cardCount) {
  return DiscoveryDevotional(
    id: 'study_1',
    versiculo: 'verse',
    reflexion: 'Study title',
    paraMeditar: const [],
    oracion: 'prayer',
    date: DateTime(2026),
    language: 'en',
    cards: List.generate(
      cardCount,
      (i) => DiscoveryCard(
        order: i,
        type: 'reflection',
        title: 'Card $i',
        content: 'Content $i',
      ),
    ),
  );
}

DiscoveryLoaded _loadedState(DiscoveryDevotional study) => DiscoveryLoaded(
      availableStudyIds: [study.id],
      loadedStudies: {study.id: study},
      studyTitles: {study.id: study.reflexion},
      studySubtitles: {},
      studyEmojis: {},
      studyReadingMinutes: {},
      completedStudies: {},
      favoriteStudyIds: {},
      languageCode: 'en',
    );

/// A DiscoveryBloc fake whose state/stream can be pushed to after the page
/// is mounted, simulating a background re-fetch (e.g. LoadDiscoveryStudy
/// retry or a locale refresh) that swaps in a study with a different card
/// count while DiscoveryDetailPage stays on screen.
class SwappableDiscoveryBloc extends Fake implements DiscoveryBloc {
  SwappableDiscoveryBloc(DiscoveryState initial)
      : _state = initial,
        _controller = StreamController<DiscoveryState>.broadcast() {
    _controller.add(initial);
  }

  DiscoveryState _state;
  final StreamController<DiscoveryState> _controller;

  @override
  DiscoveryState get state => _state;

  @override
  Stream<DiscoveryState> get stream => _controller.stream;

  void pushState(DiscoveryState next) {
    _state = next;
    _controller.add(next);
  }

  @override
  void add(DiscoveryEvent event) {}

  @override
  Future<void> close() async {
    await _controller.close();
  }
}

class TestAnalyticsService extends AnalyticsService {
  TestAnalyticsService() : super(analytics: null);

  @override
  Future<void> logDiscoveryAction({
    required String action,
    String? studyId,
  }) async {
    // no-op in tests
    return;
  }
}

class TestThemeBloc extends Fake implements ThemeBloc {
  @override
  Stream<ThemeState> get stream => Stream.value(
        ThemeLoaded(
          themeFamily: 'Deep Purple',
          themeData: ThemeData.light(),
          brightness: Brightness.light,
        ),
      );

  @override
  ThemeState get state => ThemeLoaded(
        themeFamily: 'Deep Purple',
        themeData: ThemeData.light(),
        brightness: Brightness.light,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_crashlytics'),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
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
      (call) async => null,
    );

    await setupServiceLocator();
    ServiceLocator().registerSingleton<AnalyticsService>(
      TestAnalyticsService(),
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'survives the loaded study being swapped for one with fewer cards '
    'while the detail page is mounted',
    (WidgetTester tester) async {
      final study10Cards = _studyWithCards(10);
      final study2Cards = _studyWithCards(2);

      final bloc = SwappableDiscoveryBloc(_loadedState(study10Cards));
      final themeBloc = TestThemeBloc();

      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<DiscoveryBloc>.value(value: bloc),
                BlocProvider<ThemeBloc>.value(value: themeBloc),
                ChangeNotifierProvider(create: (_) => DevocionalProvider()),
              ],
              child: const DiscoveryDetailPage(studyId: 'study_1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DiscoveryDetailPage), findsOneWidget);

        final pageView = tester.widget<PageView>(find.byType(PageView));
        expect(pageView.controller!.page, isNotNull);

        // Move well past the bounds of the smaller study we're about to
        // swap in, so the controller's cached page/offset is meaningfully
        // stale relative to the new itemCount/viewport when the swap lands.
        pageView.controller!.jumpToPage(7);
        await tester.pump();

        // Simulate a background re-fetch swapping in a study with a smaller
        // card count while the page is still mounted.
        bloc.pushState(_loadedState(study2Cards));

        // Before the fix, laying out the PageView/SliverFillViewport against
        // the stale controller here throws
        // "computeMaxScrollOffset() returned a value that is not an even
        // multiple of its itemExtent".
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(DiscoveryDetailPage), findsOneWidget);
      });
    },
  );
}
