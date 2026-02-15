import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';
import 'package:devocional_nuevo/widgets/tts_miniplayer_modal.dart';
import 'package:devocional_nuevo/widgets/voice_selector_dialog.dart';
import 'package:flutter/material.dart';

import '../../extensions/string_extensions.dart';

/// Manages the TTS mini-player modal lifecycle.
///
/// Encapsulates showing/hiding the TTS modal, preventing duplicates,
/// and coordinating voice selector dialogs. Follows Single Responsibility
/// Principle by handling only TTS modal presentation logic.
class TtsModalManager {
  final TtsAudioController ttsAudioController;

  bool _isTtsModalShowing = false;

  /// Whether the TTS modal is currently showing
  bool get isShowing => _isTtsModalShowing;

  TtsModalManager({required this.ttsAudioController});

  /// Listen to TTS state changes and show/close modal as needed.
  ///
  /// Call this from initState and pair with [removeStateListener] in dispose.
  void addStateListener(BuildContext Function() getContext) {
    ttsAudioController.state.addListener(() {
      _handleTtsStateChange(getContext);
    });
  }

  /// Build TTS text from a devotional for voice playback.
  static String buildTtsTextForDevocional(
    Devocional devocional,
    String language,
  ) {
    final verseLabel = 'devotionals.verse'.tr().replaceAll(':', '');
    final reflectionLabel = 'devotionals.reflection'.tr().replaceAll(':', '');
    final meditateLabel = 'devotionals.to_meditate'.tr().replaceAll(':', '');
    final prayerLabel = 'devotionals.prayer'.tr().replaceAll(':', '');

    final StringBuffer ttsBuffer = StringBuffer();
    ttsBuffer.write('$verseLabel: ');
    ttsBuffer.write(
      BibleTextFormatter.normalizeTtsText(
        devocional.versiculo,
        language,
        devocional.version,
      ),
    );
    ttsBuffer.write('\n$reflectionLabel: ');
    ttsBuffer.write(
      BibleTextFormatter.normalizeTtsText(
        devocional.reflexion,
        language,
        devocional.version,
      ),
    );
    if (devocional.paraMeditar.isNotEmpty) {
      ttsBuffer.write('\n$meditateLabel: ');
      ttsBuffer.write(
        devocional.paraMeditar.map((m) {
          return '${BibleTextFormatter.normalizeTtsText(m.cita, language, devocional.version)}: ${m.texto}';
        }).join('\n'),
      );
    }
    ttsBuffer.write('\n$prayerLabel: ');
    ttsBuffer.write(
      BibleTextFormatter.normalizeTtsText(
        devocional.oracion,
        language,
        devocional.version,
      ),
    );
    return ttsBuffer.toString();
  }

  void _handleTtsStateChange(BuildContext Function() getContext) {
    try {
      final s = ttsAudioController.state.value;
      final context = getContext();
      if (!context.mounted) return;

      // Show modal immediately when LOADING starts (instant feedback)
      if ((s == TtsPlayerState.loading || s == TtsPlayerState.playing) &&
          !_isTtsModalShowing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = getContext();
          if (!ctx.mounted || _isTtsModalShowing) return;
          debugPrint(
            '🎵 [Modal] Opening modal on state: $s (immediate feedback)',
          );
          showTtsModal(ctx, () => _getCurrentDevocional(ctx));
        });
      }

      // Close modal when audio completes or goes to idle
      if (s == TtsPlayerState.completed || s == TtsPlayerState.idle) {
        if (_isTtsModalShowing) {
          _isTtsModalShowing = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = getContext();
            if (ctx.mounted && Navigator.canPop(ctx)) {
              debugPrint(
                '🏁 [Modal] Closing modal on state: $s (auto-cleanup)',
              );
              Navigator.of(ctx).pop();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[TtsModalManager] Error en _handleTtsStateChange: $e');
    }
  }

  /// Returns null - subclasses or callers should provide the actual devotional.
  /// This is a placeholder for the state change listener.
  Devocional? _getCurrentDevocional(BuildContext context) => null;

  /// Show the TTS mini-player modal.
  ///
  /// [getCurrentDevocional] should return the currently displayed devotional
  /// for the voice selector dialog.
  void showTtsModal(
    BuildContext context,
    Devocional? Function() getCurrentDevocional,
  ) {
    if (!context.mounted || _isTtsModalShowing) return;

    _isTtsModalShowing = true;

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return ValueListenableBuilder<TtsPlayerState>(
          valueListenable: ttsAudioController.state,
          builder: (context, state, _) {
            if (state == TtsPlayerState.completed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.canPop(ctx)) {
                  Navigator.of(ctx).pop();
                }
              });
            }

            return ValueListenableBuilder<Duration>(
              valueListenable: ttsAudioController.currentPosition,
              builder: (context, currentPos, __) {
                return ValueListenableBuilder<Duration>(
                  valueListenable: ttsAudioController.totalDuration,
                  builder: (context, totalDur, ___) {
                    return ValueListenableBuilder<double>(
                      valueListenable: ttsAudioController.playbackRate,
                      builder: (context, rate, ____) {
                        return TtsMiniplayerModal(
                          positionListenable:
                              ttsAudioController.currentPosition,
                          totalDurationListenable:
                              ttsAudioController.totalDuration,
                          stateListenable: ttsAudioController.state,
                          playbackRateListenable:
                              ttsAudioController.playbackRate,
                          playbackRates: ttsAudioController.supportedRates,
                          onStop: () {
                            ttsAudioController.stop();
                            _isTtsModalShowing = false;
                            if (Navigator.canPop(ctx)) {
                              Navigator.of(ctx).pop();
                            }
                          },
                          onSeek: (d) => ttsAudioController.seek(d),
                          onTogglePlay: () {
                            if (state == TtsPlayerState.playing) {
                              ttsAudioController.pause();
                            } else {
                              try {
                                getService<AnalyticsService>().logTtsPlay();
                              } catch (e) {
                                debugPrint(
                                  '❌ Error logging TTS play analytics: $e',
                                );
                              }
                              ttsAudioController.play();
                            }
                          },
                          onCycleRate: () async {
                            if (state == TtsPlayerState.playing) {
                              await ttsAudioController.pause();
                            }
                            try {
                              await ttsAudioController.cyclePlaybackRate();
                            } catch (e) {
                              debugPrint(
                                '[TtsModalManager] cyclePlaybackRate failed: $e',
                              );
                            }
                          },
                          onVoiceSelector: () async {
                            final languageCode = Localizations.localeOf(
                              context,
                            ).languageCode;

                            final currentDevocional = getCurrentDevocional();
                            if (currentDevocional == null) return;

                            final sampleText = buildTtsTextForDevocional(
                              currentDevocional,
                              languageCode,
                            );

                            if (state == TtsPlayerState.playing) {
                              await ttsAudioController.pause();
                            }

                            if (!context.mounted) return;
                            final modalContext = context;

                            await showModalBottomSheet(
                              context: modalContext,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(28),
                                ),
                              ),
                              builder: (voiceCtx) => FractionallySizedBox(
                                heightFactor: 0.8,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(
                                      voiceCtx,
                                    ).viewInsets.bottom,
                                  ),
                                  child: VoiceSelectorDialog(
                                    language: languageCode,
                                    sampleText: sampleText,
                                    onVoiceSelected: (name, locale) async {},
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      _isTtsModalShowing = false;
    });
  }

  /// Clean up resources.
  void dispose() {
    _isTtsModalShowing = false;
  }
}
