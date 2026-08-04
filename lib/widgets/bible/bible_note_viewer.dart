// lib/widgets/bible/bible_note_viewer.dart

import 'package:devocional_nuevo/blocs/bible_note_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_note_event.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/widgets/app_snack_bar.dart';
import 'package:devocional_nuevo/widgets/notes/note_viewer_sheet.dart';
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
    return NoteViewerSheet(
      title: 'notes.title'.tr(),
      subtitle: referenceLabel,
      note: note,
      onEdit: onEdit,
      onDelete: () => _confirmDeleteNote(context),
    );
  }
}
