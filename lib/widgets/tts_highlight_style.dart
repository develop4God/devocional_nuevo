import 'package:flutter/material.dart';

/// Shared visual constants for the TTS follow-along highlight, so the devotional
/// and bible readers dim/fade identically instead of each hardcoding values.
class TtsHighlight {
  const TtsHighlight._();

  /// Opacity of items NOT currently being read (the current one stays at 1.0).
  static const double dimOpacity = 0.4;

  /// Fade duration when the highlighted item changes. Half the progress tick so
  /// the fade settles well before the next update, keeping the motion legible.
  static const Duration fadeDuration = Duration(milliseconds: 250);
}

/// Resolved style for one item in a TTS karaoke highlight: dim everything
/// except the item currently being read, and bold that one. Shared decision
/// logic for the Bible reader (per-verse RichText/TextSpan) and the devotional
/// page (per-unit Widget subtree) — the two apply it through different
/// mechanisms (span color alpha vs. AnimatedOpacity) because their content
/// trees differ, but "what counts as current" must stay identical.
class TtsHighlightStyle {
  final bool isCurrent;
  final double opacity;
  final FontWeight? fontWeight;

  const TtsHighlightStyle({
    required this.isCurrent,
    required this.opacity,
    required this.fontWeight,
  });

  /// [currentIndex] is the index currently being read (null when idle/not
  /// playing). [index] is the item being styled.
  factory TtsHighlightStyle.forIndex(int? currentIndex, int index) {
    final isCurrent = currentIndex == index;
    final dim = currentIndex != null && !isCurrent;
    return TtsHighlightStyle(
      isCurrent: isCurrent,
      opacity: dim ? TtsHighlight.dimOpacity : 1.0,
      fontWeight: isCurrent ? FontWeight.bold : null,
    );
  }
}
