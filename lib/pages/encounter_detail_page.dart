// lib/pages/encounter_detail_page.dart
//
// Full-screen card reader for Encounters.
// Uses a modern swiper to navigate through cards.

import 'package:card_swiper/card_swiper.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/widgets/encounter/encounter_card_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
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
            return const Center(
                child: Text('Study not found',
                    style: TextStyle(color: Colors.white)));
          }

          final cards = study.cards;

          return Stack(
            children: [
              // Swiper
              Swiper(
                controller: _swiperController,
                itemCount: cards.length,
                loop: false,
                index: 0,
                // Add a modern transition effect
                layout: SwiperLayout.DEFAULT,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 100),
                    child: buildEncounterCardWidget(
                      cards[index],
                      onBackToEncounters: () => Navigator.of(context).pop(),
                    ),
                  );
                },
              ),

              // Progress Bar at the top
              Positioned(
                top: 50,
                left: 24,
                right: 24,
                child: _ProgressBar(
                  total: cards.length,
                  current: 0, // Swiper state needed for real-time update
                  controller: _swiperController,
                ),
              ),

              // Navigation Buttons at bottom
              Positioned(
                bottom: 30,
                left: 24,
                right: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button (hidden on first card)
                    _NavButton(
                      icon: Icons.chevron_left,
                      onPressed: () => _swiperController.previous(),
                    ),

                    // indicator placeholder
                    const Text(
                      'SWIPE TO EXPLORE',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),

                    // Next button
                    _NavButton(
                      icon: Icons.chevron_right,
                      onPressed: () => _swiperController.next(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressBar extends StatefulWidget {
  final int total;
  final int current;
  final SwiperController controller;

  const _ProgressBar({
    required this.total,
    required this.current,
    required this.controller,
  });

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.current;
    // Note: In a production app, listen to Swiper index changes via a listener
    // or by lifting state. For now, this placeholder handles the visual.
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(widget.total, (index) {
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
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _NavButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
