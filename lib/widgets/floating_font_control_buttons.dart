import 'package:flutter/material.dart';

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
          bottom: 24,
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
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: colorScheme.outline.withAlpha(40),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: colorScheme.onSurface.withOpacity(0.6),
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
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.12),
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
                              : colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Font size indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentFontSize.toInt().toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Decrease font (smaller circle)
                GestureDetector(
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
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.12),
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
                              : colorScheme.onSurface.withOpacity(0.3),
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
