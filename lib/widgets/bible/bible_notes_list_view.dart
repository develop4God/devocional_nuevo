// lib/widgets/bible/bible_notes_list_view.dart

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/bible_note_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_note_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/bible_note.dart';
import 'package:devocional_nuevo/pages/app_navigation_shell.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/widgets/bible/bible_note_modal.dart';
import 'package:devocional_nuevo/widgets/bible/bible_note_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Body content listing Bible verses that have a saved personal note.
///
/// Used as a tab body in [NotesPage].
class BibleNotesListView extends StatefulWidget {
  const BibleNotesListView({super.key});

  @override
  State<BibleNotesListView> createState() => _BibleNotesListViewState();
}

class _BibleNotesListViewState extends State<BibleNotesListView> {
  String? _language;
  Future<Map<String, String>>? _bookNamesFuture;

  /// Maps short book names (as stored on [BibleNote]) to full book names,
  /// e.g. "Gn" -> "Génesis". Read from the first available Bible version's
  /// database for the app's current language.
  Future<Map<String, String>> _loadBookNames(String appLanguage) async {
    try {
      var versions = await BibleVersionRegistry.getVersionsForLanguage(
        appLanguage,
      );
      if (versions.isEmpty) {
        versions = await BibleVersionRegistry.getVersionsForLanguage('es');
      }
      if (versions.isEmpty) return {};

      final version = versions.first;
      version.service ??= BibleDbService();
      await version.service!.initDb(version.assetPath, version.dbFileName);
      final books = await version.service!.getAllBooks();

      return {
        for (final book in books)
          book['short_name'] as String: book['long_name'] as String,
      };
    } catch (e) {
      debugPrint('[BibleNotesListView] Failed to load book names: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final String language = context.select<DevocionalProvider, String>(
      (p) => p.selectedLanguage,
    );
    if (language != _language) {
      _language = language;
      _bookNamesFuture = _loadBookNames(language);
    }

    return FutureBuilder<Map<String, String>>(
      future: _bookNamesFuture,
      builder: (context, bookNamesSnapshot) {
        final bookNames = bookNamesSnapshot.data ?? const {};

        return BlocBuilder<BibleNoteBloc, BibleNoteState>(
          builder: (context, noteState) {
            if (noteState is BibleNoteLoading ||
                noteState is BibleNoteInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (noteState is BibleNoteError) {
              return _EmptyBibleNotesState(message: noteState.message);
            }

            final notes = (noteState as BibleNoteLoaded)
                .notes
                .where((note) => note.text.trim().isNotEmpty)
                .toList()
              ..sort(
                (a, b) => b.lastModifiedDate.compareTo(a.lastModifiedDate),
              );

            if (notes.isEmpty) return const _EmptyBibleNotesState();

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: notes.length,
              itemBuilder: (context, index) => _BibleNoteCard(
                note: notes[index],
                bookNames: bookNames,
              ),
            );
          },
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
  final Map<String, String> bookNames;
  const _BibleNoteCard({required this.note, required this.bookNames});

  String get _reference {
    final bookName = bookNames[note.bookName] ?? note.bookName;
    return note.startVerse == note.endVerse
        ? '$bookName ${note.chapter}:${note.startVerse}'
        : '$bookName ${note.chapter}:${note.startVerse}-${note.endVerse}';
  }

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
                tooltip: 'notes.title'.tr(),
                icon: Icon(Icons.chat_bubble, color: theme.colorScheme.primary),
                onPressed: () => BibleNoteViewer.show(
                  context,
                  bookName: note.bookName,
                  chapter: note.chapter,
                  startVerse: note.startVerse,
                  endVerse: note.endVerse,
                  referenceLabel: _reference,
                  note: note.text,
                  onEdit: () => BibleNoteModal.show(
                    context,
                    bookName: note.bookName,
                    chapter: note.chapter,
                    startVerse: note.startVerse,
                    endVerse: note.endVerse,
                    referenceLabel: _reference,
                    initialNote: note.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
