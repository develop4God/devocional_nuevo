import 'package:flutter/material.dart';
import '../extensions/string_extensions.dart';

/// Bottom modal sheet for TTS audio playback with modern gradient UI
class TtsMiniplayerModal extends StatefulWidget {
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isPlaying;
  final bool isLoading;
  final double playbackRate;
  final List<double> playbackRates;
  final VoidCallback onStop;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onTogglePlay;
  final VoidCallback onCycleRate;
  final VoidCallback onVoiceSelector;

  const TtsMiniplayerModal({
    super.key,
    required this.currentPosition,
    required this.totalDuration,
    required this.isPlaying,
    this.isLoading = false,
    required this.playbackRate,
    required this.playbackRates,
    required this.onStop,
    required this.onSeek,
    required this.onTogglePlay,
    required this.onCycleRate,
    required this.onVoiceSelector,
  });

  @override
  State<TtsMiniplayerModal> createState() => _TtsMiniplayerModalState();
}

class _TtsMiniplayerModalState extends State<TtsMiniplayerModal> {
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
    final colorScheme = theme.colorScheme;

    final sliderValue = _isSeeking
        ? _sliderValue!
        : (widget.totalDuration.inSeconds == 0
            ? 0.0
            : widget.currentPosition.inSeconds /
                widget.totalDuration.inSeconds);

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
              // Title animado
              SizedBox(
                height: 32,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: -20.0, end: 20.0),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(value, 0),
                      child: child,
                    );
                  },
                  onEnd: () {
                    setState(() {}); // reinicia la animación
                  },
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
              // Play/Pause button (large)
              Container(
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
                child: widget.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          widget.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 40,
                        ),
                        color: Colors.white,
                        onPressed: widget.onTogglePlay,
                      ),
              ),
              const SizedBox(height: 32),
              // Progress bar
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 10),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 18),
                      activeTrackColor: colorScheme.primary,
                      inactiveTrackColor: colorScheme.primary.withAlpha(80),
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: sliderValue.clamp(0.0, 1.0),
                      onChanged: _onSliderChange,
                      onChangeEnd: _onSliderChangeEnd,
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
                          _formatDuration(widget.currentPosition),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withAlpha(200),
                          ),
                        ),
                        Text(
                          _formatDuration(widget.totalDuration),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withAlpha(200),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Controls row
              Row(
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
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${widget.playbackRate.toStringAsFixed(1)}x",
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.primary,
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
                    color: colorScheme.onSurface,
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
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
