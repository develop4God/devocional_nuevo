@Tags(['unit', 'models'])
library;

import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupporterTier', () {
    test('tiers list contains all 3 tiers', () {
      expect(SupporterTier.tiers.length, equals(3));
      final levels = SupporterTier.tiers.map((t) => t.level).toList();
      expect(
          levels,
          containsAll([
            SupporterTierLevel.bronze,
            SupporterTierLevel.silver,
            SupporterTierLevel.gold,
          ]));
    });

    test('each tier has a unique product ID', () {
      final ids = SupporterTier.tiers.map((t) => t.productId).toSet();
      expect(ids.length, equals(3));
    });

    test('fromProductId returns correct tier', () {
      expect(
        SupporterTier.fromProductId('supporter_bronze')?.level,
        equals(SupporterTierLevel.bronze),
      );
      expect(
        SupporterTier.fromProductId('supporter_silver')?.level,
        equals(SupporterTierLevel.silver),
      );
      expect(
        SupporterTier.fromProductId('supporter_gold')?.level,
        equals(SupporterTierLevel.gold),
      );
    });

    test('fromProductId returns null for unknown product', () {
      expect(SupporterTier.fromProductId('unknown_product'), isNull);
    });

    test('fromLevel returns correct tier', () {
      final bronze = SupporterTier.fromLevel(SupporterTierLevel.bronze);
      expect(bronze.productId, equals('supporter_bronze'));
      expect(bronze.emoji, equals('☕'));

      final silver = SupporterTier.fromLevel(SupporterTierLevel.silver);
      expect(silver.productId, equals('supporter_silver'));
      expect(silver.emoji, equals('🙏'));

      final gold = SupporterTier.fromLevel(SupporterTierLevel.gold);
      expect(gold.productId, equals('supporter_gold'));
      expect(gold.emoji, equals('❤️'));
    });

    test('tiers have non-empty i18n keys', () {
      for (final tier in SupporterTier.tiers) {
        expect(tier.nameKey, isNotEmpty);
        expect(tier.descriptionKey, isNotEmpty);
        expect(tier.benefitKeys, isNotEmpty);
      }
    });

    test('tiers have distinct badge colors', () {
      final colors = SupporterTier.tiers.map((t) => t.badgeColor).toList();
      expect(colors[0], equals(const Color(0xFFCD7F32))); // Bronze
      expect(colors[1], equals(const Color(0xFFC0C0C0))); // Silver
      expect(colors[2], equals(const Color(0xFFFFD700))); // Gold
      expect(colors.toSet().length, equals(3)); // All unique
    });

    test('bronze has 1 benefit, silver has 2, gold has 2', () {
      final bronze = SupporterTier.fromLevel(SupporterTierLevel.bronze);
      final silver = SupporterTier.fromLevel(SupporterTierLevel.silver);
      final gold = SupporterTier.fromLevel(SupporterTierLevel.gold);

      expect(bronze.benefitKeys.length, equals(1));
      expect(silver.benefitKeys.length, equals(2));
      expect(gold.benefitKeys.length, equals(2));
    });

    test('equality is based on level', () {
      final tier1 = SupporterTier.fromLevel(SupporterTierLevel.bronze);
      final tier2 = SupporterTier.fromLevel(SupporterTierLevel.bronze);
      expect(tier1, equals(tier2));
    });

    test('hashCode is consistent with equality', () {
      final tier1 = SupporterTier.fromLevel(SupporterTierLevel.gold);
      final tier2 = SupporterTier.fromLevel(SupporterTierLevel.gold);
      expect(tier1.hashCode, equals(tier2.hashCode));
    });

    test('toString contains product ID', () {
      final tier = SupporterTier.fromLevel(SupporterTierLevel.silver);
      expect(tier.toString(), contains('supporter_silver'));
    });

    test('price displays are non-empty strings', () {
      for (final tier in SupporterTier.tiers) {
        expect(tier.priceDisplay, isNotEmpty);
        expect(tier.priceDisplay, startsWith('\$'));
      }
    });
  });
}
