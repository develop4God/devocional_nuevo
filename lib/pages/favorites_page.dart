// lib/pages/favorites_page.dart

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/blocs/note_bloc.dart';
import 'package:devocional_nuevo/blocs/note_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/pages/app_navigation_shell.dart';
import 'package:devocional_nuevo/pages/discovery_bible_studies/discovery_detail_page.dart';
import 'package:devocional_nuevo/pages/favorite_devocional_detail_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/widgets/app_bottom_nav_bar.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/devocionales/devotional_favorite_card.dart';
import 'package:devocional_nuevo/widgets/devotional_note_viewer.dart';
import 'package:devocional_nuevo/widgets/devotional_notes_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:devocional_nuevo/widgets/delete_confirmation_dialog.dart';

class FavoritesPage extends StatefulWidget {
  final int initialIndex;

  const FavoritesPage({super.key, this.initialIndex = 0});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: Scaffold(
        appBar: CustomAppBar(titleText: 'favorites.title'.tr()),
        body: Column(
          children: [
            // Container para las tabs (Estilo Prayer Page)
            Container(
              color: colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
                // Changed alpha from 0.6 to 0.3 for a lighter, less dark gray
                unselectedLabelColor: colorScheme.onSurface.withValues(
                  alpha: 0.3,
                ),
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    height: 72,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_rounded, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          'navigation.devotional'.tr(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    height: 72,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          'discovery.discovery_studies'.tr(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDevotionalsFavorites(context, theme),
                  _buildBibleStudiesFavorites(context, theme),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentTab: null,
          onSelectTab: (tab) {
            // Favorites is pushed over the shell (from the drawer, progress
            // page, or discovery list); pop back to it before switching tabs.
            Navigator.of(context).popUntil((route) => route.isFirst);
            AppNavigationShell.selectTab(tab);
          },
        ),
      ),
    );
  }

  Widget _buildDevotionalsFavorites(BuildContext context, ThemeData theme) {
    return Consumer<DevocionalProvider>(
      builder: (context, devocionalProvider, child) {
        final List<Devocional> favoriteDevocionales =
            devocionalProvider.favoriteDevocionales;

        if (favoriteDevocionales.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icon(
              Icons.favorite_border_rounded,
              size: 72,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            title: 'favorites.empty_title'.tr(),
            message: 'favorites.empty_description'.tr(),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: favoriteDevocionales.length,
          itemBuilder: (context, index) {
            final devocional = favoriteDevocionales[index];
            return _buildDevotionalCard(
              context,
              devocional,
              devocionalProvider,
            );
          },
        );
      },
    );
  }

  Widget _buildBibleStudiesFavorites(BuildContext context, ThemeData theme) {
    return BlocConsumer<DiscoveryBloc, DiscoveryState>(
      listener: (context, state) {
        // Listener fires on state changes only
        // Initial state handling is done in builder
      },
      builder: (context, state) {
        // Handle initial state - trigger load immediately
        if (state is DiscoveryInitial) {
          // Dispatch event on first build when in initial state
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.read<DiscoveryBloc>().add(LoadDiscoveryStudies());
            }
          });
          return const Center(child: CircularProgressIndicator());
        }

        // Handle loading state
        if (state is DiscoveryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle loaded state
        if (state is DiscoveryLoaded) {
          final favoritedIds = state.favoriteStudyIds.toList();

          if (favoritedIds.isEmpty) {
            return _buildEmptyState(
              context,
              icon: Icon(
                Icons.star_outline_rounded,
                size: 72,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              ),
              title: 'discovery.no_favorites_title'.tr(),
              message: 'discovery.no_favorites_description'.tr(),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favoritedIds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final id = favoritedIds[index];
              final title = state.studyTitles[id] ?? id;
              final emoji = state.studyEmojis[id] ?? '📖';
              final isCompleted = state.completedStudies[id] ?? false;

              return _buildMinimalistStudyRow(
                context,
                id,
                title,
                emoji,
                isCompleted,
                theme,
              );
            },
          );
        }

        // Handle error state
        if (state is DiscoveryError) {
          return _buildEmptyState(
            context,
            icon: Icon(
              Icons.error_outline,
              size: 72,
              color: theme.colorScheme.error,
            ),
            title: 'discovery.error'.tr(),
            message: state.localizedMessage,
          );
        }

        // Fallback for unknown states
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildDevotionalCard(
    BuildContext context,
    Devocional devocional,
    DevocionalProvider provider,
  ) {
    return DevotionalFavoriteCard(
      devocional: devocional,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => FavoriteDevocionalDetailPage(devocional: devocional),
        ),
      ),
      actions: [
        BlocBuilder<NoteBloc, NoteState>(
          builder: (context, state) {
            final note = state is NoteLoaded
                ? state.getNoteForDevocional(devocional.id)
                : null;
            return IconButton(
              icon: Icon(
                note?.isNotEmpty == true
                    ? Icons.sticky_note_2_rounded
                    : Icons.sticky_note_2_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => _handleNoteIconTap(context, devocional, note),
            );
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.favorite_rounded,
            color: Colors.redAccent,
          ),
          onPressed: () =>
              _showRemoveFavoriteConfirmation(context, devocional, provider),
        ),
      ],
    );
  }

  void _handleNoteIconTap(
    BuildContext context,
    Devocional devocional,
    String? note,
  ) {
    // If note exists and is not empty, show viewer (read-only)
    if (note != null && note.isNotEmpty) {
      DevotionalNoteViewer.show(
        context,
        devocional: devocional,
        note: note,
        onEdit: () => _showNoteEditor(context, devocional),
      );
    } else {
      // If no note, show editor directly
      _showNoteEditor(context, devocional);
    }
  }

  void _showNoteEditor(BuildContext context, Devocional devocional) {
    final state = context.read<NoteBloc>().state;
    DevotionalNotesModal.show(
      context,
      devocional: devocional,
      initialNote: state is NoteLoaded
          ? state.getNoteForDevocional(devocional.id)
          : null,
    );
  }

  Future<void> _showRemoveFavoriteConfirmation(
    BuildContext context,
    Devocional devocional,
    DevocionalProvider provider,
  ) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context: context,
      titleKey: 'devotionals.remove_from_favorites',
      contentKey: 'devotionals.remove_from_favorites_confirmation',
    );

    if (confirmed && context.mounted) {
      provider.toggleFavorite(devocional.id);
    }
  }

  Future<void> _showRemoveStudyFavoriteConfirmation(
    BuildContext context,
    String id,
  ) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context: context,
      titleKey: 'devotionals.remove_from_favorites',
      contentKey: 'discovery.remove_from_favorites_confirmation',
    );

    if (confirmed && context.mounted) {
      context.read<DiscoveryBloc>().add(ToggleDiscoveryFavorite(id));
    }
  }

  Widget _buildMinimalistStudyRow(
    BuildContext context,
    String id,
    String title,
    String emoji,
    bool isCompleted,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () {
          final languageCode =
              context.read<DevocionalProvider>().selectedLanguage;
          context.read<DiscoveryBloc>().add(
                LoadDiscoveryStudy(id, languageCode: languageCode),
              );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => DiscoveryDetailPage(studyId: id)),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: -0.5,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'discovery.completed'.tr().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.green,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                  size: 30,
                ),
                onPressed: () => _showRemoveStudyFavoriteConfirmation(
                  context,
                  id,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required Widget icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(opacity: 0.5, child: icon),
            const SizedBox(height: 24),
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
