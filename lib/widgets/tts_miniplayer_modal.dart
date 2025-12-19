import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../extensions/string_extensions.dart';
import '../controllers/tts_audio_controller.dart';

/// Estado combinado para evitar múltiples builders anidados
class _TtsPlayerSnapshot {
  final Duration position;
  final Duration totalDuration;
  final TtsPlayerState state;
  final double playbackRate;

  const _TtsPlayerSnapshot({
    required this.position,
    required this.totalDuration,
    required this.state,
    required this.playbackRate,
  });

  bool get isPlaying => state == TtsPlayerState.playing;
  bool get isLoading => state == TtsPlayerState.loading;
}

/// Modal para reproducción TTS con arquitectura reactiva optimizada
class TtsMiniplayerModal extends StatefulWidget {
  // Listenables - fuente única de verdad
  final ValueListenable<Duration> positionListenable;
  final ValueListenable<Duration> totalDurationListenable;
  final ValueListenable<TtsPlayerState> stateListenable;
  final ValueListenable<double> playbackRateListenable;

  // Props estáticos (listas)
  final List<double> playbackRates;

  // Callbacks
  final VoidCallback onStop;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onTogglePlay;
  final VoidCallback onCycleRate;
  final VoidCallback onVoiceSelector;

  // Debug
  final bool debug;

  const TtsMiniplayerModal({
    super.key,
    required this.positionListenable,
    required this.totalDurationListenable,
    required this.stateListenable,
    required this.playbackRateListenable,
    required this.playbackRates,
    required this.onStop,
    required this.onSeek,
    required this.onTogglePlay,
    required this.onCycleRate,
    required this.onVoiceSelector,
    this.debug = false,
  });

  @override
  State<TtsMiniplayerModal> createState() => _TtsMiniplayerModalState();
}

class _TtsMiniplayerModalState extends State<TtsMiniplayerModal> {
  double? _sliderValue;
  bool _isSeeking = false;

  // Listeners combinados para performance
  late final VoidCallback _combinedListener;
  _TtsPlayerSnapshot? _cachedSnapshot;

  @override
  void initState() {
    super.initState();
    _attachListeners();
  }

  @override
  void dispose() {
    _detachListeners();
    super.dispose();
  }

  void _attachListeners() {
    _combinedListener = () {
      if (!mounted) return;

      // Solo actualizar si no estamos haciendo seek
      if (!_isSeeking) {
        setState(() {
          _cachedSnapshot = _createSnapshot();
        });
      }
    };

    widget.positionListenable.addListener(_combinedListener);
    widget.totalDurationListenable.addListener(_combinedListener);
    widget.stateListenable.addListener(_combinedListener);
    widget.playbackRateListenable.addListener(_combinedListener);
  }

  void _detachListeners() {
    try {
      widget.positionListenable.removeListener(_combinedListener);
      widget.totalDurationListenable.removeListener(_combinedListener);
      widget.stateListenable.removeListener(_combinedListener);
      widget.playbackRateListenable.removeListener(_combinedListener);
    } catch (e) {
      if (widget.debug) {
        debugPrint('⚠️ [TTS Modal] Error removing listeners: $e');
      }
    }
  }

  _TtsPlayerSnapshot _createSnapshot() {
    return _TtsPlayerSnapshot(
      position: widget.positionListenable.value,
      totalDuration: widget.totalDurationListenable.value,
      state: widget.stateListenable.value,
      playbackRate: widget.playbackRateListenable.value,
    );
  }

  void _onSliderChange(double value) {
    if (widget.debug) {
      debugPrint(
          '🖐️ [TTS Modal] Slider dragging: ${value.toStringAsFixed(3)}');
    }
    setState(() {
      _sliderValue = value.clamp(0.0, 1.0);
      _isSeeking = true;
    });
  }

  void _onSliderChangeEnd(double value, Duration totalDuration) {
    final totalMs = totalDuration.inMilliseconds;
    int millis = (totalMs * value).round();
    millis = math.max(0, math.min(totalMs, millis));
    final newPosition = Duration(milliseconds: millis);

    if (widget.debug) {
      debugPrint(
          '⏯️ [TTS Modal] Seek to ${millis}ms (${value.toStringAsFixed(3)})');
    }

    widget.onSeek(newPosition);

    setState(() {
      _isSeeking = false;
      _sliderValue = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Crear snapshot actual o usar el cacheado
    final snapshot = _cachedSnapshot ?? _createSnapshot();

    final totalMs = snapshot.totalDuration.inMilliseconds;
    final currentMs = math.min(snapshot.position.inMilliseconds, totalMs);

    // Calcular valor del slider
    final sliderValue = _isSeeking
        ? (_sliderValue ?? 0.0)
        : (totalMs == 0 ? 0.0 : currentMs / totalMs);

    if (widget.debug) {
      debugPrint('🧭 [TTS Modal] Build - slider: $sliderValue, '
          'pos: ${currentMs}ms, total: ${totalMs}ms, '
          'seeking: $_isSeeking, state: ${snapshot.state}');
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withAlpha(220),
            colorScheme.secondary.withAlpha(230),
            colorScheme.surface.withAlpha(240),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(80),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Swipe indicator
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(180),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Título
              SizedBox(
                height: 32,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'app.audio_playing'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Play/Pause button
              _buildPlayPauseButton(context, colorScheme, snapshot),
              const SizedBox(height: 32),

              // Progress bar
              _buildProgressBar(
                context,
                colorScheme,
                snapshot,
                sliderValue,
              ),
              const SizedBox(height: 24),

              // Controls row
              _buildControlsRow(context, colorScheme, snapshot),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton(
    BuildContext context,
    ColorScheme colorScheme,
    _TtsPlayerSnapshot snapshot,
  ) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withAlpha(200),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(100),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: snapshot.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : IconButton(
              icon: Icon(
                snapshot.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 40,
              ),
              color: Colors.white,
              onPressed: widget.onTogglePlay,
            ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    ColorScheme colorScheme,
    _TtsPlayerSnapshot snapshot,
    double sliderValue,
  ) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            activeTrackColor: Colors.grey[800], // Gris oscuro
            inactiveTrackColor: Colors.grey[400], // Gris claro
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: sliderValue.clamp(0.0, 1.0).toDouble(),
            onChanged: _onSliderChange,
            onChangeEnd: (value) =>
                _onSliderChangeEnd(value, snapshot.totalDuration),
            min: 0.0,
            max: 1.0,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(snapshot.position),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                _formatDuration(snapshot.totalDuration),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlsRow(
    BuildContext context,
    ColorScheme colorScheme,
    _TtsPlayerSnapshot snapshot,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Speed control
        GestureDetector(
          onTap: widget.onCycleRate,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withAlpha(100),
                  colorScheme.primary.withAlpha(60),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.primary.withAlpha(150),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.speed_rounded,
                  size: 20,
                  color: Colors.black,
                ),
                const SizedBox(width: 8),
                Text(
                  "${snapshot.playbackRate.toStringAsFixed(1)}x",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),

        // Voice selector
        IconButton(
          icon: const Icon(Icons.person_outline),
          iconSize: 32,
          color: Colors.black,
          tooltip: 'Seleccionar voz',
          onPressed: widget.onVoiceSelector,
        ),

        // Stop button
        IconButton(
          icon: const Icon(Icons.stop_rounded),
          iconSize: 32,
          color: colorScheme.error,
          tooltip: 'Detener',
          onPressed: widget.onStop,
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}
