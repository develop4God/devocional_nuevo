import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
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
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Velocidad
            GestureDetector(
              onTap: () async {
                // Si el padre proveyó un handler explícito, usarlo (preserva compatibilidad)
                widget.onCycleRate();
                return;

                // Si no, usar la lógica centralizada en VoiceSettingsService
                try {
                  final voiceService = getService<VoiceSettingsService>();
                  final next = await voiceService.cyclePlaybackRate(
                      currentRate: widget.playbackRate);
                  // Notificar al padre del nuevo rate si se suscribe
                  widget.onRateChanged?.call(next);
                } catch (e) {
                  debugPrint('[TtsMiniplayer] Error cycling playback rate: $e');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(25),
                  // 10% opacity aprox
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${widget.playbackRate.toStringAsFixed(1)}x",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Tiempo transcurrido
            Text(
              _formatDuration(widget.currentPosition),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
            // Slider de progreso
            Expanded(
              child: Slider(
                value: sliderValue.clamp(0.0, 1.0),
                onChanged: _onSliderChange,
                onChangeEnd: _onSliderChangeEnd,
                min: 0.0,
                max: 1.0,
                activeColor: theme.colorScheme.primary,
                inactiveColor: theme.colorScheme.primary
                    .withAlpha(77), // 30% opacity aprox
              ),
            ),
            const SizedBox(width: 8),
            // Tiempo total
            Text(
              _formatDuration(widget.totalDuration),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
            // Botón Stop
            IconButton(
              icon: const Icon(Icons.stop),
              color: theme.colorScheme.error,
              tooltip: 'Detener',
              onPressed: widget.onStop,
            ),
            // Selector de voz (icono de persona)
            IconButton(
              icon: const Icon(Icons.person),
              color: theme.colorScheme.primary,
              tooltip: 'Seleccionar voz',
              onPressed: widget.onVoiceSelector,
            ),
          ],
        ),
      ),
    );
  }
}
