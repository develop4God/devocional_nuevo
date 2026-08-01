// lib/widgets/bible/bible_verse_note_indicator.dart

import 'package:flutter/material.dart';

/// Circular badge showing the number of a verse that has a saved note.
///
/// Enlarges the tap target beyond the small number glyph so it stays easy to
/// tap inside a verse's [RichText]. Tapping it opens the note.
class BibleVerseNoteIndicator extends StatelessWidget {
  final int verseNumber;
  final Color color;
  final VoidCallback onTap;

  const BibleVerseNoteIndicator({
    super.key,
    required this.verseNumber,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Text(
            '$verseNumber',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
