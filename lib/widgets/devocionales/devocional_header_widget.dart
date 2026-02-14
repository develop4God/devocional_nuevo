import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class DevocionalHeaderWidget extends StatelessWidget {
  final String date;
  final int currentStreak;
  final Future<int> streakFuture;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onShare;
  final VoidCallback onStreakTap;

  const DevocionalHeaderWidget({
    super.key,
    required this.date,
    required this.currentStreak,
    required this.streakFuture,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onShare,
    required this.onStreakTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Streak Badge (Left)
          FutureBuilder<int>(
            future: streakFuture,
            builder: (context, snapshot) {
              final streak = snapshot.data ?? currentStreak;
              if (streak <= 0) {
                return const SizedBox(width: 48);
              }
              return _buildStreakBadge(context, streak);
            },
          ),

          const SizedBox(width: 8),

          // 2. Date Text (Center)
          Expanded(
            child: Text(
              date,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // 3. Action Buttons (Right) - Modernized UI
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModernActionButton(
                context,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: Curves.elasticOut,
                      ),
                      child: child,
                    );
                  },
                  child: Icon(
                    isFavorite
                        ? Icons.star_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey<bool>(isFavorite),
                    color: isFavorite ? Colors.amber : colorScheme.primary,
                    size: 26,
                  ),
                ),
                onPressed: () {
                  getService<AnalyticsService>()
                      .logBottomBarAction(action: 'favorite');
                  HapticFeedback.mediumImpact();
                  onFavoriteToggle();
                },
                tooltip: isFavorite
                    ? 'devotionals.remove_from_favorites_short'.tr()
                    : 'devotionals.save_as_favorite'.tr(),
              ),
              const SizedBox(width: 8),
              _buildModernActionButton(
                context,
                icon: Icon(
                  Icons.share_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
                onPressed: () {
                  getService<AnalyticsService>()
                      .logBottomBarAction(action: 'share');
                  HapticFeedback.lightImpact();
                  onShare();
                },
                tooltip: 'devotionals.share_devotional'.tr(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton(
    BuildContext context, {
    required Widget icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: icon,
          ),
        ),
      ),
    );
  }

  Widget _buildStreakBadge(BuildContext context, int streak) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;
    final backgroundColor = colorScheme.surfaceContainerHighest.withValues(
      alpha: 0.06,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onStreakTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Lottie.asset(
                        'assets/lottie/fire.json',
                        repeat: true,
                        animate: true,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${'progress.streak'.tr()} $streak',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
