// lib/pages/devotional_discovery/widgets/devotional_card_premium.dart

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
    final verseReference = _extractVerseReference(devocional.versiculo);
    final topicEmoji = _getTopicEmoji();
    final colors = _getGradientColors();

    return Semantics(
      label:
          'Devotional card for $title. $verseReference. Posted $displayDate. ${isFavorite ? "In favorites" : "Not in favorites"}',
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
              // Use GestureDetector for better swipe compatibility
              behavior: HitTestBehavior.translucent,
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Background Image
                  _buildBackgroundImage(),

                  // 2. Light Effect / Bloom
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

                  // 3. Bottom Scrim - REDUCED DARKNESS
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.6),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),

                  // 4. Content Layer
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Badge - Replaces "Today" with "NEW" if applicable
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: isNew && !isCompleted
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFFF8C00)
                                      ],
                                    )
                                  : null,
                              color: isNew && !isCompleted
                                  ? null
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 0.8),
                              boxShadow: isNew && !isCompleted
                                  ? [
                                      BoxShadow(
                                        color: Colors.orange
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
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
                          ),
                        ),

                        const Spacer(),

                        // Hero Section
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
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
                              style: const TextStyle(fontSize: 56, shadows: [
                                Shadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 4))
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -0.8,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Subtitle / Description Section - Styled with "Bible format"
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colors[0].withValues(alpha: 0.25),
                                  colors[0].withValues(alpha: 0.08),
                                  colors[1].withValues(alpha: 0.06),
                                ],
                                stops: const [0.0, 0.6, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colors[0].withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors[0].withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                  spreadRadius: -4,
                                ),
                              ],
                            ),
                            child: Text(
                              subtitle!,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Bottom Row: Reading Info
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_stories_outlined,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'discovery.daily_bible_study'.tr(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.timer_outlined,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 12),
                              Text(
                                '${readingMinutes ?? 5} ${'discovery.minutes_suffix'.tr()}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ COMPLETION CHECK - TOP LEFT
                  if (isCompleted)
                    Positioned(
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
                          size: 24,
                        ),
                      ),
                    ),

                  // ✅ DYNAMIC FAVORITE BUTTON - TOP RIGHT
                  Positioned(
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
                            isFavorite
                                ? Icons.star_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey<bool>(isFavorite),
                            color:
                                isFavorite ? Colors.amberAccent : Colors.white,
                            size: 24,
                          ),
                        ),
                        onPressed: onFavoriteToggle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  /// Helper to get gradient colors based on study completion status
  List<Color> _getGradientColors() {
    if (isCompleted) {
      // Completed studies use Cyan/Blue palette
      return TagColorDictionary.getGradientForTag('esperanza');
    } else {
      // Incomplete studies use Amber/Gold palette
      return TagColorDictionary.getGradientForTag('luz');
    }
  }

  String _getDisplayDate() {
    // 1. Prioritize "COMPLETED" status
    if (isCompleted) {
      return 'discovery.completed'.tr();
    }

    // 2. Prioritize "NEW" status instead of "Today" (as requested)
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

  String _extractVerseReference(String? versiculo) {
    if (versiculo == null || versiculo.trim().isEmpty) {
      return 'discovery.verse_fallback'.tr();
    }
    final trimmed = versiculo.trim();
    final parts = trimmed.split(RegExp(r'\s+[A-Z]{2,}[0-9]*:'));
    if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
      final reference = parts[0].trim();
      if (reference.length >= 3) return reference;
    }
    final quoteIndex = trimmed.indexOf('"');
    if (quoteIndex > 0) {
      final reference = trimmed.substring(0, quoteIndex).trim();
      if (reference.length >= 3) return reference;
    }
    return trimmed.length < 50 ? trimmed : 'discovery.daily_verse'.tr();
  }
}
