// lib/pages/discovery_list_page.dart

import 'package:card_swiper/card_swiper.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/pages/devotional_discovery/widgets/devotional_card_premium.dart';
import 'package:devocional_nuevo/pages/discovery_detail_page.dart';
import 'package:devocional_nuevo/pages/favorites_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

/// Modern Discovery Studies page with carousel-based premium card experience
class DiscoveryListPage extends StatefulWidget {
  const DiscoveryListPage({super.key});

  @override
  State<DiscoveryListPage> createState() => _DiscoveryListPageState();
}

class _DiscoveryListPageState extends State<DiscoveryListPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _showGridOverlay = false;
  late AnimationController _gridAnimationController;
  final SwiperController _swiperController = SwiperController();

  @override
  void initState() {
    super.initState();
    final languageCode = context.read<DevocionalProvider>().selectedLanguage;
    context
        .read<DiscoveryBloc>()
        .add(LoadDiscoveryStudies(languageCode: languageCode));

    _gridAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _gridAnimationController.dispose();
    _swiperController.dispose();
    super.dispose();
  }

  void _toggleGridOverlay() {
    setState(() {
      _showGridOverlay = !_showGridOverlay;
      if (_showGridOverlay) {
        _gridAnimationController.forward();
      } else {
        _gridAnimationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleText: 'discovery.discovery_studies'.tr(),
        actions: [
          IconButton(
            icon:
                Icon(_showGridOverlay ? Icons.view_carousel : Icons.grid_view),
            onPressed: _toggleGridOverlay,
            tooltip: _showGridOverlay ? 'Carousel View' : 'Grid View',
          ),
        ],
      ),
      body: BlocBuilder<DiscoveryBloc, DiscoveryState>(
        builder: (context, state) {
          if (state is DiscoveryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DiscoveryError) {
            return _buildErrorState(context, state.message);
          }
          if (state is DiscoveryLoaded) {
            if (state.availableStudyIds.isEmpty) {
              return _buildEmptyState(context);
            }

            final sortedIds = List<String>.from(state.availableStudyIds);
            sortedIds.sort((a, b) {
              final aCompleted = state.completedStudies[a] ?? false;
              final bCompleted = state.completedStudies[b] ?? false;
              if (aCompleted && !bCompleted) return 1;
              if (!aCompleted && bCompleted) return -1;
              return 0;
            });

            return Stack(
              children: [
                Column(
                  children: [
                    _buildProgressDots(sortedIds.length),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildCarousel(context, state, sortedIds),
                    ),
                    _buildActionBar(context, state, sortedIds),
                    // We add extra space at bottom for the global navigation overlay if needed
                    const SizedBox(height: 20),
                  ],
                ),
                if (_showGridOverlay)
                  _buildGridOverlay(context, state, sortedIds),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProgressDots(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentIndex == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentIndex == index
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.withAlpha(128),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel(
      BuildContext context, DiscoveryLoaded state, List<String> studyIds) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Swiper(
      controller: _swiperController,
      itemBuilder: (context, index) {
        final studyId = studyIds[index];
        final title = state.studyTitles[studyId] ?? _formatStudyTitle(studyId);
        final subtitle = state.studySubtitles[studyId]; // Added
        final emoji = state.studyEmojis[studyId];
        final readingMinutes = state.studyReadingMinutes[studyId]; // Added
        final isCompleted = state.completedStudies[studyId] ?? false;
        final isFavorite = state.favoriteStudyIds.contains(studyId);

        final mockDevocional = _createMockDevocional(studyId, emoji: emoji);

        return DevotionalCardPremium(
          devocional: mockDevocional,
          title: title,
          subtitle: subtitle, // Added
          readingMinutes: readingMinutes, // Added
          isFavorite: isFavorite,
          isCompleted: isCompleted,
          isDark: isDark,
          onTap: () => _navigateToDetail(context, studyId),
          onFavoriteToggle: () {
            context.read<DiscoveryBloc>().add(ToggleDiscoveryFavorite(studyId));
          },
        );
      },
      itemCount: studyIds.length,
      viewportFraction: 0.85,
      scale: 0.9,
      curve: Curves.easeInOutCubic,
      onIndexChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      layout: SwiperLayout.STACK,
      itemWidth: MediaQuery.of(context).size.width * 0.85,
      itemHeight: MediaQuery.of(context).size.height * 0.6,
    );
  }

  Widget _buildActionBar(
      BuildContext context, DiscoveryLoaded state, List<String> studyIds) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentStudyId = studyIds[_currentIndex];
    final currentTitle =
        state.studyTitles[currentStudyId] ?? _formatStudyTitle(currentStudyId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: () {
                  SharePlus.instance.share(
                      'Check out this Bible Study: $currentTitle'
                          as ShareParams);
                },
                colorScheme: colorScheme),
            _buildActionButton(
                icon: Icons.star_rounded,
                label: 'Favorites',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FavoritesPage(initialIndex: 1),
                    ),
                  );
                },
                colorScheme: colorScheme),
            _buildActionButton(
              icon: Icons.auto_stories_rounded,
              label: 'Read',
              onTap: () => _navigateToDetail(context, currentStudyId),
              colorScheme: colorScheme,
              isPrimary: true,
            ),
            _buildActionButton(
                icon: Icons.arrow_forward_rounded,
                label: 'Next',
                onTap: () {
                  _swiperController.next();
                },
                colorScheme: colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary
                    ? colorScheme.primary
                    : colorScheme.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isPrimary ? Colors.white : colorScheme.primary,
                  size: 24),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface,
                    fontWeight:
                        isPrimary ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildGridOverlay(
      BuildContext context, DiscoveryLoaded state, List<String> studyIds) {
    return AnimatedBuilder(
      animation: _gridAnimationController,
      builder: (context, child) {
        return Container(
          color: Colors.black
              .withAlpha((200 * _gridAnimationController.value).toInt()),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'discovery.all_studies'.tr(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: _toggleGridOverlay),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: studyIds.length,
                    itemBuilder: (context, index) {
                      final studyId = studyIds[index];
                      final title = state.studyTitles[studyId] ??
                          _formatStudyTitle(studyId);
                      final emoji = state.studyEmojis[studyId];
                      final isCompleted =
                          state.completedStudies[studyId] ?? false;

                      return _StudyGridCard(
                        studyId: studyId,
                        title: title,
                        emoji: emoji,
                        isCompleted: isCompleted,
                        isActive: index == _currentIndex,
                        onTap: () {
                          _navigateToDetail(context, studyId);
                          setState(() {
                            _currentIndex = index;
                            _swiperController.move(index);
                          });
                          _toggleGridOverlay();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final languageCode =
                    context.read<DevocionalProvider>().selectedLanguage;
                context
                    .read<DiscoveryBloc>()
                    .add(LoadDiscoveryStudies(languageCode: languageCode));
              },
              icon: const Icon(Icons.refresh),
              label: Text('app.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('discovery.no_studies_available'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String studyId) {
    final languageCode = context.read<DevocionalProvider>().selectedLanguage;
    context
        .read<DiscoveryBloc>()
        .add(LoadDiscoveryStudy(studyId, languageCode: languageCode));
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => DiscoveryDetailPage(studyId: studyId)));
  }

  Devocional _createMockDevocional(String studyId, {String? emoji}) {
    final title = _formatStudyTitle(studyId);
    return Devocional(
      id: studyId,
      date: DateTime.now(),
      versiculo: 'Discovery Study: $title',
      reflexion: 'Explore deeper into God\'s Word with this Discovery study',
      paraMeditar: [],
      oracion: '',
      tags: ['Discovery', 'Study', 'Growth'],
      emoji: emoji,
    );
  }

  String _formatStudyTitle(String studyId) {
    return studyId
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }
}

class _StudyGridCard extends StatelessWidget {
  final String studyId;
  final String title;
  final String? emoji;
  final bool isCompleted;
  final bool isActive;
  final VoidCallback onTap;

  const _StudyGridCard({
    required this.studyId,
    required this.title,
    this.emoji,
    required this.isCompleted,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isActive ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest.withAlpha(128),
                    ),
                    child: Center(
                      child: Text(
                        emoji ?? '📖',
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isActive ? colorScheme.primary : null,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(40),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle,
                                    size: 12, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  'discovery.completed'.tr(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isActive)
                          Row(
                            children: [
                              Icon(Icons.play_circle_outline,
                                  size: 14, color: colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                'discovery.current'.tr(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isCompleted)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12, blurRadius: 4, spreadRadius: 1)
                    ],
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
