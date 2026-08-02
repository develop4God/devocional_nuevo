// lib/widgets/bible/bible_notes_list_view.dart

import 'package:devocional_nuevo/blocs/bible_note_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_note_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:devocional_nuevo/pages/app_navigation_shell.dart';
import 'package:devocional_nuevo/widgets/bible/bible_note_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Body content listing Bible verses that have a saved personal note.
///
/// Used as a tab body in [NotesPage].
class BibleNotesListView extends StatelessWidget {
  const BibleNotesListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BibleNoteBloc, BibleNoteState>(
      builder: (context, noteState) {
        if (noteState is BibleNoteLoading || noteState is BibleNoteInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (noteState is BibleNoteError) {
          return _EmptyBibleNotesState(message: noteState.message);
        }

        final notes = (noteState as BibleNoteLoaded)
            .notes
            .where((note) => note.text.trim().isNotEmpty)
            .toList()
          ..sort((a, b) => b.lastModifiedDate.compareTo(a.lastModifiedDate));

        if (notes.isEmpty) return const _EmptyBibleNotesState();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: notes.length,
          itemBuilder: (context, index) => _BibleNoteCard(note: notes[index]),
        );
      },
    );
  }
}

class _EmptyBibleNotesState extends StatelessWidget {
  final String? message;
  const _EmptyBibleNotesState({this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 72,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text('notes.empty_title'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message ?? 'notes.bible_empty_description'.tr(),
                textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _BibleNoteCard extends StatelessWidget {
  final BibleNote note;
  const _BibleNoteCard({required this.note});

  String get _reference => note.startVerse == note.endVerse
      ? '${note.bookName} ${note.chapter}:${note.startVerse}'
      : '${note.bookName} ${note.chapter}:${note.startVerse}-${note.endVerse}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () {
          debugPrint(
            '[BibleNotesListView] tapped note -> book=${note.bookName} '
            'chapter=${note.chapter} verse=${note.startVerse}',
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
          AppNavigationShell.navigateToBibleReference(
            bookName: note.bookName,
            chapter: note.chapter,
            verse: note.startVerse,
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _reference,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(note.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'notes.edit'.tr(),
                icon: Icon(Icons.chat_bubble, color: theme.colorScheme.primary),
                onPressed: () => BibleNoteModal.show(
                  context,
                  bookName: note.bookName,
                  chapter: note.chapter,
                  startVerse: note.startVerse,
                  endVerse: note.endVerse,
                  referenceLabel: _reference,
                  initialNote: note.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
