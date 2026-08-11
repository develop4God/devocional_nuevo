import 'package:flutter/material.dart';

/// Renders text containing lightweight `**bold**` and `*italic*` markers as
/// a [Text.rich], since JSON content uses this markdown-style emphasis that
/// plain [Text] does not parse. Bold is matched before italic so `**text**`
/// is never split into two italic markers.
Widget buildEmphasisMarkdownText(
  String text, {
  TextStyle? style,
  TextAlign? textAlign,
  int? maxLines,
  TextOverflow? overflow,
}) {
  final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
  final spans = <TextSpan>[];
  var lastEnd = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > lastEnd) {
      spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
    }
    final bold = match.group(1);
    if (bold != null) {
      spans.add(
        TextSpan(
          text: bold,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
    } else {
      spans.add(
        TextSpan(
          text: match.group(2),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }
    lastEnd = match.end;
  }
  if (lastEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastEnd)));
  }
  return Text.rich(
    TextSpan(style: style, children: spans),
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
  );
}
