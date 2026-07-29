import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

class DeleteConfirmationDialog {
  static Future<bool> show({
    required BuildContext context,
    required String titleKey,
    required String contentKey,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titleKey.tr()),
        content: Text(contentKey.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('app.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(titleKey.tr()),
          ),
        ],
      ),
    ).then((confirmed) => confirmed ?? false);
  }
}
