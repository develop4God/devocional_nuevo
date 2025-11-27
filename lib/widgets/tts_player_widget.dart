import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';
import 'package:flutter/material.dart';

class TtsPlayerWidget extends StatefulWidget {
  final Devocional devocional;
  final TtsAudioController audioController;
  final void Function()? onCompleted;

  const TtsPlayerWidget({
    super.key,
    required this.devocional,
    required this.audioController,
    this.onCompleted,
  });

  @override
  State<TtsPlayerWidget> createState() => _TtsPlayerWidgetState();
}

class _TtsPlayerWidgetState extends State<TtsPlayerWidget> {
  @override
  void didUpdateWidget(covariant TtsPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.devocional.id != widget.devocional.id) {
      debugPrint(
          '[TTS Widget] Cambio de devocional detectado, deteniendo audio');
      widget.audioController.stop();
    }
  }

  @override
  void dispose() {
    debugPrint('[TTS Widget] dispose() llamado, deteniendo audio');
    widget.audioController.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '[TTS Widget] build() llamado para devocional: [32m${widget.devocional.id}[0m');
    // Armar el texto TTS normalizado como un solo string
    final language = Localizations.localeOf(context).languageCode;
    final ttsText = '${BibleTextFormatter.normalizeTtsText(
      widget.devocional.versiculo,
      language,
      widget.devocional.version,
    )}\n${BibleTextFormatter.normalizeTtsText(
      widget.devocional.reflexion,
      language,
      widget.devocional.version,
    )}\n${widget.devocional.paraMeditar.map((m) => '${BibleTextFormatter.normalizeTtsText(m.cita, language, widget.devocional.version)}: ${m.texto}').join('\n')}\n${BibleTextFormatter.normalizeTtsText(
      widget.devocional.oracion,
      language,
      widget.devocional.version,
    )}';
    debugPrint('[TTS Widget] Texto TTS armado: $ttsText');
    widget.audioController.setText(ttsText);
    return ValueListenableBuilder<TtsPlayerState>(
      valueListenable: widget.audioController.state,
      builder: (context, state, child) {
        debugPrint('[TTS Widget] Estado actual: $state');
        if (state == TtsPlayerState.completed) {
          debugPrint(
              '[TTS Widget] Devocional escuchado COMPLETADO: ${widget.devocional.id}');
          SpiritualStatsService().recordDevotionalHeard(
            devocionalId: widget.devocional.id,
            listenedPercentage: 1.0,
          );
        }
        Widget mainIcon;
        switch (state) {
          case TtsPlayerState.playing:
            mainIcon = const Icon(Icons.pause, size: 32);
            break;
          case TtsPlayerState.completed:
          case TtsPlayerState.idle:
            mainIcon = const Icon(Icons.play_arrow, size: 32);
            break;
          case TtsPlayerState.paused:
            mainIcon = const Icon(Icons.play_arrow, size: 32);
            break;
          case TtsPlayerState.error:
            mainIcon = const Icon(Icons.refresh, size: 32);
            break;
        }
        debugPrint('[TTS Widget] Renderizando IconButton, estado: $state');
        return Material(
          color: Colors.transparent,
          elevation: 4,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              debugPrint('[TTS Widget] Acción de usuario: $state');
              switch (state) {
                case TtsPlayerState.playing:
                  widget.audioController.pause();
                  break;
                case TtsPlayerState.paused:
                  widget.audioController.play();
                  break;
                case TtsPlayerState.completed:
                case TtsPlayerState.idle:
                  widget.audioController.play();
                  break;
                case TtsPlayerState.error:
                  widget.audioController.play();
                  break;
              }
            },
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F8CFF), Color(0xFF6DD5FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              width: 56,
              height: 56,
              child: Center(
                child: mainIcon,
              ),
            ),
          ),
        );
      },
    );
  }
}
