@Tags(['unit', 'widgets', 'supporter'])
library;

// FeaturedTierCard: the highlighted offer shown at the top of the support
// page. Pure presentation: it only reports taps through onPurchase.

import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/widgets/gold_shimmer.dart';
import 'package:devocional_nuevo/widgets/supporter/featured_tier_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

import '../../helpers/test_helpers.dart';

final _encounters = SupporterTier.fromLevel(SupporterTierLevel.encounters);

Future<void> _pump(
  WidgetTester tester, {
  SupporterTier? tier,
  bool isPurchased = false,
  bool isLoading = false,
  String? lottieAsset = 'assets/lottie/unlocked.json',
  VoidCallback? onPurchase,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: FeaturedTierCard(
            tier: tier ?? _encounters,
            storePrice: r'$4.99',
            isPurchased: isPurchased,
            isLoading: isLoading,
            lottieAsset: lottieAsset,
            onPurchase: onPurchase,
          ),
        ),
      ),
    ),
  );
  // The shimmer loops forever: pump a frame instead of pumpAndSettle.
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await registerTestServicesWithFakes();
  });

  group('FeaturedTierCard (not purchased)', () {
    testWidgets('shows a Lottie icon, the name and a centered benefit', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('supporter.tier_encounters_name'), findsOneWidget);
      expect(find.byType(Lottie), findsOneWidget);
      expect(find.text(_encounters.emoji), findsNothing);
      // The marketing sentence is the benefit, centered and without a check.
      final benefit = tester.widget<Text>(
        find.text('supporter.benefit_encounters_unlock'),
      );
      expect(benefit.textAlign, TextAlign.center);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      // The "at your own pace" description is gone from the card.
      expect(
        find.text('supporter.tier_encounters_description'),
        findsNothing,
      );
    });

    testWidgets('has a shimmering border and button', (tester) async {
      await _pump(tester);

      // One shimmer on the border ring, one on the buy button.
      expect(find.byType(GoldShimmer), findsNWidgets(2));
      expect(find.byKey(const ValueKey('featured_tier_buy')), findsOneWidget);
    });

    testWidgets('wears a NEW ribbon in capitals', (tester) async {
      await _pump(tester);

      expect(
        find.byKey(const ValueKey('featured_tier_ribbon')),
        findsOneWidget,
      );
      expect(find.text('ENCOUNTERS.BADGE_NEW'), findsOneWidget);
    });

    testWidgets('falls back to the tier emoji without a Lottie', (
      tester,
    ) async {
      await _pump(tester, lottieAsset: null);

      expect(find.byType(Lottie), findsNothing);
      expect(find.text(_encounters.emoji), findsOneWidget);
    });

    testWidgets('tapping the button asks to purchase once', (tester) async {
      var taps = 0;
      await _pump(tester, onPurchase: () => taps++);

      await tester.tap(find.byKey(const ValueKey('featured_tier_buy')));

      expect(taps, 1);
    });

    testWidgets(
        'while a purchase is running it shows progress and ignores taps',
        (tester) async {
      var taps = 0;
      await _pump(tester, isLoading: true, onPurchase: () => taps++);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('featured_tier_buy')));

      expect(taps, 0);
    });

    testWidgets('works for any tier, not only encounters', (tester) async {
      await _pump(
        tester,
        tier: SupporterTier.fromLevel(SupporterTierLevel.silver),
      );

      expect(find.text('supporter.tier_silver_name'), findsOneWidget);
    });
  });

  group('FeaturedTierCard (purchased)', () {
    testWidgets('shows an owned state: no buy button, no shimmer', (
      tester,
    ) async {
      await _pump(tester, isPurchased: true);

      expect(find.text('supporter.tier_encounters_name'), findsOneWidget);
      expect(find.text('supporter.purchased'), findsOneWidget);
      expect(find.byKey(const ValueKey('featured_tier_buy')), findsNothing);
      expect(find.byType(GoldShimmer), findsNothing);
      expect(find.byKey(const ValueKey('featured_tier_ribbon')), findsNothing);
      expect(find.text('ENCOUNTERS.BADGE_NEW'), findsNothing);
    });
  });
}
