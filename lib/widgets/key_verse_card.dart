// lib/widgets/key_verse_card.dart

import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/discovery_card_model.dart';
import 'package:flutter/material.dart';

/// A beautiful, modern card widget for displaying the key verse of a discovery study.
///
/// Designed with a premium aesthetic featuring subtle gradients, glassmorphism
/// elements, and centered typography for a more impactful reading experience.
class KeyVerseCard extends StatelessWidget {
  final KeyVerse keyVerse;
  final String? version;
  final EdgeInsetsGeometry? margin;

  const KeyVerseCard({
    super.key,
    required this.keyVerse,
    this.version,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        // Match Devocionales main verse background, but a little darker
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withAlpha((0.40 * 255).round()),
            // darker
            colorScheme.primary.withAlpha((0.18 * 255).round()),
            // darker
            colorScheme.secondary.withAlpha((0.12 * 255).round()),
            // slightly darker
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withAlpha((0.4 * 255).round()),
          // slightly darker border
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha((0.25 * 255).round()),
            // slightly darker shadow
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).round()),
            // slightly darker
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decorative background quote icon
            Positioned(
              top: -20,
              left: -10,
              child: Icon(
                Icons.format_quote_rounded,
                size: 140,
                color: colorScheme.primary.withValues(alpha: 0.03),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Label - Cleaner, more white version
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          size: 14,
                          color: colorScheme.primary.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'discovery.key_verse'.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Verse Text
                  Text(
                    '"${keyVerse.text}"',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Reference and Version
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 1,
                        width: 24,
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Text(
                          keyVerse.reference.toUpperCase(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (version != null && version!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          version!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                      const SizedBox(width: 16),
                      Container(
                        height: 1,
                        width: 24,
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
