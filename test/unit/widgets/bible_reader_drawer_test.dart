@Tags(['unit', 'widgets'])
library;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/bible_versions/bible_versions_state.dart';
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
    List<BibleVersion> downloadableVersions = const [],
    Map<String, VersionDownloadStatus> downloadStatuses = const {},
    ValueChanged<BibleVersion>? onVersionSelected,
    ValueChanged<BibleVersion>? onDownloadVersion,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: BibleReaderDrawer(
            availableVersions: versions,
            selectedVersion: selectedVersion,
            downloadableVersions: downloadableVersions,
            downloadStatuses: downloadStatuses,
            versionLabelBuilder: (v) => v.name,
            onVersionSelected: onVersionSelected ?? (_) {},
            onDownloadVersion: onDownloadVersion ?? (_) {},
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

  testWidgets(
      'lists downloadable versions inline with a download icon; tapping '
      'closes the drawer and invokes the download callback', (tester) async {
    final versionA = _version('A_xx.SQLite3', name: 'Version A');
    final downloadable = _version('KJ2000_xx.SQLite3', name: 'KJ2000');
    BibleVersion? downloadRequested;

    await pumpDrawer(
      tester,
      versions: [versionA],
      selectedVersion: versionA,
      downloadableVersions: [downloadable],
      onDownloadVersion: (v) => downloadRequested = v,
    );

    expect(find.text('KJ2000'), findsOneWidget);
    final tileFinder = find.byKey(
      const Key('bible_reader_drawer_downloadable_KJ2000_xx.SQLite3'),
    );
    expect(
      find.descendant(
        of: tileFinder,
        matching: find.byIcon(Icons.file_download_outlined),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('KJ2000'));
    await tester.pumpAndSettle();

    expect(downloadRequested, downloadable);
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('shows progress indicator while a version is downloading',
      (tester) async {
    final versionA = _version('A_xx.SQLite3', name: 'Version A');
    final downloadable = _version('KJ2000_xx.SQLite3', name: 'KJ2000');

    await pumpDrawer(
      tester,
      versions: [versionA],
      selectedVersion: versionA,
      downloadableVersions: [downloadable],
      downloadStatuses: const {
        'KJ2000_xx.SQLite3': VersionDownloadStatus(progress: 0.5),
      },
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
      'tapping a downloadable version mid-download does not re-trigger download',
      (tester) async {
    final versionA = _version('A_xx.SQLite3', name: 'Version A');
    final downloadable = _version('KJ2000_xx.SQLite3', name: 'KJ2000');
    bool downloadRequested = false;

    await pumpDrawer(
      tester,
      versions: [versionA],
      selectedVersion: versionA,
      downloadableVersions: [downloadable],
      downloadStatuses: const {
        'KJ2000_xx.SQLite3': VersionDownloadStatus(progress: 0.5),
      },
      onDownloadVersion: (_) => downloadRequested = true,
    );

    await tester.tap(find.text('KJ2000'));
    await tester.pumpAndSettle();

    expect(downloadRequested, isFalse);
  });

  testWidgets('shows a retry icon and allows re-tap after a failed download',
      (tester) async {
    final versionA = _version('A_xx.SQLite3', name: 'Version A');
    final downloadable = _version('KJ2000_xx.SQLite3', name: 'KJ2000');
    BibleVersion? downloadRequested;

    await pumpDrawer(
      tester,
      versions: [versionA],
      selectedVersion: versionA,
      downloadableVersions: [downloadable],
      downloadStatuses: const {
        'KJ2000_xx.SQLite3': VersionDownloadStatus(
            errorMessageKey: 'bible.download_error_network'),
      },
      onDownloadVersion: (v) => downloadRequested = v,
    );

    final tileFinder = find.byKey(
      const Key('bible_reader_drawer_downloadable_KJ2000_xx.SQLite3'),
    );
    expect(
      find.descendant(
        of: tileFinder,
        matching: find.byIcon(Icons.refresh_outlined),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('KJ2000'));
    await tester.pumpAndSettle();

    expect(downloadRequested, downloadable);
  });
}
