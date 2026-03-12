// lib/pages/encounter_detail_page.dart
//
// Modern card reader for an encounter study.
// Uses a modern swiper to navigate through cards with staggered transitions.

import 'package:card_swiper/card_swiper.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
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
  final SwiperController _swiperController = SwiperController();
  int _currentIndex = 0;
  bool _isCelebrating = false;
  bool _hasTriggeredCompletion = false;

  @override
  void dispose() {
    _swiperController.dispose();
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
                    child: Container(
                      color: Colors.transparent,
                    ),
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
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white70, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Spacer(),
                  // Error UI
                  const Icon(Icons.error_outline,
                      size: 64, color: Colors.redAccent),
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
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            );
          }

          final cards = study.cards;
          if (cards.isEmpty) {
            return Center(
              child: Text(
                'encounters.no_cards_available'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final isLast = _currentIndex == cards.length - 1;

          return Stack(
            children: [
              // Swiper Reader
              Swiper(
                controller: _swiperController,
                itemCount: cards.length,
                loop: false,
                onIndexChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 100, 16, 120),
                    child: buildEncounterCardWidget(
                      cards[index],
                      onBackToEncounters: _onCompleteEncounter,
                      bibleVersion: study.bibleVersion,
                      language: study.language,
                      showCompletionMessage: state.isCompleted(widget.entry.id),
                    ),
                  );
                },
              ),

              // Progress Indicator (Lines) - Moved lower for better spacing
              Positioned(
                top: 110,
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
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Color(0xFFFFD700), size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // Card counter (Top Center) - Gold styling
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
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
                      onPressed: () => _swiperController.previous(),
                    ),
                    // Spacer between prev and exit/next
                    const Expanded(child: SizedBox.shrink()),
                    // Exit/Next Button on right side with responsive sizing
                    if (isLast)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: _ExitButton(
                          onPressed: _exitWithTransition,
                        ),
                      )
                    else
                      // Next Button (hidden on last card)
                      _NavButton(
                        icon: Icons.chevron_right,
                        visible: !isLast,
                        onPressed: () => _swiperController.next(),
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
                ? const LinearGradient(
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
                  )
                : LinearGradient(
                    colors: [
                      const Color(0xFFB8860B).withValues(alpha: 0.6),
                      const Color(0xFFFFD700).withValues(alpha: 0.7),
                      const Color(0xFFFFFFE0).withValues(alpha: 0.6),
                      const Color(0xFFFFD700).withValues(alpha: 0.7),
                      const Color(0xFFB8860B).withValues(alpha: 0.6),
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            boxShadow: visible
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Icon(
            icon,
            color: visible ? const Color(0xFF0a0e1a) : Colors.white30,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _ExitButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ExitButton({
    required this.onPressed,
  });

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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
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
          splashColor: Colors.white.withValues(alpha: 0.2),
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
                  color: const Color(0xFF0a0e1a),
                ),
                const SizedBox(width: 6),
                Text(
                  'encounters.exit'.tr(),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: const Color(0xFF0a0e1a),
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
