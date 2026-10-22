// lib/widgets/supporter/featured_tier_card.dart
import 'package:auto_size_text/auto_size_text.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/widgets/gold_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Highlighted offer for a single [SupporterTier], meant to sit at the top of
/// the support page. Pure presentation: purchases are reported through
/// [onPurchase] and the owner decides what to do with them.
///
/// While available it carries the shimmering gold border, a corner "new"
/// ribbon and a shimmering button; once [isPurchased] it settles into a calm
/// "owned" state. The icon is [lottieAsset] when given, else the tier emoji.
class FeaturedTierCard extends StatelessWidget {
  final SupporterTier tier;
  final String? storePrice;
  final bool isPurchased;
  final bool isLoading;
  final String? lottieAsset;
  final VoidCallback? onPurchase;

  const FeaturedTierCard({
    super.key,
    required this.tier,
    required this.isPurchased,
    required this.isLoading,
    this.storePrice,
    this.lottieAsset,
    this.onPurchase,
  });

  static const double _radius = 28;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  goldAccent.withValues(alpha: 0.22),
                  colorScheme.surface,
                  goldAccent.withValues(alpha: 0.08),
                ],
              ),
              border: isPurchased
                  ? Border.all(
                      color: goldAccent.withValues(alpha: 0.6),
                      width: 2,
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: _buildIcon(context)),
                const SizedBox(height: 14),
                Text(
                  tier.nameKey.tr(),
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                ...tier.benefitKeys.map(
                  (key) => Text(
                    key.tr(),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                isPurchased
                    ? _buildOwned(textTheme)
                    : _buildPurchaseButton(textTheme),
              ],
            ),
          ),
          if (!isPurchased) _buildRibbon(),
        ],
      ),
    );

    return isPurchased ? card : GoldShimmer(borderRadius: _radius, child: card);
  }

  Widget _buildIcon(BuildContext context) {
    final asset = lottieAsset;
    return Container(
      width: 84,
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: goldAccent.withValues(alpha: 0.16),
        border: Border.all(color: goldAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: goldAccent.withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: asset == null
          ? Text(tier.emoji, style: const TextStyle(fontSize: 38))
          : Lottie.asset(
              asset,
              width: 60,
              height: 60,
              fit: BoxFit.contain,
              animate: !MediaQuery.disableAnimationsOf(context),
              errorBuilder: (_, __, ___) =>
                  Text(tier.emoji, style: const TextStyle(fontSize: 38)),
            ),
    );
  }

  /// Diagonal gold ribbon across the top-right corner, in capitals.
  Widget _buildRibbon() {
    return Positioned(
      right: -38,
      top: 18,
      child: RotationTransition(
        key: const ValueKey('featured_tier_ribbon'),
        turns: const AlwaysStoppedAnimation(45 / 360),
        child: Container(
          width: 140,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [goldAccent, Color(0xFFFFE08A), goldAccent],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'encounters.badge_new'.tr().toUpperCase(),
              style: const TextStyle(
                color: goldOnGold,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOwned(TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified_rounded, color: goldAccent, size: 22),
        const SizedBox(width: 8),
        Text(
          'supporter.purchased'.tr(),
          style: textTheme.titleMedium?.copyWith(
            color: goldAccent,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseButton(TextTheme textTheme) {
    final price = storePrice ?? tier.priceDisplay;
    return SizedBox(
      height: 52,
      child: GoldShimmerButton(
        key: const ValueKey('featured_tier_buy'),
        borderRadius: 18,
        onPressed: isLoading ? null : onPurchase,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: goldOnGold,
                ),
              )
            : AutoSizeText(
                'encounters.unlock_offer_button'.tr({'price': price}),
                maxLines: 1,
                minFontSize: 12,
                textAlign: TextAlign.center,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}
