import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
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
        final isPlaying = audioController.isDevocionalPlaying(devocional.id);
        final isPaused = audioController.isPaused;
        final isLoading = audioController.isLoading;
        final hasError = audioController.hasError;
        final progress = audioController.progress;

        // Iconos y colores más intuitivos
        Widget mainIcon;
        String mainTooltip;
        Color mainColor;

        if (isLoading) {
          mainIcon = const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          );
          mainTooltip = 'Cargando...';
          mainColor = Colors.blue;
        } else if (hasError) {
          mainIcon = const Icon(Icons.refresh, size: 32);
          mainTooltip = 'Reintentar';
          mainColor = Colors.red;
        } else if (isPlaying) {
          mainIcon = const Icon(Icons.pause, size: 32);
          mainTooltip = 'Pausar';
          mainColor = Colors.orange;
        } else if (isPaused) {
          mainIcon = const Icon(Icons.play_arrow, size: 32);
          mainTooltip = 'Continuar';
          mainColor = Colors.green;
        } else {
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
                      color: mainColor,
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
                                await audioController
                                    .playDevotional(devocional);
                              }
                            },
                    ),
                  ),

                  // Stop button si está activo
                  if (audioController.isActive) ...[
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
                      color: mainColor,
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
                                await audioController
                                    .playDevotional(devocional);
                              }
                            },
                    ),
                  ),

                  // Botón stop (solo visible si está activo)
                  if (audioController.isActive) ...[
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
}
