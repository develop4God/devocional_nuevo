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
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final bool isDark;

  const DevotionalCardPremium({
    super.key,
    required this.devocional,
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

    return Semantics(
      label:
          'Devotional card for $verseReference. $verseText. Posted $displayDate. ${isFavorite ? "In favorites" : "Not in favorites"}',
      button: true,
      child: Container(
        height: 320,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
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

                  // Dark gradient overlay (bottom to top)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Date badge only
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Date badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                displayDate,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Bottom content
                        // Theme tag chips (muestra hasta 2 tags)
                        if (devocional.tags != null &&
                            devocional.tags!.isNotEmpty)
                          Row(
                            children: devocional.tags!
                                .take(2)
                                .map((tag) => Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getTagColor(tag),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        TagColorDictionary.getTagTranslation(
                                          tag,
                                          Localizations.localeOf(context)
                                              .languageCode,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),

                        const SizedBox(height: 12),

                        // Verse reference (large and bold)
                        Text(
                          verseReference,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        // Verse preview text
                        Text(
                          _extractVerseText(devocional.versiculo),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 12),

                        // Reading time badge
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '5 min read',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Floating heart button (FAB style) - top-right
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Semantics(
                      label: isFavorite
                          ? 'Remove from favorites'
                          : 'Add to favorites',
                      button: true,
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                key: ValueKey(isFavorite),
                                color: isFavorite
                                    ? Colors.red[500]
                                    : Colors.grey[700],
                                size: 24,
                              ),
                            ),
                            onPressed: onFavoriteToggle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ), // Close Semantics
    );
  }

  Widget _buildBackgroundImage() {
    // Use CachedNetworkImage with shimmer placeholder
    // For now, we'll use a fallback gradient since we don't have image URLs
    // In production, you'd fetch image URLs from your API or use Unsplash
    final imageUrl = _getImageUrl();

    if (imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        cacheManager: _DiscoveryCacheManager.instance,
        maxHeightDiskCache: 1080,
        maxWidthDiskCache: 1920,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: _getGradientColors()[0],
          highlightColor: _getGradientColors()[1].withValues(alpha: 0.5),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getGradientColors(),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getGradientColors(),
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white70,
                  size: 48,
                ),
                SizedBox(height: 8),
                Text(
                  'Tap to retry',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Fallback gradient with subtle shimmer effect
    return Shimmer.fromColors(
      baseColor: _getGradientColors()[0],
      highlightColor: _getGradientColors()[1].withValues(alpha: 0.3),
      period: const Duration(milliseconds: 2000),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(),
          ),
        ),
      ),
    );
  }

  String? _getImageUrl() {
    // TODO: In production, fetch image URLs from your devotional data
    // For now, returning null to use gradient fallback
    // You could add an "imageUrl" field to your Devocional model
    return null;
  }

  // Reemplaza el metodo _getTagColor para usar el diccionario centralizado
  Color _getTagColor(String tagKey) {
    return TagColorDictionary.getGradientForTag(tagKey).last;
  }

  // Reemplaza el metodo _getGradientColors para usar el diccionario centralizado
  List<Color> _getGradientColors() {
    final tagKey = devocional.tags != null && devocional.tags!.isNotEmpty
        ? devocional.tags!.first
        : null;
    return tagKey != null
        ? TagColorDictionary.getGradientForTag(tagKey)
        : [Color(0xFF607D8B), Color(0xFF455A64)];
  }

  String _getDisplayDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final devDate = DateTime(
      devocional.date.year,
      devocional.date.month,
      devocional.date.day,
    );

    if (devDate == today) {
      return 'Today';
    }

    DateTime displayDate = devDate;
    while (displayDate.isBefore(today)) {
      displayDate = DateTime(
        displayDate.year + 1,
        displayDate.month,
        displayDate.day,
      );
    }

    final tomorrow = today.add(const Duration(days: 1));
    if (displayDate == tomorrow) {
      return 'Tomorrow';
    }

    final daysUntil = displayDate.difference(today).inDays;
    if (daysUntil <= 7 && daysUntil > 1) {
      return DateFormat('EEEE').format(displayDate);
    }

    return DateFormat('MMM dd').format(displayDate);
  }

  /// Extract verse reference with comprehensive validation
  String _extractVerseReference(String? versiculo) {
    // Handle null, empty, or whitespace-only input
    if (versiculo == null || versiculo.trim().isEmpty) {
      return 'Unknown Verse';
    }

    final trimmed = versiculo.trim();

    // Extract reference before Bible version code (e.g., "RVR1960:")
    final parts = trimmed.split(RegExp(r'\s+[A-Z]{2,}[0-9]*:'));
    if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
      final reference = parts[0].trim();
      // Validate minimum length (e.g., "Gn 1:1" is 6 chars)
      if (reference.length >= 3) {
        return reference;
      }
    }

    // Extract reference before quote
    final quoteIndex = trimmed.indexOf('"');
    if (quoteIndex > 0) {
      final reference = trimmed.substring(0, quoteIndex).trim();
      if (reference.length >= 3) {
        return reference;
      }
    }

    // If no pattern matches and input is reasonable length, return it
    if (trimmed.length >= 3 && trimmed.length < 100) {
      return trimmed;
    }

    return 'Unknown Verse';
  }

  /// Extract verse text with comprehensive validation
  String _extractVerseText(String? versiculo) {
    // Handle null, empty, or whitespace-only input
    if (versiculo == null || versiculo.trim().isEmpty) {
      return '';
    }

    final trimmed = versiculo.trim();

    // Extract text between quotes
    final quoteStart = trimmed.indexOf('"');
    final quoteEnd = trimmed.lastIndexOf('"');

    if (quoteStart != -1 && quoteEnd != -1 && quoteEnd > quoteStart) {
      final text = trimmed.substring(quoteStart + 1, quoteEnd).trim();
      // Validate extracted text has meaningful content (min 5 chars)
      if (text.length >= 5) {
        return text;
      }
    }

    // If no quotes or invalid content, check if entire string is the text
    // (after removing potential reference at start)
    final parts = trimmed.split(RegExp(r'\s+[A-Z]{2,}[0-9]*:'));
    if (parts.length > 1) {
      final potentialText = parts.sublist(1).join(' ').trim();
      if (potentialText.length >= 5) {
        return potentialText;
      }
    }

    // Fallback: return original if it's reasonable length
    if (trimmed.length >= 5 && trimmed.length < 500) {
      return trimmed;
    }

    return '';
  }
}
