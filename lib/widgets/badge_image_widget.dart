// lib/widgets/badge_image_widget.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/badge_model.dart' as badge_model;

class BadgeImageWidget extends StatelessWidget {
  final badge_model.Badge badge;
  final double size;
  final bool isUnlocked;
  final bool showLock;
  final VoidCallback? onTap;
  final bool isSelected;

  const BadgeImageWidget({
    super.key,
    required this.badge,
    this.size = 80,
    this.isUnlocked = true,
    this.showLock = false,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme
        .of(context)
        .colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : isUnlocked
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 3 : (isUnlocked ? 2 : 1),
          ),
          boxShadow: isSelected || isUnlocked
              ? [
            BoxShadow(
              color:
              (isSelected
                  ? colorScheme.primary
                  : colorScheme.primary.withValues(alpha: 0.3))
                  .withValues(alpha: 0.3),
              blurRadius: isSelected ? 12 : 8,
              spreadRadius: isSelected ? 3 : 1,
            ),
          ]
              : null,
        ),
        child: ClipOval(
          child: Stack(
            children: [
              // Badge image
              _buildBadgeImage(context),

              // Lock overlay for locked badges
              if (!isUnlocked && showLock)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lock,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: size * 0.4,
                    ),
                  ),
                ),

              // Selection indicator
              if (isSelected)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary, width: 3),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeImage(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: badge.imageUrl,
      fit: BoxFit.cover,
      width: size,
      height: size,
      placeholder: (context, url) => _buildLoadingPlaceholder(context),
      errorWidget: (context, url, error) => _buildErrorPlaceholder(context),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    final colorScheme = Theme
        .of(context)
        .colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    final colorScheme = Theme
        .of(context)
        .colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colorScheme.errorContainer,
            colorScheme.errorContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: colorScheme.onErrorContainer.withValues(alpha: 0.7),
          size: size * 0.4,
        ),
      ),
    );
  }
}

// Widget especializado para preview de badges con información
class BadgePreviewWidget extends StatelessWidget {
  final badge_model.Badge badge;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const BadgePreviewWidget({
    super.key,
    required this.badge,
    this.isUnlocked = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Card(
      elevation: isUnlocked ? 8 : 2,
      shadowColor: isUnlocked
          ? colorScheme.primary.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge image
              BadgeImageWidget(
                badge: badge,
                size: 80,
                isUnlocked: isUnlocked,
                showLock: true,
              ),

              const SizedBox(height: 12),

              // Badge name
              Text(
                badge.name,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (isUnlocked) ...[
                const SizedBox(height: 8),

                // Bible verse preview
                Text(
                  badge.verse.length > 40
                      ? '${badge.verse.substring(0, 40)}...'
                      : badge.verse,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
