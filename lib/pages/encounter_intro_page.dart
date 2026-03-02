// lib/pages/encounter_intro_page.dart
//
// Full-screen intro before the card reader.
// Shows animated shimmer background, key info, and Begin button.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/pages/encounter_detail_page.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EncounterIntroPage extends StatefulWidget {
  final EncounterIndexEntry entry;
  final String lang;

  const EncounterIntroPage({
    required this.entry,
    required this.lang,
    super.key,
  });

  @override
  State<EncounterIntroPage> createState() => _EncounterIntroPageState();
}

class _EncounterIntroPageState extends State<EncounterIntroPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _shimmerAnimation = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    );

    // Pre-load the study
    final id = widget.entry.id;
    final bloc = context.read<EncounterBloc>();
    if (bloc.state is! EncounterLoaded ||
        !(bloc.state as EncounterLoaded).isStudyLoaded(id)) {
      bloc.add(LoadEncounterStudy(id, widget.lang));
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _beginEncounter(EncounterLoaded? state) {
    if (state == null) return;
    final study = state.getStudy(widget.entry.id);
    if (study == null) return;

    getService<AnalyticsService>().logEncounterAction(
      action: 'encounter_opened',
      encounterId: widget.entry.id,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EncounterDetailPage(
          entry: widget.entry,
          lang: widget.lang,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0f1828),
                  Color.lerp(
                    const Color(0xFF0a1220),
                    const Color(0xFF0d1a2e),
                    _shimmerAnimation.value,
                  )!,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.all(16),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.emoji ?? '✨',
                        style: const TextStyle(fontSize: 56),
                      ),
                      const SizedBox(height: 20),
                      AutoSizeText(
                        entry.titleFor(widget.lang),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        minFontSize: 14,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.subtitleFor(widget.lang),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Key verse from entry (scripture reference as teaser)
                      if (entry.scriptureFor(widget.lang).isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.menu_book,
                                  color: Colors.white70, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.scriptureFor(widget.lang),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Meta row
                      Row(
                        children: [
                          _metaBadge(
                            Icons.timer_outlined,
                            '${entry.readingMinutesFor(widget.lang)} min',
                          ),
                          const SizedBox(width: 12),
                          if (entry.testament != null)
                            _metaBadge(
                              Icons.auto_stories,
                              entry.testament!.toUpperCase(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // BLoC state for loading / ready
                      BlocBuilder<EncounterBloc, EncounterState>(
                        builder: (context, state) {
                          final loadedState =
                              state is EncounterLoaded ? state : null;
                          final isLoaded = loadedState != null &&
                              loadedState.isStudyLoaded(entry.id);
                          return Column(
                            children: [
                              if (!isLoaded)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Loading encounter...',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isLoaded
                                      ? () => _beginEncounter(loadedState)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF0f1828),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Begin the Encounter',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
