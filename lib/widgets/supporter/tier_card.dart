// lib/widgets/supporter/tier_card.dart
import 'package:auto_size_text/auto_size_text.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/supporter_pet.dart';
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: isGold
            ? LinearGradient(
                colors: [
                  const Color(0xFFFFD700).withValues(alpha: 0.3),
                  colorScheme.surface,
                  const Color(0xFFFFD700).withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : isSilver
                ? LinearGradient(
                    colors: [
                      const Color(0xFFC0C0C0).withValues(alpha: 0.25),
                      colorScheme.surface,
                      const Color(0xFFC0C0C0).withValues(alpha: 0.1),
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
          width: isPurchased ? 3.0 : 1.5,
        ),
        boxShadow: isGold || isPurchased || isSilver
            ? [
                BoxShadow(
                  color: tier.badgeColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            if (isPurchased)
              Positioned(
                right: -35,
                top: 15,
                child: RotationTransition(
                  turns: const AlwaysStoppedAnimation(45 / 360),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: tier.badgeColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'supporter.purchased'.tr().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
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
                  if (isGold) ...[
                    const SizedBox(height: 20),
                    _buildPetPreview(colorScheme, textTheme),
                  ],
                  const SizedBox(height: 24),
                  Divider(
                    color: tier.badgeColor.withValues(alpha: 0.15),
                    thickness: 1,
                    height: 1,
                  ),
                  const SizedBox(height: 24),
                  _buildBenefits(colorScheme, textTheme),
                  const SizedBox(height: 32),
                  _buildPurchaseButton(context, colorScheme, textTheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetPreview(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tier.badgeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
              const SizedBox(width: 8),
              Text(
                '¡REGALO EXCLUSIVO!'.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: tier.badgeColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Desbloquea una mascota para tu devocional diario',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: SupporterPet.allPets.take(4).map((pet) {
                return Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: Center(
                    child:
                        Text(pet.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final displayPrice = storePrice ?? tier.priceDisplay;
    const double badgeSize = 90.0;

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
          style: const TextStyle(fontSize: 42),
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
                ? tier.badgeColor.withValues(alpha: 0.08)
                : tier.badgeColor.withValues(alpha: 0.2),
            border: Border.all(
              color: tier.badgeColor.withValues(alpha: 0.9),
              width: 3.0,
            ),
            boxShadow: [
              BoxShadow(
                color: tier.badgeColor.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (isPurchased || isLoading)
                  ? null
                  : () {
                      // Log the tap with emoji to help tracing purchase flow
                      debugPrint(
                          '🛒 [SupporterPage] Tap purchase -> productId=${tier.productId}, tier=${tier.nameKey.tr()}');
                      onPurchase?.call();
                    },
              borderRadius: BorderRadius.circular(badgeSize / 2),
              child: ClipOval(
                child: badgeContent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          tier.nameKey.tr(),
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayPrice,
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            color: tier.badgeColor,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
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
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 20),
        ...tier.benefitKeys.map(
          (key) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: tier.badgeColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: tier.badgeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    key.tr(),
                    textAlign: TextAlign.left,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w700,
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tier.badgeColor, width: 2),
          color: tier.badgeColor.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stars_rounded, color: tier.badgeColor, size: 24),
            const SizedBox(width: 10),
            Text(
              'supporter.badge_active'.tr(),
              style: textTheme.titleMedium?.copyWith(
                color: tier.badgeColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            tier.badgeColor,
            Color.lerp(tier.badgeColor, Colors.white, 0.2)!,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: tier.badgeColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading
              ? null
              : () {
                  debugPrint(
                      '🛒 [SupporterPage] Tap purchase button -> productId=${tier.productId}, tier=${tier.nameKey.tr()}');
                  onPurchase?.call();
                },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: isLoading
                ? Center(
                    child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.black87),
                    ),
                  ))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tier.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AutoSizeText(
                          'supporter.get_tier'.tr(),
                          maxLines: 1,
                          minFontSize: 12,
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
