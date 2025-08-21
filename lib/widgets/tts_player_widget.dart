import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TtsPlayerWidget extends StatefulWidget {
  final Devocional devocional;
  final void Function()? onCompleted;

  const TtsPlayerWidget({
    super.key,
    required this.devocional,
    this.onCompleted,
  });

  @override
  State<TtsPlayerWidget> createState() => _TtsPlayerWidgetState();
}

class _TtsPlayerWidgetState extends State<TtsPlayerWidget> {
  // Estado local para manejar transiciones
  bool _localIsPlaying = false;
  double _lastProgress = 0.0;
  bool _completedTriggered = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioController>(
      builder: (context, audioController, child) {
        // Verificar si este devocional está activo/seleccionado
        final isThisDevocional =
            audioController.currentDevocionalId == widget.devocional.id;
        final isDevocionalPlaying =
            audioController.isDevocionalPlaying(widget.devocional.id);

        // Estados del controlador
        final currentState = audioController.currentState;
        final isLoading = audioController.isLoading;
        final hasError = audioController.hasError;
        final progress = audioController.progress;

        // FIX: Detectar reset y actualizar estado local
        if (currentState == TtsState.idle && _localIsPlaying) {
          debugPrint(
              'TtsPlayerWidget(${widget.devocional.id}): Detected reset to idle - updating local state');
          _localIsPlaying = false;
          _completedTriggered = false;

          // Forzar rebuild en el siguiente frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {});
            }
          });
        }

        // Actualizar estado local basado en el controlador
        if (isThisDevocional) {
          if (currentState == TtsState.playing && !_localIsPlaying) {
            _localIsPlaying = true;
          } else if ((currentState == TtsState.idle ||
                  currentState == TtsState.paused) &&
              _localIsPlaying) {
            if (currentState == TtsState.idle) {
              _localIsPlaying = false;
            }
          }
        }

        // Usar estado híbrido para determinar UI
        final effectiveIsPlaying = isThisDevocional &&
            (currentState == TtsState.playing ||
                (currentState == TtsState.paused && _localIsPlaying));

        // Lógica de estado mejorada para manejar transiciones
        Widget mainIcon;
        String mainTooltip;
        Color mainColor;
        bool isButtonEnabled = true;

        debugPrint(
            'TtsPlayerWidget(${widget.devocional.id}): isThisDevocional=$isThisDevocional, '
            'currentState=$currentState, isLoading=$isLoading, hasError=$hasError, '
            'isDevocionalPlaying=$isDevocionalPlaying, localIsPlaying=$_localIsPlaying, '
            'effectiveIsPlaying=$effectiveIsPlaying');

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
        } else if (effectiveIsPlaying && currentState == TtsState.playing) {
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
        if (progress >= 0.999 &&
            progress != _lastProgress &&
            !_completedTriggered) {
          _completedTriggered = true;
          if (widget.onCompleted != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onCompleted!();
            });
          }
        }
        _lastProgress = progress;

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
                      icon: const Icon(Icons.stop_circle_outlined, size: 40),
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
        audioController.currentDevocionalId == widget.devocional.id;

    debugPrint(
        'TtsPlayerWidget: Button pressed - currentState: $currentState, isThisDevocional: $isThisDevocional');

    try {
      if (audioController.hasError) {
        // Error - reintentar
        await audioController.stop();
        await Future.delayed(const Duration(milliseconds: 300));
        await audioController.playDevotional(widget.devocional);
      } else if (isThisDevocional && currentState == TtsState.playing) {
        // Pausar este devocional
        await audioController.pause();
      } else if (isThisDevocional && currentState == TtsState.paused) {
        // Continuar este devocional
        await audioController.resume();
      } else {
        // Iniciar nuevo devocional o reiniciar
        await audioController.playDevotional(widget.devocional);
      }
    } catch (e) {
      debugPrint('TtsPlayerWidget: Button press error: $e');
    }
  }
}
