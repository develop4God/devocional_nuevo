import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/tts/bible_reader_tts_text_builder.dart';
import 'package:devocional_nuevo/widgets/tts_miniplayer_modal.dart';
import 'package:devocional_nuevo/widgets/voice_selector_dialog.dart';
import 'package:flutter/material.dart';

/// Presents and manages the TTS mini-player modal for Bible Reader.
///
/// Encapsulates showing/hiding the [TtsMiniplayerModal], preventing
/// duplicate modals, and coordinating the voice selector dialog.
/// Follows Single Responsibility Principle: only manages modal presentation.
///
/// Works with [TtsAudioController] for playback state and
/// [BibleReaderTtsTextBuilder] for text formatting.
///
/// All dependencies ([AnalyticsService]) are injected at construction time
/// — no inline [getService] calls inside handlers or closures.
class BibleReaderTtsMiniplayerPresenter {
  final TtsAudioController ttsAudioController;

  /// Injected analytics service — resolved once by the page, not inline.
  final AnalyticsService _analyticsService;

  /// Optional callback that shows the voice selector dialog.
  ///
  /// Receives `(BuildContext context, String languageCode, String sampleText)`.
  /// When provided, both the miniplayer voice button and the page's
  /// first-time flow delegate to this single implementation, eliminating
  /// the duplicate-path tech debt.
  final Future<void> Function(BuildContext, String, String)?
      onShowVoiceSelector;

  bool _isModalShowing = false;

  /// Whether the TTS mini-player modal is currently visible.
  bool get isShowing => _isModalShowing;

  /// Track whether the completion handler should attempt to close the modal.
  /// Set to false when user explicitly closes (via stop/drag), preventing
  /// duplicate pop attempts after modal is already dismissed.
  bool _shouldAutoCloseOnCompletion = true;

  BibleReaderTtsMiniplayerPresenter({
    required this.ttsAudioController,
    required AnalyticsService analyticsService,
    this.onShowVoiceSelector,
  }) : _analyticsService = analyticsService;

  /// Show the TTS mini-player modal for the current Bible chapter.
  ///
  /// [getCurrentState] should return the current BibleReaderState.
  void showMiniplayerModal(
    BuildContext context,
    BibleReaderState Function() getCurrentState,
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
            debugPrint('[BibleTtsMiniplayerModal] 🎵 State changed to: $state');
            if (state == TtsPlayerState.completed &&
                _isModalShowing &&
                _shouldAutoCloseOnCompletion) {
              debugPrint(
                  '[BibleTtsMiniplayerModal] ✅ TTS Completed - Scheduling modal close');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Double-check: only pop if modal is still showing and we haven't
                // been explicitly closed by user action (stop button or drag).
                if (_isModalShowing &&
                    _shouldAutoCloseOnCompletion &&
                    Navigator.canPop(ctx)) {
                  debugPrint(
                      '[BibleTtsMiniplayerModal] 🔚 Closing modal via Navigator.pop()');
                  _shouldAutoCloseOnCompletion = false;
                  _isModalShowing = false;
                  Navigator.of(ctx).pop();
                } else {
                  debugPrint(
                      '[BibleTtsMiniplayerModal] ⚠️ Modal already closing or user dismissed — skipping pop');
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
                              // Use injected service — no inline getService<> call.
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
                                '[BibleReaderTtsMiniplayerPresenter] cyclePlaybackRate failed: $e',
                              );
                            }
                          },
                          onVoiceSelector: () async {
                            final languageCode = Localizations.localeOf(
                              context,
                            ).languageCode;

                            final currentState = getCurrentState();
                            final sampleText =
                                BibleReaderTtsTextBuilder.build(currentState);
                            if (sampleText.isEmpty) return;

                            if (state == TtsPlayerState.playing) {
                              await ttsAudioController.pause();
                            }

                            if (!context.mounted) return;

                            if (onShowVoiceSelector != null) {
                              // Delegate to the page's single implementation.
                              await onShowVoiceSelector!(
                                  context, languageCode, sampleText);
                            } else {
                              // Fallback inline path (e.g. when presenter is
                              // used outside a BibleReaderPage context).
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
                                          '[BibleReaderTts] Voice tapped for preview: $name ($locale)',
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
      _isModalShowing = false;
      _shouldAutoCloseOnCompletion = true;
    });
  }

  /// Reset the modal showing state without disposing resources.
  void resetModalState() {
    _isModalShowing = false;
  }

  /// Clean up resources.
  void dispose() {
    _isModalShowing = false;
  }
}
