// bible_reader_selector_bar.dart - Extracted from BibleReaderPage.build()
import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

/// Book / chapter / verse picker row shown above the verse list.
///
/// Pure presentation — extracted from [BibleReaderPage]'s `build()`.
class BibleReaderSelectorBar extends StatelessWidget {
  final BibleReaderState state;
  final String Function(String? languageCode) chapterPrefix;
  final String Function(String? languageCode) versePrefix;
  final VoidCallback onBookTap;
  final VoidCallback onChapterTap;
  final VoidCallback onVerseTap;

  const BibleReaderSelectorBar({
    super.key,
    required this.state,
    required this.chapterPrefix,
    required this.versePrefix,
    required this.onBookTap,
    required this.onChapterTap,
    required this.onVerseTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: onBookTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context)
                            .outlinedButtonTheme
                            .style
                            ?.side
                            ?.resolve({})?.color ??
                        colorScheme.outline,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_stories_outlined,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.selectedBookName != null
                            ? BibleVerseFormatter.resolveBookName(
                                state.books,
                                state.selectedBookName!,
                              )
                            : 'bible.select_book'.tr(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onChapterTap,
              icon: Icon(
                Icons.format_list_numbered,
                size: 18,
                color: colorScheme.primary,
              ),
              label: Text(
                '${chapterPrefix(state.selectedVersion?.languageCode)} ${state.selectedChapter ?? 1}',
                style: const TextStyle(fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onVerseTap,
              icon: const Icon(Icons.format_list_numbered, size: 18),
              label: Text(
                '${versePrefix(state.selectedVersion?.languageCode)} ${state.selectedVerse ?? 1}',
                style: const TextStyle(fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
