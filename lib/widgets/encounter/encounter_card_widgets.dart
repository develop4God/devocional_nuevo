// lib/widgets/encounter/encounter_card_widgets.dart
//
// Modern, immersive encounter card widgets.
// Redesigned with a youthful, high-contrast aesthetic.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:devocional_nuevo/models/encounter_card_model.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Mood → Color mapping (Updated for more depth)
// ---------------------------------------------------------------------------

Color moodColor(String? mood) {
  switch (mood) {
    case 'storm':
      return const Color(0xFF0d1a2e);
    case 'tense':
      return const Color(0xFF0f1828);
    case 'mysterious':
      return const Color(0xFF0a0e1a);
    case 'awe':
      return const Color(0xFF0a1220);
    case 'falling':
      return const Color(0xFF040810);
    case 'grace':
      return const Color(0xFF12100a);
    case 'peace':
      return const Color(0xFF0a120e);
    case 'intense':
      return const Color(0xFF1a0a0e);
    default:
      return const Color(0xFF0a0e1a);
  }
}

// ---------------------------------------------------------------------------
// Shared Background Helper
// ---------------------------------------------------------------------------

class _CardBackground extends StatelessWidget {
  final String? imageUrl;
  final String? mood;
  final Widget child;

  const _CardBackground({
    required this.child,
    this.imageUrl,
    this.mood,
  });

  @override
  Widget build(BuildContext context) {
    final base = moodColor(mood);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Base Layer
          if (imageUrl != null && imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: base),
              errorWidget: (_, __, ___) => Container(color: base),
            )
          else
            Container(color: base),

          // 2. Modern Glassmorphism/Scrim Layer
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),

          // 3. Content
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared Scrollable Wrapper with Modern Indicator
// ---------------------------------------------------------------------------

class _ModernScrollable extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _ModernScrollable({
    required this.child,
    this.padding = const EdgeInsets.all(32),
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.3)),
          thickness: WidgetStateProperty.all(4),
          radius: const Radius.circular(10),
          minThumbLength: 40,
        ),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CinematicSceneCard
// ---------------------------------------------------------------------------

class CinematicSceneCard extends StatelessWidget {
  final EncounterCard card;

  const CinematicSceneCard({required this.card, super.key});

  @override
  Widget build(BuildContext context) {
    return _CardBackground(
      imageUrl: card.imageUrl,
      mood: card.mood,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: 0,
            child: _ModernScrollable(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Space for cases with little text so they still align bottom
                  const SizedBox(height: 200),
                  if (card.title != null)
                    Text(
                      card.title!.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                  if (card.narrative != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      card.narrative!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  if (card.verseOverlay != null) ...[
                    const SizedBox(height: 20),
                    _ModernVerseOverlay(overlay: card.verseOverlay!),
                  ],
                  if (card.revelationKey != null) ...[
                    const SizedBox(height: 16),
                    _ModernRevelationKey(text: card.revelationKey!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ScriptureMomentCard
// ---------------------------------------------------------------------------

class ScriptureMomentCard extends StatelessWidget {
  final EncounterCard card;

  const ScriptureMomentCard({required this.card, super.key});

  @override
  Widget build(BuildContext context) {
    return _CardBackground(
      imageUrl: card.imageUrl,
      mood: card.mood,
      child: Center(
        child: _ModernScrollable(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (card.verseReference != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    card.verseReference!.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              if (card.verseText != null) ...[
                const SizedBox(height: 24),
                Text(
                  card.verseText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (card.reflection != null) ...[
                const SizedBox(height: 32),
                Container(
                  width: 40,
                  height: 2,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 24),
                Text(
                  card.reflection!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 15,
                    height: 1.7,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (card.revelationKey != null) ...[
                const SizedBox(height: 24),
                _ModernRevelationKey(text: card.revelationKey!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CharacterMomentCard & TheologicalDepthCard (Shared modern style)
// ---------------------------------------------------------------------------

class CharacterMomentCard extends StatelessWidget {
  final EncounterCard card;
  const CharacterMomentCard({required this.card, super.key});

  @override
  Widget build(BuildContext context) {
    return _CardBackground(
      imageUrl: card.imageUrl,
      mood: card.mood,
      child: _ModernContentScroll(card: card),
    );
  }
}

class TheologicalDepthCard extends StatelessWidget {
  final EncounterCard card;
  const TheologicalDepthCard({required this.card, super.key});

  @override
  Widget build(BuildContext context) {
    return _CardBackground(
      imageUrl: card.imageUrl,
      mood: card.mood,
      child: _ModernContentScroll(card: card, showConnections: true),
    );
  }
}

class _ModernContentScroll extends StatelessWidget {
  final EncounterCard card;
  final bool showConnections;

  const _ModernContentScroll({required this.card, this.showConnections = false});

  @override
  Widget build(BuildContext context) {
    return _ModernScrollable(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (card.icon != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(card.icon!, style: const TextStyle(fontSize: 40)),
            ),
          const SizedBox(height: 24),
          if (card.title != null)
            Text(
              card.title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
                height: 1.1,
              ),
            ),
          if (card.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              card.subtitle!.toUpperCase(),
              style: TextStyle(
                color: Colors.amber.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
          if (card.content != null) ...[
            const SizedBox(height: 24),
            Text(
              card.content!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 16,
                height: 1.7,
              ),
            ),
          ],
          if (showConnections && card.scriptureConnections != null) ...[
            const SizedBox(height: 32),
            const Text(
              'DEEPER CONNECTIONS',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            ...card.scriptureConnections!.map((sc) => _ConnectionTile(sc: sc)),
          ],
          if (card.revelationKey != null) ...[
            const SizedBox(height: 32),
            _ModernRevelationKey(text: card.revelationKey!),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Components
// ---------------------------------------------------------------------------

class _ModernRevelationKey extends StatelessWidget {
  final String text;
  const _ModernRevelationKey({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt, color: Colors.amber, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernVerseOverlay extends StatelessWidget {
  final EncounterVerseOverlay overlay;
  const _ModernVerseOverlay({required this.overlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${overlay.text}"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— ${overlay.reference}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  final EncounterScriptureConnection sc;
  const _ConnectionTile({required this.sc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sc.reference,
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sc.text,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Remaining Cards (DiscoveryActivation, Completion, Interactive)
// ---------------------------------------------------------------------------

class DiscoveryActivationCard extends StatelessWidget {
  final EncounterCard card;
  const DiscoveryActivationCard({required this.card, super.key});

  @override
  Widget build(BuildContext context) {
    return _CardBackground(
      imageUrl: card.imageUrl,
      mood: card.mood,
      child: _ModernScrollable(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (card.title != null)
              Text(
                card.title!.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
            const SizedBox(height: 32),
            if (card.discoveryQuestions != null)
              ...card.discoveryQuestions!.map((q) => _QuestionTile(q: q)),
            if (card.prayer != null) ...[
              const SizedBox(height: 32),
              _ModernPrayerBox(prayer: card.prayer!),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final EncounterDiscoveryQuestion q;
  const _QuestionTile({required this.q});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q.category.toUpperCase(),
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              q.question,
              style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernPrayerBox extends StatelessWidget {
  final EncounterPrayer prayer;
  const _ModernPrayerBox({required this.prayer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volunteer_activism, color: Colors.purpleAccent, size: 24),
              const SizedBox(width: 12),
              Text(
                (prayer.title ?? 'PRAYER').toUpperCase(),
                style: const TextStyle(
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            prayer.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class CompletionCard extends StatelessWidget {
  final EncounterCard card;
  final VoidCallback? onBackToEncounters;

  const CompletionCard({required this.card, this.onBackToEncounters, super.key});

  @override
  Widget build(BuildContext context) {
    return _CardBackground(
      imageUrl: card.imageUrl,
      mood: card.mood,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: Colors.greenAccent),
            const SizedBox(height: 32),
            const Text(
              'ENCOUNTER COMPLETE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            if (card.completionVerse != null) ...[
              const SizedBox(height: 24),
              Text(
                '"${card.completionVerse!.text}"',
                style: const TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(),
            if (onBackToEncounters != null)
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: onBackToEncounters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('FINISH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class InteractiveMomentCard extends StatelessWidget {
  final EncounterCard card;
  const InteractiveMomentCard({required this.card, super.key});

  @override
  Widget build(BuildContext context) {
    return _CardBackground(
      imageUrl: card.imageUrl,
      mood: card.mood,
      child: Center(
        child: _ModernScrollable(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(card.icon ?? '🌊', style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 32),
              if (card.title != null)
                Text(
                  card.title!,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                  textAlign: TextAlign.center,
                ),
              if (card.reflectionPrompt != null) ...[
                const SizedBox(height: 24),
                Text(
                  card.reflectionPrompt!,
                  style: const TextStyle(color: Colors.white70, fontSize: 18, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class UnknownCard extends StatelessWidget {
  const UnknownCard({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ---------------------------------------------------------------------------
// Factory
// ---------------------------------------------------------------------------

Widget buildEncounterCardWidget(EncounterCard card, {VoidCallback? onBackToEncounters}) {
  switch (card.type) {
    case 'cinematic_scene': return CinematicSceneCard(card: card);
    case 'scripture_moment': return ScriptureMomentCard(card: card);
    case 'character_moment': return CharacterMomentCard(card: card);
    case 'theological_depth': return TheologicalDepthCard(card: card);
    case 'discovery_activation': return DiscoveryActivationCard(card: card);
    case 'completion': return CompletionCard(card: card, onBackToEncounters: onBackToEncounters);
    case 'interactive_moment': return InteractiveMomentCard(card: card);
    default: return const UnknownCard();
  }
}
