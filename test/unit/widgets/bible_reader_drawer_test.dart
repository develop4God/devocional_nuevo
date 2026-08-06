@Tags(['unit', 'widgets'])
library;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/widgets/bible/bible_reader_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

BibleVersion _version(String dbFileName, {String name = 'Test Version'}) {
  return BibleVersion(
    name: name,
    language: 'Test',
    languageCode: 'xx',
    assetPath: '',
    dbFileName: dbFileName,
    isDownloaded: false,
    remoteUrl: 'https://example.com/$dbFileName.gz',
  );
}

void main() {
  setUp(() async {
    await registerTestServices();
  });

  Future<void> pumpDrawer(
    WidgetTester tester, {
    required List<BibleVersion> versions,
    BibleVersion? selectedVersion,
    ValueChanged<BibleVersion>? onVersionSelected,
    VoidCallback? onDownloadMoreVersions,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: BibleReaderDrawer(
            availableVersions: versions,
            selectedVersion: selectedVersion,
            versionLabelBuilder: (v) => v.name,
            onVersionSelected: onVersionSelected ?? (_) {},
            onDownloadMoreVersions: onDownloadMoreVersions ?? () {},
          ),
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists all available versions with the selected one checked', (
    tester,
  ) async {
    final versionA = _version('A_xx.SQLite3', name: 'Version A');
    final versionB = _version('B_xx.SQLite3', name: 'Version B');

    await pumpDrawer(
      tester,
      versions: [versionA, versionB],
      selectedVersion: versionA,
    );

    expect(find.text('Version A'), findsOneWidget);
    expect(find.text('Version B'), findsOneWidget);

    final aTile = tester.widget<ListTile>(
      find.byKey(const Key('bible_reader_drawer_version_A_xx.SQLite3')),
    );
    final bTile = tester.widget<ListTile>(
      find.byKey(const Key('bible_reader_drawer_version_B_xx.SQLite3')),
    );
    expect(
      (aTile.leading as Icon).icon,
      Icons.radio_button_checked,
    );
    expect(
      (bTile.leading as Icon).icon,
      Icons.radio_button_off,
    );
  });

  testWidgets(
      'tapping a non-selected version closes the drawer and invokes callback',
      (tester) async {
    final versionA = _version('A_xx.SQLite3', name: 'Version A');
    final versionB = _version('B_xx.SQLite3', name: 'Version B');
    BibleVersion? selected;

    await pumpDrawer(
      tester,
      versions: [versionA, versionB],
      selectedVersion: versionA,
      onVersionSelected: (v) => selected = v,
    );

    await tester.tap(find.text('Version B'));
    await tester.pumpAndSettle();

    expect(selected, versionB);
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('tapping the already-selected version does not invoke callback',
      (tester) async {
    final versionA = _version('A_xx.SQLite3', name: 'Version A');
    bool callbackInvoked = false;

    await pumpDrawer(
      tester,
      versions: [versionA],
      selectedVersion: versionA,
      onVersionSelected: (_) => callbackInvoked = true,
    );

    await tester.tap(find.text('Version A'));
    await tester.pumpAndSettle();

    expect(callbackInvoked, isFalse);
  });

  testWidgets(
      'tapping download-more-versions closes the drawer and invokes callback',
      (tester) async {
    final versionA = _version('A_xx.SQLite3', name: 'Version A');
    bool downloadInvoked = false;

    await pumpDrawer(
      tester,
      versions: [versionA],
      selectedVersion: versionA,
      onDownloadMoreVersions: () => downloadInvoked = true,
    );

    await tester.tap(
      find.byKey(const Key('bible_reader_drawer_download_more')),
    );
    await tester.pumpAndSettle();

    expect(downloadInvoked, isTrue);
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('close button closes the drawer', (tester) async {
    final versionA = _version('A_xx.SQLite3', name: 'Version A');

    await pumpDrawer(
      tester,
      versions: [versionA],
      selectedVersion: versionA,
    );

    expect(find.byType(Drawer), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('bible_reader_drawer_close_button')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsNothing);
  });
}
