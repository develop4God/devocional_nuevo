import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClipboardUtils {
  ClipboardUtils._();

  static Future<void> copyWithFeedback(
    BuildContext context,
    String text,
  ) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!context.mounted) return;
      HapticFeedback.selectionClick();
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colorScheme.secondary,
          duration: const Duration(seconds: 2),
          content: Text(
            'share.copied_to_clipboard'.tr(),
            style: TextStyle(color: colorScheme.onSecondary),
          ),
        ),
      );
    } catch (e) {
      debugPrint('[ClipboardUtils] Error copying to clipboard: $e');
    }
  }
}
