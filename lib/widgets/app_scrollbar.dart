import 'package:flutter/material.dart';

/// Scrollbar styled with the app's primary color theme (thumb/track color,
/// thickness 10, radius 8), always visible and interactive.
class AppScrollbar extends StatelessWidget {
  final Widget child;
  // Required, not nullable: Scrollbar.thumbVisibility:true with no explicit
  // controller falls back to the implicit PrimaryScrollController, which
  // throws "attached to more than one ScrollPosition" if more than one
  // no-controller scrollable is mounted in the same route scope at once.
  // Forcing every call site to supply its own controller makes that a
  // compile-time requirement instead of a silent runtime crash.
  final ScrollController controller;

  const AppScrollbar(
      {super.key, required this.child, required this.controller});

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
