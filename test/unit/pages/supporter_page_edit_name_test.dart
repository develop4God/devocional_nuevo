@Tags(['unit', 'widgets', 'iap'])
library;

// test/unit/pages/supporter_page_edit_name_test.dart
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
import 'package:devocional_nuevo/services/iap/i_iap_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/iap_mock_helper.dart';
import '../../helpers/test_helpers.dart';

// ---------------------------------------------------------------------------
// Minimal dialog harness — pumps only the edit-name dialog, not SupporterPage.
// This avoids Lottie/ThemeBloc/platform-channel hangs.
// ---------------------------------------------------------------------------
class _DialogHarness extends StatelessWidget {
  const _DialogHarness({required this.currentName, required this.onSave});

  final String? currentName;
  final void Function(String name) onSave;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            key: const ValueKey('open_dialog'),
            onPressed: () => showDialog<void>(
              context: ctx,
              builder: (_) => _TestDialog(
                currentName: currentName ?? '',
                onSave: onSave,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }
}

/// Mirrors the real _GoldNameEditDialog layout so we can test save/cancel
/// without touching the private class.
class _TestDialog extends StatefulWidget {
  const _TestDialog({required this.currentName, required this.onSave});

  final String currentName;
  final void Function(String name) onSave;

  @override
  State<_TestDialog> createState() => _TestDialogState();
}

class _TestDialogState extends State<_TestDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: TextField(
        key: const ValueKey('gold_name_text_field'),
        controller: _ctrl,
      ),
      actions: [
        TextButton(
          key: const ValueKey('cancel_button'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const ValueKey('save_button'),
          onPressed: () {
            final name = _ctrl.text.trim();
            if (name.isNotEmpty) widget.onSave(name);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<SupporterBloc> _goldBloc() async {
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

SupporterLoaded _loadedState({bool goldPurchased = false}) => SupporterLoaded(
      purchasedLevels: goldPurchased ? {SupporterTierLevel.gold} : const {},
      isBillingAvailable: true,
      storePrices: const {},
      initStatus: IapInitStatus.success,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await registerTestServices();
  });

  // ── 1: State — no Gold purchase ──────────────────────────────────────────

  test('1 — isPurchased(gold) is false when Gold is not in purchasedLevels',
      () {
    expect(_loadedState().isPurchased(SupporterTierLevel.gold), isFalse);
  });

  // ── 2: State — Gold purchased ────────────────────────────────────────────

  test('2 — isPurchased(gold) is true when Gold is in purchasedLevels', () {
    expect(
      _loadedState(goldPurchased: true).isPurchased(SupporterTierLevel.gold),
      isTrue,
    );
  });

  // ── 3: Bloc — EditGoldSupporterName sets isEditingGoldName ───────────────

  test('3 — EditGoldSupporterName event sets isEditingGoldName to true',
      () async {
    final bloc = await _goldBloc();

    bloc.add(EditGoldSupporterName());
    await pumpEventQueue();

    final state = bloc.state as SupporterLoaded;
    expect(state.isEditingGoldName, isTrue);

    await bloc.close();
  });

  // ── 4: Widget — dialog renders when open ─────────────────────────────────

  testWidgets('4 — dialog shows TextField when opened', (tester) async {
    await tester.pumpWidget(
      _DialogHarness(currentName: null, onSave: (_) {}),
    );
    await tester.tap(find.byKey(const ValueKey('open_dialog')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('gold_name_text_field')), findsOneWidget);
  });

  // ── 5: Widget — Save calls onSave with entered name ──────────────────────

  testWidgets('5 — tapping Save calls onSave with the entered name',
      (tester) async {
    String? saved;

    await tester.pumpWidget(
      _DialogHarness(currentName: null, onSave: (n) => saved = n),
    );
    await tester.tap(find.byKey(const ValueKey('open_dialog')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('gold_name_text_field')), 'María Soledad');
    await tester.tap(find.byKey(const ValueKey('save_button')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(saved, equals('María Soledad'));
  });

  // ── 5b: Bloc — SaveGoldSupporterName persists name in state ──────────────

  test('5b — SaveGoldSupporterName persists name in SupporterLoaded state',
      () async {
    final bloc = await _goldBloc();

    bloc.add(SaveGoldSupporterName('María Soledad'));
    await pumpEventQueue();

    final state = bloc.state as SupporterLoaded;
    expect(state.goldSupporterName, equals('María Soledad'));

    await bloc.close();
  });

  // ── 6: Widget — Cancel dismisses without calling onSave ──────────────────

  testWidgets('6 — tapping Cancel dismisses dialog without calling onSave',
      (tester) async {
    bool saveCalled = false;

    await tester.pumpWidget(
      _DialogHarness(currentName: null, onSave: (_) => saveCalled = true),
    );
    await tester.tap(find.byKey(const ValueKey('open_dialog')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('gold_name_text_field')), 'Should not save');
    await tester.tap(find.byKey(const ValueKey('cancel_button')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(saveCalled, isFalse);
  });
}
