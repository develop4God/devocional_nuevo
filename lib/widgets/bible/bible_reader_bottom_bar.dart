// bible_reader_bottom_bar.dart - Extracted from BibleReaderPage.build()
import 'package:auto_size_text/auto_size_text.dart';
import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

/// Bottom navigation bar: previous/next chapter arrows, the TTS play/pause
/// button, and the current book/chapter label button.
///
/// Pure presentation — extracted from [BibleReaderPage]'s `build()`.
class BibleReaderBottomBar extends StatelessWidget {
  final BibleReaderState state;
  final TtsAudioController ttsAudioController;
  final VoidCallback onPreviousChapter;
  final VoidCallback onNextChapter;
  final VoidCallback onBookTap;
  final void Function(BibleReaderState state) onTtsPlayPause;

  const BibleReaderBottomBar({
    super.key,
    required this.state,
    required this.ttsAudioController,
    required this.onPreviousChapter,
    required this.onNextChapter,
    required this.onBookTap,
    required this.onTtsPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: colorScheme.primary,
                ),
                tooltip: 'bible.previous_chapter'.tr(),
                onPressed: onPreviousChapter,
              ),
              // TTS play/pause button
              _buildTtsButton(context, colorScheme),
              // Botón de capítulo expandido para tablets y pantallas grandes
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onBookTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                        elevation: 2,
                        shadowColor: colorScheme.primary.withValues(
                          alpha: 0.3,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 16.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AutoSizeText(
                          state.selectedBookName != null
                              ? '${BibleVerseFormatter.resolveBookName(state.books, state.selectedBookName!)} ${state.selectedChapter}'
                              : '',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                          maxLines: 1,
                          minFontSize: 11,
                          maxFontSize: 15,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: colorScheme.primary,
                ),
                tooltip: 'bible.next_chapter'.tr(),
                onPressed: onNextChapter,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the TTS play/pause button for the bottom navigation bar.
  /// Reuses the same visual style as the devotional TTS player.
  Widget _buildTtsButton(BuildContext context, ColorScheme colorScheme) {
    return ValueListenableBuilder<TtsPlayerState>(
      valueListenable: ttsAudioController.state,
      builder: (context, ttsState, _) {
        final themeColor = colorScheme.primary;
        const borderWidth = 2.0;

        Widget mainIcon;
        BoxDecoration decoration;

        if (ttsState == TtsPlayerState.loading) {
          mainIcon = const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
          decoration = BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: themeColor, width: borderWidth),
          );
        } else if (ttsState == TtsPlayerState.playing) {
          mainIcon = Icon(Icons.pause, size: 28, color: themeColor);
          decoration = BoxDecoration(
            border: Border.all(color: themeColor, width: borderWidth),
            borderRadius: BorderRadius.circular(12),
          );
        } else {
          mainIcon = Icon(Icons.play_arrow, size: 28, color: themeColor);
          decoration = BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: themeColor, width: borderWidth),
          );
        }

        return Material(
          color: Colors.transparent,
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: state.verses.isNotEmpty ? () => onTtsPlayPause(state) : null,
            child: Container(
              decoration: decoration,
              width: 44,
              height: 44,
              child: Center(child: mainIcon),
            ),
          ),
        );
      },
    );
  }
}
