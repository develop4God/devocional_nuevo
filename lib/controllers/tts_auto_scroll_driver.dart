import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/controllers/tts_scroll_target.dart';
import 'package:flutter/foundation.dart';

/// Drives auto-scroll and current-item tracking so a page's text follows TTS
/// playback, karaoke-style.
///
/// Listens to the existing [TtsAudioController] progress notifiers
/// ([TtsAudioController.currentPosition] / [TtsAudioController.totalDuration])
/// and, while playback is active, maps the elapsed fraction onto the page:
///  * scrolls via a [TtsScrollTarget], and
///  * publishes the estimated current item index via [currentIndex], which the
///    page reads to highlight the verse/line being read.
///
/// It only *reads* the controller — it never calls play, pause, seek, or
/// otherwise touches the TTS engine, so it cannot affect playback.
///
/// Position is estimated (word-fraction of an estimated duration), so tracking
/// is proportional and may drift from the exact spoken item. This is the
/// shared, engine-untouched foundation; word-accurate progress can be layered
/// on later as an additive signal.
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

class TtsAutoScrollDriver {
  final TtsAudioController controller;
  final TtsScrollTarget target;

  /// Word-accurate resolver: current item index from a global character offset
  /// (from the TTS progress handler). Preferred when available.
  final int? Function(int charOffset)? indexForCharOffset;

  /// Estimated fallback resolver: current item index from the playback
  /// [fraction] (0.0..1.0). Used when no word-accurate offset is available
  /// (e.g. engines that emit no progress). Either resolver may be null.
  final int? Function(double fraction)? indexForFraction;

  /// Total highlightable items, read lazily. Used to translate a resolved index
  /// into a scroll position so the scroll follows the same signal as the
  /// highlight. Null when the page has no discrete item count.
  final int Function()? itemCount;

  /// Continuous scroll fraction (0.0..1.0) from the word-accurate char offset.
  /// When provided, the scroll follows this smooth signal instead of the
  /// discrete item index — so prose pages (few, large sections) keep creeping
  /// as the words are read instead of jumping once per section then sitting
  /// static. Preferred over index/fraction scrolling when a word offset exists.
  final double? Function(int charOffset)? scrollFractionForOffset;

  /// Index of the item currently being read (null when not playing or when no
  /// resolver produces one). Pages listen to this to highlight.
  final ValueNotifier<int?> currentIndex = ValueNotifier<int?>(null);

  bool _attached = false;
  bool _disposed = false;

  TtsAutoScrollDriver({
    required this.controller,
    required this.target,
    this.indexForCharOffset,
    this.indexForFraction,
    this.itemCount,
    this.scrollFractionForOffset,
  });

  /// Start following playback. Idempotent.
  void attach() {
    if (_attached) return;
    controller.currentPosition.addListener(_onTick);
    controller.state.addListener(_onTick);
    controller.wordTracker.spokenCharOffset.addListener(_onTick);
    _attached = true;
  }

  /// Stop following playback and release listeners. Idempotent.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_attached) {
      try {
        controller.currentPosition.removeListener(_onTick);
        controller.state.removeListener(_onTick);
        controller.wordTracker.spokenCharOffset.removeListener(_onTick);
      } catch (e) {
        debugPrint('⚠️ [TtsAutoScroll] Error removing listeners: $e');
      }
      _attached = false;
    }
    currentIndex.dispose();
  }

  void _onTick() {
    // Only track while actively playing — not while loading, paused, idle,
    // completed, or errored.
    if (controller.state.value != TtsPlayerState.playing) {
      currentIndex.value = null;
      return;
    }

    final total = controller.totalDuration.value.inMilliseconds;
    if (total <= 0) return;

    final pos = controller.currentPosition.value.inMilliseconds;
    final fraction = (pos / total).clamp(0.0, 1.0);

    // Resolve the current item: prefer the word-accurate offset, fall back to
    // the estimated fraction.
    final charOffset = controller.wordTracker.spokenCharOffset.value;
    final bool wordAccurate = charOffset >= 0 && indexForCharOffset != null;
    int? index;
    if (wordAccurate) {
      index = indexForCharOffset!(charOffset);
    } else if (indexForFraction != null) {
      index = indexForFraction!(fraction);
    }

    // Scroll from the SAME signal as the highlight.
    // 1) Continuous char-fraction (smooth creep for prose) when available.
    // 2) Else discrete item index (verse rows) so scroll locks to the highlight.
    // 3) Else the estimated fraction fallback.
    final double? scrollFraction =
        wordAccurate ? scrollFractionForOffset?.call(charOffset) : null;
    final count = itemCount?.call();
    if (scrollFraction != null) {
      target.scrollToFraction(scrollFraction.clamp(0.0, 1.0));
    } else if (index != null && count != null && count > 0) {
      target.scrollToIndex(index, count);
    } else {
      target.scrollToFraction(fraction);
    }

    if (index != null) {
      currentIndex.value = index;
    }
  }
}
