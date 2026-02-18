// lib/widgets/supporter/tier_card.dart
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../models/supporter_tier.dart';

/// A card widget that displays a single supporter tier with its benefits and purchase button.
class TierCard extends StatelessWidget {
  final SupporterTier tier;
  final String? storePrice;
  final bool isPurchased;
  final bool isLoading;
  final VoidCallback? onPurchase;

  const TierCard({
    super.key,
    required this.tier,
    required this.isPurchased,
    required this.isLoading,
    this.storePrice,
    this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isGold = tier.level == SupporterTierLevel.gold;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isGold
            ? LinearGradient(
                colors: [
                  const Color(0xFFFFD700).withValues(alpha: 0.15),
                  colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isGold
            ? null
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(
          color: isPurchased
              ? tier.badgeColor
              : isGold
                  ? tier.badgeColor.withValues(alpha: 0.5)
                  : colorScheme.outline.withValues(alpha: 0.3),
          width: isPurchased ? 2.5 : 1.5,
        ),
        boxShadow: isGold || isPurchased
            ? [
                BoxShadow(
                  color: tier.badgeColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, colorScheme, textTheme),
            const SizedBox(height: 12),
            _buildBenefits(colorScheme, textTheme),
            const SizedBox(height: 16),
            _buildPurchaseButton(context, colorScheme, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final displayPrice = storePrice ?? tier.priceDisplay;

    // Significantly increased size for maximum visibility
    const double badgeSize = 72.0;

    Widget badgeContent;
    bool isLottie = false;

    if (tier.level == SupporterTierLevel.bronze) {
      isLottie = true;
      // Coffee Lottie: Increased scale to 2.8 to make it look even larger
      badgeContent = Transform.scale(
        scale: 2.8,
        child: Lottie.asset(
          'assets/lottie/coffee_enter.json',
          width: badgeSize,
          height: badgeSize,
          fit: BoxFit.cover,
          repeat: true,
          animate: true,
        ),
      );
    } else if (tier.level == SupporterTierLevel.silver) {
      isLottie = true;
      // Plant Lottie for Silver tier - scaled down as requested
      badgeContent = Transform.scale(
        scale: 0.85,
        child: Lottie.asset(
          'assets/lottie/plant.json',
          width: badgeSize,
          height: badgeSize,
          fit: BoxFit.contain,
          repeat: true,
          animate: true,
        ),
      );
    } else if (tier.level == SupporterTierLevel.gold) {
      isLottie = true;
      // Heart Lottie: Scaled to 1.1 for consistency
      badgeContent = Transform.scale(
        scale: 1.1,
        child: Lottie.asset(
          'assets/lottie/hearts_love.json',
          width: badgeSize,
          height: badgeSize,
          fit: BoxFit.contain,
          repeat: true,
          animate: true,
        ),
      );
    } else {
      badgeContent = Center(
        child: Text(
          tier.emoji,
          style: const TextStyle(fontSize: 32),
        ),
      );
    }

    return Row(
      children: [
        // Unified Badge Circle with a thicker border
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLottie
                ? Colors.transparent
                : tier.badgeColor.withValues(alpha: 0.15),
            border: Border.all(
              color: tier.badgeColor,
              width: 3.0,
            ),
            boxShadow: [
              BoxShadow(
                color: tier.badgeColor.withValues(alpha: 0.15),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: badgeContent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tier.nameKey.tr(),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayPrice,
                style: textTheme.titleLarge?.copyWith(
                  color: tier.badgeColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (isPurchased)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tier.badgeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tier.badgeColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: tier.badgeColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  'supporter.purchased'.tr(),
                  style: TextStyle(
                    color: tier.badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBenefits(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tier.descriptionKey.tr(),
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        ...tier.benefitKeys.map(
          (key) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.star,
                  size: 14,
                  color: tier.badgeColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    key.tr(),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseButton(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (isPurchased) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            foregroundColor: tier.badgeColor,
            side: BorderSide(color: tier.badgeColor.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: Icon(Icons.workspace_premium, color: tier.badgeColor, size: 16),
          label: Text(
            'supporter.badge_active'.tr(),
            style: textTheme.bodyMedium?.copyWith(
              color: tier.badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPurchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: tier.badgeColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 4,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'supporter.get_tier'.tr(),
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
