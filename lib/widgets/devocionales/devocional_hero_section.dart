import 'package:cached_network_image/cached_network_image.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocional_header_widget.dart';
import 'package:flutter/material.dart';

/// Background content for the devotionals page's [SliverAppBar] when a hero
/// image is available — meant to be passed as
/// `SliverAppBar(flexibleSpace: FlexibleSpaceBar(background: DevocionalHeroSection(...)))`.
/// The drawer icon, title and font-size action live on [SliverAppBar] itself
/// (its pinned toolbar), not here — this widget only paints the photo, its
/// scrim, and the date/streak/favorite/share row that collapses away with
/// the image as the user scrolls, leaving just the pinned toolbar behind.
/// Only used for the devotionals page; other pages keep their regular
/// [CustomAppBar] untouched.
class DevocionalHeroSection extends StatelessWidget {
  final String imageUrl;

  final String date;
  final bool showDate;
  final int currentStreak;
  final Future<int> streakFuture;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onShare;
  final VoidCallback onStreakTap;

  const DevocionalHeroSection({
    super.key,
    required this.imageUrl,
    required this.date,
    this.showDate = true,
    required this.currentStreak,
    required this.streakFuture,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onShare,
    required this.onStreakTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 300),
          errorWidget: (context, url, error) => const SizedBox.shrink(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.5),
                Colors.black.withValues(alpha: 0.1),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            // Top padding clears the status bar AND the SliverAppBar's own
            // toolbar band (drawer/title/font-size), which is also painted
            // over this background — without it, this row overlaps the
            // title text instead of sitting below it.
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            ),
            child: DevocionalHeaderWidget(
              date: date,
              showDate: showDate,
              currentStreak: currentStreak,
              streakFuture: streakFuture,
              isFavorite: isFavorite,
              onFavoriteToggle: onFavoriteToggle,
              onShare: onShare,
              onStreakTap: onStreakTap,
              onHeroImage: true,
            ),
          ),
        ),
      ],
    );
  }
}
