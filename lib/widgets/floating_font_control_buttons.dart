import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FloatingFontControlButtons extends StatelessWidget {
  final double currentFontSize;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onClose;
  final double minFontSize;
  final double maxFontSize;

  const FloatingFontControlButtons({
    super.key,
    required this.currentFontSize,
    required this.onIncrease,
    required this.onDecrease,
    required this.onClose,
    this.minFontSize = 12.0,
    this.maxFontSize = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canIncrease = currentFontSize < maxFontSize;
    final canDecrease = currentFontSize > minFontSize;

    return Stack(
      children: [
        // Tap outside to close
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onClose,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          right: 24,
          top: 100,
          child: Material(
            color: Colors.transparent,
            elevation: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Close button (small circle)
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: colorScheme.error.withAlpha(90),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      Icons.close_outlined,
                      size: 25,
                      color: colorScheme.error.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Increase font (big circle)
                GestureDetector(
                  onTap: canIncrease ? onIncrease : null,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: canIncrease
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'A+',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: canIncrease
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),

                // Lottie animation for tap feedback
                Lottie.asset(
                  'assets/lottie/tap_screen.json',
                  height: 80,
                  repeat: true,
                  animate: true,
                ),

                // Decrease font (smaller circle) - centrado con los botones más grandes
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: canDecrease ? onDecrease : null,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: canDecrease
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'A-',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: canDecrease
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
