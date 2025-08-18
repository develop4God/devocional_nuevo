import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TtsPlayerWidget extends StatelessWidget {
  final Devocional devocional;
  final void Function()?
      onCompleted; // Callback cuando termina el devocional (opcional)

  const TtsPlayerWidget({
    super.key,
    required this.devocional,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioController>(
      builder: (context, audioController, child) {
        final isPlaying = audioController.isDevocionalPlaying(devocional.id);
        final isPaused = audioController.isPaused;
        final isLoading = audioController.isLoading;
        final hasError = audioController.hasError;
        final progress = audioController.progress;

        // Mejora: Exponer chunk actual y total desde el controller
        final int? currentChunk = audioController.currentChunkIndex;
        final int? totalChunks = audioController.totalChunks;

        // Estado textual
        String statusLabel;
        if (isLoading) {
          statusLabel = "Cargando audio...";
        } else if (hasError) {
          statusLabel = "Error al reproducir";
        } else if (isPlaying) {
          statusLabel = "Reproduciendo";
        } else if (isPaused) {
          statusLabel = "Pausado";
        } else {
          statusLabel = "Listo para reproducir";
        }

        // Iconos y tooltips dinámicos
        Widget mainIcon;
        String mainTooltip;
        if (isLoading) {
          mainIcon = const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
          mainTooltip = 'Cargando audio...';
        } else if (hasError) {
          mainIcon = const Icon(Icons.error, color: Colors.red, size: 34);
          mainTooltip = 'Error al reproducir';
        } else if (isPlaying) {
          mainIcon = const Icon(Icons.pause_circle_filled,
              color: Colors.amber, size: 42);
          mainTooltip = 'Pausar audio';
        } else if (isPaused) {
          mainIcon =
              const Icon(Icons.play_circle_fill, color: Colors.green, size: 42);
          mainTooltip = 'Continuar audio';
        } else {
          mainIcon = const Icon(Icons.volume_up, color: Colors.blue, size: 38);
          mainTooltip = 'Reproducir devocional';
        }

        // Función para saltar a chunk específico (solo si la lógica existe)

        // Callback cuando termina el devocional (para estadísticas, etc.)
        if (progress >= 0.999 && onCompleted != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onCompleted!();
          });
        }

        // Colores
        final Color progressColor = isPlaying
            ? Colors.lightBlue
            : isPaused
                ? Colors.orange
                : Colors.blueGrey;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de progreso con retroceso/avance
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    color: progressColor,
                    backgroundColor: Colors.grey[300],
                  ),
                  if (currentChunk != null && totalChunks != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Chunk ${currentChunk + 1} / $totalChunks",
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black54),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.fast_rewind, size: 22),
                              tooltip: 'Retroceder',
                              onPressed: (currentChunk > 0 &&
                                      !isLoading &&
                                      !hasError)
                                  ? () => audioController.previousChunk?.call()
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.fast_forward, size: 22),
                              tooltip: 'Avanzar',
                              onPressed: (currentChunk < totalChunks - 1 &&
                                      !isLoading &&
                                      !hasError)
                                  ? () => audioController.nextChunk?.call()
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Estado textual
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: hasError
                      ? Colors.red
                      : isLoading
                          ? Colors.blueGrey
                          : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Botones principales
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón play/pause/resume
                Semantics(
                  label: mainTooltip,
                  child: IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: mainIcon,
                    ),
                    tooltip: mainTooltip,
                    iconSize: 42,
                    onPressed: (isLoading)
                        ? null
                        : () async {
                            if (hasError) {
                              await audioController.stop();
                              return;
                            }
                            if (isPlaying) {
                              await audioController.pause();
                            } else if (isPaused) {
                              await audioController.resume();
                            } else {
                              await audioController.playDevotional(devocional);
                            }
                          },
                  ),
                ),
                // Botón stop (solo visible si está activo)
                if (audioController.isActive)
                  Semantics(
                    label: "Detener audio",
                    child: IconButton(
                      icon: const Icon(Icons.stop_circle,
                          color: Colors.red, size: 32),
                      tooltip: 'Detener audio',
                      onPressed: () async {
                        await audioController.stop();
                      },
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
