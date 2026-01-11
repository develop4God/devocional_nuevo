// lib/pages/discovery_study_viewer.dart

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/widgets/discovery_section_card.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Viewer for a Discovery study with sections displayed one by one.
///
/// Follows pattern from devotional_modern_view.dart with PageView.
class DiscoveryStudyViewer extends StatefulWidget {
  final String studyId;

  const DiscoveryStudyViewer({
    super.key,
    required this.studyId,
  });

  @override
  State<DiscoveryStudyViewer> createState() => _DiscoveryStudyViewerState();
}

class _DiscoveryStudyViewerState extends State<DiscoveryStudyViewer> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isDark = themeState.themeMode == ThemeMode.dark;

        return Scaffold(
          appBar: AppBar(
            title: Text('discovery.study_viewer'.tr()),
            backgroundColor: AppBarConstants.getAppBarBackgroundColor(context),
            foregroundColor: AppBarConstants.getAppBarForegroundColor(context),
            elevation: AppBarConstants.elevation,
          ),
          body: BlocBuilder<DiscoveryBloc, DiscoveryState>(
            builder: (context, state) {
              if (state is DiscoveryStudyLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is DiscoveryLoaded) {
                final study = state.getStudy(widget.studyId);

                if (study == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text('discovery.study_not_found'.tr()),
                      ],
                    ),
                  );
                }

                return _buildStudyContent(study, isDark);
              }

              if (state is DiscoveryError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(state.message),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildStudyContent(DiscoveryDevotional study, bool isDark) {
    return Column(
      children: [
        // Study header
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? Colors.grey[850] : Colors.blue[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                study.reflexion,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                study.versiculoClave,
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Section content
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: study.secciones.length,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
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

        // Bottom navigation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button
              if (_currentPage > 0)
                ElevatedButton.icon(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: Text('common.previous'.tr()),
                )
              else
                const SizedBox(width: 100),

              // Progress indicator
              Text(
                '${_currentPage + 1} / ${study.secciones.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Next button
              if (_currentPage < study.secciones.length - 1)
                ElevatedButton.icon(
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text('common.next'.tr()),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: Text('common.finish'.tr()),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
