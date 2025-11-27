import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TtsPlayerState>(
      valueListenable: widget.audioController.state,
      builder: (context, state, child) {
        print('[TTS Widget] Estado actual: $state');
        Widget mainIcon;
        String mainTooltip;
        bool isButtonEnabled = true;

        switch (state) {
          case TtsPlayerState.playing:
            mainIcon = const Icon(Icons.pause, size: 32);
            mainTooltip = 'Pausar';
            break;
          case TtsPlayerState.paused:
            mainIcon = const Icon(Icons.play_arrow, size: 32);
            mainTooltip = 'Continuar';
            break;
          case TtsPlayerState.completed:
          case TtsPlayerState.idle:
            mainIcon = const Icon(Icons.play_arrow, size: 32);
            mainTooltip = 'Escuchar';
            break;
          case TtsPlayerState.error:
            mainIcon = const Icon(Icons.refresh, size: 32);
            mainTooltip = 'Reintentar';
            break;
        }

        print('[TTS Widget] Renderizando IconButton, estado: $state');
        return Material(
          color: Colors.transparent,
          elevation: 4,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: isButtonEnabled
                ? () {
                    print('[TTS Widget] Acción de usuario: $state');
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
                  }
                : null,
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
                    color: Colors.black.withOpacity(0.15),
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
