import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/devocional_tts_text_builder.dart';
import 'package:devocional_nuevo/widgets/tts_miniplayer_modal.dart';
import 'package:devocional_nuevo/widgets/voice_selector_dialog.dart';
import 'package:flutter/material.dart';

/// Presents and manages the TTS mini-player modal for devotionals.
///
/// Encapsulates showing/hiding the [TtsMiniplayerModal], preventing
/// duplicate modals, and coordinating the voice selector dialog.
/// Follows Single Responsibility Principle: only manages modal presentation.
///
/// Works with [TtsAudioController] for playback state and
/// [DevocionalTtsTextBuilder] for text formatting.
class DevocionalTtsMiniplayerPresenter {
  final TtsAudioController ttsAudioController;

  bool _isModalShowing = false;

  /// Whether the TTS mini-player modal is currently visible
  bool get isShowing => _isModalShowing;

  DevocionalTtsMiniplayerPresenter({required this.ttsAudioController});

  /// Show the TTS mini-player modal.
  ///
  /// [getCurrentDevocional] should return the currently displayed devotional
  /// for the voice selector dialog.
  void showMiniplayerModal(
    BuildContext context,
    Devocional? Function() getCurrentDevocional,
  ) {
    if (!context.mounted || _isModalShowing) return;

    _isModalShowing = true;

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
                            _isModalShowing = false;
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
                                '[DevocionalTtsMiniplayerPresenter] cyclePlaybackRate failed: $e',
                              );
                            }
                          },
                          onVoiceSelector: () async {
                            final languageCode = Localizations.localeOf(
                              context,
                            ).languageCode;

                            final currentDevocional = getCurrentDevocional();
                            if (currentDevocional == null) return;

                            final sampleText = DevocionalTtsTextBuilder.build(
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
      _isModalShowing = false;
    });
  }

  /// Reset the modal showing state without disposing resources.
  ///
  /// Use this when the modal needs to be closed externally (e.g., on TTS
  /// completion). Use [dispose] only during widget teardown.
  void resetModalState() {
    _isModalShowing = false;
  }

  /// Clean up resources.
  void dispose() {
    _isModalShowing = false;
  }
}
