import 'package:devocional_nuevo/blocs/note_bloc.dart';
import 'package:devocional_nuevo/blocs/note_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/pages/app_navigation_shell.dart';
import 'package:devocional_nuevo/pages/favorite_devocional_detail_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/app_bottom_nav_bar.dart';
import 'package:devocional_nuevo/widgets/app_snack_bar.dart';
import 'package:devocional_nuevo/widgets/delete_confirmation_dialog.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/devotional_note_viewer.dart';
import 'package:devocional_nuevo/widgets/devotional_notes_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Lists the devotionals that have a saved personal note, regardless of their
/// favorite status.
class DevocionalesNotesPage extends StatelessWidget {
  const DevocionalesNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: Scaffold(
        appBar: CustomAppBar(titleText: 'drawer.my_notes'.tr()),
        body: BlocBuilder<NoteBloc, NoteState>(
          builder: (context, noteState) {
            if (noteState is NoteLoading || noteState is NoteInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (noteState is NoteError) {
              return _EmptyNotesState(message: noteState.message);
            }

            final noteIds = (noteState as NoteLoaded)
                .notes
                .where((note) => note.text.trim().isNotEmpty)
                .map((note) => note.devocionalId)
                .toSet();
            return Consumer<DevocionalProvider>(
              builder: (context, provider, _) {
                final devotionals = provider.allDevocionalesForCurrentLanguage
                    .where((devocional) => noteIds.contains(devocional.id))
                    .toList();
                if (devotionals.isEmpty) return const _EmptyNotesState();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: devotionals.length,
                  itemBuilder: (context, index) =>
                      _DevotionalNoteCard(devocional: devotionals[index]),
                );
              },
            );
          },
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentTab: null,
          onSelectTab: (tab) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            AppNavigationShell.selectTab(tab);
          },
        ),
      ),
    );
  }
}

class _EmptyNotesState extends StatelessWidget {
  final String? message;
  const _EmptyNotesState({this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sticky_note_2_outlined,
                size: 72,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text('notes.empty_title'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message ?? 'notes.empty_description'.tr(),
                textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _DevotionalNoteCard extends StatelessWidget {
  final Devocional devocional;
  const _DevotionalNoteCard({required this.devocional});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DevocionalProvider>();
    final isFavorite = provider.isFavorite(devocional);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FavoriteDevocionalDetailPage(
              devocional: devocional,
              titleKey: 'drawer.my_notes',
            ),
          ),
        ),
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
                      DateFormat(
                        'EEEE, d MMMM yyyy',
                        getService<LocalizationService>()
                            .currentLocale
                            .languageCode,
                      ).format(devocional.date),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(devocional.versiculo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.sticky_note_2_rounded,
                    color: theme.colorScheme.primary),
                onPressed: () => _openNote(context),
              ),
              IconButton(
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color:
                      isFavorite ? Colors.redAccent : theme.colorScheme.primary,
                ),
                onPressed: () => _toggleFavorite(context, provider, isFavorite),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNote(BuildContext context) {
    final state = context.read<NoteBloc>().state;
    final note =
        state is NoteLoaded ? state.getNoteForDevocional(devocional.id) : null;
    if (note == null || note.isEmpty) return;
    DevotionalNoteViewer.show(
      context,
      devocional: devocional,
      note: note,
      onEdit: () => DevotionalNotesModal.show(
        context,
        devocional: devocional,
        initialNote: note,
      ),
    );
  }

  Future<void> _toggleFavorite(BuildContext context,
      DevocionalProvider provider, bool isFavorite) async {
    if (isFavorite) {
      final confirmed = await DeleteConfirmationDialog.show(
        context: context,
        titleKey: 'devotionals.remove_from_favorites',
        contentKey: 'devotionals.remove_from_favorites_confirmation',
      );
      if (!confirmed || !context.mounted) return;
    }
    final wasAdded = await provider.toggleFavorite(devocional.id);
    if (context.mounted && wasAdded) {
      AppSnackBar.show(context, 'devotionals_page.added_to_favorites'.tr());
    }
  }
}
