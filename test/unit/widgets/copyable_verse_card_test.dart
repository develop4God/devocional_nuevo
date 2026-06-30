@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/widgets/devocionales/copyable_verse_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CopyableVerseCard', () {
    const verseText = 'Juan 3:16 — De tal manera amó Dios al mundo';

    Widget buildWidget({String text = verseText, TextStyle? textStyle}) {
      return MaterialApp(
        home: Scaffold(
          body: CopyableVerseCard(text: text, textStyle: textStyle),
        ),
      );
    }

    testWidgets('renders the verse text', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text(verseText), findsOneWidget);
    });

    testWidgets('shows copy icon', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
    });

    testWidgets('copies text to clipboard on tap', (tester) async {
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<String, dynamic>)['text'] as String?;
          }
          return null;
        },
      );

      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(copiedText, equals(verseText));

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    testWidgets('renders prefixSpan and body text separately', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CopyableVerseCard(
              text: 'cuerpo del versículo',
              prefixSpan: const TextSpan(text: 'Juan 3:16: '),
            ),
          ),
        ),
      );
      expect(find.textContaining('Juan 3:16:'), findsOneWidget);
      expect(find.textContaining('cuerpo del versículo'), findsOneWidget);
    });

    testWidgets('copies copyText instead of text when both provided',
        (tester) async {
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<String, dynamic>)['text'] as String?;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CopyableVerseCard(
              text: 'solo cuerpo',
              copyText: 'Juan 3:16: solo cuerpo',
              prefixSpan: const TextSpan(text: 'Juan 3:16: '),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(copiedText, equals('Juan 3:16: solo cuerpo'));

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
  });
}
