import 'package:flutter/material.dart';

/// One-time notice for English readers explaining the KJV/KJ2000 relabeling
/// fix. English-only by design — not routed through the translation system.
///
/// Tapping the banner opens the drawer menu ([onOpenDrawer]) so the reader
/// can pick KJ2000 themselves.
class KjvKj2000Banner extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onOpenDrawer;

  const KjvKj2000Banner({
    super.key,
    required this.onDismiss,
    required this.onOpenDrawer,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onOpenDrawer,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: colorScheme.secondary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 13,
                        height: 1.35,
                      ),
                      children: [
                        const TextSpan(
                          text: "The version labeled KJV was actually the "
                              "KJ2000 text. We've corrected this: KJV now "
                              "shows the authentic King James Version. If "
                              "you'd like to keep reading the KJ2000 text, "
                              "open the menu ",
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Icons.menu,
                            size: 15,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const TextSpan(
                          text: " in the top-left corner and choose KJ2000.",
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon:
                      Icon(Icons.close, size: 18, color: colorScheme.secondary),
                  tooltip: 'Close',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
