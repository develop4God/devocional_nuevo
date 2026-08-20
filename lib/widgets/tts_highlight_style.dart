import 'package:devocional_nuevo/controllers/tts_auto_scroll_driver.dart';
import 'package:flutter/material.dart';

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
