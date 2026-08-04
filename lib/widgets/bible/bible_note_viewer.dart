// lib/widgets/bible/bible_note_viewer.dart

import 'package:devocional_nuevo/blocs/bible_note_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_note_event.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Read-only modal widget for viewing a saved note on a Bible verse range.
///
/// Displays the note text and provides an Edit button to open [BibleNoteModal].
/// Single Responsibility: display note content only.
class BibleNoteViewer extends StatelessWidget {
  final String bookName;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final String referenceLabel;
  final String note;
  final VoidCallback onEdit;

  const BibleNoteViewer({
    super.key,
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.referenceLabel,
    required this.note,
    required this.onEdit,
  });

  Future<void> _confirmDeleteNote(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('notes.title'.tr()),
        content: Text('notes.delete_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('notes.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text('app.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      context.read<BibleNoteBloc>().add(
            SaveBibleNoteForRange(
              bookName: bookName,
              chapter: chapter,
              startVerse: startVerse,
              endVerse: endVerse,
              text: null,
            ),
          );
      if (context.mounted) {
        Navigator.of(context).pop();
        AppSnackBar.show(
          context,
          'notes.deleted_message'.tr(),
          icon: Icons.check_circle_outline,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          'notes.save_error'.tr(),
          type: AppSnackBarType.error,
        );
      }
    }
  }

  /// Show the viewer modal in a clean, static way.
  static Future<void> show(
    BuildContext context, {
    required String bookName,
    required int chapter,
    required int startVerse,
    required int endVerse,
    required String referenceLabel,
    required String note,
    required VoidCallback onEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BibleNoteViewer(
        bookName: bookName,
        chapter: chapter,
        startVerse: startVerse,
        endVerse: endVerse,
        referenceLabel: referenceLabel,
        note: note,
        onEdit: onEdit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: mediaQuery.viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: icon + title/reference + close button
          Row(
            children: [
              Icon(
                Icons.note_alt_rounded,
                color: colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'notes.title'.tr(),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      referenceLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _confirmDeleteNote(context),
                tooltip: 'app.delete'.tr(),
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Note content (read-only)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Text(
                note,
                style: textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Buttons: edit + close
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onEdit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'notes.edit'.tr(),
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colorScheme.outline),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'notes.close'.tr(),
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: mediaQuery.viewInsets.bottom > 0 ? 0 : 20),
        ],
      ),
    );
  }
}
