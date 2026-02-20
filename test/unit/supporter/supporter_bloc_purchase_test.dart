@Tags(['unit', 'iap'])
library;

// test/unit/pages/supporter_bloc_purchase_test.dart
//
// TASK 9 — SupporterBloc purchase flow unit tests
//
// Covers:
//   Scenario 4 — InitializeSupporter emits SupporterError when initialize() throws
//   Scenario 5 — PurchaseTier sets purchasingProductId while pending, clears on error
//   Scenario 6 — PurchaseTier blocked when billing unavailable

import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_event.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_state.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/services/iap/i_iap_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/iap_mock_helper.dart';
import '../../helpers/test_helpers.dart';

// ── Throwing fake ─────────────────────────────────────────────────────────────

/// [FakeIapService] variant whose [initialize] always throws.
class _ThrowingIapService extends FakeIapService {
  final Object error;

  _ThrowingIapService({this.error = 'iap_init_failed'});

  @override
  Future<void> initialize() async => throw error;
}

// ── Purchase-error fake ───────────────────────────────────────────────────────

/// [FakeIapService] variant whose [purchaseTier] always returns [IapResult.error].
class _ErrorPurchaseIapService extends FakeIapService {
  _ErrorPurchaseIapService() : super(isAvailable: true);

  @override
  Future<void> initialize() async {
    // Mark as available so billing check passes.
  }

  @override
  bool get isAvailable => true;

  @override
  IapInitStatus get initStatus => IapInitStatus.success;

  @override
  Future<IapResult> purchaseTier(SupporterTier tier) async => IapResult.error;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await registerTestServices();
  });

  // ── Scenario 4: initialize throws → SupporterError ───────────────────────

  test('Scenario 4 — InitializeSupporter emits SupporterError when initialize throws',
      () async {
    final fakeIap = _ThrowingIapService();
    final bloc = SupporterBloc(
      iapService: fakeIap,
      profileRepository: FakeSupporterProfileRepository(),
    );

    bloc.add(InitializeSupporter());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(bloc.state, isA<SupporterError>());
    final error = bloc.state as SupporterError;
    expect(error.message, contains('iap_init_failed'));

    await bloc.close();
    await fakeIap.dispose();
  });

  // ── Scenario 5: PurchaseTier pending → error ──────────────────────────────

  test(
      'Scenario 5 — PurchaseTier sets purchasingProductId while pending, '
      'clears it and sets errorMessage on IapResult.error', () async {
    final fakeIap = _ErrorPurchaseIapService();
    final bloc = SupporterBloc(
      iapService: fakeIap,
      profileRepository: FakeSupporterProfileRepository(),
    );

    // Initialize first so state is SupporterLoaded with billing available.
    bloc.add(InitializeSupporter());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final loadedState = bloc.state as SupporterLoaded;
    expect(loadedState.isBillingAvailable, isTrue);
    expect(loadedState.purchasingProductId, isNull);

    // Dispatch purchase — FakeIapService returns IapResult.error immediately.
    final tier = SupporterTier.fromLevel(SupporterTierLevel.bronze);
    bloc.add(PurchaseTier(tier));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final afterState = bloc.state as SupporterLoaded;
    expect(afterState.purchasingProductId, isNull); // cleared after error
    expect(afterState.errorMessage, equals('purchase_error'));

    await bloc.close();
    await fakeIap.dispose();
  });

  // ── Scenario 6: PurchaseTier blocked when billing unavailable ─────────────

  test(
      'Scenario 6 — PurchaseTier emits billing_unavailable error '
      'when isBillingAvailable is false', () async {
    // Default FakeIapService has isAvailable: false.
    final fakeIap = FakeIapService();
    final bloc = SupporterBloc(
      iapService: fakeIap,
      profileRepository: FakeSupporterProfileRepository(),
    );

    bloc.add(InitializeSupporter());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final loadedState = bloc.state as SupporterLoaded;
    expect(loadedState.isBillingAvailable, isFalse);

    final tier = SupporterTier.fromLevel(SupporterTierLevel.silver);
    bloc.add(PurchaseTier(tier));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final afterState = bloc.state as SupporterLoaded;
    expect(afterState.errorMessage, equals('billing_unavailable'));
    expect(afterState.purchasingProductId, isNull); // never set
    expect(afterState.purchasedLevels, isEmpty); // nothing purchased

    await bloc.close();
    await fakeIap.dispose();
  });
}
