// lib/widgets/key_verse_card.dart

import 'package:devocional_nuevo/models/discovery_card_model.dart';
import 'package:flutter/material.dart';

/// A beautiful card widget for displaying the key verse of a discovery study.
///
/// This card is displayed at the beginning of the study to set the context
/// and theme before the other content cards.
class KeyVerseCard extends StatelessWidget {
  final KeyVerse keyVerse;

  const KeyVerseCard({
    super.key,
    required this.keyVerse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.15),
            colorScheme.primaryContainer.withValues(alpha: 0.25),
            colorScheme.tertiaryContainer.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and label
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    size: 24,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'VERSÍCULO CLAVE',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Verse reference
            Text(
              keyVerse.reference,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            // Verse text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '"${keyVerse.text}"',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.95),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Decorative element
            Center(
              child: Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.3),
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
