@Tags(['unit', 'iap'])
library;

// test/unit/pages/supporter_bloc_restore_test.dart
//
// TASK 9 — SupporterBloc restore purchases unit tests
//
// Covers:
//   Scenario 7 — RestorePurchases sets isRestoring: true, clears it after,
//                and delivered tiers appear in state

import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_event.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_state.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
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

  // ── Scenario 7: RestorePurchases full cycle ───────────────────────────────

  test(
      'Scenario 7 — RestorePurchases sets isRestoring true, '
      'clears it after completion, and delivered tiers appear in state',
      () async {
    final fakeIap = FakeIapService();

    // Pre-load gold so restorePurchases() re-emits it.
    await fakeIap.deliver(SupporterTier.fromLevel(SupporterTierLevel.gold));

    final bloc = SupporterBloc(
      iapService: fakeIap,
      profileRepository: FakeSupporterProfileRepository(),
    );

    bloc.add(InitializeSupporter());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Confirm initialized — gold already delivered before init.
    final initialState = bloc.state as SupporterLoaded;
    expect(initialState.isPurchased(SupporterTierLevel.gold), isTrue);
    expect(initialState.isRestoring, isFalse);

    // Collect states emitted during restore.
    final states = <SupporterLoaded>[];
    final subscription = bloc.stream
        .where((s) => s is SupporterLoaded)
        .map((s) => s as SupporterLoaded)
        .listen(states.add);

    bloc.add(RestorePurchases());
    await Future<void>.delayed(const Duration(milliseconds: 100));

    await subscription.cancel();

    // At least one intermediate state must have isRestoring: true.
    expect(states.any((s) => s.isRestoring), isTrue,
        reason: 'Expected at least one state with isRestoring: true');

    // Final state must have isRestoring cleared.
    final finalState = bloc.state as SupporterLoaded;
    expect(finalState.isRestoring, isFalse);

    // Gold still present after restore.
    expect(finalState.isPurchased(SupporterTierLevel.gold), isTrue);

    await bloc.close();
    await fakeIap.dispose();
  });

  test(
      'Scenario 7b — RestorePurchases ignored when state is not SupporterLoaded',
      () async {
    final fakeIap = FakeIapService();
    final bloc = SupporterBloc(
      iapService: fakeIap,
      profileRepository: FakeSupporterProfileRepository(),
    );

    // State is SupporterInitial — RestorePurchases should be a no-op.
    expect(bloc.state, isA<SupporterInitial>());

    bloc.add(RestorePurchases());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // State must remain SupporterInitial — no crash, no transition.
    expect(bloc.state, isA<SupporterInitial>());

    await bloc.close();
    await fakeIap.dispose();
  });
}
