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
          '[TTS Widget] App en segundo plano o pantalla inactiva, deteniendo audio');
      widget.audioController.stop();
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
    debugPrint('[TTS Widget] Texto TTS armado: $ttsText');
    widget.audioController.setText(ttsText);
    return ValueListenableBuilder<TtsPlayerState>(
      valueListenable: widget.audioController.state,
      builder: (context, state, child) {
        debugPrint('[TTS Widget] Estado actual: $state');
        if (state == TtsPlayerState.completed) {
          debugPrint(
              '[TTS Widget] Devocional escuchado COMPLETADO: ${widget.devocional.id}');
          debugPrint(
              '[TTS Widget] Tracking TTS: id=${widget.devocional.id}, porcentaje=100%');
          // Solo registrar si no está ya registrado como leído/escuchado
          SpiritualStatsService()
              .hasDevocionalBeenRead(widget.devocional.id)
              .then((alreadyRegistered) {
            if (!alreadyRegistered) {
              debugPrint(
                  '[TTS Widget] Registrando devocional heard en stats: id=${widget.devocional.id}, porcentaje=100%');
              SpiritualStatsService().recordDevotionalHeard(
                devocionalId: widget.devocional.id,
                listenedPercentage: 1.0,
              );
            } else {
              debugPrint(
                  '[TTS Widget] Ya registrado como leído/escuchado, no se duplica');
            }
          });
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
