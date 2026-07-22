// lib/pages/encounter_detail_page.dart
//
// Modern card reader for an encounter study.
// Uses PageView with intuitive viewport peeking (0.88) to show next card preview.
// Matches Discovery Bible Studies carousel for consistent UX across features.

import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/i_analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/encounter_tts_text_builder.dart';
import 'package:devocional_nuevo/services/tts/utils/tts_chunk_processor.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:devocional_nuevo/utils/image_precache_utils.dart';
import 'package:devocional_nuevo/utils/constants/constants.dart';
import 'package:devocional_nuevo/widgets/tts/reader_tts_miniplayer_presenter.dart';

import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/encounter_card_model.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/widgets/encounter/encounter_card_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  late final PageController _pageController = PageController(
    viewportFraction: 0.88,
  );
  int _currentIndex = 0;
  bool _isCelebrating = false;
  bool _hasTriggeredCompletion = false;

  /// Tracks image URLs already submitted to [precacheImage] so we never
  /// fire duplicate network requests for the same asset.
  final Set<String> _precachedUrls = {};

  /// Guards the one-time study-ready debug log inside the BlocBuilder.
  bool _studyLoggedOnce = false;

  // TTS — page-scoped, mirrors the pattern used by BibleReaderPage /
  // DevocionalesPage. Not registered in ServiceLocator; owns its own
  // FlutterTts instance, created/disposed with this page.
  late final TtsAudioController _ttsAudioController;
  late final ReaderTtsMiniplayerPresenter<EncounterCard>
      _ttsMiniplayerPresenter;
  List<EncounterCard> _currentCards = const [];

  EncounterCard? get _currentCard => _currentIndex < _currentCards.length
      ? _currentCards[_currentIndex]
      : null;

  @override
  void initState() {
    super.initState();

    final flutterTts = FlutterTts();
    _ttsAudioController = TtsAudioController(
      flutterTts: flutterTts,
      voiceSettingsService: getService<VoiceSettingsService>(),
      chunkProcessor: getService<TtsChunkProcessor>(),
    );
    _ttsMiniplayerPresenter = ReaderTtsMiniplayerPresenter<EncounterCard>(
      ttsAudioController: _ttsAudioController,
      analyticsService: getService<IAnalyticsService>(),
      buildSampleText: (card) => EncounterTtsTextBuilder.build(card),
    );
    // Guarantee card[1] preload on first frame, before user can swipe.
    // This is safer than relying on _studyLoggedOnce inside BlocBuilder,
    // which rebuilds after state changes and may miss the window on fast devices.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<EncounterBloc>().state;
      if (state is EncounterLoaded) {
        final study = state.getStudy(widget.entry.id);
        if (study != null && study.cards.length > 1) {
          _preloadCardImage(study.cards, 1);
          debugPrint(
            '🔐 [Detail/${widget.entry.id}] Safety preload card[1] triggered from initState',
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _ttsMiniplayerPresenter.dispose();
    _ttsAudioController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _playCurrentCard(BuildContext context, String? language) {
    final card = _currentCard;
    if (card == null) return;
    final languageCode =
        language ?? ui.PlatformDispatcher.instance.locale.languageCode;
    final text = EncounterTtsTextBuilder.build(card);
    if (text.isEmpty) return;
    _ttsAudioController.setText(text, languageCode: languageCode);
    _ttsMiniplayerPresenter.showMiniplayerModal(
      context,
      () => _currentCard ?? card,
    );
    _ttsAudioController.play();
  }

  // ---------------------------------------------------------------------------
  // Just-in-time image preloading
  // ---------------------------------------------------------------------------

  /// Preloads the image for card at [targetIndex] into Flutter's in-memory
  /// image cache — always fire-and-forget, never awaited.
  ///
  /// Accepts [cards] directly so this method has no hidden dependency on
  /// [context.read] — callers own the state lookup, keeping contracts explicit.
  /// [_precachedUrls] prevents duplicate work: each URL is submitted at most
  /// once per page-view session. On individual failure the URL is removed so
  /// the next swipe can retry if the network recovers.
  void _preloadCardImage(List<EncounterCard> cards, int targetIndex) {
    if (targetIndex < 0 || targetIndex >= cards.length) return;

    final base = cards[targetIndex].imageUrl;
    final url = base != null
        ? Constants.getEncounterImageUrl(base, encounterId: widget.entry.id)
        : null;
    if (url == null) {
      debugPrint(
        '🖼️ [Detail/${widget.entry.id}] card[$targetIndex] — no imageUrl, skip',
      );
      return;
    }

    if (_precachedUrls.contains(url)) {
      debugPrint(
        '⚡ [Detail/${widget.entry.id}] card[$targetIndex] cache HIT — already preloaded',
      );
      return;
    }

    _precachedUrls.add(url);
    debugPrint(
      '🖼️ [Detail/${widget.entry.id}] JIT: preloading card[$targetIndex] → $url',
    );

    safePrecacheImage(
      CachedNetworkImageProvider(url),
      context,
      debugTag: '[Detail/${widget.entry.id}] card[$targetIndex]',
      onNetworkError: (_, __) {
        // The .catchError() on the old code never fired because precacheImage
        // always completes the future successfully — even on errors.  The
        // onError parameter is the only way to intercept image-load failures.
        _precachedUrls.remove(url); // Allow retry on next swipe
      },
    ).then(
      (_) => debugPrint(
        '✅ [Detail/${widget.entry.id}] card[$targetIndex] preload DONE',
      ),
    );
  }

  void _onCompleteEncounter() {
    if (_hasTriggeredCompletion) return;

    setState(() {
      _isCelebrating = true;
      _hasTriggeredCompletion = true;
    });

    context.read<EncounterBloc>().add(CompleteEncounter(widget.entry.id));
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _isCelebrating = false);
        Navigator.of(context).pop();
      }
    });
  }

  void _exitWithTransition() {
    HapticFeedback.mediumImpact();
    final currentContext = context;

    // Create fade and scale transition before exiting
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return AnimatedBuilder(
          animation: AlwaysStoppedAnimation(0.0),
          builder: (context, child) {
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInCubic,
              onEnd: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                Future.microtask(() {
                  if (mounted && currentContext.mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.of(currentContext).pop(); // Exit page
                  }
                });
              },
              builder: (context, value, child) {
                return FadeTransition(
                  opacity: AlwaysStoppedAnimation(1.0 - value),
                  child: ScaleTransition(
                    scale: AlwaysStoppedAnimation(1.0 - (value * 0.05)),
                    child: Container(color: Colors.transparent),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0e1a),
      body: BlocBuilder<EncounterBloc, EncounterState>(
        builder: (context, state) {
          if (state is! EncounterLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final study = state.getStudy(widget.entry.id);
          if (study == null) {
            return SafeArea(
              child: Column(
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white70,
                        size: 24,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Spacer(),
                  // Error UI
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'encounters.study_not_found'.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<EncounterBloc>().add(
                            LoadEncounterStudy(widget.entry.id, widget.lang),
                          );
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text('encounters.retry'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      foregroundColor: Colors.black.withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            );
          }

          final cards = study.cards;
          _currentCards = cards;
          if (cards.isEmpty) {
            return Center(
              child: Text(
                'encounters.no_cards_available'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          // One-time log — fires on first successful render, not on every rebuild.
          if (!_studyLoggedOnce) {
            _studyLoggedOnce = true;
            debugPrint(
              '📚 [Detail/${widget.entry.id}] Study ready — ${cards.length} cards'
              ' | bible: ${study.bibleVersion ?? 'n/a'}'
              ' | lang: ${study.language ?? 'n/a'}',
            );
          }

          final isLast = _currentIndex == cards.length - 1;

          return Stack(
            children: [
              // PageView Reader with viewport peeking (0.88 shows next card preview)
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  debugPrint(
                    '📖 [Detail/${widget.entry.id}] swiped → card[$index] / ${cards.length}',
                  );
                  setState(() => _currentIndex = index);
                  // JIT: cards already in scope — no extra context.read needed.
                  _preloadCardImage(cards, index + 1);
                  // Page-change-while-playing policy: stop rather than
                  // silently reset position or keep narrating a stale card.
                  final ttsState = _ttsAudioController.state.value;
                  if (ttsState == TtsPlayerState.playing ||
                      ttsState == TtsPlayerState.paused) {
                    _ttsAudioController.stop();
                  }
                },
                physics: const BouncingScrollPhysics(),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                        // Subtle scale and fade for cards as they move away from center
                        value = (1 - (value.abs() * 0.12)).clamp(0.0, 1.0);
                      }
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value.clamp(
                            0.5,
                            1.0,
                          ), // Keep peeked cards visible
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 100, 16, 120),
                      child: buildEncounterCardWidget(
                        cards[index],
                        onBackToEncounters: _onCompleteEncounter,
                        bibleVersion: () {
                          final v = context
                              .read<DevocionalProvider>()
                              .selectedVersion;
                          return v.isNotEmpty ? v : (study.bibleVersion ?? '');
                        }(),
                        language: study.language,
                        showCompletionMessage: state.isCompleted(
                          widget.entry.id,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Progress Indicator (Lines) - Moved lower for better spacing
              Positioned(
                top: 90,
                left: 24,
                right: 24,
                child: Row(
                  children: List.generate(cards.length, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= _currentIndex
                              ? const Color(0xFFFFD700)
                              : const Color(0xFFFFD700).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Back Button (Top Left) - Gold arrow only
              Positioned(
                top: 44,
                left: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Color(0xFFFFD700),
                    size: 24,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // TTS play button (Top Right) - Gold styling, mirrors back button
              Positioned(
                top: 44,
                right: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: Color(0xFFFFD700),
                    size: 24,
                  ),
                  onPressed: () => _playCurrentCard(context, study.language),
                ),
              ),

              // Card counter (Top Center) - Gold styling
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFB8860B),
                          Color(0xFFFFD700),
                          Color(0xFFFFFFE0),
                          Color(0xFFFFD700),
                          Color(0xFFB8860B),
                        ],
                        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${cards.length}',
                      style: const TextStyle(
                        color: Color(0xFF0a0e1a),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Navigation Controls
              Positioned(
                bottom: 40,
                left: 24,
                right: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Prev Button
                    _NavButton(
                      icon: Icons.chevron_left,
                      visible: _currentIndex > 0,
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    // Spacer between prev and exit/next
                    const Expanded(child: SizedBox.shrink()),
                    // Exit/Next Button on right side with responsive sizing
                    if (isLast)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 12),
                        child: _ExitButton(onPressed: _exitWithTransition),
                      )
                    else
                      // Next Button (hidden on last card)
                      _NavButton(
                        icon: Icons.chevron_right,
                        visible: !isLast,
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                  ],
                ),
              ),

              // Lottie Celebration Overlay
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
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool visible;

  const _NavButton({
    required this.icon,
    required this.onPressed,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: visible ? 1.0 : 0.0,
      child: GestureDetector(
        onTap: visible ? onPressed : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: visible
                ? LinearGradient(
                    colors: [
                      Color(0xFFB8860B).withValues(alpha: 0.35),
                      Color(0xFFFFD700).withValues(alpha: 0.35),
                      Color(0xFFFFFFE0).withValues(alpha: 0.25),
                      Color(0xFFFFD700).withValues(alpha: 0.35),
                      Color(0xFFB8860B).withValues(alpha: 0.35),
                    ],
                    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : LinearGradient(
                    colors: [
                      Color(0xFFB8860B).withValues(alpha: 0.18),
                      Color(0xFFFFD700).withValues(alpha: 0.18),
                      Color(0xFFFFFFE0).withValues(alpha: 0.12),
                      Color(0xFFFFD700).withValues(alpha: 0.18),
                      Color(0xFFB8860B).withValues(alpha: 0.18),
                    ],
                    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            boxShadow: visible
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.18),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.08),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Icon(
            icon,
            color: visible
                ? const Color(0xFF0a0e1a).withValues(alpha: 0.7)
                : Colors.white24,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _ExitButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ExitButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing based on screen width
    // Small devices (width < 600): compact size
    // Medium devices (600-900): medium size
    // Large devices (900+): larger size
    final isSmallDevice = screenWidth < 600;
    final isMediumDevice = screenWidth >= 600 && screenWidth < 900;

    final buttonHeight = isSmallDevice
        ? 42.0
        : isMediumDevice
            ? 46.0
            : 50.0;
    final iconSize = isSmallDevice
        ? 16.0
        : isMediumDevice
            ? 18.0
            : 20.0;
    final fontSize = isSmallDevice
        ? 11.0
        : isMediumDevice
            ? 12.0
            : 13.0;
    final horizontalPadding = isSmallDevice
        ? 10.0
        : isMediumDevice
            ? 12.0
            : 14.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFB8860B).withValues(alpha: 0.35),
            Color(0xFFFFD700).withValues(alpha: 0.35),
            Color(0xFFFFFFE0).withValues(alpha: 0.25),
            Color(0xFFFFD700).withValues(alpha: 0.35),
            Color(0xFFB8860B).withValues(alpha: 0.35),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.18),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.white.withValues(alpha: 0.12),
          child: Container(
            height: buttonHeight,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: iconSize,
                  color: const Color(0xFF0a0e1a).withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'encounters.exit'.tr(),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: const Color(0xFF0a0e1a).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
