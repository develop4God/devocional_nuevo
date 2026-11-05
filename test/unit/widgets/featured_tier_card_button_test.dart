@Tags(['unit', 'widgets', 'supporter'])
library;

// FeaturedTierCard buy button: the label must stay readable on the gold
// button in every theme (it used to inherit the theme's near-white text).

import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/widgets/gold_shimmer.dart';
import 'package:devocional_nuevo/widgets/supporter/featured_tier_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await registerTestServicesWithFakes();
  });

  for (final theme in [ThemeData.light(), ThemeData.dark()]) {
    testWidgets('label is always dark on gold (${theme.brightness.name})', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: FeaturedTierCard(
                tier: SupporterTier.fromLevel(SupporterTierLevel.encounters),
                storePrice: r'$4.99',
                isPurchased: false,
                isLoading: false,
                lottieAsset: null,
                onPurchase: () {},
              ),
            ),
          ),
        ),
      );
      // The shimmer loops forever: pump a frame instead of pumpAndSettle.
      await tester.pump();

      final label = tester.widget<RichText>(
        find.descendant(
          of: find.byKey(const ValueKey('featured_tier_buy')),
          matching: find.byType(RichText),
        ),
      );
      expect(label.text.style?.color, goldOnGold);
    });
  }
}
