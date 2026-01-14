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
    final verseText = _extractVerseText(devocional.versiculo);
    final topicEmoji = _getTopicEmoji();

    return Semantics(
      label:
          'Devotional card for $title. $verseReference. $verseText. Posted $displayDate. ${isFavorite ? "In favorites" : "Not in favorites"}',
      button: true,
      child: Container(
        height: 340, // Increased slightly for centered content
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(38),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  _buildBackgroundImage(),

                  // Sophisticated gradient overlay for centered text
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),

                  // Content Layer
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Badge (Date) - Floating style
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              displayDate.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Main Feature: Emoji + Title + Verse
                        // Large Emoji for visual anchor
                        Text(
                          topicEmoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 12),

                        // Localized title
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 12),

                        // Verse Reference as a distinct subtitle
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            verseReference,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Bottom row: Tags and Reading Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (devocional.tags != null && devocional.tags!.isNotEmpty)
                              ...devocional.tags!.take(1).map((tag) => Text(
                                TagColorDictionary.getTagTranslation(
                                  tag,
                                  Localizations.localeOf(context).languageCode,
                                ).toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              )),
                            const SizedBox(width: 8),
                            Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white54, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(
                              '5 MIN READ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Floating heart button - remains in top-right for utility
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey[800],
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

  /// Returns an emoji based on the first tag or a default
  String _getTopicEmoji() {
    if (devocional.tags == null || devocional.tags!.isEmpty) return '📖';
    final tag = devocional.tags!.first.toLowerCase();

    // Mapping common tags to emojis
    if (tag.contains('amor') || tag.contains('love')) return '❤️';
    if (tag.contains('paz') || tag.contains('peace')) return '🕊️';
    if (tag.contains('fe') || tag.contains('faith')) return '⚓';
    if (tag.contains('esperanza') || tag.contains('hope')) return '🌟';
    if (tag.contains('sabiduria') || tag.contains('wisdom')) return '💡';
    if (tag.contains('familia') || tag.contains('family')) return '🏠';
    if (tag.contains('oracion') || tag.contains('prayer')) return '🙏';

    return '📖'; // Default Bible emoji
  }

  Widget _buildBackgroundImage() {
    final imageUrl = devocional.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        cacheManager: _DiscoveryCacheManager.instance,
        maxHeightDiskCache: 1080,
        maxWidthDiskCache: 1920,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: _getGradientColors()[0],
          highlightColor: _getGradientColors()[1].withAlpha(128),
          child: Container(color: Colors.black26),
        ),
        errorWidget: (context, url, error) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getGradientColors(),
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
          colors: _getGradientColors(),
        ),
      ),
    );
  }

  List<Color> _getGradientColors() {
    final tagKey = devocional.tags != null && devocional.tags!.isNotEmpty
        ? devocional.tags!.first
        : null;
    return tagKey != null
        ? TagColorDictionary.getGradientForTag(tagKey)
        : [const Color(0xFF607D8B), const Color(0xFF455A64)];
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

  String _extractVerseText(String? versiculo) {
    if (versiculo == null || versiculo.trim().isEmpty) return '';
    final trimmed = versiculo.trim();
    final quoteStart = trimmed.indexOf('"');
    final quoteEnd = trimmed.lastIndexOf('"');
    if (quoteStart != -1 && quoteEnd != -1 && quoteEnd > quoteStart) {
      return trimmed.substring(quoteStart + 1, quoteEnd).trim();
    }
    return '';
  }
}
