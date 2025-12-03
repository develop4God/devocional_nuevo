import 'package:flutter/material.dart';

class AppGradientDialog extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double maxHeight;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final double borderRadius;
  final Color? borderColor;
  final double borderWidth;

  const AppGradientDialog({
    super.key,
    required this.child,
    this.maxWidth = 420,
    this.maxHeight = 420,
    this.padding = const EdgeInsets.all(24),
    this.backgroundColor,
    this.gradientColors,
    this.borderRadius = 28,
    this.borderColor,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor =
        backgroundColor ?? colorScheme.surface.withAlpha(240); // más oscuro
    final gradColors = gradientColors ??
        [
          colorScheme.primary.withAlpha(220),
          colorScheme.secondary.withAlpha(230),
          colorScheme.surface.withAlpha(240),
        ];
    final bColor = borderColor ?? Colors.white.withAlpha(200);
    return SafeArea(
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.of(context).maybePop();
            },
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {}, // Para evitar que el tap dentro cierre el modal
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  gradient: LinearGradient(
                    colors: gradColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(color: bColor, width: borderWidth),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(80),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                padding: padding,
                child: SingleChildScrollView(child: child),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
