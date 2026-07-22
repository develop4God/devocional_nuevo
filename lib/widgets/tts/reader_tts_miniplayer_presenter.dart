import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/services/i_analytics_service.dart';
import 'package:devocional_nuevo/widgets/tts_miniplayer_modal.dart';
import 'package:devocional_nuevo/widgets/voice_selector_dialog.dart';
import 'package:flutter/material.dart';

/// Presents and manages the TTS mini-player modal for a page-scoped reader
/// screen, parameterized over its content type [T].
///
/// Shared by Encounters and Discovery detail pages — both display one
/// `PageView` card at a time and need identical modal/auto-close/voice
/// selector wiring around [TtsAudioController]. Mirrors the pattern
/// established by `BibleReaderTtsMiniplayerPresenter` (constructor-injected
/// [IAnalyticsService], no inline `getService` calls) without touching that
/// file or the Devocional/Bible reader presenters.
///
/// [T] is the currently visible content unit (e.g. `EncounterCard` or
/// `DiscoveryCard`). [buildSampleText] converts it to TTS text for the
/// voice-selector preview.
class ReaderTtsMiniplayerPresenter<T> {
  final TtsAudioController ttsAudioController;
  final IAnalyticsService _analyticsService;
  final String Function(T) buildSampleText;

  /// Optional callback that shows the voice selector dialog.
  ///
  /// Receives `(BuildContext context, String languageCode, String sampleText)`.
  final Future<void> Function(BuildContext, String, String)?
      onShowVoiceSelector;

  bool get isShowing => _shouldAutoCloseOnCompletion;

  bool _shouldAutoCloseOnCompletion = false;

  ReaderTtsMiniplayerPresenter({
    required this.ttsAudioController,
    required IAnalyticsService analyticsService,
    required this.buildSampleText,
    this.onShowVoiceSelector,
  }) : _analyticsService = analyticsService;

  /// Show the TTS mini-player modal for the currently visible content.
  ///
  /// [getCurrentContent] should return the content unit currently on screen.
  void showMiniplayerModal(
    BuildContext context,
    T Function() getCurrentContent,
  ) {
    if (!context.mounted || _shouldAutoCloseOnCompletion) return;

    _shouldAutoCloseOnCompletion = true;

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
            if (state == TtsPlayerState.completed &&
                _shouldAutoCloseOnCompletion) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_shouldAutoCloseOnCompletion && Navigator.canPop(ctx)) {
                  _shouldAutoCloseOnCompletion = false;
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
                            _shouldAutoCloseOnCompletion = false;
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
                                _analyticsService.logTtsPlay();
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
                                '[ReaderTtsMiniplayerPresenter] cyclePlaybackRate failed: $e',
                              );
                            }
                          },
                          onVoiceSelector: () async {
                            final languageCode = Localizations.localeOf(
                              context,
                            ).languageCode;

                            final sampleText =
                                buildSampleText(getCurrentContent());
                            if (sampleText.isEmpty) return;

                            if (state == TtsPlayerState.playing) {
                              await ttsAudioController.pause();
                            }

                            if (!context.mounted) return;

                            if (onShowVoiceSelector != null) {
                              await onShowVoiceSelector!(
                                context,
                                languageCode,
                                sampleText,
                              );
                            } else {
                              await showModalBottomSheet(
                                context: context,
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
                                      onVoiceSelected: (name, locale) {
                                        debugPrint(
                                          '[ReaderTts] Voice tapped for preview: $name ($locale)',
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }
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
      _shouldAutoCloseOnCompletion = false;
    });
  }

  /// Reset the modal showing state without disposing resources.
  void resetModalState() {
    _shouldAutoCloseOnCompletion = false;
  }

  /// Clean up resources.
  void dispose() {
    _shouldAutoCloseOnCompletion = false;
  }
}
