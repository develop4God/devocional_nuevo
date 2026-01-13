// lib/pages/discovery_detail_page.dart

import 'dart:math';

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/discovery_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

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

  // List of celebratory Lottie assets
  final List<String> _celebrationLotties = [
    'assets/lottie/confetti.json',
    'assets/lottie/trophy_star.json',
    // Add more assets here as needed
  ];

  String get _randomCelebrationLottie {
    final rand = Random();
    return _celebrationLotties[rand.nextInt(_celebrationLotties.length)];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
              debugPrint(
                  '❌ [DiscoveryDetailPage] Study not found for id: \\${widget.studyId} (fallback or missing)');
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
            } else {
              debugPrint(
                  '🌐 [DiscoveryDetailPage] Study loaded for id: \\${widget.studyId} (likely from network or updated cache)');
            }

            return Column(
              children: [
                // Study header
                _buildStudyHeader(study, theme, isDark),
                // Progress dots for sections
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      study.secciones.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentSectionIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentSectionIndex == index
                              ? theme.colorScheme.primary
                              : Colors.grey.withAlpha(128),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                // Swipeable carousel for sections
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
                      final isLast = index == study.secciones.length - 1;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        margin: EdgeInsets.symmetric(
                          horizontal: _currentSectionIndex == index ? 8 : 24,
                          vertical: _currentSectionIndex == index ? 0 : 24,
                        ),
                        child: Material(
                          elevation: _currentSectionIndex == index ? 8 : 2,
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              DiscoverySectionCard(
                                section: study.secciones[index],
                                studyId: widget.studyId,
                                sectionIndex: index,
                                isDark: isDark,
                                versiculoClave: study.versiculoClave,
                              ),
                              if (isLast)
                                Positioned.fill(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Show a random Lottie animation from the list
                                      SizedBox(
                                        height: 120,
                                        child: Lottie.asset(
                                          _randomCelebrationLottie,
                                          repeat: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
