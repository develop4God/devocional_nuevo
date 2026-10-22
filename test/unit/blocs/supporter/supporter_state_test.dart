@Tags(['unit', 'blocs', 'iap'])
library;

import 'package:devocional_nuevo/blocs/supporter/supporter_state.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:flutter_test/flutter_test.dart';

SupporterLoaded _loaded(Set<SupporterTierLevel> levels) => SupporterLoaded(
      purchasedLevels: levels,
      isBillingAvailable: true,
      storePrices: const {},
    );

void main() {
  group('SupporterLoaded.unlocksAllEncounters', () {
    test('is false with no purchases', () {
      expect(_loaded({}).unlocksAllEncounters, isFalse);
    });

    test('is false when only donation tiers are owned', () {
      final state = _loaded({
        SupporterTierLevel.bronze,
        SupporterTierLevel.silver,
        SupporterTierLevel.gold,
      });
      expect(state.unlocksAllEncounters, isFalse);
    });

    test('is true when the encounters product is owned', () {
      final state = _loaded({
        SupporterTierLevel.bronze,
        SupporterTierLevel.encounters,
      });
      expect(state.unlocksAllEncounters, isTrue);
    });

    test('matches the unlocksEncounters flag of every tier', () {
      for (final tier in SupporterTier.tiers) {
        expect(
          _loaded({tier.level}).unlocksAllEncounters,
          tier.unlocksEncounters,
          reason: tier.productId,
        );
      }
    });
  });
}
