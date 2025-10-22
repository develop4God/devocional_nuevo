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

    return Positioned(
      right: 16,
      top: 120, // Ajusta según tu AppBar + controles
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón cerrar
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Botón A+
              Material(
                color: canIncrease
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: canIncrease ? onIncrease : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'A',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: canIncrease
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                        Icon(
                          Icons.add,
                          size: 16,
                          color: canIncrease
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Indicador de tamaño
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
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

              // Botón A-
              Material(
                color: canDecrease
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: canDecrease ? onDecrease : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'A',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: canDecrease
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                        Icon(
                          Icons.remove,
                          size: 16,
                          color: canDecrease
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
