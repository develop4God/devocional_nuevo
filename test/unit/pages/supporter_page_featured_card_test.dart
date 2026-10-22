@Tags(['unit', 'widgets', 'iap', 'supporter'])
library;

// The support page leads with the "open all encounters" offer instead of
// burying it as the last card of the tier list.

import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_event.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/pages/supporter_page.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/widgets/supporter/featured_tier_card.dart';
import 'package:devocional_nuevo/widgets/supporter/tier_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/iap_mock_helper.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/widget_pump_helper.dart';

// The page reads a loaded theme; the plain ThemeBloc() starts uninitialised.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeIapService iap;
  late SupporterBloc bloc;

  setUp(() async {
    await registerTestServicesWithFakes();
    SharedPreferences.setMockInitialValues({});
    iap = FakeIapService(isAvailable: true, autoDeliver: true);
    bloc = SupporterBloc(
      iapService: iap,
      profileRepository: FakeSupporterProfileRepository(),
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
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
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
  }

  testWidgets('the encounters offer is featured once, above the tier list', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.byType(FeaturedTierCard), findsOneWidget);
    // Bronze, Silver and Gold stay in the list; encounters is not repeated.
    expect(find.byType(TierCard), findsNWidgets(3));
    final featuredTop = tester.getTopLeft(find.byType(FeaturedTierCard)).dy;
    final firstTierTop = tester.getTopLeft(find.byType(TierCard).first).dy;
    expect(featuredTop, lessThan(firstTierTop));

    await unmount(tester);
  });

  testWidgets('buying from the featured card unlocks all encounters', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('featured_tier_buy')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(seconds: 1));

    expect(iap.isPurchased(SupporterTierLevel.encounters), isTrue);
    final state = bloc.state;
    expect(state, isA<SupporterLoaded>());
    expect((state as SupporterLoaded).unlocksAllEncounters, isTrue);
    expect(find.text('supporter.encounters_success_title'), findsOneWidget);

    await unmount(tester);
  });
}
