@Tags(['unit', 'widgets'])
library;

// Behavioral tests for the "open all encounters" supporter option:
//  - EncounterLoaded.isUnlocked honours allUnlocked
//  - tapping a waiting encounter opens the offer (never blocks free reading)
//  - buying from the offer closes it and opens every encounter

import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/pages/encounters/encounters_list_page.dart';
import 'package:devocional_nuevo/pages/supporter_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/i_analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/encounter/encounter_unlock_offer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/iap_mock_helper.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/widget_pump_helper.dart';

class _FakeEncounterBloc extends Fake implements EncounterBloc {
  final EncounterState _s;

  _FakeEncounterBloc(this._s);

  @override
  Stream<EncounterState> get stream => Stream.value(_s);

  @override
  EncounterState get state => _s;

  @override
  void add(EncounterEvent event) {}

  @override
  Future<void> close() async {}
}

class _FakeThemeBloc extends Fake implements ThemeBloc {
  final ThemeState _s = ThemeLoaded(
    themeFamily: 'Deep Purple',
    brightness: Brightness.light,
    themeData: ThemeData.light(),
  );

  @override
  Stream<ThemeState> get stream => Stream.value(_s);

  @override
  ThemeState get state => _s;

  @override
  Future<void> close() async {}
}

class _RecordingAnalytics extends FakeAnalyticsService {
  int offerShown = 0;
  int purchaseTapped = 0;

  @override
  Future<void> logEncounterUnlockOfferShown() async => offerShown++;

  @override
  Future<void> logEncounterUnlockOfferPurchaseTapped() async =>
      purchaseTapped++;
}

EncounterIndexEntry _entry(String id) => EncounterIndexEntry(
      id: id,
      version: '1.0',
      emoji: '🌊',
      status: 'published',
      files: {'en': '$id.json'},
      titles: {'en': 'Title $id'},
      subtitles: {'en': 'Subtitle $id'},
      scriptureReference: {'en': 'John 1:1'},
      estimatedReadingMinutes: {'en': 5},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EncounterLoaded.isUnlocked', () {
    final state =
        EncounterLoaded(index: [_entry('a'), _entry('b'), _entry('c')]);

    test('keeps the sequential rule by default', () {
      expect(state.isUnlocked('a'), isTrue);
      expect(state.isUnlocked('b'), isFalse);
      expect(state.isUnlocked('c'), isFalse);
    });

    test('opens every encounter when allUnlocked is true', () {
      expect(state.isUnlocked('b', allUnlocked: true), isTrue);
      expect(state.isUnlocked('c', allUnlocked: true), isTrue);
    });

    test('completing the previous one still unlocks the next for free', () {
      final done = state.copyWith(completedIds: {'a'});
      expect(done.isUnlocked('b'), isTrue);
      expect(done.isUnlocked('c'), isFalse);
    });
  });

  group('Unlock offer on the encounters list', () {
    late FakeIapService iap;
    late SupporterBloc supporterBloc;
    late _RecordingAnalytics analytics;

    setUp(() async {
      await registerTestServicesWithFakes();
      // Welcome already seen, otherwise it is pushed over the list page.
      // (Set after the helper, which resets the mock prefs.)
      SharedPreferences.setMockInitialValues({'encounter_welcome_seen': true});
      analytics = _RecordingAnalytics();
      final locator = ServiceLocator();
      if (locator.isRegistered<IAnalyticsService>()) {
        locator.unregister<IAnalyticsService>();
      }
      locator.registerSingleton<IAnalyticsService>(analytics);

      iap = FakeIapService(isAvailable: true, autoDeliver: true);
      supporterBloc = SupporterBloc(
        iapService: iap,
        profileRepository: FakeSupporterProfileRepository(),
      );
    });

    tearDown(() async {
      await supporterBloc.close();
    });

    Future<void> pumpList(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<EncounterBloc>.value(
                value: _FakeEncounterBloc(
                  EncounterLoaded(index: [_entry('a'), _entry('b')]),
                ),
              ),
              BlocProvider<ThemeBloc>.value(value: _FakeThemeBloc()),
              BlocProvider<SupporterBloc>.value(value: supporterBloc),
              ChangeNotifierProvider(create: (_) => DevocionalProvider()),
            ],
            child: const EncountersListPage(),
          ),
        ),
      );
      await tester.pump();
    }

    // Unmount and let pending timers (provider/animations) elapse.
    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));
    }

    testWidgets('waiting encounter shows a soft hint and opens the offer', (
      tester,
    ) async {
      supporterBloc.add(InitializeSupporter());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await pumpList(tester);

      expect(find.text('encounters.read_now_hint'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('encounter_locked_b')));
      await tester.pumpAndSettle();

      expect(find.byType(EncounterUnlockOfferSheet), findsOneWidget);
      expect(find.text('encounters.unlock_offer_title'), findsOneWidget);
      expect(analytics.offerShown, 1);

      await unmount(tester);
    });

    testWidgets('"keep reading in order" closes the offer without buying', (
      tester,
    ) async {
      supporterBloc.add(InitializeSupporter());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await pumpList(tester);

      await tester.tap(find.byKey(const ValueKey('encounter_locked_b')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('encounter_unlock_offer_dismiss')));
      await tester.pumpAndSettle();

      expect(find.byType(EncounterUnlockOfferSheet), findsNothing);
      expect(iap.isPurchased(SupporterTierLevel.encounters), isFalse);
      expect(find.byKey(const ValueKey('encounter_locked_b')), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('buying closes the offer and opens every encounter', (
      tester,
    ) async {
      supporterBloc.add(InitializeSupporter());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await pumpList(tester);

      await tester.tap(find.byKey(const ValueKey('encounter_locked_b')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('encounter_unlock_offer_buy')));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(analytics.purchaseTapped, 1);
      expect(iap.isPurchased(SupporterTierLevel.encounters), isTrue);
      expect(find.byType(EncounterUnlockOfferSheet), findsNothing);
      // The lock overlay is gone: the second encounter is now readable.
      expect(find.byKey(const ValueKey('encounter_locked_b')), findsNothing);

      await unmount(tester);
    });

    testWidgets('a store error leaves encounters locked and the offer usable', (
      tester,
    ) async {
      iap.purchaseShouldSucceed = false;
      supporterBloc.add(InitializeSupporter());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await pumpList(tester);

      await tester.tap(find.byKey(const ValueKey('encounter_locked_b')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('encounter_unlock_offer_buy')));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(iap.isPurchased(SupporterTierLevel.encounters), isFalse);
      expect(find.byKey(const ValueKey('encounter_locked_b')), findsOneWidget);

      await unmount(tester);
    });
  });

  group('Buying the encounters option from the Supporter page', () {
    testWidgets('shows a thank-you dialog and unlocks (no badge lookup)', (
      tester,
    ) async {
      await registerTestServicesWithFakes();
      SharedPreferences.setMockInitialValues({});
      final iap = FakeIapService(isAvailable: true, autoDeliver: true);
      final bloc = SupporterBloc(
        iapService: iap,
        profileRepository: FakeSupporterProfileRepository(),
      );
      addTearDown(bloc.close);

      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bloc.add(InitializeSupporter());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));

      await tester.pumpWidget(
        MaterialApp(
          home: DefaultAssetBundle(
            bundle: TestAssetBundle(),
            child: MultiBlocProvider(
              providers: [
                BlocProvider<SupporterBloc>.value(value: bloc),
                BlocProvider<ThemeBloc>.value(value: _FakeThemeBloc()),
              ],
              child: const SupporterPage(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      bloc.add(
        PurchaseTier(SupporterTier.fromLevel(SupporterTierLevel.encounters)),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(seconds: 1));

      expect(iap.isPurchased(SupporterTierLevel.encounters), isTrue);
      expect(find.text('supporter.encounters_success_title'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));
    });
  });
}
