// lib/pages/devotional_discovery/widgets/devotional_card_premium.dart

import 'package:cached_network_image/cached_network_image.dart';
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
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final bool isDark;

  const DevotionalCardPremium({
    super.key,
    required this.devocional,
    required this.title,
    required this.isFavorite,
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
        height: 360,
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
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Background Image or Base Gradient
                  _buildBackgroundImage(),

                  // 2. Light Effect / Bloom (Fondo dinámico detrás del emoji)
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

                  // 3. Bottom Scrim (Degradado para lectura de texto)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.85),
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
                        // Top Badge - Clean surface style
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
                            ),
                            child: Text(
                              displayDate.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white, // On surface
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // The "Hero" Section: Emoji + Title
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
                                Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Title (Large & Powerful)
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

                        const SizedBox(height: 14),

                        // Verse reference in a elegant capsule
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15), // Surface style
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5),
                          ),
                          child: Text(
                            verseReference,
                            style: const TextStyle(
                              color: Colors.white, // White font
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Reading Info - All Surface (White)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_rounded, color: Colors.white.withValues(alpha: 0.9), size: 14),
                            const SizedBox(width: 8),
                            Text(
                              'DAILY BIBLE STUDY',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle)),
                            const SizedBox(width: 12),
                            Text(
                              '5 MIN',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Favorite Button (Glassmorphism style)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10),
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.redAccent : Colors.white,
                            size: 20,
                          ),
                          onPressed: onFavoriteToggle,
                        ),
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
    if (devocional.emoji != null && devocional.emoji!.isNotEmpty) return devocional.emoji!;
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
          child: const Center(child: Icon(Icons.book, color: Colors.white30, size: 48)),
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
    if (devocional.tags != null && devocional.tags!.isNotEmpty) {
      return TagColorDictionary.getGradientForTag(devocional.tags!.first);
    }
    return [const Color(0xFF37474F), const Color(0xFF102027)];
  }

  String _getDisplayDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final devDate = DateTime(devocional.date.year, devocional.date.month, devocional.date.day);

    if (devDate == today) return 'Today';
    DateTime displayDate = devDate;
    while (displayDate.isBefore(today)) {
      displayDate = DateTime(displayDate.year + 1, displayDate.month, displayDate.day);
    }
    final tomorrow = today.add(const Duration(days: 1));
    if (displayDate == tomorrow) return 'Tomorrow';
    final daysUntil = displayDate.difference(today).inDays;
    if (daysUntil <= 7 && daysUntil > 1) return DateFormat('EEEE').format(displayDate);
    return DateFormat('MMM dd').format(displayDate);
  }

  String _extractVerseReference(String? versiculo) {
    if (versiculo == null || versiculo.trim().isEmpty) return 'Bible Study';
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
    return trimmed.length < 50 ? trimmed : 'Daily Verse';
  }
}
