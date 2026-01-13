// lib/pages/discovery_detail_page.dart

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/discovery_action_bar.dart';
import 'package:devocional_nuevo/widgets/discovery_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Detail page for viewing a specific Discovery study
class DiscoveryDetailPage extends StatefulWidget {
  final String studyId;

  const DiscoveryDetailPage({
    required this.studyId,
    super.key,
  });

  @override
  State<DiscoveryDetailPage> createState() => _DiscoveryDetailPageState();
}

class _DiscoveryDetailPageState extends State<DiscoveryDetailPage> {
  int _currentSectionIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextSection(int totalSections) {
    if (_currentSectionIndex < totalSections - 1) {
      setState(() {
        _currentSectionIndex++;
      });
      _pageController.animateToPage(
        _currentSectionIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousSection() {
    if (_currentSectionIndex > 0) {
      setState(() {
        _currentSectionIndex--;
      });
      _pageController.animateToPage(
        _currentSectionIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        titleText: 'discovery.discovery_studies'.tr(),
      ),
      body: BlocBuilder<DiscoveryBloc, DiscoveryState>(
        builder: (context, state) {
          if (state is DiscoveryLoading || state is DiscoveryStudyLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DiscoveryError) {
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
                      state.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<DiscoveryBloc>().add(
                              LoadDiscoveryStudy(widget.studyId,
                                  languageCode: 'es'),
                            );
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text('app.retry'.tr()),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is DiscoveryLoaded) {
            final study = state.getStudy(widget.studyId);

            if (study == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 64),
                    const SizedBox(height: 16),
                    Text('discovery.no_studies_available'.tr()),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Study header
                _buildStudyHeader(study, theme, isDark),

                // Section content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentSectionIndex = index;
                      });
                    },
                    itemCount: study.secciones.length,
                    itemBuilder: (context, index) {
                      return DiscoverySectionCard(
                        section: study.secciones[index],
                        studyId: widget.studyId,
                        sectionIndex: index,
                        isDark: isDark,
                      );
                    },
                  ),
                ),

                // Action bar with navigation
                DiscoveryActionBar(
                  devocional: study,
                  isComplete: false,
                  isPlaying: false,
                  onPrevious:
                      _currentSectionIndex > 0 ? _goToPreviousSection : null,
                  onNext: _currentSectionIndex < study.secciones.length - 1
                      ? () => _goToNextSection(study.secciones.length)
                      : null,
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStudyHeader(
    DiscoveryDevotional study,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.grey[850] : theme.colorScheme.primary.withAlpha(26),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            study.reflexion,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.menu_book,
                size: 16,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  study.versiculoClave,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const Spacer(),
              Chip(
                label: Text(
                  '${'Section'.tr()} ${_currentSectionIndex + 1}/${study.secciones.length}',
                  style: const TextStyle(fontSize: 12),
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
