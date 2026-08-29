import 'package:cached_network_image/cached_network_image.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocional_header_widget.dart';
import 'package:flutter/material.dart';

/// Full-bleed hero replacing the page's normal AppBar + header row when a
/// hero image is available. Reaches from the very top of the screen (behind
/// the status bar, via [MediaQuery] padding) down past the date/streak/
/// favorite/share row, so the whole top of the devotionals page reads as one
/// borderless photo. Only used for that page — other pages keep their
/// regular [CustomAppBar] untouched.
///
/// The drawer/title row here duplicates what [CustomAppBar] normally shows,
/// scoped to this widget alone: the drawer icon opens the same [Scaffold]
/// drawer, and the title matches the page's usual title text.
class DevocionalHeroSection extends StatelessWidget {
  final String imageUrl;
  final String titleText;

  final String date;
  final bool showDate;
  final int currentStreak;
  final Future<int> streakFuture;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onShare;
  final VoidCallback onStreakTap;
  final VoidCallback onFontSizeToggle;

  const DevocionalHeroSection({
    super.key,
    required this.imageUrl,
    required this.titleText,
    required this.date,
    this.showDate = true,
    required this.currentStreak,
    required this.streakFuture,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onShare,
    required this.onStreakTap,
    required this.onFontSizeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: topInset + kToolbarHeight + 140,
      child: Stack(
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
          Padding(
            padding: EdgeInsets.only(top: topInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: kToolbarHeight,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                      Expanded(
                        child: Text(
                          titleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.text_increase_outlined,
                          color: Colors.white,
                        ),
                        onPressed: onFontSizeToggle,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
