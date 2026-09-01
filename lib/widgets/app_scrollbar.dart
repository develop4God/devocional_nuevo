import 'package:flutter/material.dart';

/// Scrollbar styled with the app's primary color theme (thumb/track color,
/// thickness 10, radius 8), always visible and interactive.
class AppScrollbar extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;

  const AppScrollbar({super.key, required this.child, this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(colorScheme.primary),
        trackColor: WidgetStateProperty.all(
          colorScheme.primary.withAlpha(60),
        ),
        thickness: WidgetStateProperty.all(10),
        radius: const Radius.circular(8),
      ),
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        thickness: 10,
        radius: const Radius.circular(8),
        interactive: true,
        trackVisibility: true,
        child: child,
      ),
    );
  }
}
