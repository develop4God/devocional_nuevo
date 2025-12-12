import 'package:flutter/material.dart';

/// Miniplayer de audio para devocionales con barra de progreso, control de velocidad,
/// botón de stop y selector de voz.
class TtsMiniplayerWidget extends StatefulWidget {
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isPlaying;
  final double playbackRate;
  final List<double> playbackRates;
  final VoidCallback onStop;
  final VoidCallback onSeekStart;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onTogglePlay;
  final VoidCallback onCycleRate;
  final ValueChanged<double>?
      onRateChanged; // Notifica el nuevo playbackRate al padre (opcional)
  final VoidCallback onVoiceSelector;

  const TtsMiniplayerWidget({
    super.key,
    required this.currentPosition,
    required this.totalDuration,
    required this.isPlaying,
    required this.playbackRate,
    required this.playbackRates,
    required this.onStop,
    required this.onSeekStart,
    required this.onSeek,
    required this.onTogglePlay,
    required this.onCycleRate,
    this.onRateChanged,
    required this.onVoiceSelector,
  });

  @override
  State<TtsMiniplayerWidget> createState() => _TtsMiniplayerWidgetState();
}

class _TtsMiniplayerWidgetState extends State<TtsMiniplayerWidget> {
  double? _sliderValue;
  bool _isSeeking = false;

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void _onSliderChange(double value) {
    setState(() {
      _sliderValue = value;
      _isSeeking = true;
    });
  }

  void _onSliderChangeEnd(double value) {
    final newPosition = Duration(
      seconds: (widget.totalDuration.inSeconds * value).round(),
    );
    widget.onSeek(newPosition);
    setState(() {
      _isSeeking = false;
      _sliderValue = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sliderValue = _isSeeking
        ? _sliderValue!
        : (widget.totalDuration.inSeconds == 0
            ? 0.0
            : widget.currentPosition.inSeconds /
                widget.totalDuration.inSeconds);
    // Modern gradient mini-player with rounded pill layout (darker tones)
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            // Más oscuro: usar alpha explícito
            theme.colorScheme.primary.withAlpha(71), // 0.28 * 255 ≈ 71
            theme.colorScheme.primary.withAlpha(31), // 0.12 * 255 ≈ 31
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(31), // 0.12 * 255 ≈ 31
            blurRadius: 14,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Speed pill
          GestureDetector(
            onTap: () async {
              widget.onCycleRate();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    // Pill más marcado (alpha explícito)
                    theme.colorScheme.primary.withAlpha(87), // 0.34 * 255 ≈ 87
                    theme.colorScheme.primary.withAlpha(46), // 0.18 * 255 ≈ 46
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.primary
                      .withAlpha(71), // 0.28 * 255 ≈ 71
                ),
              ),
              child: Text(
                "${widget.playbackRate.toStringAsFixed(1)}x",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Elapsed time
          Text(_formatDuration(widget.currentPosition),
              style: theme.textTheme.bodySmall),
          const SizedBox(width: 8),
          // Slider with custom theme
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor: theme.colorScheme.primary.withAlpha(64),
                // 0.25 * 255 ≈ 63.75 -> 64
                thumbColor: theme.colorScheme.primary,
              ),
              child: Slider(
                value: sliderValue.clamp(0.0, 1.0),
                onChanged: _onSliderChange,
                onChangeEnd: _onSliderChangeEnd,
                min: 0.0,
                max: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Total time
          Text(_formatDuration(widget.totalDuration),
              style: theme.textTheme.bodySmall),
          const SizedBox(width: 8),
          // Stop button (compact)
          IconButton(
            icon: const Icon(Icons.stop_rounded),
            color: theme.colorScheme.error,
            tooltip: 'Detener',
            onPressed: widget.onStop,
          ),
          // Voice selector
          IconButton(
            icon: const Icon(Icons.person_outline),
            color: theme.colorScheme.onSurface,
            tooltip: 'Seleccionar voz',
            onPressed: widget.onVoiceSelector,
          ),
        ],
      ),
    );
  }
}
