@Tags(['unit', 'widgets'])
library;

// test/unit/widgets/supporter_gold_purchase_dialog_test.dart

import 'dart:convert';

import 'package:devocional_nuevo/models/supporter_pet.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/supporter_pet_service.dart';
import 'package:devocional_nuevo/widgets/supporter/supporter_gold_purchase_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

const _emptyLottieJson =
    '{"v":"5.5.7","fr":30,"ip":0,"op":2,"w":1,"h":1,"layers":[]}';

class _TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('.json')) {
      final bytes = utf8.encode(_emptyLottieJson);
      return ByteData.view(Uint8List.fromList(bytes).buffer);
    }
    return rootBundle.load(key);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key.endsWith('.json')) return _emptyLottieJson;
    return rootBundle.loadString(key, cache: cache);
  }
}

/// Drives the real user-facing gold purchase flow: name -> pet -> confirmation.
/// SupporterPetService is the real DI-registered instance backed by mocked
/// SharedPreferences, so assertions check actual persisted state.
///
/// The dialog is opened via showDialog (a real route) so PopScope's back
/// handler behaves as it does in production. Fade transitions use bounded
/// tester.pump(duration) instead of pumpAndSettle, which never settles due
/// to the dialog's non-repeating Lottie tickers.
void main() {
  late TextEditingController nameController;
  late bool onConfirmCalled;

  setUp(() async {
    await registerTestServices();
    nameController = TextEditingController();
    onConfirmCalled = false;
  });

  Future<void> pumpDialog(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => DefaultAssetBundle(
            bundle: _TestAssetBundle(),
            child: Scaffold(
              body: Center(
                child: OutlinedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (dialogContext) => SupporterGoldPurchaseDialog(
                      tier: SupporterTier.fromLevel(SupporterTierLevel.gold),
                      dialogContext: dialogContext,
                      nameController: nameController,
                      onConfirm: () async {
                        onConfirmCalled = true;
                      },
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('open'));
    await tester.pump();
    // Settle the dialog's entry fade without spinning on Lottie tickers.
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Settles the phase-transition fade (reverse + forward, 450ms each way)
  /// without pumpAndSettle, which never converges due to Lottie tickers.
  Future<void> settlePhaseTransition(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('marks gold setup pending on init', (tester) async {
    await pumpDialog(tester);

    final petService = getService<SupporterPetService>();
    expect(petService.isGoldSetupPending, isTrue);
  });

  testWidgets('name phase renders name field', (tester) async {
    await pumpDialog(tester);

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('tapping Next advances from name phase to pet phase', (
    tester,
  ) async {
    await pumpDialog(tester);

    await tester.tap(find.text('app.next'));
    await settlePhaseTransition(tester);

    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets(
    'selecting a pet calls setSelectedPet, onConfirm, and advances to confirmation',
    (tester) async {
      await pumpDialog(tester);

      await tester.tap(find.text('app.next'));
      await settlePhaseTransition(tester);

      expect(find.byType(GridView), findsOneWidget);

      final firstPetInkWell = find
          .descendant(
            of: find.byType(GridView),
            matching: find.byWidgetPredicate((w) => w is InkWell),
          )
          .first;
      await tester.tap(firstPetInkWell);
      await tester.pump();
      await settlePhaseTransition(tester);

      final petService = getService<SupporterPetService>();
      expect(petService.selectedPet.id, SupporterPet.allPets.first.id);
      expect(onConfirmCalled, isTrue);

      // Confirmation phase shows the "Go to Settings" / "Go to Devotionals" CTAs.
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
      expect(find.byIcon(Icons.home_filled), findsOneWidget);
    },
  );

  /// Triggers the OS back gesture on the current top route, exercising
  /// PopScope's onPopInvokedWithResult the same way a real back-press does.
  Future<void> simulateSystemBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
  }

  testWidgets(
    'leaving name phase shows the "set up later" confirmation sheet',
    (tester) async {
      await pumpDialog(tester);

      await simulateSystemBack(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    },
  );

  testWidgets(
    '"Set up later" in the leave sheet dismisses the whole dialog',
    (tester) async {
      await pumpDialog(tester);

      await simulateSystemBack(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      await tester.tap(find.text('supporter.gold_back_confirm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog and its name field are gone; back on the host page.
      expect(find.byType(TextField), findsNothing);
      expect(find.text('open'), findsOneWidget);
    },
  );
}
