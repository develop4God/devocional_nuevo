// lib/widgets/notes/note_icons.dart

import 'package:flutter/material.dart';

/// Single source of truth for the note add/view icon pair, so every note
/// tap target (Bible reader, devocionales tab, favorites page, notes page)
/// shows the same icon for the same state.
class NoteIcons {
  const NoteIcons._();

  /// Shown when there is no note yet — opens the editor.
  static const IconData add = Icons.note_add_outlined;

  /// Shown when a note already exists — opens the read-only viewer.
  static const IconData hasNote = Icons.chat_bubble;

  static IconData forState(bool hasNote) =>
      hasNote ? NoteIcons.hasNote : NoteIcons.add;
}
