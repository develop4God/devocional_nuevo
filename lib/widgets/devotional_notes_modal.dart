// lib/widgets/devotional_notes_modal.dart

import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/blocs/note_bloc.dart';
import 'package:devocional_nuevo/blocs/note_event.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/widgets/app_snack_bar.dart';
import 'package:devocional_nuevo/widgets/notes/note_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Stateful modal widget for editing notes on a devotional.
///
/// Encapsulates the notes editor UI and lifecycle (auto-focus, save/cancel flow).
/// Handles persistence through [NoteBloc].
/// Displays feedback via SnackBar (success/error).
class DevotionalNotesModal extends StatefulWidget {
  final Devocional devocional;
  final String? initialNote;

  const DevotionalNotesModal({
    super.key,
    required this.devocional,
    this.initialNote,
  });

  /// Show the modal in a clean, static way.
  static Future<void> show(
    BuildContext context, {
    required Devocional devocional,
    String? initialNote,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DevotionalNotesModal(
        devocional: devocional,
        initialNote: initialNote,
      ),
    );
  }

  @override
  State<DevotionalNotesModal> createState() => _DevotionalNotesModalState();
}

class _DevotionalNotesModalState extends State<DevotionalNotesModal> {
  late TextEditingController _noteController;
  late FocusNode _focusNode;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _focusNode = FocusNode();

    // Auto-focus text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final text = _noteController.text.trim();

    setState(() => _errorMessage = null);

    if (text.isEmpty) {
      setState(() => _errorMessage = 'notes.enter_note_text_error'.tr());
      return;
    }

    if (text.length < 10) {
      setState(() => _errorMessage = 'notes.note_min_length_error'.tr());
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final isNewNote = widget.initialNote?.trim().isEmpty ?? true;

    try {
      context.read<NoteBloc>().add(SaveNoteForDevocional(
            widget.devocional.id,
            text,
          ));
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.show(
          context,
          isNewNote ? 'notes.added_message'.tr() : 'notes.saved_message'.tr(),
          icon: Icons.check_circle_outline,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        AppSnackBar.show(
          context,
          'notes.save_error'.tr(),
          type: AppSnackBarType.error,
        );
      }
    }
  }

  Future<void> _confirmDeleteNote() async {
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

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);

    try {
      context.read<NoteBloc>().add(
            SaveNoteForDevocional(widget.devocional.id, null),
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.show(
          context,
          'notes.deleted_message'.tr(),
          icon: Icons.check_circle_outline,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.show(
          context,
          'notes.save_error'.tr(),
          type: AppSnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NoteEditorSheet(
      title: 'notes.title'.tr(),
      controller: _noteController,
      focusNode: _focusNode,
      errorMessage: _errorMessage,
      isSaving: _isSaving,
      showDelete: widget.initialNote?.trim().isNotEmpty == true,
      onDelete: _confirmDeleteNote,
      onSave: _saveNote,
    );
  }
}
