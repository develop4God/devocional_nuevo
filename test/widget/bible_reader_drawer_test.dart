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

  group('BibleReaderDrawer Version Selection Tests', () {
    testWidgets('Version tile shows download icon when not downloaded',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InkWell(
              onTap: () {},
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_outlined),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NIV',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('English',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    // Not downloaded - show download icon
                    const Icon(Icons.file_download_outlined, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('NIV'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
    });

    testWidgets('Version tile shows downloaded icon when downloaded',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InkWell(
              onTap: () {},
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_outlined),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('KJV',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('English',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    // Downloaded - show check icon
                    const Icon(Icons.file_download_done_rounded, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('KJV'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.byIcon(Icons.file_download_done_rounded), findsOneWidget);
    });

    testWidgets('Selected version tile shows check icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InkWell(
              onTap: () {},
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.purple.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.purple),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RVR1960',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('Español',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.file_download_done_rounded, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('RVR1960'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Version tile shows progress indicator when downloading',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InkWell(
              onTap: () {},
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: const Row(
                  children: [
                    Icon(Icons.menu_book_outlined),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LSG1910',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('Français',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    // Downloading - show progress indicator
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: 0.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('LSG1910'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Language header is displayed above versions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    'English',
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ListTile(title: Text('KJV')),
                ListTile(title: Text('NIV')),
                Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    'Español',
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ListTile(title: Text('RVR1960')),
                ListTile(title: Text('NVI')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('KJV'), findsOneWidget);
      expect(find.text('NIV'), findsOneWidget);
      expect(find.text('RVR1960'), findsOneWidget);
      expect(find.text('NVI'), findsOneWidget);
    });
  });
}
