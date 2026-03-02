// lib/pages/encounter_detail_page.dart
//
// Modern card reader for an encounter study.
// Uses a modern swiper to navigate through cards with staggered transitions.

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
  int _currentIndex = 0;

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
            return Center(
              child: Text(
                'Study not found',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            );
          }

          final cards = study.cards;
          if (cards.isEmpty) {
            return const Center(
              child: Text('No cards available.', style: TextStyle(color: Colors.white)),
            );
          }

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
                      onBackToEncounters: () => Navigator.of(context).pop(),
                    ),
                  );
                },
              ),

              // Progress Indicator (Lines to swipe)
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

              // Close Button (Top Right, above the lines)
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
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
                    
                    Text(
                      '${_currentIndex + 1} / ${cards.length}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),

                    // Next Button
                    _NavButton(
                      icon: Icons.chevron_right,
                      visible: _currentIndex < cards.length - 1,
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
