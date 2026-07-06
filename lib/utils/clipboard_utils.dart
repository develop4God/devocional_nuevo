import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/widgets/app_snack_bar.dart';
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
      AppSnackBar.show(context, 'share.copied_to_clipboard'.tr());
    } catch (e) {
      debugPrint('[ClipboardUtils] Error copying to clipboard: $e');
    }
  }
}
