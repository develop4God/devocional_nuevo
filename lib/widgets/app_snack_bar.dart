import 'package:flutter/material.dart';

/// Visual variant of [AppSnackBar]. Determines background/text color.
enum AppSnackBarType { feedback, tip, error }

/// Single reusable floating snackbar style for the whole app.
///
/// Replaces ad-hoc `ScaffoldMessenger.showSnackBar` calls scattered across
/// pages so every snackbar shares the same shape (floating, rounded corners)
/// and color rules instead of each call site redefining them.
class AppSnackBar {
  AppSnackBar._();

  static const Duration duration = Duration(seconds: 3);

  static void show(
    BuildContext context,
    String message, {
    AppSnackBarType type = AppSnackBarType.feedback,
    IconData? icon,
    Color? iconColor,
    String? title,
    SnackBarAction? action,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = switch (type) {
      AppSnackBarType.tip => colorScheme.primary,
      AppSnackBarType.error => colorScheme.error,
      AppSnackBarType.feedback => colorScheme.secondary,
    };
    final foregroundColor = switch (type) {
      AppSnackBarType.tip => Colors.white,
      AppSnackBarType.error => colorScheme.onError,
      AppSnackBarType.feedback => colorScheme.onSecondary,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: iconColor ?? foregroundColor),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: title == null
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
                        Text(
                          message,
                          style:
                              TextStyle(fontSize: 13, color: foregroundColor),
                        ),
                      ],
                    ),
            ),
          ],
        ),
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: action,
      ),
    );
  }
}
