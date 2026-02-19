@Tags(['unit', 'widgets', 'iap'])
library;

// test/unit/pages/supporter_page_edit_name_test.dart
//
// Task 5 — Widget tests for the Gold supporter edit-name flow.
//
// Coverage:
//   1. "Edit name" button is NOT visible when Gold is NOT purchased.
//   2. "Edit name" / "Set display name" button IS visible when Gold IS purchased.
//   3. Tapping the button dispatches EditGoldSupporterName to the BLoC.
//   4. Dialog opens when isEditingGoldName == true in state.
//   5. Entering a name and tapping Save dispatches SaveGoldSupporterName.
//   6. Tapping Cancel dismisses without dispatching SaveGoldSupporterName.

import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_event.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_state.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/iap_mock_helper.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/widget_pump_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await registerTestServices();
  });

  // ── helpers ───────────────────────────────────────────────────────────────

  /// Creates a SupporterBloc in SupporterLoaded state with Gold purchased.
  Future<SupporterBloc> goldPurchasedBloc() async {
    final fakeIap = FakeIapService(isAvailable: true);
    await fakeIap.deliver(SupporterTier.fromLevel(SupporterTierLevel.gold));
    final bloc = SupporterBloc(
      iapService: fakeIap,
      profileRepository: FakeSupporterProfileRepository(),
    );
    bloc.add(InitializeSupporter());
    await pumpEventQueue();
    return bloc;
  }

  /// Creates a SupporterBloc in SupporterLoaded with NO purchases.
  SupporterBloc noPurchasesBloc() {
    final fakeIap = FakeIapService();
    return SupporterBloc(
      iapService: fakeIap,
      profileRepository: FakeSupporterProfileRepository(),
    );
  }

  // ── Test 1: button hidden when Gold NOT purchased ─────────────────────────

  testWidgets('1 — edit-name button is NOT shown when Gold is not purchased',
      (tester) async {
    final bloc = noPurchasesBloc();
    bloc.add(InitializeSupporter());
    await pumpEventQueue();

    await pumpSupporterPage(tester, bloc);
    await tester.pump();

    // Use the stable key added to the button — absent when Gold not purchased.
    expect(find.byKey(const ValueKey('gold_edit_name_button')), findsNothing);

    await bloc.close();
  });

  // ── Test 2: button visible when Gold IS purchased ─────────────────────────

  testWidgets('2 — edit-name button IS shown when Gold is purchased',
      (tester) async {
    final bloc = await goldPurchasedBloc();

    await pumpSupporterPage(tester, bloc);
    await tester.pump();

    // Button is rendered with a stable key when Gold is purchased.
    expect(
      find.byKey(const ValueKey('gold_edit_name_button')),
      findsOneWidget,
    );

    await bloc.close();
  });

  // ── Test 3: tapping button dispatches EditGoldSupporterName ──────────────

  testWidgets(
      '3 — tapping the edit-name button dispatches EditGoldSupporterName',
      (tester) async {
    final fakeIap2 = FakeIapService(isAvailable: true);
    await fakeIap2.deliver(SupporterTier.fromLevel(SupporterTierLevel.gold));
    final spyBloc = SupporterBloc(
      iapService: fakeIap2,
      profileRepository: FakeSupporterProfileRepository(),
    );
    spyBloc.add(InitializeSupporter());
    await pumpEventQueue();

    await pumpSupporterPage(tester, spyBloc);
    await tester.pump();

    // Tap the edit button via stable key
    final editButton = find.byKey(const ValueKey('gold_edit_name_button'));
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pump();

    // After tap the bloc state should have isEditingGoldName == true
    final state = spyBloc.state;
    expect(state, isA<SupporterLoaded>());
    expect((state as SupporterLoaded).isEditingGoldName, isTrue);

    await spyBloc.close();
    await fakeIap2.dispose();
  });

  // ── Test 4: dialog opens when isEditingGoldName is true ──────────────────

  testWidgets('4 — dialog opens when isEditingGoldName == true in state',
      (tester) async {
    final bloc = await goldPurchasedBloc();

    await pumpSupporterPage(tester, bloc);
    await tester.pump();

    // Tap edit button via stable key to trigger EditGoldSupporterName event
    await tester.tap(find.byKey(const ValueKey('gold_edit_name_button')));
    await tester.pumpAndSettle();

    // Dialog should be visible — look for the TextField inside it
    expect(find.byType(TextField), findsOneWidget);

    await bloc.close();
  });

  // ── Test 5: Save dispatches SaveGoldSupporterName ─────────────────────────

  testWidgets(
      '5 — entering name and tapping Save dispatches SaveGoldSupporterName',
      (tester) async {
    final fakeRepo = FakeSupporterProfileRepository();
    final fakeIap = FakeIapService(isAvailable: true);
    await fakeIap.deliver(SupporterTier.fromLevel(SupporterTierLevel.gold));
    final bloc = SupporterBloc(
      iapService: fakeIap,
      profileRepository: fakeRepo,
    );
    bloc.add(InitializeSupporter());
    await pumpEventQueue();

    await pumpSupporterPage(tester, bloc);
    await tester.pump();

    // Open dialog via stable key
    await tester.tap(find.byKey(const ValueKey('gold_edit_name_button')));
    await tester.pumpAndSettle();

    // Enter name
    await tester.enterText(find.byType(TextField), 'María Soledad');
    await tester.pump();

    // Tap Save
    await tester.tap(find.text('app.save'.tr()));
    await tester.pumpAndSettle();

    // Dialog should be gone
    expect(find.byType(TextField), findsNothing);

    // Name should be persisted in repository
    expect(await fakeRepo.loadGoldSupporterName(), equals('María Soledad'));

    // BLoC state should reflect the saved name
    final state = bloc.state as SupporterLoaded;
    expect(state.goldSupporterName, equals('María Soledad'));

    await bloc.close();
    await fakeIap.dispose();
  });

  // ── Test 6: Cancel dismisses without saving ────────────────────────────────

  testWidgets('6 — tapping Cancel dismisses dialog without saving',
      (tester) async {
    final fakeRepo = FakeSupporterProfileRepository();
    final fakeIap = FakeIapService(isAvailable: true);
    await fakeIap.deliver(SupporterTier.fromLevel(SupporterTierLevel.gold));
    final bloc = SupporterBloc(
      iapService: fakeIap,
      profileRepository: fakeRepo,
    );
    bloc.add(InitializeSupporter());
    await pumpEventQueue();

    await pumpSupporterPage(tester, bloc);
    await tester.pump();

    // Open dialog via stable key
    await tester.tap(find.byKey(const ValueKey('gold_edit_name_button')));
    await tester.pumpAndSettle();

    // Type but then cancel
    await tester.enterText(find.byType(TextField), 'Should not be saved');
    await tester.tap(find.text('app.cancel'.tr()));
    await tester.pumpAndSettle();

    // Dialog gone
    expect(find.byType(TextField), findsNothing);

    // Name not saved
    expect(await fakeRepo.loadGoldSupporterName(), isNull);

    await bloc.close();
    await fakeIap.dispose();
  });
}

// Convenience tr() stub for test keys that reference i18n strings
extension _TrStub on String {
  String tr() => this; // tests use the key itself as the text
}
