@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/widgets/markdown_emphasis_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildEmphasisMarkdownText', () {
    testWidgets('renders **bold** segment with bold weight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(child: buildEmphasisMarkdownText('a **bold** word')),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      final rootSpan = text.textSpan as TextSpan;
      final boldSpan = rootSpan.children!
          .whereType<TextSpan>()
          .firstWhere((s) => s.text == 'bold');

      expect(boldSpan.style?.fontWeight, FontWeight.w800);
    });

    testWidgets('renders *italic* segment with italic style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: buildEmphasisMarkdownText('a *italic* word'),
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      final rootSpan = text.textSpan as TextSpan;
      final italicSpan = rootSpan.children!
          .whereType<TextSpan>()
          .firstWhere((s) => s.text == 'italic');

      expect(italicSpan.style?.fontStyle, FontStyle.italic);
    });

    testWidgets('does not split **bold** into two italic markers',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(child: buildEmphasisMarkdownText('**bold**')),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      final rootSpan = text.textSpan as TextSpan;
      final texts =
          rootSpan.children!.whereType<TextSpan>().map((s) => s.text).toList();

      expect(texts, ['bold']);
      final boldSpan = rootSpan.children!.whereType<TextSpan>().first;
      expect(boldSpan.style?.fontWeight, FontWeight.w800);
      expect(boldSpan.style?.fontStyle, isNot(FontStyle.italic));
    });

    testWidgets('renders plain text with no markers unchanged', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(child: buildEmphasisMarkdownText('plain text')),
        ),
      );

      expect(find.text('plain text'), findsOneWidget);
    });
  });
}
