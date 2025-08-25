import 'package:flutter/material.dart';

/// Widget personalizado para el AppBar de la aplicación.
/// Utiliza los colores y estilos del tema de la app.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.titleText,
    this.bottom,
  });

  @override
  Size get preferredSize {
    // Calcula la altura total del AppBar con el widget inferior.
    final double appBarHeight =
        kToolbarHeight + (bottom?.preferredSize.height ?? 0);
    return Size.fromHeight(appBarHeight);
  }

  @override
  Widget build(BuildContext context) {
    // Obtiene el tema actual para usar sus colores.
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AppBar(
      title: Text(
        titleText,
        style: textTheme.titleLarge?.copyWith(
          // El color del texto se adapta al color de fondo primario.
          color: colorScheme.onPrimary,
        ),
      ),
      // El color de fondo del AppBar es el color primario del tema.
      backgroundColor: colorScheme.primary,
      iconTheme: IconThemeData(
        // El color de los iconos se adapta al color del fondo primario.
        color: colorScheme.onPrimary,
      ),
      // Añade el widget inferior (TabBar) si existe.
      bottom: bottom,
    );
  }
}
