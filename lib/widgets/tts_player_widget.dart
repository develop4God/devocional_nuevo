import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/devocional_provider.dart';
import '../widgets/voice_selector_dialog.dart';
import 'modern_voice_feature_dialog.dart';

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
  bool _hasRegisteredHeard = false;
  late VoidCallback _stateListener;
  String? _ttsText;
  String? _currentLanguage;

  void _updateTtsText(String language) {
    _currentLanguage = language;
    _ttsText = _buildTtsText(language);
    if (_ttsText != null) {
      widget.audioController.setText(_ttsText!, languageCode: language);
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final language = Localizations.localeOf(context).languageCode;
        _updateTtsText(language);
        debugPrint('[TTS Widget] ✅ Texto configurado correctamente');
      }
    });
    // Listener para detectar cuando la reproducción completa y registrar 'heard'
    _stateListener = () {
      try {
        final s = widget.audioController.state.value;
        if (s == TtsPlayerState.completed && !_hasRegisteredHeard) {
          _hasRegisteredHeard = true;
          final provider = Provider.of<DevocionalProvider>(
            context,
            listen: false,
          );
          // Usamos 0.8 (80%) como umbral consistente con implementaciones previas
          provider
              .recordDevocionalHeard(widget.devocional.id, 0.8, context)
              .then((result) {
            if (result == 'guardado') {
              debugPrint(
                '[TTS Widget] Devocional marcado como heard: ${widget.devocional.id}',
              );
              widget.onCompleted?.call();
            } else if (result == 'ya_registrado') {
              debugPrint(
                '[TTS Widget] Devocional ya registrado anteriormente: ${widget.devocional.id}',
              );
            } else {
              debugPrint(
                '[TTS Widget] recordDevocionalHeard result: $result for ${widget.devocional.id}',
              );
            }
          }).catchError((e) {
            debugPrint(
              '[TTS Widget] Error registrando devocional heard: $e',
            );
          });
        }
      } catch (e) {
        debugPrint('[TTS Widget] State listener error: $e');
      }
    };
    widget.audioController.state.addListener(_stateListener);
  }

  @override
  void didUpdateWidget(covariant TtsPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.devocional.id != widget.devocional.id) {
      debugPrint(
          '[TTS Widget] Cambio de devocional detectado, deteniendo audio');
      widget.audioController.stop();
      _hasRegisteredHeard = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final language = Localizations.localeOf(context).languageCode;
        _updateTtsText(language);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLang = Localizations.localeOf(context).languageCode;
    if (newLang != _currentLanguage) {
      _updateTtsText(newLang);
    }
  }

  @override
  void dispose() {
    debugPrint('[TTS Widget] dispose() llamado, deteniendo audio');
    widget.audioController.stop();
    // Remover listener agregado en initState
    try {
      widget.audioController.state.removeListener(_stateListener);
    } catch (_) {}
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
        '[TTS Widget] App en segundo plano o pantalla inactiva, pausando audio',
      );
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
    ttsBuffer.write(
      BibleTextFormatter.normalizeTtsText(
        widget.devocional.versiculo,
        language,
        widget.devocional.version,
      ),
    );

    ttsBuffer.write('\n$reflectionLabel: ');
    ttsBuffer.write(
      BibleTextFormatter.normalizeTtsText(
        widget.devocional.reflexion,
        language,
        widget.devocional.version,
      ),
    );

    if (widget.devocional.paraMeditar.isNotEmpty) {
      ttsBuffer.write('\n$meditateLabel: ');
      ttsBuffer.write(
        widget.devocional.paraMeditar.map((m) {
          return '${BibleTextFormatter.normalizeTtsText(m.cita, language, widget.devocional.version)}: ${m.texto}';
        }).join('\n'),
      );
    }

    ttsBuffer.write('\n$prayerLabel: ');
    ttsBuffer.write(
      BibleTextFormatter.normalizeTtsText(
        widget.devocional.oracion,
        language,
        widget.devocional.version,
      ),
    );

    return ttsBuffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[TTS Widget] build() llamado para devocional: ${widget.devocional.id}',
    );
    // Solo usar el valor cacheado, nunca recalcular ni llamar setText aquí
    debugPrint(
      '[TTS Widget] Texto TTS armado: ${_ttsText != null && _ttsText!.length > 80 ? '${_ttsText!.substring(0, 80)}...' : _ttsText}',
    );

    // Restore dynamic visuals: show spinner while loading, pause when playing, play otherwise.
    return ValueListenableBuilder<TtsPlayerState>(
      valueListenable: widget.audioController.state,
      builder: (context, state, _) {
        return Material(
          color: Colors.transparent,
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _handlePlayPause(
                context,
                state,
                _currentLanguage ??
                    Localizations.localeOf(context).languageCode,
                _ttsText ?? ''),
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
    debugPrint('[TTS Widget] ========== HANDLE PLAY/PAUSE ==========');
    debugPrint('[TTS Widget] Estado actual: $state');

    final voiceService = getService<VoiceSettingsService>();
    final hasSaved = await voiceService.hasUserSavedVoice(language);
    debugPrint('[TTS Widget] ¿Tiene voz guardada?: $hasSaved');

    // Check mounted after async operation and before using context
    if (!mounted) return;

    if (!hasSaved) {
      debugPrint('[TTS Widget] Mostrando diálogo de configuración de voz...');
      // Safe to use context here - we just checked mounted right before this call
      await showModalBottomSheet<void>(
        // ignore: use_build_context_synchronously
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ModernVoiceFeatureDialog(
              onConfigure: () async {
                Navigator.of(ctx).pop();
                if (!mounted) return;
                await _showVoiceSelector(context, language, ttsText);
              },
              onContinue: () async {
                debugPrint('[TTS Widget] Usuario continuó sin configurar voz');
                Navigator.of(ctx).pop();
                await voiceService.setUserSavedVoice(language);
                if (state != TtsPlayerState.loading) {
                  debugPrint(
                    '[TTS Widget] ▶️ Llamando widget.audioController.play()',
                  );
                  widget.audioController.play();
                }
              },
            ),
          );
        },
      );
      return;
    }

    final friendlyName = await voiceService.loadSavedVoice(language);
    debugPrint(
      '[TTS Widget] 🗂️🔊 Voz aplicada antes de reproducir: $friendlyName',
    );

    if (state == TtsPlayerState.playing) {
      debugPrint('[TTS Widget] ⏸️ Estado es PLAYING, llamando pause()');
      widget.audioController.pause();
    } else if (state != TtsPlayerState.loading) {
      // Si el estado es completed, hacer stop primero para resetear completamente
      if (state == TtsPlayerState.completed) {
        debugPrint(
          '[TTS Widget] 🔄 Estado es COMPLETED, llamando stop() antes de play() para resetear',
        );
        await widget.audioController.stop();
      }
      debugPrint(
        '[TTS Widget] ▶️ Estado NO es playing ni loading, llamando play()',
      );
      // Lanzar trigger FIAM tts_play
      try {
        FirebaseInAppMessaging.instance.triggerEvent('tts_play');
        debugPrint('[TTS Widget] Trigger FIAM tts_play lanzado');
      } catch (e) {
        debugPrint(
          '[TTS Widget] ⚠️ Firebase not initialized, skipping FIAM trigger: $e',
        );
      }
      widget.audioController.play();
    } else {
      debugPrint('[TTS Widget] ⚠️ Estado es LOADING, no se hace nada');
    }

    debugPrint('[TTS Widget] ========== FIN HANDLE PLAY/PAUSE ==========');
  }

  Future<void> _showVoiceSelector(
    BuildContext context,
    String language,
    String ttsText,
  ) async {
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
        width: 28,
        height: 28,
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
        borderRadius: BorderRadius.circular(12),
      );
    } else {
      mainIcon = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.7, end: 1.3),
        duration: const Duration(milliseconds: 800),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Icon(Icons.play_arrow, size: 32, color: themeColor),
          );
        },
      );
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
}
