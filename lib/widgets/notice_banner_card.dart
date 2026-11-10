import 'package:flutter/material.dart';

/// Fixed (not theme-derived) so the accent edge of in-app notices looks the
/// same in every theme.
const Color kNoticeAccent = Color(0xFF2E7D32);

/// Icon accent on the notice banners (cyan 800, readable on light and dark surfaces).
const Color kNoticeIcon = Color(0xFF00838F);

/// Opaque card shared by the in-app notice banners, styled like the app's
/// bottom sheets: theme surface, large radius, soft shadow, and a green accent
/// edge. The whole card is the tap target; a null [onTap] disables it.
class NoticeBannerCard extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const NoticeBannerCard({super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: radius,
        // Hairline keeps the card visible on dark surfaces, where the shadow
        // alone disappears.
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            // A Stack, not IntrinsicHeight: the accent strip follows the
            // content height without a second layout pass.
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: child,
                ),
                const Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: ColoredBox(color: kNoticeAccent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
