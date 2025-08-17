// lib/widgets/tts_player_widget.dart

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TtsPlayerWidget extends StatelessWidget {
  final Devocional devocional;
  final bool compact;

  const TtsPlayerWidget({
    super.key,
    required this.devocional,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<DevocionalProvider>(
      builder: (context, provider, child) {
        // Estados del TTS
        provider.isDevocionalPlaying(devocional.id);
        final isCurrentDevocional =
            provider.currentPlayingDevocionalId == devocional.id;
        final isAudioPaused = provider.isAudioPaused && isCurrentDevocional;

        // Determinar icono y estado
        IconData icon;
        Color iconColor;
        Color backgroundColor;

        if (isCurrentDevocional && provider.isAudioPlaying) {
          // Reproduciendo este devocional
          icon = Icons.pause;
          iconColor = Colors.white;
          backgroundColor = colorScheme.primary;
        } else if (isCurrentDevocional && isAudioPaused) {
          // Pausado en este devocional
          icon = Icons.play_arrow;
          iconColor = Colors.white;
          backgroundColor = colorScheme.primary.withValues(alpha: 0.8);
        } else {
          // Idle - listo para reproducir
          icon = Icons.play_arrow;
          iconColor = colorScheme.primary;
          backgroundColor = colorScheme.primary.withValues(alpha: 0.1);
        }

        return Container(
          width: compact ? 50 : 60,
          height: compact ? 40 : 50,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(compact ? 20 : 25),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(compact ? 20 : 25),
              onTap: () => _handleTap(context, provider),
              child: Container(
                padding: EdgeInsets.all(compact ? 8 : 12),
                child: Icon(
                  icon,
                  size: compact ? 20 : 24,
                  color: iconColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(BuildContext context, DevocionalProvider provider) async {
    try {
      await provider.toggleAudioPlayPause(devocional);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de audio: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
