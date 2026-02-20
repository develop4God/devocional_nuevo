@Tags(['unit', 'iap'])
library;

// test/unit/pages/supporter_bloc_test.dart
//
// TASK 9 — SupporterBloc unit tests
//

import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_event.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_state.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/services/iap/i_iap_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/iap_mock_helper.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await registerTestServices();
  });

  // ── Scenario 1: initial / loading state ──────────────────────────────────

  test('Scenario 1 — SupporterInitial before InitializeSupporter', () {
    final fakeIap = FakeIapService();
    final bloc = SupporterBloc(
      iapService: fakeIap,
      profileRepository: FakeSupporterProfileRepository(),
    );
    expect(bloc.state, isA<SupporterInitial>());
    bloc.close();
  });

  // ── Scenario 2: loaded with no purchases ─────────────────────────────────

  test('Scenario 2 — SupporterLoaded with no purchases after initialize',
      () async {
    final fakeIap = FakeIapService();
    final bloc = SupporterBloc(
      iapService: fakeIap,
      profileRepository: FakeSupporterProfileRepository(),
    );
    bloc.add(InitializeSupporter());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final state = bloc.state as SupporterLoaded;
    expect(state.purchasedLevels, isEmpty);
    expect(state.isBillingAvailable, isFalse);
    expect(state.initStatus, equals(IapInitStatus.billingUnavailable));

    await bloc.close();
    await fakeIap.dispose();
  });

  // ── Scenario 3: loaded with silver purchased ──────────────────────────────

  test('Scenario 3 — SupporterLoaded with silver purchased', () async {
    final fakeIap = FakeIapService();
    // Pre-deliver silver so the bloc picks it up during initialize.
    await fakeIap.deliver(SupporterTier.fromLevel(SupporterTierLevel.silver));

    final bloc = SupporterBloc(
      iapService: fakeIap,
      profileRepository: FakeSupporterProfileRepository(),
    );
    bloc.add(InitializeSupporter());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final state = bloc.state as SupporterLoaded;
    expect(state.isPurchased(SupporterTierLevel.silver), isTrue);
    expect(state.isPurchased(SupporterTierLevel.bronze), isFalse);

    await bloc.close();
    await fakeIap.dispose();
  });

  // ── BlocBuilder wiring: state change updates downstream ──────────────────

  test('BlocBuilder wiring — bronze delivery after initialize updates state',
      () async {
    final fakeIap = FakeIapService();
    final bloc = SupporterBloc(
      iapService: fakeIap,
      profileRepository: FakeSupporterProfileRepository(),
    );
    bloc.add(InitializeSupporter());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect((bloc.state as SupporterLoaded).purchasedLevels, isEmpty);

    // Deliver bronze — BlocBuilder would rebuild in the real widget.
    await fakeIap.deliver(SupporterTier.fromLevel(SupporterTierLevel.bronze));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final state = bloc.state as SupporterLoaded;
    expect(state.isPurchased(SupporterTierLevel.bronze), isTrue);
    expect(state.justDeliveredTier?.level, equals(SupporterTierLevel.bronze));

    await bloc.close();
    await fakeIap.dispose();
  });
}
