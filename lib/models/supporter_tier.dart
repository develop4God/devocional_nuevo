// lib/models/supporter_tier.dart
import 'package:flutter/material.dart';

/// Represents the three supporter tiers available for purchase.
enum SupporterTierLevel { bronze, silver, gold }

/// Model for a supporter tier IAP product.
class SupporterTier {
  final SupporterTierLevel level;
  final String productId;
  final String emoji;
  final String nameKey;
  final String descriptionKey;
  final String priceDisplay;
  final Color badgeColor;
  final List<String> benefitKeys;

  const SupporterTier({
    required this.level,
    required this.productId,
    required this.emoji,
    required this.nameKey,
    required this.descriptionKey,
    required this.priceDisplay,
    required this.badgeColor,
    required this.benefitKeys,
  });

  static const List<SupporterTier> tiers = [_bronze, _silver, _gold];

  static const SupporterTier _bronze = SupporterTier(
    level: SupporterTierLevel.bronze,
    productId: 'supporter_bronze',
    emoji: '',
    // replaced by Lottie in UI
    nameKey: 'supporter.tier_bronze_name',
    descriptionKey: 'supporter.tier_bronze_description',
    priceDisplay: '\$1.99',
    badgeColor: Color(0xFFCD7F32),
    benefitKeys: ['supporter.benefit_bronze_badge'],
  );

  static const SupporterTier _silver = SupporterTier(
    level: SupporterTierLevel.silver,
    productId: 'supporter_silver',
    emoji: '🙏',
    nameKey: 'supporter.tier_silver_name',
    descriptionKey: 'supporter.tier_silver_description',
    priceDisplay: '\$4.99',
    badgeColor: Color(0xFFC0C0C0),
    benefitKeys: [
      'supporter.benefit_silver_badge',
      'supporter.benefit_silver_icon',
    ],
  );

  static const SupporterTier _gold = SupporterTier(
    level: SupporterTierLevel.gold,
    productId: 'supporter_gold',
    emoji: '',
    // replaced by Lottie in UI
    nameKey: 'supporter.tier_gold_name',
    descriptionKey: 'supporter.tier_gold_description',
    priceDisplay: '\$9.99',
    badgeColor: Color(0xFFFFD700),
    benefitKeys: [
      'supporter.benefit_gold_badge',
      'supporter.benefit_gold_thanks',
    ],
  );

  /// Returns the tier for a given product ID, or null if not found.
  static SupporterTier? fromProductId(String productId) {
    for (final tier in tiers) {
      if (tier.productId == productId) return tier;
    }
    return null;
  }

  /// Returns the tier for a given level.
  static SupporterTier fromLevel(SupporterTierLevel level) {
    return tiers.firstWhere((t) => t.level == level);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SupporterTier && other.level == level);

  @override
  int get hashCode => level.hashCode;

  @override
  String toString() => 'SupporterTier($productId, $priceDisplay)';
}
