// lib/pages/encounters/encounters_list_page.dart
//
// Grid of encounter tiles.
// published  → full opacity, tappable → navigates to EncounterIntroPage
// coming_soon → 0.45 opacity, badge, not tappable

import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/main.dart' show routeObserver;
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/pages/encounters/encounter_intro_page.dart';
import 'package:devocional_nuevo/pages/encounters/encounter_welcome_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/i_analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/encounter/encounter_grid_overlay.dart';
import 'package:devocional_nuevo/widgets/encounter/encounter_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncountersListPage extends StatefulWidget {
  const EncountersListPage({super.key});

  @override
  State<EncountersListPage> createState() => _EncountersListPageState();
}

class _EncountersListPageState extends State<EncountersListPage>
    with SingleTickerProviderStateMixin, RouteAware {
  bool _showGridOverlay = false;
  late AnimationController _gridAnimationController;
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;

  // Unlock animation state
  Set<String> _previousCompletedIds = {};
  bool _showUnlockAnimation = false;
  bool _routeSubscribed = false;

  @override
  void initState() {
    super.initState();
    _gridAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    final bloc = context.read<EncounterBloc>();
    // Snapshot completed IDs so we can detect new ones on return
    if (bloc.state is EncounterLoaded) {
      _previousCompletedIds = Set.from(
        (bloc.state as EncounterLoaded).completedIds,
      );
    }
    if (bloc.state is! EncounterLoaded) {
      final lang = context.read<DevocionalProvider>().selectedLanguage;
      bloc.add(LoadEncounterIndex(languageCode: lang));
    }
    _checkWelcomeSeen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routeSubscribed) {
      final route = ModalRoute.of(context);
      if (route is PageRoute) {
        routeObserver.subscribe(this, route);
        _routeSubscribed = true;
      }
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _gridAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Called when user pops back to this page (e.g. after completing an encounter).
  @override
  void didPopNext() {
    final state = context.read<EncounterBloc>().state;
    if (state is! EncounterLoaded) return;

    final newlyCompleted = state.completedIds.difference(_previousCompletedIds);
    _previousCompletedIds = Set.from(state.completedIds);

    if (newlyCompleted.isEmpty) return;

    // Check if any new completion unlocked the next encounter
    final published =
        state.index.where((e) => e.status == 'published').toList();
    for (final completedId in newlyCompleted) {
      final idx = published.indexWhere((e) => e.id == completedId);
      if (idx >= 0 && idx < published.length - 1) {
        // There is a newly-unlocked encounter — play the animation
        setState(() => _showUnlockAnimation = true);
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _showUnlockAnimation = false);
        });
        break;
      }
    }
  }

  Future<void> _checkWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('encounter_welcome_seen') ?? false;
    if (!seen && mounted) {
      // Push (not pushReplacement) so this shell-hosted page stays on the
      // stack underneath — EncounterWelcomePage pops back into it instead
      // of needing to construct a new, standalone (bottom-bar-less) copy.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EncounterWelcomePage()),
      );
    }
  }

  void _toggleGridOverlay() {
    getService<IAnalyticsService>().logEncounterViewToggle(
      view: _showGridOverlay ? 'list' : 'grid',
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: PopScope(
        canPop: !_showGridOverlay,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_showGridOverlay) _toggleGridOverlay();
        },
        child: Scaffold(
          appBar: CustomAppBar(titleText: 'encounters.section_title'.tr()),
          backgroundColor: colorScheme.brightness == Brightness.dark
              ? const Color(0xFF0a0e1a)
              : Colors.grey[50],
          body: Stack(
            children: [
              BlocBuilder<EncounterBloc, EncounterState>(
                builder: (context, state) {
                  if (state is EncounterLoading || state is EncounterInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is EncounterError) {
                    return _buildError(state.localizedMessage);
                  }
                  if (state is EncounterLoaded) {
                    if (state.index.isEmpty) return _buildEmpty();
                    return _buildContent(state);
                  }
                  return const SizedBox.shrink();
                },
              ),
              // Floating grid/list toggle button
              Positioned(
                top: 24,
                right: 24,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: InkWell(
                    onTap: _toggleGridOverlay,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        _showGridOverlay
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              // ── Unlock celebration overlay (bottom-right) ───────────────
              if (_showUnlockAnimation)
                Positioned(
                  bottom: 80,
                  right: 20,
                  child: IgnorePointer(
                    child: Lottie.asset(
                      'assets/lottie/unlocked.json',
                      repeat: false,
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(EncounterLoaded state) {
    final lang = context.read<DevocionalProvider>().selectedLanguage;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        ScrollbarTheme(
          data: ScrollbarThemeData(
            thumbColor: WidgetStateProperty.all(colorScheme.primary),
            trackColor: WidgetStateProperty.all(
              colorScheme.primary.withAlpha(60),
            ),
            thickness: WidgetStateProperty.all(10),
            radius: const Radius.circular(8),
          ),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            thickness: 10,
            radius: const Radius.circular(8),
            interactive: true,
            trackVisibility: true,
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: state.index.length + 1, // +1 for header
              itemBuilder: (context, i) {
                if (i == 0) return _buildHeader();
                final entry = state.index[i - 1];
                final isUnlocked = state.isUnlocked(entry.id);
                final isCompleted = state.isCompleted(entry.id);

                final card = _EncounterCard(
                  entry: entry,
                  lang: lang,
                  isCompleted: isCompleted,
                  onTap: (entry.isPublished && isUnlocked)
                      ? () {
                          setState(() => _currentIndex = i - 1);
                          _openEncounter(entry, lang);
                        }
                      : null,
                );

                Widget cardWidget;
                if (entry.isPublished && !isUnlocked) {
                  // Locked: dim + dark overlay with lock icon and prerequisite text
                  final prerequisite = state.getPrerequisite(entry.id);
                  final prerequisiteTitle = prerequisite?.titleFor(lang) ?? '';

                  cardWidget = Stack(
                    children: [
                      Opacity(opacity: 0.4, child: card),
                      Positioned.fill(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lock_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'encounters.complete_to_unlock'.tr({
                                  'title': prerequisiteTitle,
                                }),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                } else if (isCompleted) {
                  // Completed: no extra badge needed, already shown in card
                  cardWidget = card;
                } else {
                  cardWidget = card;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: cardWidget,
                );
              },
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
            final isUnlocked = state.isUnlocked(entry.id);
            setState(() => _currentIndex = originalIndex);
            _toggleGridOverlay();
            if (entry.isPublished && isUnlocked) _openEncounter(entry, lang);
          },
          onClose: _toggleGridOverlay,
          animation: _gridAnimationController,
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, right: 56),
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
    getService<IAnalyticsService>().logEncounterOpened(encounterId: entry.id);
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
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final lang = context.read<DevocionalProvider>().selectedLanguage;
              context.read<EncounterBloc>().add(
                    LoadEncounterIndex(languageCode: lang),
                  );
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 272,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: accentColor.withValues(alpha: 0.15),
          boxShadow: isPublished
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Image or Fallback Color
              if (entry.introImage != null)
                EncounterImageWidget(
                  baseFilename: entry.introImage!,
                  encounterId: entry.id,
                  imageVersion: entry.imageVersion,
                  fit: BoxFit.cover,
                  fallbackColor: accentColor,
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
                padding: const EdgeInsets.all(20),
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
                            icon: Icons.auto_awesome_rounded,
                            color: Colors.yellowAccent,
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
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            entry.emoji ?? '✨',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ],
                    ),
                    // Main content area wrapped in Expanded to prevent overflow
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
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
                          const SizedBox(height: 10),
                          // Subtitle
                          Text(
                            entry.subtitleFor(lang),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Meta row
                          Row(
                            children: [
                              Flexible(
                                child: _MetaInfo(
                                  icon: Icons.timer,
                                  text:
                                      '${entry.readingMinutesFor(lang)} ${'discovery.minutes_suffix'.tr()}',
                                ),
                              ),
                              const SizedBox(width: 24),
                              Flexible(
                                child: _MetaInfo(
                                  icon: Icons.auto_stories_outlined,
                                  text: entry.scriptureFor(lang).toUpperCase(),
                                ),
                              ),
                            ],
                          ),
                          // Release date for coming_soon cards
                          if (!isPublished &&
                              entry.releaseDateFor(lang) != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    color: Color(0xFFFFD700),
                                    size: 13,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    entry.releaseDateFor(lang)!,
                                    style: const TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
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
                        horizontal: 28,
                        vertical: 14,
                      ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
