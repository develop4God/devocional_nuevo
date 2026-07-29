// lib/widgets/devotional_notes_modal.dart

import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/blocs/note_bloc.dart';
import 'package:devocional_nuevo/blocs/note_event.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/widgets/app_snack_bar.dart';
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
    setState(() {
      _isSaving = true;
    });

    try {
      context.read<NoteBloc>().add(SaveNoteForDevocional(
            widget.devocional.id,
            _noteController.text.trim(),
          ));
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.show(
          context,
          'notes.saved_message'.tr(),
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
      if (mounted) Navigator.of(context).pop();
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
          // Header: icon + title + close button
          Row(
            children: [
              Icon(
                Icons.note_alt_outlined,
                color: colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'notes.title'.tr(),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (widget.initialNote?.trim().isNotEmpty == true)
                IconButton(
                  onPressed: _isSaving ? null : _confirmDeleteNote,
                  tooltip: 'app.delete'.tr(),
                  icon: Icon(
                    Icons.delete_outline,
                    color: colorScheme.error,
                  ),
                ),
              IconButton(
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Text field
          TextField(
            controller: _noteController,
            focusNode: _focusNode,
            maxLines: 8,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            style: textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'notes.hint'.tr(),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colorScheme.outline),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'notes.cancel'.tr(),
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          'notes.save'.tr(),
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
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
