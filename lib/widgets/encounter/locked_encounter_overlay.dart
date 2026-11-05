import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/widgets/gold_shimmer.dart';
import 'package:flutter/material.dart';

/// Overlay drawn over a published encounter whose prerequisite is not done.
///
/// [highlight] marks the next waiting encounter (gold treatment); other locked
/// encounters get the plain dark overlay. [compact] is the small grid-card
/// variant: tighter sizes, and no hint text on non-highlighted cards.
class LockedEncounterOverlay extends StatelessWidget {
  final String prerequisiteTitle;
  final bool highlight;
  final bool compact;
  final BorderRadius? borderRadius;

  const LockedEncounterOverlay({
    super.key,
    required this.prerequisiteTitle,
    required this.highlight,
    this.compact = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 32),
      decoration: BoxDecoration(
        color: highlight ? null : Colors.black.withValues(alpha: 0.65),
        gradient: highlight ? goldLockOverlayGradient : null,
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIcon(),
          SizedBox(height: compact ? 8 : 16),
          Text(
            'encounters.complete_to_unlock'.tr({'title': prerequisiteTitle}),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 9 : (highlight ? 16 : 14),
              fontWeight:
                  highlight && !compact ? FontWeight.w900 : FontWeight.bold,
              height: compact ? 1.3 : 1.4,
            ),
          ),
          ..._buildHint(),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    if (highlight) {
      return compact
          ? const GoldLockBadge(iconSize: 28, padding: 8)
          : const GoldLockBadge();
    }
    return Icon(
      Icons.lock_rounded,
      color: Colors.white,
      size: compact ? 32 : 40,
    );
  }

  List<Widget> _buildHint() {
    final hint = 'encounters.read_now_hint'.tr();
    if (highlight) {
      return [
        SizedBox(height: compact ? 6 : 8),
        GoldHintPill(
          text: hint,
          fontSize: compact ? 9 : 12,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 16,
            vertical: compact ? 5 : 8,
          ),
        ),
      ];
    }
    if (compact) return const [];
    return [
      const SizedBox(height: 8),
      Text(
        hint,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          fontSize: 12,
          height: 1.4,
        ),
      ),
    ];
  }
}
