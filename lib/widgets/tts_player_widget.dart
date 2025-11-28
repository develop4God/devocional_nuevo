import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
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

class _TtsPlayerWidgetState extends State<TtsPlayerWidget>
    with WidgetsBindingObserver {
  /// Track if we have already registered this devotional as heard
  /// to prevent duplicate registrations
  bool _hasRegisteredHeard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant TtsPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.devocional.id != widget.devocional.id) {
      debugPrint(
          '[TTS Widget] Cambio de devocional detectado, deteniendo audio');
      widget.audioController.stop();
      // Reset heard tracking for new devotional
      _hasRegisteredHeard = false;
    }
  }

  @override
  void dispose() {
    debugPrint('[TTS Widget] dispose() llamado, deteniendo audio');
    widget.audioController.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[TTS Widget] didChangeAppLifecycleState: $state');
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      debugPrint(
          '[TTS Widget] App en segundo plano o pantalla inactiva, pausando audio');
      widget.audioController.pause();
    }
  }

  /// Build TTS text with localized section labels
  /// Uses i18n keys: devotionals.verse, devotionals.reflection, devotionals.to_meditate, devotionals.prayer
  String _buildTtsText(String language) {
    // Get localized labels (remove trailing colon from labels, we add it in formatting)
    final verseLabel = 'devotionals.verse'.tr().replaceAll(':', '');
    final reflectionLabel = 'devotionals.reflection'.tr().replaceAll(':', '');
    final meditateLabel = 'devotionals.to_meditate'.tr().replaceAll(':', '');
    final prayerLabel = 'devotionals.prayer'.tr().replaceAll(':', '');

    final StringBuffer ttsBuffer = StringBuffer();

    // Section 1: Verse with label
    ttsBuffer.write('$verseLabel: ');
    ttsBuffer.write(BibleTextFormatter.normalizeTtsText(
      widget.devocional.versiculo,
      language,
      widget.devocional.version,
    ));

    // Section 2: Reflection with label
    ttsBuffer.write('\n$reflectionLabel: ');
    ttsBuffer.write(BibleTextFormatter.normalizeTtsText(
      widget.devocional.reflexion,
      language,
      widget.devocional.version,
    ));

    // Section 3: To Meditate with label
    if (widget.devocional.paraMeditar.isNotEmpty) {
      ttsBuffer.write('\n$meditateLabel: ');
      ttsBuffer.write(widget.devocional.paraMeditar.map((m) {
        return '${BibleTextFormatter.normalizeTtsText(m.cita, language, widget.devocional.version)}: ${m.texto}';
      }).join('\n'));
    }

    // Section 4: Prayer with label
    ttsBuffer.write('\n$prayerLabel: ');
    ttsBuffer.write(BibleTextFormatter.normalizeTtsText(
      widget.devocional.oracion,
      language,
      widget.devocional.version,
    ));

    return ttsBuffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '[TTS Widget] build() llamado para devocional: ${widget.devocional.id}');
    // Armar el texto TTS normalizado con etiquetas localizadas
    final language = Localizations.localeOf(context).languageCode;
    final ttsText = _buildTtsText(language);
    debugPrint(
        '[TTS Widget] Texto TTS armado: ${ttsText.length > 80 ? '${ttsText.substring(0, 80)}...' : ttsText}');
    widget.audioController.setText(ttsText);
    return ValueListenableBuilder<TtsPlayerState>(
      valueListenable: widget.audioController.state,
      builder: (context, state, child) {
        debugPrint('[TTS Widget] Estado actual: $state');

        // Record devotional as heard when TTS completes (80% threshold)
        // This is called with a real estimate of listening completion
        if (state == TtsPlayerState.completed && !_hasRegisteredHeard) {
          _hasRegisteredHeard = true;
          // Check if already read to avoid duplication
          SpiritualStatsService()
              .hasDevocionalBeenRead(widget.devocional.id)
              .then((alreadyRead) {
            if (!alreadyRead) {
              debugPrint(
                  '[TTS Widget] Registrando devocional heard: id=${widget.devocional.id}, porcentaje=80%');
              SpiritualStatsService().recordDevotionalHeard(
                devocionalId: widget.devocional.id,
                listenedPercentage: 0.8, // 80% threshold for TTS completion
              );
            } else {
              debugPrint(
                  '[TTS Widget] Ya registrado como leído, no se duplica');
            }
          });
        }

        Widget mainIcon;
        Widget buttonWidget;
        final themeColor = Theme.of(context).colorScheme.primary;
        const borderWidth = 2.0;
        if (state == TtsPlayerState.loading) {
          mainIcon = const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          );
          buttonWidget = Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: themeColor, width: borderWidth),
            ),
            width: 56,
            height: 56,
            child: Center(child: mainIcon),
          );
        } else if (state == TtsPlayerState.playing) {
          mainIcon = Icon(Icons.pause, size: 32, color: themeColor);
          buttonWidget = Container(
            decoration: BoxDecoration(
              border: Border.all(color: themeColor, width: borderWidth),
              borderRadius: BorderRadius.circular(16),
            ),
            width: 56,
            height: 56,
            child: Center(child: mainIcon),
          );
        } else {
          mainIcon = Icon(Icons.play_arrow, size: 32, color: themeColor);
          buttonWidget = Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: themeColor, width: borderWidth),
            ),
            width: 56,
            height: 56,
            child: Center(child: mainIcon),
          );
        }
        debugPrint('[TTS Widget] Renderizando IconButton, estado: $state');
        return Material(
          color: Colors.transparent,
          elevation: 0,
          shape: state == TtsPlayerState.playing
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              : const CircleBorder(),
          child: InkWell(
            customBorder: state == TtsPlayerState.playing
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))
                : const CircleBorder(),
            onTap: () {
              debugPrint('[TTS Widget] Acción de usuario: $state');
              if (state == TtsPlayerState.playing) {
                widget.audioController.pause();
              } else if (state == TtsPlayerState.loading) {
                // No hacer nada mientras carga
              } else {
                widget.audioController.play();
              }
            },
            child: buttonWidget,
          ),
        );
      },
    );
  }
}
