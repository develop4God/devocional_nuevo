// lib/pages/donate/donate_success_page.dart
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

import '../../models/badge_model.dart' as badge_model;
import '../../widgets/badge_image_widget.dart';

class DonateSuccessPage extends StatelessWidget {
  final badge_model.Badge? unlockedBadge;
  final AnimationController successAnimationController;
  final Animation<double> scaleAnimation;
  final Animation<double> glowAnimation;
  final Function(String) showSuccessSnackBar;

  const DonateSuccessPage({
    required this.unlockedBadge,
    required this.successAnimationController,
    required this.scaleAnimation,
    required this.glowAnimation,
    required this.showSuccessSnackBar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.1),
              colorScheme.secondary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Animation Badge
                _buildAnimatedBadge(colorScheme),

                const SizedBox(height: 32),

                // Success Text
                Text(
                  'donate.badge_unlocked'.tr(),
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Badge Details
                if (unlockedBadge != null) ...[
                  _buildBadgeDetails(colorScheme, textTheme),
                  const SizedBox(height: 24),
                ],

                // Thank you message
                Text(
                  'donate.thank_you_message'.tr(),
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Action Buttons
                _buildActionButtons(context, colorScheme, textTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBadge(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: successAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(
                    alpha: 0.3 * glowAnimation.value,
                  ),
                  blurRadius: 20 * glowAnimation.value,
                  spreadRadius: 5 * glowAnimation.value,
                ),
              ],
            ),
            child: unlockedBadge != null
                ? BadgeImageWidget(
                    badge: unlockedBadge!,
                    size: 120,
                    isUnlocked: true,
                  )
                : Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 60,
                      color: colorScheme.onPrimary,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildBadgeDetails(ColorScheme colorScheme, TextTheme textTheme) {
    if (unlockedBadge == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Badge name
        Text(
          unlockedBadge!.name,
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Bible verse section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '"${unlockedBadge!.verse}"',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.9),
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '- ${unlockedBadge!.reference}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      children: [
        // Save badge button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              showSuccessSnackBar('donate.badge_saved'.tr());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.bookmark_add),
            label: Text(
              'donate.save_badge'.tr(),
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Support again button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/donate');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.favorite),
            label: Text(
              'donate.support_again'.tr(),
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
