import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/widgets/gold_shimmer.dart';
import 'package:flutter/material.dart';

/// Dark warm overlay painted over the next waiting (locked) encounter card.
const goldLockOverlayGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xD9000000), Color(0xE62A2110)],
);

/// Lock icon colour on top of [goldLockOverlayGradient].
const goldLockIconColor = Color(0xFFFFE08A);

/// Where the overlay is drawn; each style carries its own sizes.
enum LockedOverlayStyle {
  /// Full-size card in the encounters list.
  list(
    radius: 32,
    horizontalPadding: 32,
    plainIconSize: 40,
    badgeIconSize: 32,
    badgePadding: 12,
    iconGap: 16,
    plainTitleSize: 14,
    highlightTitleSize: 16,
    titleHeight: 1.4,
    hintGap: 8,
    pillFontSize: 12,
    pillPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    showPlainHint: true,
    animatedPill: true,
  ),

  /// Small card in the encounter grid; the card's ring already shimmers, so
  /// the pill is static.
  grid(
    radius: 0,
    horizontalPadding: 12,
    plainIconSize: 32,
    badgeIconSize: 28,
    badgePadding: 8,
    iconGap: 8,
    plainTitleSize: 10,
    highlightTitleSize: 10,
    titleHeight: 1.3,
    hintGap: 6,
    pillFontSize: 10,
    pillPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    showPlainHint: false,
    animatedPill: false,
  );

  final double radius;
  final double horizontalPadding;
  final double plainIconSize;
  final double badgeIconSize;
  final double badgePadding;
  final double iconGap;
  final double plainTitleSize;
  final double highlightTitleSize;
  final double titleHeight;
  final double hintGap;
  final double pillFontSize;
  final EdgeInsets pillPadding;
  final bool showPlainHint;
  final bool animatedPill;

  const LockedOverlayStyle({
    required this.radius,
    required this.horizontalPadding,
    required this.plainIconSize,
    required this.badgeIconSize,
    required this.badgePadding,
    required this.iconGap,
    required this.plainTitleSize,
    required this.highlightTitleSize,
    required this.titleHeight,
    required this.hintGap,
    required this.pillFontSize,
    required this.pillPadding,
    required this.showPlainHint,
    required this.animatedPill,
  });
}

/// Lock icon inside a glowing gold ring, used on the next waiting encounter.
class GoldLockBadge extends StatelessWidget {
  final double iconSize;
  final double padding;

  const GoldLockBadge({super.key, this.iconSize = 32, this.padding = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.5),
        border: Border.all(color: goldAccent, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x66D9A62E), blurRadius: 18, spreadRadius: 2),
        ],
      ),
      child: Icon(Icons.lock_rounded, color: goldLockIconColor, size: iconSize),
    );
  }
}

/// Overlay drawn over a published encounter whose prerequisite is not done.
///
/// [highlight] marks the next waiting encounter (gold treatment); other locked
/// encounters get the plain dark overlay. Content is scaled down rather than
/// overflowing when the card is small or the text scale is large.
class LockedEncounterOverlay extends StatelessWidget {
  final String prerequisiteTitle;
  final bool highlight;
  final LockedOverlayStyle style;

  const LockedEncounterOverlay({
    super.key,
    required this.prerequisiteTitle,
    required this.highlight,
    this.style = LockedOverlayStyle.list,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: style.horizontalPadding),
      decoration: BoxDecoration(
        color: highlight ? null : Colors.black.withValues(alpha: 0.65),
        gradient: highlight ? goldLockOverlayGradient : null,
        borderRadius:
            style.radius > 0 ? BorderRadius.circular(style.radius) : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIcon(),
                SizedBox(height: style.iconGap),
                Text(
                  'encounters.complete_to_unlock'.tr({
                    'title': prerequisiteTitle,
                  }),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: highlight
                        ? style.highlightTitleSize
                        : style.plainTitleSize,
                    fontWeight: highlight ? FontWeight.w900 : FontWeight.bold,
                    height: style.titleHeight,
                  ),
                ),
                ..._buildHint(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (highlight) {
      return GoldLockBadge(
        iconSize: style.badgeIconSize,
        padding: style.badgePadding,
      );
    }
    return Icon(
      Icons.lock_rounded,
      color: Colors.white,
      size: style.plainIconSize,
    );
  }

  List<Widget> _buildHint() {
    final hint = 'encounters.read_now_hint'.tr();
    if (highlight) {
      return [
        SizedBox(height: style.hintGap),
        GoldHintPill(
          text: hint,
          fontSize: style.pillFontSize,
          padding: style.pillPadding,
          animated: style.animatedPill,
        ),
      ];
    }
    if (!style.showPlainHint) return const [];
    return [
      SizedBox(height: style.hintGap),
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
