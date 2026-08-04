// lib/widgets/bible/bible_note_modal.dart

import 'package:devocional_nuevo/blocs/bible_note_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_note_event.dart';
import 'package:devocional_nuevo/blocs/bible_note_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/widgets/app_snack_bar.dart';
import 'package:devocional_nuevo/widgets/notes/note_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Stateful modal widget for viewing and editing a note on a Bible verse
/// range.
///
/// Encapsulates the notes editor UI and lifecycle (auto-focus, save/cancel
/// flow). Handles persistence through [BibleNoteBloc].
class BibleNoteModal extends StatefulWidget {
  final String bookName;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final String referenceLabel;
  final String? initialNote;

  const BibleNoteModal({
    super.key,
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.referenceLabel,
    this.initialNote,
  });

  /// Show the modal in a clean, static way.
  static Future<void> show(
    BuildContext context, {
    required String bookName,
    required int chapter,
    required int startVerse,
    required int endVerse,
    required String referenceLabel,
    String? initialNote,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BibleNoteModal(
        bookName: bookName,
        chapter: chapter,
        startVerse: startVerse,
        endVerse: endVerse,
        referenceLabel: referenceLabel,
        initialNote: initialNote,
      ),
    );
  }

  @override
  State<BibleNoteModal> createState() => _BibleNoteModalState();
}

class _BibleNoteModalState extends State<BibleNoteModal> {
  late TextEditingController _noteController;
  late FocusNode _focusNode;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _focusNode = FocusNode();

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

  void _saveNote() {
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
      _isDeleting = false;
    });

    context.read<BibleNoteBloc>().add(
          SaveBibleNoteForRange(
            bookName: widget.bookName,
            chapter: widget.chapter,
            startVerse: widget.startVerse,
            endVerse: widget.endVerse,
            text: text,
          ),
        );
    // Navigation and snackbar now handled by the BlocListener in build().
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

    setState(() {
      _isSaving = true;
      _isDeleting = true;
    });

    context.read<BibleNoteBloc>().add(
          SaveBibleNoteForRange(
            bookName: widget.bookName,
            chapter: widget.chapter,
            startVerse: widget.startVerse,
            endVerse: widget.endVerse,
            text: null,
          ),
        );
    // Navigation and snackbar now handled by the BlocListener in build().
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BibleNoteBloc, BibleNoteState>(
      listener: (context, state) {
        if (!_isSaving) return;
        if (state is BibleNoteLoaded) {
          setState(() => _isSaving = false);
          Navigator.of(context).pop();
          final isNewNote = widget.initialNote?.trim().isEmpty ?? true;
          AppSnackBar.show(
            context,
            _isDeleting
                ? 'notes.deleted_message'.tr()
                : (isNewNote
                    ? 'notes.added_message'.tr()
                    : 'notes.saved_message'.tr()),
            icon: Icons.check_circle_outline,
          );
        } else if (state is BibleNoteError) {
          setState(() => _isSaving = false);
          AppSnackBar.show(
            context,
            state.message,
            type: AppSnackBarType.error,
          );
        }
      },
      child: NoteEditorSheet(
        title: 'notes.title'.tr(),
        subtitle: widget.referenceLabel,
        controller: _noteController,
        focusNode: _focusNode,
        errorMessage: _errorMessage,
        isSaving: _isSaving,
        showDelete: widget.initialNote?.trim().isNotEmpty == true,
        onDelete: _confirmDeleteNote,
        onSave: _saveNote,
      ),
    );
  }
}
