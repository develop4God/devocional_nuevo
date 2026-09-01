import 'package:flutter/material.dart';

/// Visual variant of [AppSnackBar]. Determines background/text color.
enum AppSnackBarType { feedback, tip, error, warning }

/// Single reusable floating snackbar style for the whole app.
///
/// Replaces ad-hoc `ScaffoldMessenger.showSnackBar` calls scattered across
/// pages so every snackbar shares the same shape (floating, rounded corners)
/// and color rules instead of each call site redefining them.
class AppSnackBar {
  AppSnackBar._();

  static const Duration defaultDuration = Duration(seconds: 3);

  static void show(
    BuildContext context,
    String message, {
    AppSnackBarType type = AppSnackBarType.feedback,
    IconData? icon,
    Color? iconColor,
    String? title,
    SnackBarAction? action,
    Duration? duration,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = switch (type) {
      AppSnackBarType.tip => colorScheme.primary,
      AppSnackBarType.error => colorScheme.error,
      AppSnackBarType.warning => Colors.orange.shade800,
      AppSnackBarType.feedback => colorScheme.secondary,
    };
    final foregroundColor = switch (type) {
      AppSnackBarType.tip => Colors.white,
      AppSnackBarType.error => colorScheme.onError,
      AppSnackBarType.warning => Colors.white,
      AppSnackBarType.feedback => colorScheme.onSecondary,
    };

    final textColumn = title == null
        ? Text(message, style: TextStyle(color: foregroundColor))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: foregroundColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(message,
                  style: TextStyle(fontSize: 13, color: foregroundColor)),
            ],
          );

    final row = Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: iconColor ?? foregroundColor),
          const SizedBox(width: 12),
        ],
        Expanded(child: textColumn),
        if (onTap != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IgnorePointer(
              child: Icon(Icons.chevron_right, color: foregroundColor),
            ),
          ),
      ],
    );

    final content = onTap == null
        ? row
        : Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                onTap();
              },
              borderRadius: BorderRadius.circular(8),
              child: row,
            ),
          );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        duration: duration ?? AppSnackBar.defaultDuration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: onTap == null ? action : null,
      ),
    );
  }
}
