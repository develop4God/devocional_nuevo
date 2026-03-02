// lib/widgets/encounter/encounter_card_widgets.dart
//
// One widget per encounter card type.
// All cards handle null optional fields gracefully — never crash.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:devocional_nuevo/models/encounter_card_model.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Mood → Color mapping
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
// Shared: card with optional full-bleed background image + dark scrim overlay
// ---------------------------------------------------------------------------

/// Wraps [child] in a card that shows [imageUrl] as a full-bleed background
/// when provided, with a dark scrim so text stays readable.
/// Falls back to [fallbackColor] (or a dark blue) when no image is available.
class _CardWithImageBackground extends StatelessWidget {
  final String? imageUrl;
  final Widget child;

  const _CardWithImageBackground({
    required this.child,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFF0a0e1a);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image or solid colour
          if (imageUrl != null && imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: base),
              errorWidget: (_, __, ___) => Container(color: base),
            )
          else
            Container(color: base),
          // Dark scrim so text is readable over any image
          Container(color: Colors.black.withValues(alpha: 0.55)),
          // Actual card content
          child,
        ],
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
    final base = moodColor(card.mood);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image or mood-colored container
          if (card.imageUrl != null && card.imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: card.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: base),
              errorWidget: (_, __, ___) => Container(color: base),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [base, base.withValues(alpha: 0.6)],
                ),
              ),
            ),
          // Gradient overlay bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, base.withValues(alpha: 0.95)],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (card.title != null)
                  Text(
                    card.title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (card.narrative != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    card.narrative!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
                if (card.verseOverlay != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"${card.verseOverlay!.text}"',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '— ${card.verseOverlay!.reference}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (card.revelationKey != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.key, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            card.revelationKey!,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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
    final theme = Theme.of(context);
    final hasImage = card.imageUrl != null && card.imageUrl!.isNotEmpty;
    final textColor = hasImage ? Colors.white : null;
    final subTextColor = hasImage ? Colors.white.withValues(alpha: 0.75) : null;

    return _CardWithImageBackground(
      imageUrl: card.imageUrl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (card.verseReference != null)
              Text(
                card.verseReference!,
                style: TextStyle(
                  color: hasImage ? Colors.amber : theme.colorScheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            if (card.verseText != null) ...[
              const SizedBox(height: 16),
              Text(
                '"${card.verseText!}"',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                  fontSize: 20,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (card.reflection != null) ...[
              const SizedBox(height: 24),
              Divider(
                  color: hasImage
                      ? Colors.white.withValues(alpha: 0.3)
                      : theme.dividerColor),
              const SizedBox(height: 16),
              Text(
                card.reflection!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(height: 1.7, color: subTextColor),
                textAlign: TextAlign.left,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CharacterMomentCard
// ---------------------------------------------------------------------------

class CharacterMomentCard extends StatelessWidget {
  final EncounterCard card;

  const CharacterMomentCard({required this.card, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = card.imageUrl != null && card.imageUrl!.isNotEmpty;
    final textColor = hasImage ? Colors.white : null;
    final subTextColor = hasImage ? Colors.white.withValues(alpha: 0.85) : null;

    return _CardWithImageBackground(
      imageUrl: card.imageUrl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (card.icon != null)
                  Text(card.icon!, style: const TextStyle(fontSize: 36)),
                if (card.icon != null) const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    card.title ?? '',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            if (card.content != null) ...[
              const SizedBox(height: 16),
              Text(
                card.content!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(height: 1.7, color: subTextColor),
              ),
            ],
            if (card.revelationKey != null) ...[
              const SizedBox(height: 20),
              _RevelationKeyBox(text: card.revelationKey!),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TheologicalDepthCard
// ---------------------------------------------------------------------------

class TheologicalDepthCard extends StatelessWidget {
  final EncounterCard card;

  const TheologicalDepthCard({required this.card, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = card.imageUrl != null && card.imageUrl!.isNotEmpty;
    final textColor = hasImage ? Colors.white : null;
    final subTextColor = hasImage ? Colors.white.withValues(alpha: 0.85) : null;

    return _CardWithImageBackground(
      imageUrl: card.imageUrl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (card.icon != null)
                  Text(card.icon!, style: const TextStyle(fontSize: 36)),
                if (card.icon != null) const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    card.title ?? '',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            if (card.content != null) ...[
              const SizedBox(height: 16),
              Text(
                card.content!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(height: 1.7, color: subTextColor),
              ),
            ],
            if (card.scriptureConnections != null &&
                card.scriptureConnections!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Scripture Connections',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              ...card.scriptureConnections!.map(
                (sc) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasImage
                          ? Colors.white.withValues(alpha: 0.12)
                          : theme.colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sc.reference,
                          style: TextStyle(
                            color: hasImage
                                ? Colors.amber
                                : theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(sc.text,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(height: 1.5, color: subTextColor)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (card.revelationKey != null) ...[
              const SizedBox(height: 16),
              _RevelationKeyBox(text: card.revelationKey!),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DiscoveryActivationCard
// ---------------------------------------------------------------------------

class DiscoveryActivationCard extends StatelessWidget {
  final EncounterCard card;

  const DiscoveryActivationCard({required this.card, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = card.imageUrl != null && card.imageUrl!.isNotEmpty;
    final textColor = hasImage ? Colors.white : null;
    final subTextColor = hasImage ? Colors.white.withValues(alpha: 0.85) : null;

    return _CardWithImageBackground(
      imageUrl: card.imageUrl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (card.title != null)
              Text(
                card.title!,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            if (card.discoveryQuestions != null &&
                card.discoveryQuestions!.isNotEmpty) ...[
              const SizedBox(height: 20),
              ...card.discoveryQuestions!.map(
                (q) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: hasImage
                          ? Colors.white.withValues(alpha: 0.12)
                          : theme.colorScheme.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (q.category.isNotEmpty)
                          Text(
                            q.category.toUpperCase(),
                            style: TextStyle(
                              color: hasImage
                                  ? Colors.amber
                                  : theme.colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(q.question,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(height: 1.5, color: subTextColor)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (card.prayer != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasImage
                      ? Colors.white.withValues(alpha: 0.12)
                      : theme.colorScheme.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: hasImage
                          ? Colors.white.withValues(alpha: 0.25)
                          : theme.colorScheme.secondary
                              .withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.volunteer_activism,
                            size: 18, color: Colors.purple),
                        const SizedBox(width: 8),
                        Text(
                          card.prayer!.title ?? 'Prayer',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      card.prayer!.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CompletionCard
// ---------------------------------------------------------------------------

class CompletionCard extends StatefulWidget {
  final EncounterCard card;
  final VoidCallback? onBackToEncounters;

  const CompletionCard({
    required this.card,
    this.onBackToEncounters,
    super.key,
  });

  @override
  State<CompletionCard> createState() => _CompletionCardState();
}

class _CompletionCardState extends State<CompletionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage =
        widget.card.imageUrl != null && widget.card.imageUrl!.isNotEmpty;
    final textColor = hasImage ? Colors.white : null;
    final subTextColor = hasImage ? Colors.white.withValues(alpha: 0.85) : null;

    return _CardWithImageBackground(
      imageUrl: widget.card.imageUrl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary
                          .withValues(alpha: _glowAnimation.value),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: hasImage ? Colors.white : theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (widget.card.title != null)
              Text(
                widget.card.title!,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            if (widget.card.completionVerse != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasImage
                      ? Colors.white.withValues(alpha: 0.12)
                      : theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '"${widget.card.completionVerse!.text}"',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '— ${widget.card.completionVerse!.reference}',
                      style: TextStyle(
                        color:
                            hasImage ? Colors.amber : theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.card.reflectionPrompt != null) ...[
              const SizedBox(height: 20),
              Text(
                widget.card.reflectionPrompt!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(height: 1.7, color: subTextColor),
                textAlign: TextAlign.center,
              ),
            ],
            if (widget.onBackToEncounters != null) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('back_to_encounters_button'),
                  onPressed: widget.onBackToEncounters,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back to Encounters'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// UnknownCard — never crashes, renders empty
// ---------------------------------------------------------------------------

class UnknownCard extends StatelessWidget {
  const UnknownCard({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ---------------------------------------------------------------------------
// Shared helper widget
// ---------------------------------------------------------------------------

class _RevelationKeyBox extends StatelessWidget {
  final String text;

  const _RevelationKeyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.key, color: Colors.amber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.amber.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Factory: build the correct widget for a card
// ---------------------------------------------------------------------------

Widget buildEncounterCardWidget(
  EncounterCard card, {
  VoidCallback? onBackToEncounters,
}) {
  switch (card.type) {
    case 'cinematic_scene':
      return CinematicSceneCard(card: card);
    case 'scripture_moment':
      return ScriptureMomentCard(card: card);
    case 'character_moment':
      return CharacterMomentCard(card: card);
    case 'theological_depth':
      return TheologicalDepthCard(card: card);
    case 'discovery_activation':
      return DiscoveryActivationCard(card: card);
    case 'completion':
      return CompletionCard(card: card, onBackToEncounters: onBackToEncounters);
    case 'interactive_moment':
      // v1: model only, no UI — render as empty
      return const UnknownCard();
    default:
      return const UnknownCard();
  }
}
