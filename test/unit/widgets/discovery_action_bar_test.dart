@Tags(['unit', 'widgets'])
library;

// DiscoveryActionBar widget has been removed from production code.
// These tests are updated to exercise the real discovery detail page
// and to avoid importing the removed widget directly.

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/models/discovery_card_model.dart';
import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/pages/discovery_bible_studies/discovery_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  group('DiscoveryActionBar Widget Tests (via DiscoveryDetailPage)', () {
    late PrayerBloc prayerBloc;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      registerTestServices();

      prayerBloc = PrayerBloc();
    });

    tearDown(() async {
      await prayerBloc.close();
    });

    /// Creates a test DiscoveryDevotional with mock cards
    DiscoveryDevotional createTestStudy() {
      final now = DateTime.now();
      return DiscoveryDevotional(
        id: 'dummy-study-id',
        versiculo: 'John 3:16',
        reflexion: 'Test Study Title',
        paraMeditar: [],
        oracion: 'Test Prayer',
        date: now,
        emoji: '✨',
        subtitle: 'Test Subtitle',
        estimatedReadingMinutes: 10,
        cards: [
          DiscoveryCard(
            order: 1,
            type: 'natural_revelation',
            title: 'Natural Revelation',
            content: 'Test content for natural revelation',
            icon: '🌿',
          ),
          DiscoveryCard(
            order: 2,
            type: 'historical_thread',
            title: 'Historical Thread',
            content: 'Test content for historical thread',
            icon: '📜',
          ),
        ],
      );
    }

    Widget createDiscoveryDetailPageUnderTest() {
      // NOTE: We now provide complete BLoC setup with mocked states
      // that include the actual study data needed for the page to render.
      final testStudy = createTestStudy();
      final discoveryBloc = MockDiscoveryBlocWithLoadedStudy(testStudy);
      final themeBloc = MockThemeBlocForTesting();

      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<DiscoveryBloc>.value(value: discoveryBloc),
            BlocProvider<ThemeBloc>.value(value: themeBloc),
            BlocProvider<PrayerBloc>.value(value: prayerBloc),
          ],
          child: const DiscoveryDetailPage(studyId: 'dummy-study-id'),
        ),
      );
    }

    testWidgets(
      'renders discovery detail page without errors',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createDiscoveryDetailPageUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(DiscoveryDetailPage), findsOneWidget);
      },
    );

    testWidgets(
        'displays discovery action controls in real discovery detail page',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createDiscoveryDetailPageUnderTest());
      await tester.pumpAndSettle();

      // The DiscoveryDetailPage displays navigation and completion controls.
      // Check for check_circle_outline_rounded which is the mark-complete button
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsWidgets);

      // Check for arrow_forward_ios_rounded for next navigation
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsWidgets);
    });
  });
}

/// Mock DiscoveryBloc that provides a loaded study with complete data
class MockDiscoveryBlocWithLoadedStudy extends Fake implements DiscoveryBloc {
  final DiscoveryDevotional study;

  MockDiscoveryBlocWithLoadedStudy(this.study);

  @override
  Stream<DiscoveryState> get stream => Stream.value(
        DiscoveryLoaded(
          availableStudyIds: [study.id],
          studyTitles: {study.id: study.reflexion},
          studySubtitles: {study.id: study.subtitle ?? ''},
          studyEmojis: {study.id: study.emoji ?? '✨'},
          studyReadingMinutes: {study.id: study.estimatedReadingMinutes ?? 0},
          completedStudies: {study.id: false},
          favoriteStudyIds: {},
          loadedStudies: {study.id: study},
          languageCode: 'en',
        ),
      );

  @override
  DiscoveryState get state => DiscoveryLoaded(
        availableStudyIds: [study.id],
        studyTitles: {study.id: study.reflexion},
        studySubtitles: {study.id: study.subtitle ?? ''},
        studyEmojis: {study.id: study.emoji ?? '✨'},
        studyReadingMinutes: {study.id: study.estimatedReadingMinutes ?? 0},
        completedStudies: {study.id: false},
        favoriteStudyIds: {},
        loadedStudies: {study.id: study},
        languageCode: 'en',
      );

  @override
  void add(event) {}

  @override
  Future<void> close() async {}
}

/// Mock ThemeBloc for testing with proper theme data
class MockThemeBlocForTesting extends Fake implements ThemeBloc {
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

  @override
  void add(event) {}

  @override
  Future<void> close() async {}
}
