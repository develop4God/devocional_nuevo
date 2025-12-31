// lib/widgets/bible_chapter_grid_selector.dart
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

/// Widget that displays a grid of chapters for selection in the Bible reader
/// Replaces the dropdown approach for better UX and navigation
class BibleChapterGridSelector extends StatelessWidget {
  /// Total number of chapters in the current book
  final int totalChapters;

  /// Currently selected chapter number
  final int selectedChapter;

  /// Callback when a chapter is selected
  final Function(int) onChapterSelected;

  /// Book name for display purposes
  final String bookName;

  const BibleChapterGridSelector({
    required this.totalChapters,
    required this.selectedChapter,
    required this.onChapterSelected,
    required this.bookName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'bible.select_chapter'.tr(),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          bookName,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'bible.close'.tr(),
                  ),
                ],
              ),
            ),
            // Chapter count info
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'bible.total_chapters'.tr({'count': totalChapters.toString()}),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            // Grid
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: totalChapters,
                  itemBuilder: (context, index) {
                    final chapterNumber = index + 1;
                    final isSelected = chapterNumber == selectedChapter;

                    return _buildChapterItem(
                      chapterNumber,
                      isSelected,
                      colorScheme,
                      textTheme,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterItem(
    int chapterNumber,
    bool isSelected,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Material(
      color: isSelected
          ? colorScheme.primary
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChapterSelected(chapterNumber),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: colorScheme.onPrimary, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              chapterNumber.toString(),
              style: textTheme.bodyMedium?.copyWith(
                color:
                    isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
