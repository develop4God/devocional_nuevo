import 'package:auto_size_text/auto_size_text.dart';
import 'package:devocional_nuevo/utils/clipboard_utils.dart';
import 'package:flutter/material.dart';

class CopyableVerseCard extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final int maxLines;

  /// Optional bold prefix rendered before [text] (e.g. citation label).
  /// When provided the card renders rich text instead of plain text.
  final TextSpan? prefixSpan;

  /// Text sent to clipboard. Defaults to [text] when omitted.
  final String? copyText;

  const CopyableVerseCard({
    super.key,
    required this.text,
    this.textStyle,
    this.maxLines = 12,
    this.prefixSpan,
    this.copyText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedStyle = textStyle?.copyWith(color: colorScheme.onSurface) ??
        TextStyle(color: colorScheme.onSurface);

    final Widget textWidget = prefixSpan != null
        ? AutoSizeText.rich(
            TextSpan(
              children: [
                prefixSpan!,
                TextSpan(text: text, style: resolvedStyle),
              ],
            ),
            maxLines: maxLines,
          )
        : AutoSizeText(
            text,
            textAlign: TextAlign.center,
            style: resolvedStyle,
            maxLines: maxLines,
          );

    return GestureDetector(
      onTap: () => ClipboardUtils.copyWithFeedback(context, copyText ?? text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.25),
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.secondary.withValues(alpha: 0.06),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 40,
              offset: const Offset(0, 16),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 28),
              child: textWidget,
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.copy_outlined,
                size: 18,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
