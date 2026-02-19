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
    final isSilver = tier.level == SupporterTierLevel.silver;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isGold
            ? LinearGradient(
                colors: [
                  const Color(0xFFFFD700).withValues(alpha: 0.25),
                  colorScheme.surface,
                  const Color(0xFFFFD700).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : isSilver
                ? LinearGradient(
                    colors: [
                      const Color(0xFFC0C0C0).withValues(alpha: 0.2),
                      colorScheme.surface,
                      const Color(0xFFC0C0C0).withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
        color: (isGold || isSilver)
            ? null
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border.all(
          color: isPurchased
              ? tier.badgeColor
              : (isGold || isSilver)
                  ? tier.badgeColor.withValues(alpha: 0.6)
                  : colorScheme.outline.withValues(alpha: 0.2),
          width: isPurchased ? 2.5 : 1.5,
        ),
        boxShadow: isGold || isPurchased || isSilver
            ? [
                BoxShadow(
                  color: tier.badgeColor.withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (isPurchased)
              Positioned(
                right: -32,
                top: 12,
                child: RotationTransition(
                  turns: const AlwaysStoppedAnimation(45 / 360),
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: tier.badgeColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'supporter.purchased'.tr().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(context, colorScheme, textTheme),
                  const SizedBox(height: 20),
                  Divider(
                    color: tier.badgeColor.withValues(alpha: 0.1),
                    height: 1,
                  ),
                  const SizedBox(height: 20),
                  _buildBenefits(colorScheme, textTheme),
                  const SizedBox(height: 24),
                  _buildPurchaseButton(context, colorScheme, textTheme),
                ],
              ),
            ),
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
    const double badgeSize = 80.0;

    Widget badgeContent;
    bool isLottie = false;

    if (tier.level == SupporterTierLevel.bronze) {
      isLottie = true;
      badgeContent = Transform.scale(
        scale: 3.5,
        child: Lottie.asset(
          'assets/lottie/coffee_enter.json',
          width: badgeSize,
          height: badgeSize,
          fit: BoxFit.cover,
        ),
      );
    } else if (tier.level == SupporterTierLevel.silver) {
      isLottie = true;
      badgeContent = Transform.scale(
        scale: 0.9,
        child: Lottie.asset(
          'assets/lottie/plant.json',
          width: badgeSize,
          height: badgeSize,
          fit: BoxFit.contain,
        ),
      );
    } else if (tier.level == SupporterTierLevel.gold) {
      isLottie = true;
      badgeContent = Transform.scale(
        scale: 1.2,
        child: Lottie.asset(
          'assets/lottie/hearts_love.json',
          width: badgeSize,
          height: badgeSize,
          fit: BoxFit.contain,
        ),
      );
    } else {
      badgeContent = Center(
        child: Text(
          tier.emoji,
          style: const TextStyle(fontSize: 36),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLottie
                ? tier.badgeColor.withValues(alpha: 0.05)
                : tier.badgeColor.withValues(alpha: 0.15),
            border: Border.all(
              color: tier.badgeColor.withValues(alpha: 0.8),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: tier.badgeColor.withValues(alpha: 0.2),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (isPurchased || isLoading) ? null : onPurchase,
              borderRadius: BorderRadius.circular(badgeSize / 2),
              child: ClipOval(
                child: badgeContent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          tier.nameKey.tr(),
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayPrice,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            color: tier.badgeColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefits(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          tier.descriptionKey.tr(),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        ...tier.benefitKeys.map(
          (key) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: tier.badgeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 10,
                    color: tier.badgeColor,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    key.tr(),
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
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
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tier.badgeColor.withValues(alpha: 0.3)),
          color: tier.badgeColor.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium, color: tier.badgeColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'supporter.badge_active'.tr(),
              style: textTheme.bodyLarge?.copyWith(
                color: tier.badgeColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: tier.badgeColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPurchase,
          style: ElevatedButton.styleFrom(
            backgroundColor: tier.badgeColor,
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                  ),
                )
              : Text(
                  '${tier.emoji} ${'supporter.get_tier'.tr()}',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
        ),
      ),
    );
  }
}
