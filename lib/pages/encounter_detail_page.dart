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
          final isAlreadyCompleted =
              state.isCompleted(widget.entry.id) || _hasTriggeredCompletion;

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
                    ),
                  );
                },
              ),

              // Progress Indicator (Lines)
              Positioned(
                top: 85,
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
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Back Button (Top Left)
              Positioned(
                top: 44,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white70, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // Card counter (Top Center)
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${_currentIndex + 1} / ${cards.length}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
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
                    // Complete button on last card
                    if (isLast)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: isAlreadyCompleted ? 0.6 : 1.0,
                            child: SizedBox(
                              height: 48,
                              child: TextButton.icon(
                                onPressed: isAlreadyCompleted
                                    ? null
                                    : _onCompleteEncounter,
                                icon: Icon(
                                  isAlreadyCompleted
                                      ? Icons.verified_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 18,
                                  color: isAlreadyCompleted
                                      ? Colors.greenAccent
                                      : Colors.white,
                                ),
                                label: Text(
                                  isAlreadyCompleted
                                      ? 'encounters.badge_completed'.tr()
                                      : 'encounters.complete'.tr(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    color: isAlreadyCompleted
                                        ? Colors.greenAccent
                                        : Colors.white,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: isAlreadyCompleted
                                      ? Colors.greenAccent
                                          .withValues(alpha: 0.1)
                                      : Colors.white.withValues(alpha: 0.15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      const Expanded(child: SizedBox.shrink()),
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
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
