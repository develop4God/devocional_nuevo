// lib/pages/notes_page.dart

import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/pages/app_navigation_shell.dart';
import 'package:devocional_nuevo/pages/devocionales_notes_page.dart';
import 'package:devocional_nuevo/widgets/app_bottom_nav_bar.dart';
import 'package:devocional_nuevo/widgets/bible/bible_notes_list_view.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Shows the user's personal notes, split into a "Devotional" tab and a
/// "Bible" tab, mirroring [FavoritesPage]'s tab layout.
class NotesPage extends StatefulWidget {
  final int initialIndex;

  const NotesPage({super.key, this.initialIndex = 0});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage>
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
    final colorScheme = Theme.of(context).colorScheme;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: Scaffold(
        appBar: CustomAppBar(titleText: 'drawer.my_notes'.tr()),
        body: Column(
          children: [
            Container(
              color: colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
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
                        const Icon(Icons.auto_stories_outlined, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          'bible.title'.tr(),
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
                children: const [
                  DevocionalNotesListView(),
                  BibleNotesListView(),
                ],
              ),
            ),
          ],
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
