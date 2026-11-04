@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/widgets/linkified_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ntbt = 'Santa Biblia, NTBT. Publicada por BibliaTodo LLC. '
      'https://www.bibliatodo.com/ntbt/';

  Future<List<Uri>> pump(WidgetTester tester, String text) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LinkifiedText(
            text: text,
            onOpenUrl: (uri) async => opened.add(uri),
          ),
        ),
      ),
    );
    return opened;
  }

  testWidgets('tapping the URL opens it', (tester) async {
    final opened = await pump(tester, ntbt);

    await tester.tapOnText(
      find.textRange.ofSubstring('https://www.bibliatodo.com/ntbt/'),
    );

    expect(opened, [Uri.parse('https://www.bibliatodo.com/ntbt/')]);
  });

  testWidgets('tapping plain text opens nothing', (tester) async {
    final opened = await pump(tester, ntbt);

    await tester.tapOnText(find.textRange.ofSubstring('Santa Biblia'));

    expect(opened, isEmpty);
  });

  testWidgets('text without a URL renders unchanged', (tester) async {
    final opened = await pump(tester, 'No links here.');

    expect(find.text('No links here.'), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets('trailing sentence punctuation is excluded from the URL',
      (tester) async {
    final opened = await pump(tester, 'See https://example.com/a.');

    await tester.tapOnText(find.textRange.ofSubstring('https://example.com/a'));

    expect(opened, [Uri.parse('https://example.com/a')]);
  });

  testWidgets('multiple URLs are each tappable', (tester) async {
    final opened = await pump(tester, 'https://a.com and https://b.com');

    await tester.tapOnText(find.textRange.ofSubstring('https://b.com'));

    expect(opened, [Uri.parse('https://b.com')]);
  });

  testWidgets('quotes and angle brackets are not part of the URL',
      (tester) async {
    final opened = await pump(
        tester,
        'Terms: "https://example.org/x" or '
        '<https://example.org/y>');

    await tester.tapOnText(find.textRange.ofSubstring('https://example.org/x'));
    await tester.tapOnText(find.textRange.ofSubstring('https://example.org/y'));

    expect(opened, [
      Uri.parse('https://example.org/x'),
      Uri.parse('https://example.org/y'),
    ]);
  });

  testWidgets('a failing opener does not throw', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LinkifiedText(
            text: 'https://a.com',
            onOpenUrl: (_) async => throw Exception('no browser'),
          ),
        ),
      ),
    );

    await tester.tapOnText(find.textRange.ofSubstring('https://a.com'));

    expect(tester.takeException(), isNull);
  });

  testWidgets('a closing parenthesis balanced inside the URL is kept',
      (tester) async {
    final opened =
        await pump(tester, 'See https://en.wikipedia.org/wiki/Foo_(bar).');

    await tester.tapOnText(
      find.textRange.ofSubstring('https://en.wikipedia.org/wiki/Foo_(bar)'),
    );

    expect(opened, [Uri.parse('https://en.wikipedia.org/wiki/Foo_(bar)')]);
  });

  testWidgets('a parenthesis wrapping the URL is excluded', (tester) async {
    final opened = await pump(tester, '(see https://example.com/x)');

    await tester.tapOnText(find.textRange.ofSubstring('https://example.com/x'));

    expect(opened, [Uri.parse('https://example.com/x')]);
  });

  testWidgets('links keep working after a theme change and a text change',
      (tester) async {
    final opened = <Uri>[];
    Widget app(String text, Color seed) => MaterialApp(
          theme: ThemeData(colorSchemeSeed: seed),
          home: Scaffold(
            body: LinkifiedText(
              text: text,
              onOpenUrl: (uri) async => opened.add(uri),
            ),
          ),
        );

    await tester.pumpWidget(app('go https://a.com', Colors.red));
    await tester.pumpWidget(app('go https://a.com', Colors.blue));
    await tester.tapOnText(find.textRange.ofSubstring('https://a.com'));
    await tester.pumpWidget(app('now https://b.com', Colors.blue));
    await tester.tapOnText(find.textRange.ofSubstring('https://b.com'));

    expect(opened, [Uri.parse('https://a.com'), Uri.parse('https://b.com')]);
    expect(tester.takeException(), isNull);
  });
}
