// lib/pages/encounter_intro_page.dart
//
// Modern, immersive intro page for Encounters.
// Designed for a younger audience with bold typography and vibrant visuals.

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
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _controller.forward();

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
    _controller.dispose();
    super.dispose();
  }

  void _beginEncounter(EncounterLoaded? state) {
    if (state == null) return;
    final study = state.getStudy(widget.entry.id);
    if (study == null) return;

    getService<AnalyticsService>().logEncounterAction(
      action: 'encounter_started',
      encounterId: widget.entry.id,
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EncounterDetailPage(entry: widget.entry, lang: widget.lang),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final accentColor = _parseColor(entry.accentColor) ?? Colors.blueAccent;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient with a deep space feel
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0a0e1a),
            ),
          ),

          // Decorative Blurred Orbs for modern aesthetic
          Positioned(
            top: -100,
            right: -50,
            child: _Orb(color: accentColor.withValues(alpha: 0.35), size: 300),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: _Orb(color: Colors.purple.withValues(alpha: 0.2), size: 400),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Close Button
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ),

                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),

                            // Hero Emoji
                            Hero(
                              tag: 'encounter_emoji_${entry.id}',
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Text(
                                  entry.emoji ?? '✨',
                                  style: const TextStyle(fontSize: 64),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Title with bold weight
                            AutoSizeText(
                              entry.titleFor(widget.lang),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                letterSpacing: -1.0,
                              ),
                              maxLines: 2,
                            ),

                            const SizedBox(height: 12),

                            // Subtitle
                            Text(
                              entry.subtitleFor(widget.lang),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.2,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Scripture Reference
                            if (entry.scriptureFor(widget.lang).isNotEmpty)
                              _FeatureItem(
                                icon: Icons.auto_stories,
                                label: entry.scriptureFor(widget.lang),
                              ),

                            const SizedBox(height: 16),

                            // Time to read
                            _FeatureItem(
                              icon: Icons.timer_outlined,
                              label:
                                  '${entry.readingMinutesFor(widget.lang)} min session',
                            ),

                            const SizedBox(height: 16),

                            // Testament badge
                            if (entry.testament != null)
                              _FeatureItem(
                                icon: Icons.explore_outlined,
                                label:
                                    '${entry.testament!.toUpperCase()} TESTAMENT',
                              ),

                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Fixed Action Area
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: BlocBuilder<EncounterBloc, EncounterState>(
                    builder: (context, state) {
                      final loadedState =
                          state is EncounterLoaded ? state : null;
                      final isLoaded = loadedState != null &&
                          loadedState.isStudyLoaded(entry.id);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isLoaded)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                'Preparing your journey...',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: ElevatedButton(
                              onPressed: isLoaded
                                  ? () => _beginEncounter(loadedState)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isLoaded ? Colors.white : Colors.white12,
                                foregroundColor: const Color(0xFF0a0e1a),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: isLoaded
                                  ? const Text(
                                      'BEGIN JOURNEY',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    )
                                  : const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
      if (clean.length == 8) return Color(int.parse(clean, radix: 16));
    } catch (_) {}
    return null;
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;

  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size / 2,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
