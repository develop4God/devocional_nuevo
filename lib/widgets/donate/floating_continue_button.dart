// lib/widgets/donate/floating_continue_button.dart
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

class FloatingContinueButton extends StatelessWidget {
  final AnimationController animationController;
  final Animation<double> buttonSlideAnimation;
  final bool isProcessing;
  final bool isTestMode;
  final VoidCallback? onPressed;

  const FloatingContinueButton({
    required this.animationController,
    required this.buttonSlideAnimation,
    required this.isProcessing,
    required this.isTestMode,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 100 * (1 - buttonSlideAnimation.value)),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface.withValues(alpha: 0.0),
                    colorScheme.surface.withValues(alpha: 0.8),
                    colorScheme.surface,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: _buildContinueButton(colorScheme, textTheme),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContinueButton(ColorScheme colorScheme, TextTheme textTheme) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isProcessing ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: colorScheme.primary.withValues(alpha: 0.4),
        ),
        child: isProcessing
            ? _buildProcessingContent(colorScheme, textTheme)
            : _buildNormalContent(colorScheme, textTheme),
      ),
    );
  }

  Widget _buildProcessingContent(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'donate.processing_payment'.tr(),
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildNormalContent(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isTestMode ? Icons.science : Icons.payment,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          isTestMode
              ? 'TEST: Simular Donación'
              : 'donate.continue_to_payment'.tr(),
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
