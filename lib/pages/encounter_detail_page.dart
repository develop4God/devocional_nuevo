// lib/pages/encounter_detail_page.dart
//
// Card reader for an encounter study.
// Mirrors DiscoveryDetailPage structure.

import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/models/encounter_study.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/encounter/encounter_card_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

class EncounterDetailPage extends StatefulWidget {
  final EncounterIndexEntry entry;
  final String lang;

  const EncounterDetailPage({
    required this.entry,
    required this.lang,
    super.key,
  });

  @override
  State<EncounterDetailPage> createState() => _EncounterDetailPageState();
}

class _EncounterDetailPageState extends State<EncounterDetailPage> {
  int _currentCardIndex = 0;
  late final PageController _pageController =
      PageController(viewportFraction: 0.92);
  bool _isCelebrating = false;
  bool _hasTriggeredCompletion = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCompleteEncounter() {
    if (_hasTriggeredCompletion) return;

    setState(() {
      _isCelebrating = true;
      _hasTriggeredCompletion = true;
    });

    context.read<EncounterBloc>().add(CompleteEncounter(widget.entry.id));
    HapticFeedback.heavyImpact();

    getService<AnalyticsService>().logEncounterAction(
      action: 'encounter_completed',
      encounterId: widget.entry.id,
    );

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _isCelebrating = false);
    });
  }

  void _onPageChanged(int index, EncounterStudy study) {
    setState(() => _currentCardIndex = index);

    getService<AnalyticsService>().logEncounterAction(
      action: 'card_viewed',
      encounterId: widget.entry.id,
      cardOrder: index + 1,
    );

    // Check if last card
    if (index == study.cards.length - 1) {
      _onCompleteEncounter();
    }
  }

  void _navigatePrev() {
    if (_currentCardIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateNext(int total) {
    if (_currentCardIndex < total - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.entry.titleFor(widget.lang),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: BlocBuilder<EncounterBloc, EncounterState>(
        builder: (context, state) {
          if (state is! EncounterLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final study = state.getStudy(widget.entry.id);
          if (study == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (study.cards.isEmpty) {
            return const Center(child: Text('No cards available.'));
          }

          final total = study.cards.length;
          final isLast = _currentCardIndex == total - 1;

          return Stack(
            children: [
              Column(
                children: [
                  _buildProgressBar(total, theme),
                  _buildStudyHeader(study, total, theme),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) =>
                          _onPageChanged(index, study),
                      itemCount: total,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double scale = 1.0;
                            if (_pageController.position.haveDimensions) {
                              final diff =
                                  (_pageController.page! - index).abs();
                              scale = (1 - diff * 0.12).clamp(0.0, 1.0);
                            }
                            return Transform.scale(
                              scale: scale,
                              child: Opacity(
                                opacity: scale.clamp(0.5, 1.0),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            child: buildEncounterCardWidget(
                              study.cards[index],
                              onBackToEncounters: study.cards[index].type ==
                                      'completion'
                                  ? () => Navigator.of(context)
                                      .popUntil((route) => route.isFirst)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildNavRow(total, isLast, theme),
                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
              // Bottom gradient fade
              Positioned(
                left: 0, right: 0, bottom: 0,
                height: 80,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.scaffoldBackgroundColor.withValues(alpha: 0),
                          theme.scaffoldBackgroundColor
                              .withValues(alpha: 0.8),
                          theme.scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Completion celebration
              if (_isCelebrating)
                IgnorePointer(
                  child: Center(
                    child: Lottie.asset(
                      'assets/lottie/kudos_birdie.json',
                      repeat: false,
                      height: 350,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(int total, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(
          total,
          (i) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              decoration: BoxDecoration(
                color: i <= _currentCardIndex
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudyHeader(
      EncounterStudy study, int total, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.entry.titleFor(widget.lang),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentCardIndex + 1} / $total',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow(int total, bool isLast, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _currentCardIndex > 0 ? _navigatePrev : null,
            icon: const Icon(Icons.arrow_back_ios),
          ),
          // Dot indicators
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                total,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentCardIndex ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _currentCardIndex
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: isLast ? null : () => _navigateNext(total),
            icon: const Icon(Icons.arrow_forward_ios),
          ),
        ],
      ),
    );
  }
}
