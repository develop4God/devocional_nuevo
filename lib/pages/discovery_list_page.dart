// lib/pages/discovery_list_page.dart

import 'package:card_swiper/card_swiper.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/pages/devotional_discovery/widgets/devotional_card_premium.dart';
import 'package:devocional_nuevo/pages/discovery_detail_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  void initState() {
    super.initState();
    context.read<DiscoveryBloc>().add(LoadDiscoveryStudies());
    _gridAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _gridAnimationController.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        titleText: 'discovery.discovery_studies'.tr(),
        actions: [
          // Grid view toggle button
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

            return Stack(
              children: [
                // Main carousel view
                Column(
                  children: [
                    // Progress dots
                    _buildProgressDots(state.availableStudyIds.length),
                    const SizedBox(height: 16),

                    // Carousel
                    Expanded(
                      child: _buildCarousel(
                          context, state.availableStudyIds, isDark),
                    ),

                    // Action bar
                    _buildActionBar(context, state.availableStudyIds),
                  ],
                ),

                // Grid overlay (pull-down style)
                if (_showGridOverlay)
                  _buildGridOverlay(context, state.availableStudyIds, isDark),
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
      BuildContext context, List<String> studyIds, bool isDark) {
    return Swiper(
      itemBuilder: (context, index) {
        final studyId = studyIds[index];
        // Create a mock Devocional object for the premium card
        final mockDevocional = _createMockDevocional(studyId);

        return DevotionalCardPremium(
          devocional: mockDevocional,
          isFavorite: false,
          isDark: isDark,
          onTap: () => _navigateToDetail(context, studyId),
          onFavoriteToggle: () {
            // TODO: Implement favorite toggle for Discovery studies
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

  Widget _buildActionBar(BuildContext context, List<String> studyIds) {
    final colorScheme = Theme.of(context).colorScheme;

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
            // Share button
            _buildActionButton(
              icon: Icons.share_outlined,
              label: 'Share',
              onTap: () {
                // TODO: Implement share functionality
              },
              colorScheme: colorScheme,
            ),

            // Favorite button
            _buildActionButton(
              icon: Icons.favorite_border,
              label: 'Save',
              onTap: () {
                // TODO: Implement favorite functionality
              },
              colorScheme: colorScheme,
            ),

            // Read button
            _buildActionButton(
              icon: Icons.play_arrow,
              label: 'Read',
              onTap: () => _navigateToDetail(context, studyIds[_currentIndex]),
              colorScheme: colorScheme,
              isPrimary: true,
            ),

            // Next button
            _buildActionButton(
              icon: Icons.skip_next,
              label: 'Next',
              onTap: () {
                // TODO: Navigate to next study
              },
              colorScheme: colorScheme,
            ),
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
              child: Icon(
                icon,
                color: isPrimary ? Colors.white : colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
                fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridOverlay(
      BuildContext context, List<String> studyIds, bool isDark) {
    return AnimatedBuilder(
      animation: _gridAnimationController,
      builder: (context, child) {
        return Container(
          color: Colors.black
              .withAlpha((200 * _gridAnimationController.value).toInt()),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Studies',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _toggleGridOverlay,
                      ),
                    ],
                  ),
                ),

                // Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: studyIds.length,
                    itemBuilder: (context, index) {
                      final studyId = studyIds[index];
                      return _StudyGridCard(
                        studyId: studyId,
                        isActive: index == _currentIndex,
                        onTap: () {
                          setState(() {
                            _currentIndex = index;
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<DiscoveryBloc>().add(LoadDiscoveryStudies());
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
            Icon(
              Icons.explore_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'discovery.no_studies_available'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String studyId) {
    final languageCode = context.read<DevocionalProvider>().selectedLanguage;
    context.read<DiscoveryBloc>().add(
          LoadDiscoveryStudy(studyId, languageCode: languageCode),
        );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiscoveryDetailPage(studyId: studyId),
      ),
    );
  }

  Devocional _createMockDevocional(String studyId) {
    // Create a mock devocional for the premium card display
    // TODO: Replace with actual study data when available
    final title = _formatStudyTitle(studyId);

    return Devocional(
      id: studyId,
      date: DateTime.now(),
      versiculo: 'Discovery Study: $title',
      reflexion: 'Explore deeper into God\'s Word with this Discovery study',
      paraMeditar: [],
      oracion: '',
      tags: ['Discovery', 'Study', 'Growth'],
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

/// Grid card for quick study selection
class _StudyGridCard extends StatelessWidget {
  final String studyId;
  final bool isActive;
  final VoidCallback onTap;

  const _StudyGridCard({
    required this.studyId,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: isActive ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(51),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Icon(
                  Icons.explore,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatStudyTitle(studyId),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isActive ? theme.colorScheme.primary : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (isActive)
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Current',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
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
      ),
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
