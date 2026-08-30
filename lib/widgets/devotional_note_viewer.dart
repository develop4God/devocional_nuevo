// lib/widgets/devotional_note_viewer.dart

import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/blocs/note_bloc.dart';
import 'package:devocional_nuevo/blocs/note_event.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/widgets/app_snack_bar.dart';
import 'package:devocional_nuevo/widgets/notes/note_viewer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Read-only modal widget for viewing a devotional note.
///
/// Displays the note text and provides an Edit button to open the editor.
/// Single Responsibility: display note content only.
class DevotionalNoteViewer extends StatelessWidget {
  final Devocional devocional;
  final String note;
  final VoidCallback onEdit;

  const DevotionalNoteViewer({
    super.key,
    required this.devocional,
    required this.note,
    required this.onEdit,
  });

  Future<void> _confirmDeleteNote(BuildContext context) async {
    final noteBloc = context.read<NoteBloc>();
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

    if (confirmed != true) return;

    try {
      noteBloc.add(SaveNoteForDevocional(devocional.id, null));
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
    required Devocional devocional,
    required String note,
    required VoidCallback onEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DevotionalNoteViewer(
        devocional: devocional,
        note: note,
        onEdit: onEdit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NoteViewerSheet(
      title: 'notes.title'.tr(),
      note: note,
      onEdit: onEdit,
      onDelete: () => _confirmDeleteNote(context),
    );
  }
}
