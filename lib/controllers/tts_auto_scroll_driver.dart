import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/controllers/tts_scroll_target.dart';
import 'package:flutter/foundation.dart';

/// Drives auto-scroll of a page's text so it follows TTS playback.
///
/// Listens to the existing [TtsAudioController] progress notifiers
/// ([TtsAudioController.currentPosition] / [TtsAudioController.totalDuration])
/// and, while playback is active, maps the elapsed fraction onto the page via a
/// [TtsScrollTarget]. It only *reads* the controller — it never calls play,
/// pause, seek, or otherwise touches the TTS engine, so it cannot affect
/// playback.
///
/// Position is estimated (word-fraction of an estimated duration), so scrolling
/// tracks proportionally and may drift from the exact spoken word. This is the
/// shared, engine-untouched foundation; word-accurate progress can be layered
/// on later as an additive signal.
class TtsAutoScrollDriver {
  final TtsAudioController controller;
  final TtsScrollTarget target;

  bool _attached = false;

  TtsAutoScrollDriver({required this.controller, required this.target});

  /// Start following playback. Idempotent.
  void attach() {
    if (_attached) return;
    controller.currentPosition.addListener(_onTick);
    controller.state.addListener(_onTick);
    _attached = true;
  }

  /// Stop following playback and release listeners. Idempotent.
  void dispose() {
    if (!_attached) return;
    try {
      controller.currentPosition.removeListener(_onTick);
      controller.state.removeListener(_onTick);
    } catch (e) {
      debugPrint('⚠️ [TtsAutoScroll] Error removing listeners: $e');
    }
    _attached = false;
  }

  void _onTick() {
    // Only scroll while actively playing — not while loading, paused, idle,
    // completed, or errored.
    if (controller.state.value != TtsPlayerState.playing) return;

    final total = controller.totalDuration.value.inMilliseconds;
    if (total <= 0) return;

    final pos = controller.currentPosition.value.inMilliseconds;
    final fraction = (pos / total).clamp(0.0, 1.0);
    target.scrollToFraction(fraction);
  }
}
