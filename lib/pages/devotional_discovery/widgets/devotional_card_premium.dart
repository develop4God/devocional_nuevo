// lib/pages/devotional_discovery/widgets/devotional_card_premium.dart

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../models/devocional_model.dart';
import '../../../utils/tag_color_dictionary.dart';

// Singleton cache manager for Discovery images with size and TTL limits
class _DiscoveryCacheManager {
  static CacheManager? _instance;

  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        'discovery_images',
        maxNrOfCacheObjects: 200,
        stalePeriod: const Duration(days: 7),
      ),
    );
    return _instance!;
  }
}

/// Premium devotional card with full background image (Glorify/YouVersion style)
class DevotionalCardPremium extends StatelessWidget {
  final Devocional devocional;
  final String title;
  final String? subtitle;
  final int? readingMinutes;
  final bool isFavorite;
  final bool isCompleted;
  final bool isNew; // NEW: Track if study is "New" (unseen)
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final bool isDark;

  const DevotionalCardPremium({
    super.key,
    required this.devocional,
    required this.title,
    this.subtitle,
    this.readingMinutes,
    required this.isFavorite,
    this.isCompleted = false,
    this.isNew = false,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final displayDate = _getDisplayDate();
    final topicEmoji = _getTopicEmoji();
    final colors = _getGradientColors();

    return Semantics(
      label:
          'Devotional card for $title. Posted $displayDate. ${isFavorite ? "In favorites" : "Not in favorites"}',
      button: true,
      child: Container(
        height: 380,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Background Image
                  _buildBackgroundImage(),

                  // 2. Gradient Overlays
                  _buildGradientOverlay(colors),

                  // 3. Content Layer (Using AutoSizeText for multi-device safety)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      children: [
                        // Top Badge
                        _buildTopBadge(displayDate),

                        const Spacer(flex: 1),

                        // Central Hero Section
                        Flexible(
                          flex: 15, // Increased flex budget for text
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildHeroEmoji(topicEmoji, colors),
                                const SizedBox(height: 16),
                                
                                // Optimized Title with AutoSize
                                AutoSizeText(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                    letterSpacing: -0.8,
                                    shadows: [
                                      Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2))
                                    ],
                                  ),
                                  maxLines: 4,
                                  minFontSize: 18, // Safety for small devices
                                  stepGranularity: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                if (subtitle != null && subtitle!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _buildSubtitleSection(colors),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const Spacer(flex: 1),

                        // Bottom Row: Reading Info
                        _buildReadingInfo(),
                      ],
                    ),
                  ),

                  // ✅ COMPLETION CHECK - TOP LEFT
                  if (isCompleted) _buildCompletionBadge(),

                  // ✅ DYNAMIC FAVORITE BUTTON - TOP RIGHT
                  _buildFavoriteButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBadge(String displayDate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: isNew && !isCompleted
            ? const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
              )
            : null,
        color: isNew && !isCompleted
            ? null
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isNew && !isCompleted) ...[
            const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 12),
            const SizedBox(width: 6),
          ],
          Text(
            displayDate.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroEmoji(String topicEmoji, List<Color> colors) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 70, 
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1),
            boxShadow: [
              BoxShadow(
                color: colors[0].withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        Text(
          topicEmoji,
          style: const TextStyle(fontSize: 48, shadows: [
            Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
          ]),
        ),
      ],
    );
  }

  Widget _buildSubtitleSection(List<Color> colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors[0].withValues(alpha: 0.2),
            colors[0].withValues(alpha: 0.05),
            colors[1].withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: AutoSizeText(
        subtitle!,
        textAlign: TextAlign.center,
        maxLines: 3, 
        minFontSize: 11,
        stepGranularity: 0.5,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildReadingInfo() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_outlined,
              color: Colors.white.withValues(alpha: 0.9), size: 14),
          const SizedBox(width: 6),
          Text(
            'discovery.daily_bible_study'.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(
            '${readingMinutes ?? 5} ${'discovery.minutes_suffix'.tr()}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay(List<Color> colors) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.1),
                radius: 0.8,
                colors: [
                  colors[1].withValues(alpha: 0.4),
                  colors[1].withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.05),
                Colors.black.withValues(alpha: 0.25),
                Colors.black.withValues(alpha: 0.65),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteButton() {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
        ),
        child: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              isFavorite ? Icons.star_rounded : Icons.favorite_border_rounded,
              key: ValueKey<bool>(isFavorite),
              color: isFavorite ? Colors.amberAccent : Colors.white,
              size: 22,
            ),
          ),
          onPressed: onFavoriteToggle,
        ),
      ),
    );
  }

  Widget _buildCompletionBadge() {
    return Positioned(
      top: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
        ),
        child: const Icon(
          Icons.verified_rounded,
          color: Colors.greenAccent,
          size: 22,
        ),
      ),
    );
  }

  String _getTopicEmoji() {
    if (devocional.emoji != null && devocional.emoji!.isNotEmpty) {
      return devocional.emoji!;
    }
    if (devocional.tags != null && devocional.tags!.isNotEmpty) {
      final tag = devocional.tags!.first.toLowerCase();
      if (tag.contains('amor') || tag.contains('love')) return '❤️';
      if (tag.contains('paz') || tag.contains('peace')) return '🕊️';
      if (tag.contains('fe') || tag.contains('faith')) return '⚓';
      if (tag.contains('esperanza') || tag.contains('hope')) return '🌟';
      if (tag.contains('sabiduria') || tag.contains('wisdom')) return '💡';
      if (tag.contains('familia') || tag.contains('family')) return '🏠';
      if (tag.contains('oracion') || tag.contains('prayer')) return '🙏';
    }
    return '📖';
  }

  Widget _buildBackgroundImage() {
    final imageUrl = devocional.imageUrl;
    final colors = _getGradientColors();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        cacheManager: _DiscoveryCacheManager.instance,
        maxHeightDiskCache: 1080,
        maxWidthDiskCache: 1920,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: colors[0],
          highlightColor: colors[1].withAlpha(128),
          child: Container(color: Colors.black26),
        ),
        errorWidget: (context, url, error) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: const Center(
              child: Icon(Icons.book, color: Colors.white30, size: 48)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }

  List<Color> _getGradientColors() {
    if (isCompleted) {
      return TagColorDictionary.getGradientForTag('esperanza');
    } else {
      return TagColorDictionary.getGradientForTag('luz');
    }
  }

  String _getDisplayDate() {
    if (isCompleted) {
      return 'discovery.completed'.tr();
    }
    if (isNew) {
      return 'bubble_constants.new_feature'.tr();
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final devDate = DateTime(
        devocional.date.year, devocional.date.month, devocional.date.day);

    if (devDate == today) return 'app.today'.tr();
    DateTime displayDate = devDate;
    while (displayDate.isBefore(today)) {
      displayDate =
          DateTime(displayDate.year + 1, displayDate.month, displayDate.day);
    }
    final tomorrow = today.add(const Duration(days: 1));
    if (displayDate == tomorrow) return 'app.tomorrow'.tr();
    final daysUntil = displayDate.difference(today).inDays;
    if (daysUntil <= 7 && daysUntil > 1) {
      return DateFormat('EEEE').format(displayDate);
    }
    return DateFormat('MMM dd').format(displayDate);
  }
}
