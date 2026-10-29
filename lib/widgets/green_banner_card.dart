import 'package:flutter/material.dart';

/// Fixed (not theme-derived) so in-app notices look the same in every theme;
/// white on this green passes 4.5:1.
const Color kBannerGreen = Color(0xFF2E7D32);

/// Tinted green card shared by the in-app notice banners. The whole card is
/// the tap target.
class GreenBannerCard extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const GreenBannerCard({super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: kBannerGreen.withValues(alpha: 0.14),
        borderRadius: radius,
        border: Border.all(color: kBannerGreen.withValues(alpha: 0.6)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: child,
          ),
        ),
      ),
    );
  }
}
