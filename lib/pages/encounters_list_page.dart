// lib/pages/encounters_list_page.dart
//
// Grid of encounter tiles.
// published  → full opacity, tappable → navigates to EncounterIntroPage
// coming_soon → 0.45 opacity, badge, not tappable

import 'package:cached_network_image/cached_network_image.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/pages/encounter_intro_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/encounter/encounter_grid_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EncountersListPage extends StatefulWidget {
  const EncountersListPage({super.key});

  @override
  State<EncountersListPage> createState() => _EncountersListPageState();
}

class _EncountersListPageState extends State<EncountersListPage>
    with SingleTickerProviderStateMixin {
  bool _showGridOverlay = false;
  late AnimationController _gridAnimationController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _gridAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    final bloc = context.read<EncounterBloc>();
    if (bloc.state is! EncounterLoaded) {
      final lang = context.read<DevocionalProvider>().selectedLanguage;
      bloc.add(LoadEncounterIndex(languageCode: lang));
    }
    getService<AnalyticsService>().logEncounterAction(action: 'index_loaded');
  }

  @override
  void dispose() {
    _gridAnimationController.dispose();
    super.dispose();
  }

  void _toggleGridOverlay() {
    getService<AnalyticsService>().logEncounterAction(
      action: _showGridOverlay ? 'toggle_list_view' : 'toggle_grid_view',
    );
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_showGridOverlay,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_showGridOverlay) _toggleGridOverlay();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0a0e1a) : Colors.grey[50],
        appBar: CustomAppBar(
          titleText: 'encounters.section_title'.tr(),
        ),
        body: BlocBuilder<EncounterBloc, EncounterState>(
          builder: (context, state) {
            if (state is EncounterLoading || state is EncounterInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is EncounterError) {
              return _buildError(state.message);
            }

            if (state is EncounterLoaded) {
              if (state.index.isEmpty) {
                return _buildEmpty();
              }
              return _buildContent(state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(EncounterLoaded state) {
    final lang = context.read<DevocionalProvider>().selectedLanguage;

    return Stack(
      children: [
        ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: state.index.length + 1, // +1 for header
          itemBuilder: (context, i) {
            if (i == 0) return _buildHeader();
            final entry = state.index[i - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _EncounterCard(
                entry: entry,
                lang: lang,
                isCompleted: state.isCompleted(entry.id),
                onTap: entry.isPublished
                    ? () {
                        setState(() => _currentIndex = i - 1);
                        _openEncounter(entry, lang);
                      }
                    : null,
              ),
            );
          },
        ),
        // Grid view toggle button (top right)
        Positioned(
          top: 8,
          right: 16,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: InkWell(
              onTap: _toggleGridOverlay,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  _showGridOverlay
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        // Grid overlay
        EncounterGridOverlay(
          state: state,
          entries: state.index,
          currentIndex: _currentIndex,
          lang: lang,
          onEncounterSelected: (entry, originalIndex) {
            setState(() => _currentIndex = originalIndex);
            _toggleGridOverlay();
            if (entry.isPublished) _openEncounter(entry, lang);
          },
          onClose: _toggleGridOverlay,
          animation: _gridAnimationController,
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'encounters.page_title'.tr(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'encounters.page_subtitle'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _openEncounter(EncounterIndexEntry entry, String lang) {
    getService<AnalyticsService>().logEncounterAction(
      action: 'encounter_opened',
      encounterId: entry.id,
    );
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EncounterIntroPage(entry: entry, lang: lang),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.explore_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'encounters.empty_title'.tr(),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'encounters.empty_subtitle'.tr(),
            style: const TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message.isNotEmpty ? message : 'encounters.error_load'.tr(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final lang = context.read<DevocionalProvider>().selectedLanguage;
              context
                  .read<EncounterBloc>()
                  .add(LoadEncounterIndex(languageCode: lang));
            },
            child: Text('encounters.retry'.tr()),
          ),
        ],
      ),
    );
  }
}

class _EncounterCard extends StatelessWidget {
  final EncounterIndexEntry entry;
  final String lang;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _EncounterCard({
    required this.entry,
    required this.lang,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPublished = entry.isPublished;
    final accentColor = _parseColor(entry.accentColor) ?? Colors.blueAccent;

    final bool isToday = !isCompleted && entry.isPublished;
    final bool isNew = !isCompleted && !isToday;

    final imageUrl = entry.introImage != null
        ? Constants.getEncounterImageUrl(entry.introImage!)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: accentColor.withValues(alpha: 0.15),
          boxShadow: isPublished
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Image or Fallback Color
              if (imageUrl != null)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) {
                    debugPrint(
                        '🖼️ Encounter: Showing bundled asset as placeholder — ${entry.introImage}');
                    return Image.asset(
                      'assets/encounters/${entry.introImage}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          Container(color: accentColor),
                    );
                  },
                  errorWidget: (context, url, error) {
                    debugPrint(
                        '⚠️ Encounter: CDN image failed — using bundled asset ${entry.introImage}');
                    return Image.asset(
                      'assets/encounters/${entry.introImage}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) {
                        debugPrint(
                            '❌ Encounter: Bundled asset also failed — ${entry.introImage}');
                        return const SizedBox.shrink();
                      },
                    );
                  },
                )
              else
                Container(color: accentColor),

              // 2. Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),

              // 3. Content Area
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Status Badges row
                    Row(
                      children: [
                        if (isCompleted)
                          _StatusBadge(
                            label:
                                'encounters.badge_completed'.tr().toUpperCase(),
                            icon: Icons.verified_rounded,
                            color: Colors.greenAccent,
                          )
                        else if (isToday)
                          _StatusBadge(
                            label: 'encounters.badge_today'.tr().toUpperCase(),
                            icon: Icons.stars_outlined,
                            color: const Color(0xFFFF8F00),
                          )
                        else if (isNew)
                          _StatusBadge(
                            label: 'encounters.badge_new'.tr().toUpperCase(),
                            icon: Icons.new_releases_rounded,
                            color: Colors.cyanAccent,
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Text(
                            entry.emoji ?? '✨',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Title
                    Text(
                      entry.titleFor(lang),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Subtitle
                    Text(
                      entry.subtitleFor(lang),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Meta row
                    Row(
                      children: [
                        _MetaInfo(
                          icon: Icons.timer,
                          text:
                              '${entry.readingMinutesFor(lang)} ${'discovery.minutes_suffix'.tr()}',
                        ),
                        const SizedBox(width: 24),
                        _MetaInfo(
                          icon: Icons.auto_stories_outlined,
                          text: entry.scriptureFor(lang).toUpperCase(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Coming Soon Overlay
              if (!isPublished)
                Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'encounters.coming_soon'.tr(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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

class _StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
