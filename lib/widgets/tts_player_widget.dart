import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TtsPlayerWidget extends StatelessWidget {
  final Devocional devocional;
  final void Function()? onCompleted;

  const TtsPlayerWidget({
    super.key,
    required this.devocional,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioController>(
      builder: (context, audioController, child) {
        // Verificar si este devocional está activo/seleccionado
        final isThisDevocional =
            audioController.currentDevocionalId == devocional.id;
        final isDevocionalPlaying =
            audioController.isDevocionalPlaying(devocional.id);

        // Estados del controlador
        final currentState = audioController.currentState;
        final isLoading = audioController.isLoading;
        final hasError = audioController.hasError;
        final progress = audioController.progress;

        // Lógica de estado mejorada para manejar transiciones
        Widget mainIcon;
        String mainTooltip;
        Color mainColor;
        bool isButtonEnabled = true;

        debugPrint(
            'TtsPlayerWidget(${devocional.id}): isThisDevocional=$isThisDevocional, currentState=$currentState, isLoading=$isLoading, hasError=$hasError, isDevocionalPlaying=$isDevocionalPlaying');

        if (hasError && isThisDevocional) {
          // Error en este devocional
          mainIcon = const Icon(Icons.refresh, size: 32);
          mainTooltip = 'Reintentar';
          mainColor = Colors.red;
        } else if (isLoading && isThisDevocional) {
          // Cargando este devocional
          mainIcon = const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          );
          mainTooltip = 'Cargando...';
          mainColor = Colors.blue;
          isButtonEnabled = false;
        } else if (isThisDevocional && currentState == TtsState.playing) {
          // Este devocional está reproduciendo
          mainIcon = const Icon(Icons.pause, size: 32);
          mainTooltip = 'Pausar';
          mainColor = Colors.orange;
        } else if (isThisDevocional && currentState == TtsState.paused) {
          // Este devocional está pausado
          mainIcon = const Icon(Icons.play_arrow, size: 32);
          mainTooltip = 'Continuar';
          mainColor = Colors.green;
        } else if (isThisDevocional &&
            (currentState == TtsState.stopping ||
                currentState == TtsState.initializing)) {
          // Estados de transición para este devocional
          mainIcon = const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          );
          mainTooltip = currentState == TtsState.stopping
              ? 'Deteniendo...'
              : 'Iniciando...';
          mainColor = Colors.blue;
          isButtonEnabled = false;
        } else {
          // Estado idle o devocional diferente
          mainIcon = const Icon(Icons.play_arrow, size: 32);
          mainTooltip = 'Escuchar';
          mainColor = Colors.blue;
        }

        // Callback cuando termina el devocional
        if (progress >= 0.999 && onCompleted != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onCompleted!();
          });
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Si el ancho es muy pequeño, usar layout compacto
            if (constraints.maxWidth < 200) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón principal centrado
                  Container(
                    decoration: BoxDecoration(
                      color: isButtonEnabled
                          ? mainColor
                          : mainColor.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: mainIcon,
                      ),
                      tooltip: mainTooltip,
                      iconSize: 32,
                      color: Colors.white,
                      onPressed: isButtonEnabled
                          ? () async {
                              await _handleButtonPress(audioController);
                            }
                          : null,
                    ),
                  ),

                  // Stop button si está activo
                  if (isThisDevocional && audioController.isActive) ...[
                    const SizedBox(height: 4),
                    IconButton(
                      icon: const Icon(Icons.stop, size: 24),
                      tooltip: 'Detener',
                      color: Colors.red,
                      onPressed: () async {
                        await audioController.stop();
                      },
                    ),
                  ],
                ],
              );
            } else {
              // Layout normal para espacios más amplios
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón principal centrado y prominente
                  Container(
                    decoration: BoxDecoration(
                      color: isButtonEnabled
                          ? mainColor
                          : mainColor.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: mainIcon,
                      ),
                      tooltip: mainTooltip,
                      iconSize: 42,
                      color: Colors.white,
                      onPressed: isButtonEnabled
                          ? () async {
                              await _handleButtonPress(audioController);
                            }
                          : null,
                    ),
                  ),

                  // Botón stop (solo visible si está activo)
                  if (isThisDevocional && audioController.isActive) ...[
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.stop, size: 28),
                      tooltip: 'Detener',
                      color: Colors.red,
                      onPressed: () async {
                        await audioController.stop();
                      },
                    ),
                  ],
                ],
              );
            }
          },
        );
      },
    );
  }

  Future<void> _handleButtonPress(AudioController audioController) async {
    final currentState = audioController.currentState;
    final isThisDevocional =
        audioController.currentDevocionalId == devocional.id;

    debugPrint(
        'TtsPlayerWidget: Button pressed - currentState: $currentState, isThisDevocional: $isThisDevocional');

    try {
      if (audioController.hasError) {
        // Error - reintentar
        await audioController.stop();
        await Future.delayed(const Duration(milliseconds: 300));
        await audioController.playDevotional(devocional);
      } else if (isThisDevocional && currentState == TtsState.playing) {
        // Pausar este devocional
        await audioController.pause();
      } else if (isThisDevocional && currentState == TtsState.paused) {
        // Continuar este devocional
        await audioController.resume();
      } else {
        // Iniciar nuevo devocional o reiniciar
        await audioController.playDevotional(devocional);
      }
    } catch (e) {
      debugPrint('TtsPlayerWidget: Button press error: $e');
    }
  }
}
