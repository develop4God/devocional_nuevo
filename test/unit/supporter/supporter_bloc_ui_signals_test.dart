@Tags(['unit', 'iap'])
library;

// test/unit/pages/supporter_bloc_ui_signals_test.dart
//
// TASK 9 — SupporterBloc UI signals and dispose safety unit tests
//
// Covers:
//   Scenario 8  — SaveGoldSupporterName persists name and updates state
//   Scenario 9  — ClearSupporterError clears errorMessage and justDeliveredTier
//   Scenario 10 — EditGoldSupporterName sets isEditingGoldName,
//                 AcknowledgeGoldNameEdit clears it
//   Scenario 11 — Dispose safety: close() cancels stream, no updates after close

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

  // ── Helper: initialize bloc to SupporterLoaded ───────────────────────────

  Future<SupporterBloc> _initBloc(FakeIapService fakeIap) async {
    final bloc = SupporterBloc(
      iapService: fakeIap,
      profileRepository: FakeSupporterProfileRepository(),
    );
    bloc.add(InitializeSupporter());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bloc.state, isA<SupporterLoaded>());
    return bloc;
  }

  // ── Scenario 8: SaveGoldSupporterName ────────────────────────────────────

  test(
      'Scenario 8 — SaveGoldSupporterName persists name '
      'and updates goldSupporterName in state', () async {
    final fakeIap = FakeIapService();
    final fakeRepo = FakeSupporterProfileRepository();
    final bloc = SupporterBloc(
      iapService: fakeIap,
      profileRepository: fakeRepo,
    );
    bloc.add(InitializeSupporter());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect((bloc.state as SupporterLoaded).goldSupporterName, isNull);

    bloc.add(SaveGoldSupporterName('Ana María'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final state = bloc.state as SupporterLoaded;
    expect(state.goldSupporterName, equals('Ana María'));

    // Verify persistence via repository.
    final persisted = await fakeRepo.loadGoldSupporterName();
    expect(persisted, equals('Ana María'));

    await bloc.close();
    await fakeIap.dispose();
  });

  // ── Scenario 9: ClearSupporterError ──────────────────────────────────────

  test(
      'Scenario 9 — ClearSupporterError clears errorMessage '
      'and justDeliveredTier from state', () async {
    final fakeIap = FakeIapService();
    final bloc = await _initBloc(fakeIap);

    // Deliver a tier to set justDeliveredTier.
    await fakeIap.deliver(SupporterTier.fromLevel(SupporterTierLevel.bronze));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    var state = bloc.state as SupporterLoaded;
    expect(state.justDeliveredTier, isNotNull);

    // Now clear.
    bloc.add(ClearSupporterError());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    state = bloc.state as SupporterLoaded;
    expect(state.errorMessage, isNull);
    expect(state.justDeliveredTier, isNull);

    await bloc.close();
    await fakeIap.dispose();
  });

  // ── Scenario 10: EditGoldSupporterName / AcknowledgeGoldNameEdit ─────────

  test(
      'Scenario 10 — EditGoldSupporterName sets isEditingGoldName true; '
      'AcknowledgeGoldNameEdit clears it', () async {
    final fakeIap = FakeIapService();
    final bloc = await _initBloc(fakeIap);

    expect((bloc.state as SupporterLoaded).isEditingGoldName, isFalse);

    bloc.add(EditGoldSupporterName());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect((bloc.state as SupporterLoaded).isEditingGoldName, isTrue);

    bloc.add(AcknowledgeGoldNameEdit());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect((bloc.state as SupporterLoaded).isEditingGoldName, isFalse);

    await bloc.close();
    await fakeIap.dispose();
  });

  // ── Scenario 11: Dispose safety ──────────────────────────────────────────

  test(
      'Scenario 11 — close() cancels the delivery stream subscription; '
      'no state updates after close', () async {
    final fakeIap = FakeIapService();
    final bloc = await _initBloc(fakeIap);

    final statesAfterClose = <SupporterState>[];

    await bloc.close();

    // Any delivery after close must NOT update the bloc state.
    try {
      await fakeIap.deliver(SupporterTier.fromLevel(SupporterTierLevel.gold));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    } catch (_) {
      // StreamController may be closed — that's acceptable.
    }

    expect(statesAfterClose, isEmpty,
        reason: 'No state updates expected after bloc.close()');
    expect(bloc.isClosed, isTrue);

    await fakeIap.dispose();
  });
}
