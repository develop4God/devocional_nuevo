// bible_verse_list_view.dart - Extracted from BibleReaderPage.build()
import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/bible_note_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:devocional_nuevo/widgets/bible/bible_verse_note_indicator.dart';
import 'package:devocional_nuevo/widgets/tts_highlight_style.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// The scrollable Bible chapter body: loading placeholder, or the verse
/// list (title + verses + copyright disclaimer) with TTS highlight, note
/// indicators, and verse-selection styling.
///
/// Pure presentation — extracted from [BibleReaderPage]'s `build()` so the
/// verse rendering logic can be reasoned about and tested independently.
class BibleVerseListView extends StatelessWidget {
  final BibleReaderState state;
  final BibleNoteState bibleNoteState;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final int? currentSpokenVerseIndex;
  final String Function(dynamic text) cleanVerseText;
  final void Function(int verseNumber) onVerseTap;
  final void Function(String key) onVerseLongPress;
  final void Function(String bookName, int chapter, int verseNumber) onNoteTap;

  const BibleVerseListView({
    super.key,
    required this.state,
    required this.bibleNoteState,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.currentSpokenVerseIndex,
    required this.cleanVerseText,
    required this.onVerseTap,
    required this.onVerseLongPress,
    required this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.verses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lottie animation shown while loading the Bible version
            Lottie.asset(
              'assets/lottie/book_stars.json',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              repeat: true,
            ),
            const SizedBox(height: 12),
            Text(
              'bible.loading_version'.tr({
                'version': state.selectedVersion?.name ?? '',
              }),
            ),
          ],
        ),
      );
    }

    return ScrollablePositionedList.builder(
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: state.verses.length + 2,
      // +1 título, +1 disclaimer
      itemBuilder: (context, idx) {
        if (idx == 0) {
          // Título como primer elemento scrollable
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              state.selectedBookName != null && state.selectedChapter != null
                  ? '${BibleVerseFormatter.resolveBookName(state.books, state.selectedBookName!)} ${state.selectedChapter}'
                  : '',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
          );
        }
        // Último item: disclaimer de copyright
        if (idx == state.verses.length + 1) {
          if (state.selectedVersion == null) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              state.selectedVersion!.disclaimer ??
                  CopyrightUtils.getCopyrightText(
                    state.selectedVersion!.languageCode,
                    state.selectedVersion!.name,
                  ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 153),
                  ),
              textAlign: TextAlign.center,
            ),
          );
        }
        // Versos
        final verse = state.verses[idx - 1];
        final verseNumber = verse['verse'];
        final verseNum = verseNumber is int
            ? verseNumber
            : int.parse(verseNumber.toString());
        final key =
            "${state.selectedBookName}|${state.selectedChapter}|$verseNumber";
        final isSelected = state.selectedVerses.contains(key);
        // idx-1 is the 0-based verse index; the driver
        // publishes the estimated verse being read.
        // Highlight it and dim the others.
        final highlightStyle = TtsHighlightStyle.forIndex(
          currentSpokenVerseIndex,
          idx - 1,
        );
        final isPersistentlyMarked =
            state.persistentlyMarkedVerses.contains(key);
        final hasNote = bibleNoteState is BibleNoteLoaded &&
            state.selectedBookName != null &&
            state.selectedChapter != null &&
            (bibleNoteState as BibleNoteLoaded).getNoteForVerse(
                  state.selectedBookName!,
                  state.selectedChapter!,
                  verseNum,
                ) !=
                null;

        // Get section titles for this verse
        final titlesForVerse = state.sectionTitles
            .where((title) => title['verse'] == verseNumber)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display section titles if any
            ...titlesForVerse.map(
              (title) => Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  title['title'] as String,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
              ),
            ),
            // Verse content
            GestureDetector(
              onTap: () => onVerseTap(verseNumber),
              onLongPress: () => onVerseLongPress(key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 4,
                ),
                decoration: isSelected
                    ? BoxDecoration(
                        color:
                            colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      )
                    : null,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: state.fontSize,
                      // Karaoke highlight: while a
                      // verse is being read, keep it
                      // full-strength (bold) and dim
                      // the others so the eye follows.
                      color: colorScheme.onSurface
                          .withValues(alpha: highlightStyle.opacity),
                      fontWeight: highlightStyle.fontWeight,
                      height: 1.6,
                    ),
                    children: [
                      if (hasNote &&
                          state.selectedBookName != null &&
                          state.selectedChapter != null)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: BibleVerseNoteIndicator(
                            verseNumber: verseNum,
                            color: colorScheme.primary,
                            onTap: () => onNoteTap(
                              state.selectedBookName!,
                              state.selectedChapter!,
                              verseNum,
                            ),
                          ),
                        )
                      else
                        TextSpan(
                          text: "$verseNum ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            fontSize: 14,
                          ),
                        ),
                      TextSpan(
                        text: cleanVerseText(verse['text']),
                        style: isPersistentlyMarked
                            ? TextStyle(
                                backgroundColor: colorScheme.secondary
                                    .withValues(alpha: 0.25),
                                fontWeight: FontWeight.w500,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
