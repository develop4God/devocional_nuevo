@Tags(['unit', 'widgets'])
library;

import 'dart:async';

import 'package:devocional_nuevo/services/i_update_service.dart';
import 'package:devocional_nuevo/widgets/notice_banner_card.dart';
import 'package:devocional_nuevo/widgets/update_ready_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  static int created = 0;
  static double? topPadding;

  @override
  void initState() {
    super.initState();
    created++;
  }

  @override
  Widget build(BuildContext context) {
    topPadding = MediaQuery.paddingOf(context).top;
    return const SizedBox.expand();
  }
}

void main() {
  late ValueNotifier<bool> ready;
  late int restarts;
  late UpdateInstallResult restartResult;
  Object? restartError;

  Future<void> pumpBanner(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateReadyBanner(
            updateReady: ready,
            onRestart: () async {
              restarts++;
              if (restartError != null) throw restartError!;
              return restartResult;
            },
            title: 'Update ready',
            message: 'Tap to restart and get the latest improvements.',
            closeTooltip: 'Close',
            restartFailedMessage: 'Could not restart',
            child: const _Probe(),
          ),
        ),
      ),
    );
  }

  setUp(() {
    _ProbeState.created = 0;
    _ProbeState.topPadding = null;
    ready = ValueNotifier(false);
    restarts = 0;
    restartResult = UpdateInstallResult.installing;
    restartError = null;
  });

  tearDown(() => ready.dispose());

  group('download in progress', () {
    late ValueNotifier<bool> downloading;

    Future<void> pumpWithDownload(WidgetTester tester) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateReadyBanner(
              updateReady: ready,
              download: UpdateDownloadNotice(
                downloading: downloading,
                title: 'Downloading update',
                message: 'You can keep using the app.',
              ),
              onRestart: () async {
                restarts++;
                return UpdateInstallResult.installing;
              },
              title: 'Update ready',
              message: 'Tap to restart and get the latest improvements.',
              closeTooltip: 'Close',
              restartFailedMessage: 'Could not restart',
              child: const _Probe(),
            ),
          ),
        ),
      );
    }

    setUp(() => downloading = ValueNotifier(false));
    tearDown(() => downloading.dispose());

    testWidgets('shows a spinner banner while downloading', (tester) async {
      await pumpWithDownload(tester);
      expect(find.text('Downloading update'), findsNothing);

      downloading.value = true;
      await tester.pump();

      expect(find.text('Downloading update'), findsOneWidget);
      expect(find.text('You can keep using the app.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('tapping the downloading banner does not restart',
        (tester) async {
      downloading.value = true;
      await pumpWithDownload(tester);

      await tester.tap(find.text('Downloading update'));

      expect(restarts, 0);
    });

    testWidgets('ready replaces the downloading banner', (tester) async {
      downloading.value = true;
      await pumpWithDownload(tester);

      downloading.value = false;
      ready.value = true;
      await tester.pump();

      expect(find.text('Downloading update'), findsNothing);
      expect(find.text('Update ready'), findsOneWidget);
    });

    testWidgets('closing the downloading banner does not hide the ready one',
        (tester) async {
      downloading.value = true;
      await pumpWithDownload(tester);
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();

      downloading.value = false;
      ready.value = true;
      await tester.pump();

      expect(find.text('Update ready'), findsOneWidget);
    });

    testWidgets('a later download shows again after an earlier one was closed',
        (tester) async {
      downloading.value = true;
      await pumpWithDownload(tester);
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();

      downloading.value = false;
      await tester.pump();
      downloading.value = true;
      await tester.pump();

      expect(find.text('Downloading update'), findsOneWidget);
    });

    testWidgets('close hides the downloading banner', (tester) async {
      downloading.value = true;
      await pumpWithDownload(tester);

      await tester.tap(find.byTooltip('Close'));
      await tester.pump();

      expect(find.text('Downloading update'), findsNothing);
    });
  });

  testWidgets('is hidden until an update is ready', (tester) async {
    await pumpBanner(tester);

    expect(find.text('Update ready'), findsNothing);
  });

  testWidgets('appears when the update becomes ready', (tester) async {
    await pumpBanner(tester);

    ready.value = true;
    await tester.pump();

    expect(find.text('Update ready'), findsOneWidget);
    expect(find.byIcon(Icons.download_done_outlined), findsOneWidget);
  });

  testWidgets('logs shown once per state, not on every rebuild',
      (tester) async {
    final logs = <String>[];
    await runZoned(
      () async {
        await pumpBanner(tester);
        ready.value = true;
        await tester.pump();
        await pumpBanner(tester); // parent rebuild, same state
        await tester.pump();
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => logs.add(line),
      ),
    );

    expect(logs.where((l) => l.contains('shown (ready)')), hasLength(1));
  });

  testWidgets('tapping the message restarts and offers no Later action',
      (tester) async {
    ready.value = true;
    await pumpBanner(tester);

    await tester
        .tap(find.text('Tap to restart and get the latest improvements.'));

    expect(restarts, 1);
    expect(find.text('Later'), findsNothing);
  });

  testWidgets('tapping the title restarts', (tester) async {
    ready.value = true;
    await pumpBanner(tester);

    await tester.tap(find.text('Update ready'));

    expect(restarts, 1);
  });

  testWidgets('a failed restart tells the user and keeps the banner',
      (tester) async {
    ready.value = true;
    restartResult = UpdateInstallResult.failed;
    await pumpBanner(tester);

    await tester.tap(find.text('Update ready'));
    await tester.pump();

    expect(find.text('Could not restart'), findsOneWidget);
    expect(find.text('Update ready'), findsOneWidget);
  });

  testWidgets('a thrown restart error shows the failed message and re-enables',
      (tester) async {
    ready.value = true;
    restartError = StateError('boom');
    await pumpBanner(tester);

    await tester.tap(find.text('Update ready'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Could not restart'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('the failure message uses the shared floating error snackbar',
      (tester) async {
    ready.value = true;
    restartResult = UpdateInstallResult.failed;
    await pumpBanner(tester);

    await tester.tap(find.text('Update ready'));
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    final scheme = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
    expect(snackBar.behavior, SnackBarBehavior.floating);
    expect(snackBar.backgroundColor, scheme.error);
    expect(find.text('Could not restart'), findsOneWidget);
  });

  testWidgets('taps while a restart is in progress are ignored',
      (tester) async {
    final release = Completer<UpdateInstallResult>();
    ready.value = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateReadyBanner(
            updateReady: ready,
            onRestart: () {
              restarts++;
              return release.future;
            },
            title: 'Update ready',
            message: 'Restart',
            closeTooltip: 'Close',
            restartFailedMessage: 'Could not restart',
            child: const _Probe(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Update ready'));
    await tester.tap(find.text('Update ready'));
    release.complete(UpdateInstallResult.failed);
    await tester.pump();

    expect(restarts, 1);
    expect(find.text('Could not restart'), findsOneWidget);
  });

  testWidgets(
      'an unconfirmed restart shows no error and the card is tappable again',
      (tester) async {
    ready.value = true;
    restartResult = UpdateInstallResult.unconfirmed;
    await pumpBanner(tester);

    await tester.tap(find.text('Update ready'));
    await tester.pump();

    expect(find.text('Could not restart'), findsNothing);
    expect(find.text('Update ready'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Update ready'));
    await tester.pump();

    expect(restarts, 2);
    expect(find.text('Could not restart'), findsNothing);
  });

  testWidgets('a restart that throws does not lock the banner nor escape',
      (tester) async {
    ready.value = true;
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateReadyBanner(
            updateReady: ready,
            onRestart: () async {
              attempts++;
              throw StateError('boom');
            },
            title: 'Update ready',
            message: 'Restart',
            closeTooltip: 'Close',
            restartFailedMessage: 'Could not restart',
            child: const _Probe(),
          ),
        ),
      ),
    );

    final errors = <Object>[];
    for (var i = 0; i < 2; i++) {
      await runZonedGuarded(() async {
        await tester.tap(find.text('Update ready'));
        await tester.pump();
      }, (error, _) => errors.add(error));
    }

    expect(attempts, 2);
    expect(errors, isEmpty, reason: 'a thrown error maps to the failed result');
  });

  testWidgets('a successful restart shows no error', (tester) async {
    ready.value = true;
    await pumpBanner(tester);

    await tester.tap(find.text('Update ready'));
    await tester.pump();

    expect(find.text('Could not restart'), findsNothing);
  });

  testWidgets('has no separate restart button, the card is the target',
      (tester) async {
    ready.value = true;
    await pumpBanner(tester);

    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(InkWell), findsWidgets);
  });

  testWidgets('close hides the banner without restarting', (tester) async {
    ready.value = true;
    await pumpBanner(tester);

    await tester.tap(find.byTooltip('Close'));
    await tester.pump();

    expect(find.text('Update ready'), findsNothing);
    expect(restarts, 0);
  });

  testWidgets('close sits on top of the card tap and never restarts',
      (tester) async {
    ready.value = true;
    await pumpBanner(tester);

    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(restarts, 0);
  });

  testWidgets('stays closed for the session when ready fires again',
      (tester) async {
    ready.value = true;
    await pumpBanner(tester);
    await tester.tap(find.byTooltip('Close'));
    await tester.pump();

    ready.value = false;
    await tester.pump();
    ready.value = true;
    await tester.pump();

    expect(find.text('Update ready'), findsNothing);
  });

  testWidgets('closed banner returns when the app comes back to the foreground',
      (tester) async {
    ready.value = true;
    await pumpBanner(tester);
    await tester.tap(find.byTooltip('Close'));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('Update ready'), findsOneWidget);
  });

  testWidgets(
      'closed banner stays closed while the app stays in the foreground',
      (tester) async {
    ready.value = true;
    await pumpBanner(tester);
    await tester.tap(find.byTooltip('Close'));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('Update ready'), findsNothing);
  });

  testWidgets('a child that does not expand still fills the area',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateReadyBanner(
            updateReady: ready,
            onRestart: () async => UpdateInstallResult.installing,
            title: 'Update ready',
            message: 'Tap to restart and get the latest improvements.',
            closeTooltip: 'Close',
            restartFailedMessage: 'Could not restart',
            child: const SizedBox.shrink(key: Key('shrunk_child')),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('shrunk_child'))),
      tester.getSize(find.byType(Scaffold)),
    );
  });

  testWidgets('keeps the child state when the banner toggles', (tester) async {
    await pumpBanner(tester);

    ready.value = true;
    await tester.pump();
    ready.value = false;
    await tester.pump();

    expect(_ProbeState.created, 1);
  });

  Widget hostWithPadding({Widget? child}) => MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(top: 24)),
        child: MaterialApp(
          home: Scaffold(
            body: UpdateReadyBanner(
              updateReady: ready,
              onRestart: () async => UpdateInstallResult.installing,
              title: 'Update ready',
              message: 'Restart',
              closeTooltip: 'Close',
              restartFailedMessage: 'Could not restart',
              child: child ?? const _Probe(),
            ),
          ),
        ),
      );

  testWidgets('child keeps its size, position and top inset when banner shows',
      (tester) async {
    await tester.pumpWidget(hostWithPadding());
    final before = tester.getRect(find.byType(_Probe));
    expect(_ProbeState.topPadding, 24);

    ready.value = true;
    await tester.pump();

    expect(find.text('Update ready'), findsOneWidget);
    expect(tester.getRect(find.byType(_Probe)), before);
    expect(_ProbeState.topPadding, 24);
  });

  testWidgets('banner floats at the top below the status-bar inset',
      (tester) async {
    await tester.pumpWidget(hostWithPadding());
    ready.value = true;
    await tester.pump();

    final card = tester.getRect(find.byType(NoticeBannerCard));
    // The rect includes the card's own 8px top margin, so it starts right at
    // the inset.
    expect(card.top, 24);
  });

  testWidgets('nothing opaque is painted around the card', (tester) async {
    await tester.pumpWidget(hostWithPadding());
    ready.value = true;
    await tester.pump();

    final screenWidth = tester.getSize(find.byType(Scaffold)).width;
    final overlay = find.descendant(
      of: find.byType(Positioned),
      matching: find.byWidgetPredicate(
        (w) => w is Material || w is ColoredBox || w is DecoratedBox,
      ),
    );
    for (final element in overlay.evaluate()) {
      final box = element.renderObject! as RenderBox;
      final isCardOrInner = find
              .descendant(
                of: find.byType(NoticeBannerCard),
                matching: find.byWidget(element.widget),
              )
              .evaluate()
              .isNotEmpty ||
          element.widget is Material &&
              (element.widget as Material).type == MaterialType.transparency;
      if (isCardOrInner) continue;
      expect(box.size.width, lessThan(screenWidth));
    }
    final positioned = tester.widget<Positioned>(
      find.ancestor(
        of: find.byType(NoticeBannerCard),
        matching: find.byType(Positioned),
      ),
    );
    expect(positioned.bottom, isNull);
  });

  testWidgets('taps below the card reach the child while the banner shows',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      hostWithPadding(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox.expand(),
        ),
      ),
    );
    ready.value = true;
    await tester.pump();

    final card = tester.getRect(find.byType(NoticeBannerCard));
    await tester.tapAt(Offset(card.center.dx, card.bottom + 40));
    // Beside the card margin at the top: also reaches the child.
    await tester.tapAt(const Offset(2, 2));

    expect(taps, 2);
  });

  group('restart in progress', () {
    late Completer<UpdateInstallResult> release;

    Future<void> pumpPending(WidgetTester tester) {
      release = Completer<UpdateInstallResult>();
      ready.value = true;
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateReadyBanner(
              updateReady: ready,
              onRestart: () {
                restarts++;
                return release.future;
              },
              title: 'Update ready',
              message: 'Restart',
              closeTooltip: 'Close',
              restartFailedMessage: 'Could not restart',
              child: const _Probe(),
            ),
          ),
        ),
      );
    }

    testWidgets('shows progress and ignores a second tap', (tester) async {
      await pumpPending(tester);

      await tester.tap(find.text('Update ready'));
      await tester.pump();
      await tester.tap(find.text('Update ready'));
      await tester.pump();

      expect(restarts, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.download_done_outlined), findsNothing);

      release.complete(UpdateInstallResult.installing);
      await tester.pump();
    });

    testWidgets('the progress indicator has a semantics label', (tester) async {
      await pumpPending(tester);

      await tester.tap(find.text('Update ready'));
      await tester.pump();

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.semanticsLabel, 'Update ready');

      release.complete(UpdateInstallResult.installing);
      await tester.pump();
    });

    testWidgets('close stays enabled while restarting and hides the card',
        (tester) async {
      await pumpPending(tester);

      await tester.tap(find.text('Update ready'));
      await tester.pump();
      final close = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.close),
      );
      expect(close.onPressed, isNotNull);
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();

      expect(find.text('Update ready'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('the card returns idle and restart works again after resume',
        (tester) async {
      await pumpPending(tester);
      await tester.tap(find.text('Update ready'));
      await tester.pump();
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.byIcon(Icons.download_done_outlined), findsOneWidget);
      await tester.tap(find.text('Update ready'));
      await tester.pump();
      expect(restarts, 2);
    });

    testWidgets('a late failure of an abandoned restart shows nothing',
        (tester) async {
      await pumpPending(tester);
      await tester.tap(find.text('Update ready'));
      await tester.pump();
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();

      release.complete(UpdateInstallResult.failed);
      await tester.pump();

      expect(find.text('Could not restart'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a late result of an abandoned restart leaves a newer attempt',
        (tester) async {
      await pumpPending(tester);
      final first = release;
      await tester.tap(find.text('Update ready'));
      await tester.pump();
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      release = Completer<UpdateInstallResult>();
      await tester.tap(find.text('Update ready'));
      await tester.pump();

      first.complete(UpdateInstallResult.unconfirmed);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      release.complete(UpdateInstallResult.installing);
      await tester.pump();
    });

    testWidgets('a late unconfirmed result of an abandoned restart is silent',
        (tester) async {
      await pumpPending(tester);
      await tester.tap(find.text('Update ready'));
      await tester.pump();
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();

      release.complete(UpdateInstallResult.unconfirmed);
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('failure restores the icon, shows the snackbar, allows retry',
        (tester) async {
      await pumpPending(tester);

      await tester.tap(find.text('Update ready'));
      await tester.pump();
      release.complete(UpdateInstallResult.failed);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.download_done_outlined), findsOneWidget);
      expect(find.text('Could not restart'), findsOneWidget);

      release = Completer<UpdateInstallResult>();
      await tester.tap(find.text('Update ready'));
      await tester.pump();

      expect(restarts, 2);

      release.complete(UpdateInstallResult.installing);
      await tester.pump();
    });

    testWidgets('finishing after the banner is gone does not throw',
        (tester) async {
      await pumpPending(tester);

      await tester.tap(find.text('Update ready'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      release.complete(UpdateInstallResult.failed);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
