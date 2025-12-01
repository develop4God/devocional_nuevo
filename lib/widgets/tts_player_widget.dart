import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/material.dart';

import '../widgets/voice_selector_dialog.dart';

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

  static Future<void> clearUserVoiceFlagForTest(String language) async {
    await VoiceSettingsService().clearUserSavedVoiceFlag(language);
  }
}

class _TtsPlayerWidgetState extends State<TtsPlayerWidget>
    with WidgetsBindingObserver {
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

  String _buildTtsText(String language) {
    final verseLabel = 'devotionals.verse'.tr().replaceAll(':', '');
    final reflectionLabel = 'devotionals.reflection'.tr().replaceAll(':', '');
    final meditateLabel = 'devotionals.to_meditate'.tr().replaceAll(':', '');
    final prayerLabel = 'devotionals.prayer'.tr().replaceAll(':', '');

    final StringBuffer ttsBuffer = StringBuffer();

    ttsBuffer.write('$verseLabel: ');
    ttsBuffer.write(BibleTextFormatter.normalizeTtsText(
      widget.devocional.versiculo,
      language,
      widget.devocional.version,
    ));

    ttsBuffer.write('\n$reflectionLabel: ');
    ttsBuffer.write(BibleTextFormatter.normalizeTtsText(
      widget.devocional.reflexion,
      language,
      widget.devocional.version,
    ));

    if (widget.devocional.paraMeditar.isNotEmpty) {
      ttsBuffer.write('\n$meditateLabel: ');
      ttsBuffer.write(widget.devocional.paraMeditar.map((m) {
        return '${BibleTextFormatter.normalizeTtsText(m.cita, language, widget.devocional.version)}: ${m.texto}';
      }).join('\n'));
    }

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
    final language = Localizations.localeOf(context).languageCode;
    final ttsText = _buildTtsText(language);
    debugPrint(
        '[TTS Widget] Texto TTS armado: ${ttsText.length > 80 ? '${ttsText.substring(0, 80)}...' : ttsText}');
    widget.audioController.setText(ttsText);

    return ValueListenableBuilder<TtsPlayerState>(
      valueListenable: widget.audioController.state,
      builder: (context, state, child) {
        debugPrint('[TTS Widget] Estado actual: $state');

        if (state == TtsPlayerState.completed && !_hasRegisteredHeard) {
          _hasRegisteredHeard = true;
          _registerDevotionalHeard(
              widget.devocional.id, widget.audioController);
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
            onTap: () => _handlePlayPause(context, state, language, ttsText),
            child: _buildButton(context, state),
          ),
        );
      },
    );
  }

  Future<void> _handlePlayPause(
    BuildContext context,
    TtsPlayerState state,
    String language,
    String ttsText,
  ) async {
    debugPrint('[TTS Widget] Acción de usuario: $state');

    final voiceService = VoiceSettingsService();
    final hasSaved = await voiceService.hasUserSavedVoice(language);

    if (!mounted) return;

    if (!hasSaved) {
      // ignore: use_build_context_synchronously
      await _showVoiceSelector(context, language, ttsText);
      return;
    }

    final friendlyName = await voiceService.loadSavedVoice(language);
    debugPrint(
        '🗂️🔊 [TTS Widget] Voz aplicada antes de reproducir: $friendlyName');

    if (state == TtsPlayerState.playing) {
      widget.audioController.pause();
    } else if (state != TtsPlayerState.loading) {
      widget.audioController.play();
    }
  }

  Future<void> _showVoiceSelector(
    BuildContext context,
    String language,
    String ttsText,
  ) async {
    // ignore: use_build_context_synchronously
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: VoiceSelectorDialog(
            language: language,
            sampleText: ttsText,
            onVoiceSelected: (name, locale) async {},
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, TtsPlayerState state) {
    final themeColor = Theme.of(context).colorScheme.primary;
    const borderWidth = 2.0;

    Widget mainIcon;
    BoxDecoration decoration;

    if (state == TtsPlayerState.loading) {
      mainIcon = const SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: themeColor, width: borderWidth),
      );
    } else if (state == TtsPlayerState.playing) {
      mainIcon = Icon(Icons.pause, size: 32, color: themeColor);
      decoration = BoxDecoration(
        border: Border.all(color: themeColor, width: borderWidth),
        borderRadius: BorderRadius.circular(16),
      );
    } else {
      mainIcon = Icon(Icons.play_arrow, size: 32, color: themeColor);
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: themeColor, width: borderWidth),
      );
    }

    return Container(
      decoration: decoration,
      width: 56,
      height: 56,
      child: Center(child: mainIcon),
    );
  }

  void _registerDevotionalHeard(
    String devotionalId,
    TtsAudioController audioController,
  ) {
    SpiritualStatsService()
        .hasDevocionalBeenRead(devotionalId)
        .then((alreadyRead) {
      if (!alreadyRead) {
        debugPrint(
            '[TTS Widget] Registrando devocional heard: id=$devotionalId, porcentaje=80%');
        SpiritualStatsService().recordDevotionalHeard(
          devocionalId: devotionalId,
          listenedPercentage: 0.8,
        );
      } else {
        debugPrint('[TTS Widget] Ya registrado como leído, no se duplica');
      }
      audioController.state.value = TtsPlayerState.idle;
    }).catchError((error) {
      debugPrint('[TTS Widget] Error recording devotional heard: $error');
      audioController.state.value = TtsPlayerState.idle;
    });
  }
}
