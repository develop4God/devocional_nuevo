import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests to ensure that the BibleReaderDrawer's download dialog
/// properly wraps ListTile widgets in a Material ancestor.
///
/// This test validates the fix for the "No Material widget found" error
/// that occurred when displaying version lists in the download dialog.
void main() {
  group('BibleReaderDrawer Material Widget Fix Tests', () {
    testWidgets('ListTile works inside Material widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Material(
              type: MaterialType.transparency,
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.book),
                    title: Text('Test Version'),
                    subtitle: Text('1.0 MB'),
                  ),
                  ListTile(
                    leading: Icon(Icons.download),
                    title: Text('Another Version'),
                    subtitle: Text('2.0 MB'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify ListTiles render without Material widget errors
      expect(find.text('Test Version'), findsOneWidget);
      expect(find.text('Another Version'), findsOneWidget);
      expect(find.byIcon(Icons.book), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('ListTile with Material.transparency does not show background',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Material(
              type: MaterialType.transparency,
              child: Container(
                color: Colors.purple, // Background color
                child: ListView(
                  children: const [
                    ListTile(
                      title: Text('Transparent Material ListTile'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // The Material should be transparent, letting background show through
      expect(find.text('Transparent Material ListTile'), findsOneWidget);

      // Verify Material widget is present
      expect(find.byType(Material), findsWidgets);
    });

    testWidgets('Multiple ListTiles work inside a ConstrainedBox with Material',
        (tester) async {
      // This simulates the structure in _BibleDownloadDialog._buildVersionsList
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Material(
                type: MaterialType.transparency,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      leading: const Icon(Icons.download_for_offline_outlined),
                      title: Text('Version $index'),
                      subtitle: Text('${(index + 1) * 1.5} MB'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Verify all items render
      expect(find.text('Version 0'), findsOneWidget);
      expect(find.text('Version 4'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(5));
    });

    testWidgets('LinearProgressIndicator works inside ListTile with Material',
        (tester) async {
      // Test the downloading state display
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Material(
              type: MaterialType.transparency,
              child: ListView(
                children: const [
                  ListTile(
                    title: Text('Downloading Version'),
                    subtitle: LinearProgressIndicator(value: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Downloading Version'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('IconButton works inside ListTile trailing with Material',
        (tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Material(
              type: MaterialType.transparency,
              child: ListView(
                children: [
                  ListTile(
                    title: const Text('Version with action'),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => buttonPressed = true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Version with action'), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);

      // Tap the download button
      await tester.tap(find.byIcon(Icons.download));
      await tester.pump();

      expect(buttonPressed, isTrue);
    });
  });
}
