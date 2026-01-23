// lib/pages/discovery_list_page.dart

import 'package:card_swiper/card_swiper.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/pages/devotional_discovery/widgets/devotional_card_premium.dart';
import 'package:devocional_nuevo/pages/discovery_detail_page.dart';
import 'package:devocional_nuevo/pages/favorites_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/utils/discovery_share_helper.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/discovery_grid_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const double _inactiveDotsAlpha = 0.3;

  int _currentIndex = 0;
  bool _showGridOverlay = false;
  late AnimationController _gridAnimationController;
  final SwiperController _swiperController = SwiperController();

  Set<String>? _previousFavoriteIds;
  Set<String>? _previousLoadedStudyIds;

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
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: PopScope(
        canPop: !_showGridOverlay,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_showGridOverlay) {
            _toggleGridOverlay();
          }
        },
        child: Scaffold(
          appBar: CustomAppBar(
            titleText: 'discovery.discovery_studies'.tr(),
            actions: [
              IconButton(
                icon: Icon(
                    _showGridOverlay ? Icons.view_carousel : Icons.grid_view),
                onPressed: _toggleGridOverlay,
                tooltip: _showGridOverlay ? 'Carousel View' : 'Grid View',
              ),
            ],
          ),
          body: BlocListener<DiscoveryBloc, DiscoveryState>(
            listener: (context, state) {
              if (state is DiscoveryLoaded) {
                final currentFavoriteIds = state.favoriteStudyIds;
                final currentLoadedIds = state.loadedStudies.keys.toSet();

                if (_previousFavoriteIds != null) {
                  if (currentFavoriteIds.length >
                      _previousFavoriteIds!.length) {
                    _showFeedbackSnackBar(
                        'devotionals_page.added_to_favorites'.tr());
                  } else if (currentFavoriteIds.length <
                      _previousFavoriteIds!.length) {
                    _showFeedbackSnackBar(
                        'devotionals_page.removed_from_favorites'.tr());
                  }
                }

                if (_previousLoadedStudyIds != null) {
                  if (currentLoadedIds.length >
                      _previousLoadedStudyIds!.length) {
                    final addedId = currentLoadedIds
                        .difference(_previousLoadedStudyIds!)
                        .first;
                    final title = state.studyTitles[addedId] ?? addedId;
                    _showFeedbackSnackBar(
                      '$title ${'devotionals.offline_mode'.tr()}',
                      useIcon: true,
                    );
                  }
                }

                _previousFavoriteIds = Set.from(currentFavoriteIds);
                _previousLoadedStudyIds = Set.from(currentLoadedIds);
              }
            },
            child: BlocBuilder<DiscoveryBloc, DiscoveryState>(
              builder: (context, state) {
                if (state is DiscoveryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is DiscoveryError) {
                  return _buildErrorState(context, state.message);
                }
                if (state is DiscoveryLoaded) {
                  // Requirement #2: Auto-reorder - completed studies to the end
                  final sortedIds = List<String>.from(state.availableStudyIds);
                  sortedIds.sort((a, b) {
                    final aCompleted = state.completedStudies[a] ?? false;
                    final bCompleted = state.completedStudies[b] ?? false;

                    // Incomplete studies come first
                    if (aCompleted != bCompleted) {
                      return aCompleted ? 1 : -1;
                    }
                    // Within same completion status, maintain original order
                    return state.availableStudyIds
                        .indexOf(a)
                        .compareTo(state.availableStudyIds.indexOf(b));
                  });

                  if (state.availableStudyIds.isEmpty) {
                    return _buildEmptyState(context);
                  }

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
                          const SizedBox(height: 20),
                        ],
                      ),
                      DiscoveryGridOverlay(
                        state: state,
                        studyIds: sortedIds,
                        currentIndex: _currentIndex,
                        onStudySelected: (studyId, originalIndex) {
                          setState(() {
                            _currentIndex = originalIndex;
                            _swiperController.move(originalIndex);
                          });

                          _toggleGridOverlay();
                          _navigateToDetail(context, studyId);
                        },
                        onClose: _toggleGridOverlay,
                        animation: _gridAnimationController,
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDots(int count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentIndex == index ? 28 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: _currentIndex == index
                  ? colorScheme.primary
                  : colorScheme.primary.withValues(alpha: _inactiveDotsAlpha),
              border: Border.all(
                color: _currentIndex == index
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.5),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(5),
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
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      index: _currentIndex,
      itemBuilder: (context, index) {
        final studyId = studyIds[index];
        final title = state.studyTitles[studyId] ?? _formatStudyTitle(studyId);
        final subtitle = state.studySubtitles[studyId];
        final emoji = state.studyEmojis[studyId];
        final readingMinutes = state.studyReadingMinutes[studyId];
        final isCompleted = state.completedStudies[studyId] ?? false;
        final isFavorite = state.favoriteStudyIds.contains(studyId);

        final mockDevocional = _createMockDevocional(studyId, emoji: emoji);

        return DevotionalCardPremium(
          devocional: mockDevocional,
          title: title,
          subtitle: subtitle,
          readingMinutes: readingMinutes,
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
      viewportFraction: 0.88,
      scale: 0.92,
      curve: Curves.easeInOutCubic,
      duration: 350,
      onIndexChanged: (index) {
        if (mounted) {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      layout: SwiperLayout.STACK,
      itemWidth: MediaQuery.of(context).size.width * 0.88,
      itemHeight: MediaQuery.of(context).size.height * 0.6,
    );
  }

  Widget _buildActionBar(
      BuildContext context, DiscoveryLoaded state, List<String> studyIds) {
    if (studyIds.isEmpty || _currentIndex >= studyIds.length) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final currentStudyId = studyIds[_currentIndex];
    final currentTitle =
        state.studyTitles[currentStudyId] ?? _formatStudyTitle(currentStudyId);

    final isDownloaded = state.isStudyLoaded(currentStudyId);
    final isDownloading = state.isStudyDownloading(currentStudyId);

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
                icon: isDownloaded
                    ? Icons.file_download_done_rounded
                    : isDownloading
                        ? Icons.sync_rounded
                        : Icons.file_download_outlined,
                label: isDownloaded
                    ? 'devotionals.offline_mode'.tr()
                    : 'discovery.download_study'.tr(),
                onTap: () => _handleDownloadStudy(currentStudyId, currentTitle),
                colorScheme: colorScheme,
                isDownloading: isDownloading),
            _buildActionButton(
                icon: Icons.share_rounded,
                label: 'discovery.share'.tr(),
                onTap: () => _handleShareStudy(state, currentStudyId),
                colorScheme: colorScheme),
            _buildActionButton(
                icon: Icons.star_rounded,
                label: 'navigation.favorites'.tr(),
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
              label: 'discovery.read'.tr(),
              onTap: () => _navigateToDetail(context, currentStudyId),
              colorScheme: colorScheme,
              isPrimary: true,
            ),
            // Requirement #1: Next arrow button (minimalistic round design)
            _buildActionButton(
              icon: Icons.arrow_forward_rounded,
              label: 'discovery.next'.tr(),
              onTap: () {
                if (_currentIndex < studyIds.length - 1) {
                  _swiperController.next();
                }
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
    bool isDownloading = false,
  }) {
    final bool isBorderedIcon = [
      Icons.share_rounded,
      Icons.star_rounded,
      Icons.auto_stories_rounded,
      Icons.arrow_forward_rounded,
      Icons.file_download_outlined,
      Icons.file_download_done_rounded,
      Icons.sync_rounded,
    ].contains(icon);

    return InkWell(
      onTap: isDownloading ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isBorderedIcon
                ? Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isPrimary
                            ? colorScheme.primary
                            : colorScheme.primary.withAlpha(180),
                        width: 2,
                      ),
                      color: isPrimary
                          ? colorScheme.primary.withAlpha(26)
                          : Colors.transparent,
                    ),
                    child: Center(
                      child: isDownloading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                          : Icon(
                              icon,
                              color: colorScheme.primary,
                              size: 22,
                            ),
                    ),
                  )
                : Container(
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

  void _showFeedbackSnackBar(String message, {bool useIcon = false}) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (useIcon) ...[
              const Icon(
                Icons.verified_rounded,
                color: Colors.greenAccent,
                size: 20,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onSecondary),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _handleDownloadStudy(String studyId, String title) async {
    final languageCode = context.read<DevocionalProvider>().selectedLanguage;
    context
        .read<DiscoveryBloc>()
        .add(LoadDiscoveryStudy(studyId, languageCode: languageCode));
  }

  Future<void> _handleShareStudy(
    DiscoveryLoaded state,
    String studyId,
  ) async {
    var study = state.loadedStudies[studyId];

    if (study == null) {
      final languageCode = context.read<DevocionalProvider>().selectedLanguage;
      _showFeedbackSnackBar('discovery.loading_studies'.tr());
      context
          .read<DiscoveryBloc>()
          .add(LoadDiscoveryStudy(studyId, languageCode: languageCode));
      int attempts = 0;
      while (attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        final currentState = context.read<DiscoveryBloc>().state;
        if (currentState is DiscoveryLoaded) {
          study = currentState.loadedStudies[studyId];
          if (study != null) break;
        }
        attempts++;
      }
      if (study == null) {
        if (!mounted) return;
        _showFeedbackSnackBar('discovery.study_not_found'.tr());
        return;
      }
    }

    try {
      final shareText = DiscoveryShareHelper.generarTextoParaCompartir(
        study,
        resumen: true,
      );
      await SharePlus.instance.share(ShareParams(text: shareText));
    } catch (e) {
      debugPrint('Error sharing study: $e');
      if (!mounted) return;
      _showFeedbackSnackBar('share.share_error'.tr());
    }
  }
}
