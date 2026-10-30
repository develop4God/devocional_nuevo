@Tags(['unit', 'widgets'])
library;

import 'dart:async';

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
  late bool restartSucceeds;

  Future<void> pumpBanner(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateReadyBanner(
            updateReady: ready,
            onRestart: () async {
              restarts++;
              return restartSucceeds;
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
    restartSucceeds = true;
  });

  tearDown(() => ready.dispose());

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
    restartSucceeds = false;
    await pumpBanner(tester);

    await tester.tap(find.text('Update ready'));
    await tester.pump();

    expect(find.text('Could not restart'), findsOneWidget);
    expect(find.text('Update ready'), findsOneWidget);
  });

  testWidgets('taps while a restart is in progress are ignored',
      (tester) async {
    final release = Completer<bool>();
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
    release.complete(false);
    await tester.pump();

    expect(restarts, 1);
    expect(find.text('Could not restart'), findsOneWidget);
  });

  testWidgets('a restart that throws does not lock the banner', (tester) async {
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
    expect(errors, hasLength(2));
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

  testWidgets('keeps the child state when the banner toggles', (tester) async {
    await pumpBanner(tester);

    ready.value = true;
    await tester.pump();
    ready.value = false;
    await tester.pump();

    expect(_ProbeState.created, 1);
  });

  testWidgets('child loses the top inset only while the banner shows',
      (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(top: 24)),
        child: MaterialApp(
          home: Scaffold(
            body: UpdateReadyBanner(
              updateReady: ready,
              onRestart: () async => true,
              title: 'Update ready',
              message: 'Restart',
              closeTooltip: 'Close',
              restartFailedMessage: 'Could not restart',
              child: const _Probe(),
            ),
          ),
        ),
      ),
    );
    expect(_ProbeState.topPadding, 24);

    ready.value = true;
    await tester.pump();
    expect(_ProbeState.topPadding, 0);

    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    expect(_ProbeState.topPadding, 24);
  });
}
