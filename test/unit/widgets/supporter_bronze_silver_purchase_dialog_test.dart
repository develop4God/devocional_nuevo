@Tags(['unit', 'widgets'])
library;

// test/unit/widgets/supporter_bronze_silver_purchase_dialog_test.dart

import 'dart:async';
import 'dart:convert';

import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/widgets/supporter/supporter_bronze_silver_purchase_dialog.dart';
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

/// Drives the real post-purchase confirmation flow for Bronze/Silver tiers:
/// tap primary CTA -> onConfirm runs -> dialog pops -> navigates to progress;
/// tap secondary "Close" -> onConfirm runs -> dialog pops, no navigation.
void main() {
  late bool onConfirmCalled;

  setUp(() async {
    await registerTestServices();
    onConfirmCalled = false;
  });

  Future<void> pumpDialog(WidgetTester tester, SupporterTierLevel level) async {
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
                    builder: (dialogContext) => SupporterPurchaseDialog(
                      tier: SupporterTier.fromLevel(level),
                      dialogContext: dialogContext,
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
    // Settle the entry ScaleTransition (600ms) without spinning on the
    // dialog's non-repeating Lottie confetti ticker.
    await tester.pump(const Duration(milliseconds: 700));
  }

  testWidgets('renders the badge emoji for the given tier', (tester) async {
    await pumpDialog(tester, SupporterTierLevel.bronze);

    final tier = SupporterTier.fromLevel(SupporterTierLevel.bronze);
    expect(find.text(tier.emoji), findsWidgets);
  });

  testWidgets(
    'tapping primary CTA calls onConfirm and closes the dialog',
    (tester) async {
      await pumpDialog(tester, SupporterTierLevel.silver);

      await tester.tap(find.byIcon(Icons.emoji_events_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(onConfirmCalled, isTrue);
      // Dialog closed — back to the host page's "open" button.
      expect(find.text('open'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping Close calls onConfirm and closes the dialog without extra navigation',
    (tester) async {
      await pumpDialog(tester, SupporterTierLevel.bronze);

      await tester.tap(find.text('app.close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(onConfirmCalled, isTrue);
      expect(find.text('open'), findsOneWidget);
    },
  );

  testWidgets(
    'primary CTA shows a loading indicator while onConfirm is pending',
    (tester) async {
      final completer = Completer<void>();
      onConfirmCalled = false;

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
                      builder: (dialogContext) => SupporterPurchaseDialog(
                        tier:
                            SupporterTier.fromLevel(SupporterTierLevel.silver),
                        dialogContext: dialogContext,
                        onConfirm: () => completer.future,
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
      await tester.pump(const Duration(milliseconds: 700));

      await tester.tap(find.byIcon(Icons.emoji_events_outlined));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    },
  );
}
