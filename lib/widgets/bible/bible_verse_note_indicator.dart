// lib/widgets/bible/bible_verse_note_indicator.dart

import 'package:flutter/material.dart';

/// Circular badge showing a verse number.
///
/// Enlarges the tap target beyond the small number glyph so it stays easy to
/// tap inside a verse's [RichText]. When [hasNote] is true the circle is
/// filled to signal a saved note and [onTap] opens it.
class BibleVerseNoteIndicator extends StatelessWidget {
  final int verseNumber;
  final Color color;
  final bool hasNote;
  final VoidCallback? onTap;

  const BibleVerseNoteIndicator({
    super.key,
    required this.verseNumber,
    required this.color,
    required this.hasNote,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasNote ? color.withValues(alpha: 0.2) : null,
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            '$verseNumber',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
