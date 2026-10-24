@Tags(['unit', 'widgets'])
library;

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

  Future<void> pumpBanner(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateReadyBanner(
            updateReady: ready,
            onRestart: () => restarts++,
            title: 'Update ready',
            message: 'Restart to get the latest improvements.',
            restartLabel: 'Restart',
            closeTooltip: 'Close',
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
    expect(find.text('Restart'), findsOneWidget);
  });

  testWidgets('Restart calls onRestart and offers no Later action',
      (tester) async {
    ready.value = true;
    await pumpBanner(tester);

    await tester.tap(find.text('Restart'));

    expect(restarts, 1);
    expect(find.text('Later'), findsNothing);
  });

  testWidgets('close hides the banner without restarting', (tester) async {
    ready.value = true;
    await pumpBanner(tester);

    await tester.tap(find.byTooltip('Close'));
    await tester.pump();

    expect(find.text('Update ready'), findsNothing);
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
              onRestart: () {},
              title: 'Update ready',
              message: 'Restart',
              restartLabel: 'Restart',
              closeTooltip: 'Close',
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
