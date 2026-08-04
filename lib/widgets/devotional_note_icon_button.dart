// lib/widgets/devotional_note_icon_button.dart

import 'package:devocional_nuevo/blocs/note_bloc.dart';
import 'package:devocional_nuevo/blocs/note_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/widgets/devotional_note_viewer.dart';
import 'package:devocional_nuevo/widgets/devotional_notes_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Icon button for a devotional's personal note, shared across pages that
/// list devotionals (Favorites, Notes) so the icon and tap behavior stay
/// identical everywhere: [Icons.note_add_outlined] opens the editor when
/// there is no note yet, [Icons.sticky_note_2_rounded] opens the read-only
/// viewer (with an edit action) when a note already exists.
class DevotionalNoteIconButton extends StatelessWidget {
  final Devocional devocional;

  const DevotionalNoteIconButton({super.key, required this.devocional});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NoteBloc, NoteState>(
      builder: (context, state) {
        final note = state is NoteLoaded
            ? state.getNoteForDevocional(devocional.id)
            : null;
        final hasNote = note?.isNotEmpty == true;

        return IconButton(
          icon: Icon(
            hasNote ? Icons.sticky_note_2_rounded : Icons.note_add_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: hasNote ? 'notes.view_action'.tr() : 'notes.add_action'.tr(),
          onPressed: () => _handleTap(context, hasNote, note),
        );
      },
    );
  }

  void _handleTap(BuildContext context, bool hasNote, String? note) {
    if (hasNote) {
      DevotionalNoteViewer.show(
        context,
        devocional: devocional,
        note: note!,
        onEdit: () => DevotionalNotesModal.show(
          context,
          devocional: devocional,
          initialNote: note,
        ),
      );
    } else {
      DevotionalNotesModal.show(context, devocional: devocional);
    }
  }
}
