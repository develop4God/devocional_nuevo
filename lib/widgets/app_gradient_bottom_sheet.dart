import 'package:flutter/material.dart';

/// AppGradientBottomSheet
///
/// Contenedor reutilizable para modales inferiores (bottom sheets) que
/// aplica el mismo gradiente, borde y sombra que `AppGradientDialog`,
/// pero pensado para ser mostrado con `showModalBottomSheet(..., backgroundColor: Colors.transparent)`.
///
/// Por defecto envuelve el `child` en un [Material] transparente para que
/// `InkWell` y otros efectos de material funcionen sin que el llamador tenga
/// que envolver manualmente el contenido.
class AppGradientBottomSheet extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double maxHeight;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final double borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final bool useMaterial;

  const AppGradientBottomSheet({
    super.key,
    required this.child,
    this.maxWidth = double.infinity,
    this.maxHeight = 420,
    this.padding = const EdgeInsets.all(24),
    this.backgroundColor,
    this.gradientColors,
    this.borderRadius = 28,
    this.borderColor,
    this.borderWidth = 2,
    this.useMaterial = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? colorScheme.surface.withAlpha(255);
    final gradColors = gradientColors ??
        [
          colorScheme.primary.withAlpha(245),
          colorScheme.secondary.withAlpha(245),
          colorScheme.surface.withAlpha(255),
        ];
    final bColor = borderColor ?? Colors.white.withAlpha(200);

    Widget content = SingleChildScrollView(child: child);

    if (useMaterial) {
      content = Material(type: MaterialType.transparency, child: content);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        // Limitar ancho máximo y alto del sheet para que se comporte bien en pantallas grandes
        maxWidth: maxWidth,
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Container(
        // Usar el ancho disponible del parent (p. ej. el padding exterior dado en showModalBottomSheet)
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          gradient: LinearGradient(
            colors: gradColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          // Solo esquinas superiores redondeadas para que parezca un bottom sheet
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(borderRadius)),
          border: Border.all(color: bColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withAlpha(80),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: padding,
        child: content,
      ),
    );
  }
}
