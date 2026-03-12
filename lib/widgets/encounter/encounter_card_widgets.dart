// lib/widgets/encounter/encounter_card_widgets.dart
//
// Modern, immersive encounter card widgets.
// Redesigned with a "Visual First" approach and modern transitions.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/encounter_card_model.dart';
import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Mood -> Color mapping
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
// Shared Components: Animated Entry
// ---------------------------------------------------------------------------

class _DelayedEntry extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const _DelayedEntry({required this.child, this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Shared: Visual Header
// ---------------------------------------------------------------------------

class _VisualHeader extends StatelessWidget {
  final String? imageUrl;
  final String? mood;
  final String? icon;

  const _VisualHeader({this.imageUrl, this.mood, this.icon});

  @override
  Widget build(BuildContext context) {
    final base = moodColor(mood);
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(color: base),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: base),
              errorWidget: (_, __, ___) => Container(color: base),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  base.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          if (icon != null)
            Center(
              child: _DelayedEntry(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(icon!, style: const TextStyle(fontSize: 48)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared: Card Shell (Stateful to handle scroll feedback)
// ---------------------------------------------------------------------------

class _CardShell extends StatefulWidget {
  final String? imageUrl;
  final String? mood;
  final String? icon;
  final List<Widget> children;
  final bool showScrollIndicator;

  const _CardShell({
    this.imageUrl,
    this.mood,
    this.icon,
    required this.children,
    this.showScrollIndicator = true,
  });

  @override
  State<_CardShell> createState() => _CardShellState();
}

class _CardShellState extends State<_CardShell> {
  final ScrollController _scrollController = ScrollController();
  bool _canScroll = false;
  bool _isAtTop = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    // Check for scrollability after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        setState(() {
          _canScroll = _scrollController.position.maxScrollExtent > 0;
        });
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final atTop = _scrollController.offset <= 10;
      if (atTop != _isAtTop) {
        setState(() => _isAtTop = atTop);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = moodColor(widget.mood);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: base,
        child: Stack(
          children: [
            Column(
              children: [
                _VisualHeader(
                    imageUrl: widget.imageUrl,
                    mood: widget.mood,
                    icon: widget.icon),
                Expanded(
                  child: RawScrollbar(
                    controller: _scrollController,
                    thumbColor: Colors.white.withValues(alpha: 0.3),
                    thickness: 4,
                    radius: const Radius.circular(10),
                    thumbVisibility: true,
                    // Always show if scrollable to indicate more content
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.children,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Modern "Scroll for more" indicator
            if (widget.showScrollIndicator && _canScroll && _isAtTop)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: _ScrollIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScrollIndicator extends StatefulWidget {
  @override
  State<_ScrollIndicator> createState() => _ScrollIndicatorState();
}

class _ScrollIndicatorState extends State<_ScrollIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _animation = Tween<double>(begin: 0, end: 10)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Opacity(
            opacity: 1.0 - (_animation.value / 15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    'encounters.scroll_for_more'.tr().toUpperCase(),
                    style: const TextStyle(
                        color: Color(0xFF0a0e1a),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.keyboard_arrow_down,
                    color: Color(0xFFFFD700), size: 16),
              ],
            ),
          ),
        );
      },
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
    return _CardShell(
      imageUrl: card.imageUrl,
      mood: card.mood,
      children: [
        if (card.title != null)
          _DelayedEntry(
            delay: const Duration(milliseconds: 300),
            child: Text(
              card.title!.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        if (card.narrative != null) ...[
          const SizedBox(height: 16),
          _DelayedEntry(
            delay: const Duration(milliseconds: 400),
            child: Text(
              card.narrative!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ),
        ],
        if (card.verseOverlay != null) ...[
          const SizedBox(height: 24),
          _DelayedEntry(
            delay: const Duration(milliseconds: 500),
            child: _ModernVerseOverlay(overlay: card.verseOverlay!),
          ),
        ],
        if (card.revelationKey != null) ...[
          const SizedBox(height: 20),
          _DelayedEntry(
            delay: const Duration(milliseconds: 600),
            child: _ModernRevelationKey(text: card.revelationKey!),
          ),
        ],
      ],
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
    return _CardShell(
      imageUrl: card.imageUrl,
      mood: card.mood,
      children: [
        Center(
          child: Column(
            children: [
              if (card.verseReference != null)
                _DelayedEntry(
                  delay: const Duration(milliseconds: 300),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      card.verseReference!.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              if (card.verseText != null) ...[
                const SizedBox(height: 24),
                _DelayedEntry(
                  delay: const Duration(milliseconds: 400),
                  child: Text(
                    card.verseText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              if (card.reflection != null) ...[
                const SizedBox(height: 32),
                _DelayedEntry(
                  delay: const Duration(milliseconds: 500),
                  child: Text(
                    card.reflection!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 15,
                      height: 1.7,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              if (card.revelationKey != null) ...[
                const SizedBox(height: 24),
                _DelayedEntry(
                  delay: const Duration(milliseconds: 600),
                  child: _ModernRevelationKey(text: card.revelationKey!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CharacterMomentCard & TheologicalDepthCard
// ---------------------------------------------------------------------------

class CharacterMomentCard extends StatelessWidget {
  final EncounterCard card;

  const CharacterMomentCard({required this.card, super.key});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      imageUrl: card.imageUrl,
      mood: card.mood,
      icon: card.icon,
      children: [
        if (card.title != null)
          _DelayedEntry(
            delay: const Duration(milliseconds: 300),
            child: Text(
              card.title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        if (card.subtitle != null) ...[
          const SizedBox(height: 8),
          _DelayedEntry(
            delay: const Duration(milliseconds: 400),
            child: Text(
              card.subtitle!.toUpperCase(),
              style: TextStyle(
                color: Colors.amber.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
        if (card.content != null) ...[
          const SizedBox(height: 24),
          _DelayedEntry(
            delay: const Duration(milliseconds: 500),
            child: Text(
              card.content!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 16,
                height: 1.7,
              ),
            ),
          ),
        ],
        if (card.revelationKey != null) ...[
          const SizedBox(height: 32),
          _DelayedEntry(
            delay: const Duration(milliseconds: 600),
            child: _ModernRevelationKey(text: card.revelationKey!),
          ),
        ],
      ],
    );
  }
}

class TheologicalDepthCard extends StatelessWidget {
  final EncounterCard card;

  const TheologicalDepthCard({required this.card, super.key});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      imageUrl: card.imageUrl,
      mood: card.mood,
      icon: card.icon,
      children: [
        if (card.title != null)
          _DelayedEntry(
            delay: const Duration(milliseconds: 300),
            child: Text(
              card.title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        if (card.subtitle != null) ...[
          const SizedBox(height: 8),
          _DelayedEntry(
            delay: const Duration(milliseconds: 400),
            child: Text(
              card.subtitle!.toUpperCase(),
              style: TextStyle(
                color: Colors.amber.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
        if (card.content != null) ...[
          const SizedBox(height: 24),
          _DelayedEntry(
            delay: const Duration(milliseconds: 500),
            child: Text(
              card.content!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 16,
                height: 1.7,
              ),
            ),
          ),
        ],
        if (card.scriptureConnections != null) ...[
          const SizedBox(height: 32),
          _DelayedEntry(
            delay: const Duration(milliseconds: 600),
            child: Text(
              'encounters.deeper_connections'.tr(),
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...card.scriptureConnections!.map(
            (sc) => _DelayedEntry(
              delay: const Duration(milliseconds: 700),
              child: _ConnectionTile(sc: sc),
            ),
          ),
        ],
        if (card.revelationKey != null) ...[
          const SizedBox(height: 32),
          _DelayedEntry(
            delay: const Duration(milliseconds: 800),
            child: _ModernRevelationKey(text: card.revelationKey!),
          ),
        ],
      ],
    );
  }
}

class DiscoveryActivationCard extends StatelessWidget {
  final EncounterCard card;

  const DiscoveryActivationCard({required this.card, super.key});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      imageUrl: card.imageUrl,
      mood: card.mood,
      children: [
        if (card.title != null)
          _DelayedEntry(
            delay: const Duration(milliseconds: 300),
            child: Text(
              card.title!.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900),
            ),
          ),
        const SizedBox(height: 24),
        if (card.discoveryQuestions != null)
          ...card.discoveryQuestions!.asMap().entries.map(
                (e) => _DelayedEntry(
                  delay: Duration(milliseconds: 400 + (e.key * 100)),
                  child: _QuestionTile(q: e.value),
                ),
              ),
        if (card.prayer != null) ...[
          const SizedBox(height: 32),
          _DelayedEntry(
            delay: const Duration(milliseconds: 800),
            child: _ModernPrayerBox(prayer: card.prayer!),
          ),
        ],
      ],
    );
  }
}

class CompletionCard extends StatefulWidget {
  final EncounterCard card;
  final VoidCallback? onBackToEncounters;
  final String? bibleVersion;
  final String? language;
  final bool showCompletionMessage;

  const CompletionCard({
    required this.card,
    this.onBackToEncounters,
    this.bibleVersion,
    this.language,
    this.showCompletionMessage = false,
    super.key,
  });

  @override
  State<CompletionCard> createState() => _CompletionCardState();
}

class _CompletionCardState extends State<CompletionCard> {
  bool _showCompletionMessage = false;

  @override
  void initState() {
    super.initState();
    _showCompletionMessage = widget.showCompletionMessage;
    debugPrint(
      '🔵 [CompletionCard] Initialized — already completed: $_showCompletionMessage',
    );
  }

  void _onCompleteButtonTapped() {
    if (_showCompletionMessage) {
      debugPrint(
          '⚠️ [CompletionCard] Tap ignored — encounter already completed');
      return;
    }
    debugPrint('✅ [CompletionCard] Complete button tapped — marking as done');
    setState(() {
      _showCompletionMessage = true;
    });

    // Call the callback after showing the message
    Future.delayed(const Duration(milliseconds: 500), () {
      if (widget.onBackToEncounters != null) {
        widget.onBackToEncounters!();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      imageUrl: widget.card.imageUrl,
      mood: widget.card.mood,
      showScrollIndicator: false,
      children: [
        Center(
          child: Column(
            children: [
              // Check icon - only show if _showCompletionMessage is true
              if (_showCompletionMessage)
                const _DelayedEntry(
                  delay: Duration(milliseconds: 300),
                  child: Icon(Icons.verified_rounded,
                      size: 80, color: Colors.greenAccent),
                )
              else
                const SizedBox(height: 80), // Placeholder space when hidden
              const SizedBox(height: 24),
              // Completion text - only show if _showCompletionMessage is true
              if (_showCompletionMessage)
                _DelayedEntry(
                  delay: const Duration(milliseconds: 400),
                  child: Text(
                    'encounters.encounter_complete'.tr(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                const SizedBox(height: 0),
              if (widget.card.completionVerse != null) ...[
                const SizedBox(height: 24),
                _DelayedEntry(
                  delay: const Duration(milliseconds: 500),
                  child: Text(
                    '"${widget.card.completionVerse!.text}"',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                _DelayedEntry(
                  delay: const Duration(milliseconds: 550),
                  child: Text(
                    '— ${widget.card.completionVerse!.reference}',
                    style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.card.completionVerse!.bibleVersion != null) ...[
                  const SizedBox(height: 4),
                  _DelayedEntry(
                    delay: const Duration(milliseconds: 600),
                    child: Text(
                      widget.card.completionVerse!.bibleVersion!,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 48),
              _DelayedEntry(
                delay: const Duration(milliseconds: 600),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed:
                        _showCompletionMessage ? null : _onCompleteButtonTapped,
                    icon: _showCompletionMessage
                        ? const Icon(Icons.verified_rounded,
                            color: Colors.greenAccent, size: 20)
                        : const SizedBox.shrink(),
                    label: Text(
                      _showCompletionMessage
                          ? 'encounters.encounter_complete'.tr()
                          : 'encounters.complete'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: _showCompletionMessage
                            ? const Color(0xFFFFD700)
                            : Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showCompletionMessage
                          ? Colors.transparent
                          : Colors.white,
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: const Color(0xFFFFD700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: _showCompletionMessage
                            ? const BorderSide(
                                color: Color(0xFFFFD700), width: 1.5)
                            : BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              // Bible version copyright disclaimer
              if (widget.bibleVersion != null) ...[
                const SizedBox(height: 32),
                _DelayedEntry(
                  delay: const Duration(milliseconds: 700),
                  child: _CopyrightDisclaimer(
                    bibleVersion: widget.bibleVersion!,
                    language: widget.language ?? 'en',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class InteractiveMomentCard extends StatelessWidget {
  final EncounterCard card;

  const InteractiveMomentCard({required this.card, super.key});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      imageUrl: card.imageUrl,
      mood: card.mood,
      children: [
        Center(
          child: Column(
            children: [
              _DelayedEntry(
                delay: const Duration(milliseconds: 300),
                child: Text(card.icon ?? '🌊',
                    style: const TextStyle(fontSize: 64)),
              ),
              const SizedBox(height: 24),
              if (card.title != null)
                _DelayedEntry(
                  delay: const Duration(milliseconds: 400),
                  child: Text(
                    card.title!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (card.reflectionPrompt != null) ...[
                const SizedBox(height: 24),
                _DelayedEntry(
                  delay: const Duration(milliseconds: 500),
                  child: Text(
                    card.reflectionPrompt!,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 18, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ModernRevelationKey extends StatelessWidget {
  final String text;

  const _ModernRevelationKey({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${overlay.text}"',
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          Text(
            '— ${overlay.reference}',
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700),
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
                  fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              sc.text,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.5),
            ),
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
          color: Colors.white.withValues(alpha: 0.05),
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
                  letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            Text(q.question,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, height: 1.5)),
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
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (prayer.title ?? 'encounters.prayer_label'.tr()).toUpperCase(),
            style: const TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.w900,
                fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(prayer.content,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  height: 1.7)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CopyrightDisclaimer
// ---------------------------------------------------------------------------

class _CopyrightDisclaimer extends StatelessWidget {
  final String bibleVersion;
  final String language;

  const _CopyrightDisclaimer({
    required this.bibleVersion,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final copyrightText =
        CopyrightUtils.getCopyrightText(language, bibleVersion);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              copyrightText,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildEncounterCardWidget(
  EncounterCard card, {
  VoidCallback? onBackToEncounters,
  String? bibleVersion,
  String? language,
  bool showCompletionMessage = false,
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
      return CompletionCard(
        card: card,
        onBackToEncounters: onBackToEncounters,
        bibleVersion: bibleVersion,
        language: language,
        showCompletionMessage: showCompletionMessage,
      );
    case 'interactive_moment':
      return InteractiveMomentCard(card: card);
    default:
      return const SizedBox.shrink();
  }
}
