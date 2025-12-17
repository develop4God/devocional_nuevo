import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../extensions/string_extensions.dart';

/// Bottom modal sheet for TTS audio playback with modern gradient UI
class TtsMiniplayerModal extends StatefulWidget {
  final Duration currentPosition;
  final Duration totalDuration;
  // Optional: provide a listenable (e.g., from player) to receive real-time updates
  final ValueListenable<Duration>? positionListenable;
  // Debug flag to enable emoji logs
  final bool debug;
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
    this.positionListenable,
    this.debug = false,
  });

  @override
  State<TtsMiniplayerModal> createState() => _TtsMiniplayerModalState();
}

class _TtsMiniplayerModalState extends State<TtsMiniplayerModal> {
  double? _sliderValue;
  bool _isSeeking = false;
  Duration? _listenedPosition;
  VoidCallback? _listenableListener;

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void _onSliderChange(double value) {
    if (widget.debug) print('🖐️ [tts] onChanged dragging value=${value.toStringAsFixed(3)}');
    setState(() {
      _sliderValue = value.clamp(0.0, 1.0);
      _isSeeking = true;
    });
  }

  @override
  void didUpdateWidget(covariant TtsMiniplayerModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.debug) {
      print('🔄 [tts] didUpdateWidget: oldTotal=${oldWidget.totalDuration.inMilliseconds}ms newTotal=${widget.totalDuration.inMilliseconds}ms');
      print('🔄 [tts] didUpdateWidget: oldPos=${oldWidget.currentPosition.inMilliseconds}ms newPos=${widget.currentPosition.inMilliseconds}ms');
    }
    // Si el totalDuration cambió, resetear el sliderValue
    if (oldWidget.totalDuration != widget.totalDuration) {
      setState(() {
        _sliderValue = null;
        _isSeeking = false;
      });
    } else if (!_isSeeking && oldWidget.currentPosition != widget.currentPosition) {
      // Cuando el padre actualiza currentPosition y no estamos en seek, refrescar
      if (widget.debug) print('🔔 [tts] parent updated currentPosition and not seeking -> rebuild');
      setState(() {});
    }
    // Handle listenable swap
    if (oldWidget.positionListenable != widget.positionListenable) {
      if (widget.debug) print('🔁 [tts] positionListenable changed -> reattach');
      _detachListenable(oldWidget.positionListenable);
      _attachListenable(widget.positionListenable);
    }
  }

  void _attachListenable(ValueListenable<Duration>? l) {
    if (l == null) return;
    _listenableListener = () {
      final pos = l.value;
      if (widget.debug) print('🔁 [tts] listen pos=${pos.inMilliseconds}ms isSeeking=$_isSeeking');
      // Only update UI when not actively dragging/ seeking
      if (!_isSeeking) {
        setState(() {
          _listenedPosition = pos;
        });
      } else {
        // still update cached position so when user releases we reflect accurate value
        _listenedPosition = pos;
      }
    };
    if (widget.debug) print('🔗 [tts] attaching positionListenable');
    l.addListener(_listenableListener!);
  }

  void _detachListenable(ValueListenable<Duration>? l) {
    if (l == null || _listenableListener == null) return;
    if (widget.debug) print('❌ [tts] detaching previous positionListenable');
    try {
      l.removeListener(_listenableListener!);
    } catch (_) {}
    _listenableListener = null;
    _listenedPosition = null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.debug) print('🚀 [tts] initState total=${widget.totalDuration.inMilliseconds}ms current=${widget.currentPosition.inMilliseconds}ms hasListenable=${widget.positionListenable!=null}');
    _attachListenable(widget.positionListenable);
  }

  @override
  void dispose() {
    if (widget.debug) print('🗑️ [tts] dispose - removing listenable');
    _detachListenable(widget.positionListenable);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalMs = widget.totalDuration.inMilliseconds;
    final sourcePosition = _listenedPosition ?? widget.currentPosition;
    final currentMs = math.min(sourcePosition.inMilliseconds, totalMs);

    final sliderValue = _isSeeking
        ? (_sliderValue ?? 0.0)
        : (totalMs == 0 ? 0.0 : currentMs / totalMs);

    if (widget.debug) {
      print('🧭 [tts] build slider=$sliderValue currentMs=$currentMs totalMs=$totalMs isSeeking=$_isSeeking sliderCache=$_sliderValue listened=${_listenedPosition?.inMilliseconds}');
    }

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
              // Solo mostrar el texto sin animación
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
                      value: sliderValue.clamp(0.0, 1.0).toDouble(),
                      onChanged: _onSliderChange,
                      onChangeEnd: (value) {
                        final totalMs = widget.totalDuration.inMilliseconds;
                        int millis = (totalMs * value).round();
                        millis = math.max(0, math.min(totalMs, millis));
                        final newPosition = Duration(milliseconds: millis);
                        if (widget.debug) print('⏯️ [tts] onChangeEnd user seek to ${millis}ms (fraction=${value.toStringAsFixed(3)})');
                        widget.onSeek(newPosition);
                        setState(() {
                          _isSeeking = false;
                          _sliderValue = null;
                        });
                      },
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
