// lib/pages/encounter_intro_page.dart
//
// Modern, high-impact intro page for Encounters.
// Designed for a younger audience with cinematic visuals and bold typography.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/pages/encounter_detail_page.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/utils/constants.dart';
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

  // Staggered reveal animations
  late Animation<double> _imageOpacity;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 1. Background image fades in immediately
    _imageOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    // 2. Content area slides and fades in
    _contentFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    ));

    _controller.forward();

    // Pre-load the study
    final id = widget.entry.id;
    final bloc = context.read<EncounterBloc>();

    // Only skip if the study is already in the loaded studies map.
    // If the bloc is in any other state (Initial, Loading, Error) we still
    // dispatch so the study is fetched once the bloc is ready.
    final alreadyLoaded = bloc.state is EncounterLoaded &&
        (bloc.state as EncounterLoaded).isStudyLoaded(id);

    if (!alreadyLoaded) {
      // Resolve the filename from the index files map (e.g. peter_water_001_es.json).
      // Fall back to the {id}_{lang}.json convention if the map has no entry.
      final filename = widget.entry.files[widget.lang] ??
          widget.entry.files['en'] ??
          '${id}_${widget.lang}.json';
      bloc.add(LoadEncounterStudy(id, widget.lang, filename: filename));
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
    final accentColor =
        _parseColor(entry.accentColor) ?? const Color(0xFF1e3a5f);

    // Dynamic intro image from JSON schema
    final String? imageUrl = entry.introImage != null
        ? Constants.getEncounterImageUrl(entry.introImage!,
            encounterId: entry.id)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0a0e1a),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. CINEMATIC BACKGROUND IMAGE
          if (imageUrl != null)
            FadeTransition(
              opacity: _imageOpacity,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                placeholder: (context, url) {
                  debugPrint(
                      '🖼️ Encounter: Showing bundled asset as placeholder — ${widget.entry.introImage}');
                  return Image.asset(
                    'assets/encounters/${widget.entry.introImage}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        Container(color: const Color(0xFF0a0e1a)),
                  );
                },
                errorWidget: (context, url, error) {
                  debugPrint(
                      '⚠️ Encounter: CDN image failed — using bundled asset ${widget.entry.introImage}');
                  return Image.asset(
                    'assets/encounters/${widget.entry.introImage}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) {
                      debugPrint(
                          '❌ Encounter: Bundled asset also failed — ${widget.entry.introImage}');
                      return Container(color: const Color(0xFF0a0e1a));
                    },
                  );
                },
              ),
            ),

          // 2. GRADIENT OVERLAYS
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.1),
                  const Color(0xFF0a0e1a).withValues(alpha: 0.95),
                  const Color(0xFF0a0e1a),
                ],
                stops: const [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),

          // 3. DECORATIVE ORBS (For depth)
          Positioned(
            top: 100,
            left: -100,
            child: _Orb(color: accentColor.withValues(alpha: 0.2), size: 400),
          ),

          // 4. MAIN CONTENT
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Action Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white70, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),

                        const SizedBox(height: 40),

                        // Text Reveal Section
                        FadeTransition(
                          opacity: _contentFade,
                          child: SlideTransition(
                            position: _contentSlide,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  entry.titleFor(widget.lang),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                    letterSpacing: -1.5,
                                  ),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  entry.subtitleFor(widget.lang),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 40),

                                // Meta Features
                                _FeatureRow(
                                  icon: Icons.auto_stories_outlined,
                                  label: entry.scriptureFor(widget.lang),
                                ),
                                const SizedBox(height: 16),
                                _FeatureRow(
                                  icon: Icons.bolt_rounded,
                                  label:
                                      '${entry.readingMinutesFor(widget.lang)} ${'encounters.min_immersive_journey'.tr()}',
                                ),
                                if (entry.testament != null) ...[
                                  const SizedBox(height: 16),
                                  _FeatureRow(
                                    icon: Icons.explore_rounded,
                                    label:
                                        entry.testament!.toLowerCase() == 'new'
                                            ? 'encounters.new_testament'.tr()
                                            : 'encounters.old_testament'.tr(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),

                // BOTTOM ACTION AREA
                FadeTransition(
                  opacity: _contentFade,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                    child: BlocBuilder<EncounterBloc, EncounterState>(
                      builder: (context, state) {
                        final loadedState =
                            state is EncounterLoaded ? state : null;
                        final isLoaded = loadedState != null &&
                            loadedState.isStudyLoaded(entry.id);
                        // Show error label if study failed to load but we have
                        // an errorMessage (lets user know something went wrong)
                        final hasError = loadedState?.errorMessage != null;

                        return SizedBox(
                          width: double.infinity,
                          height: 72,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Modern Gold Gradient Button
                              Container(
                                width: double.infinity,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: isLoaded
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFFB8860B), // darker gold
                                            Color(0xFFFFD700), // bright gold
                                            Color(0xFFFFFFE0), // light gold
                                            Color(0xFFFFD700), // bright gold
                                            Color(0xFFB8860B), // darker gold
                                          ],
                                          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        )
                                      : LinearGradient(
                                          colors: [
                                            const Color(0xFFB8860B)
                                                .withValues(alpha: 0.6),
                                            const Color(0xFFFFD700)
                                                .withValues(alpha: 0.6),
                                            const Color(0xFFFFFFE0)
                                                .withValues(alpha: 0.6),
                                            const Color(0xFFFFD700)
                                                .withValues(alpha: 0.6),
                                            const Color(0xFFB8860B)
                                                .withValues(alpha: 0.6),
                                          ],
                                          stops: const [
                                            0.0,
                                            0.25,
                                            0.5,
                                            0.75,
                                            1.0
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withValues(
                                          alpha: isLoaded ? 0.6 : 0.3),
                                      blurRadius: isLoaded ? 24 : 12,
                                      spreadRadius: isLoaded ? 2 : 1,
                                      offset: const Offset(0, 8),
                                    ),
                                    if (isLoaded)
                                      BoxShadow(
                                        color: const Color(0xFFFFD700)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        spreadRadius: 4,
                                        offset: const Offset(0, 0),
                                      ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: isLoaded
                                        ? () => _beginEncounter(loadedState)
                                        : null,
                                    borderRadius: BorderRadius.circular(24),
                                    splashColor:
                                        Colors.white.withValues(alpha: 0.3),
                                    highlightColor:
                                        Colors.white.withValues(alpha: 0.1),
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 8),
                                        child: AutoSizeText(
                                          hasError
                                              ? 'encounters.error_load'.tr()
                                              : 'encounters.enter_experience'
                                                  .tr(),
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                          minFontSize: 12,
                                          maxFontSize: 18,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                            color: isLoaded
                                                ? const Color(0xFF0a0e1a)
                                                : const Color(0xFF0a0e1a)
                                                    .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Spinner overlay while study is fetching
                              if (!isLoaded && !hasError)
                                const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation(
                                        Color(0xFFFFD700)),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
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

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureRow({required this.icon, required this.label});

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
          child: Icon(icon, color: Colors.amberAccent, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
