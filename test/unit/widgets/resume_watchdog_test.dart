@Tags(['unit', 'widgets'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal test widget mirroring lib/main.dart's _MyAppState resume
/// watchdog confirmation — see _confirmResumeDrawn() and the
/// AppLifecycleState.resumed branch of didChangeAppLifecycleState().
///
/// Confirms to native (via the resume_watchdog MethodChannel) that a resume
/// actually rendered a frame, clearing the black-screen-on-resume telemetry
/// marker set natively in MainActivity.onPause(). Fire-and-forget: any
/// channel error is caught and logged, never propagated, since this is
/// non-critical telemetry and must never affect the app's real behavior.
class TestResumeWatchdogWidget extends StatefulWidget {
  final Completer<String> resultCompleter;

  const TestResumeWatchdogWidget({super.key, required this.resultCompleter});

  @override
  State<TestResumeWatchdogWidget> createState() =>
      _TestResumeWatchdogWidgetState();
}

class _TestResumeWatchdogWidgetState extends State<TestResumeWatchdogWidget> {
  static const MethodChannel _resumeWatchdogChannel = MethodChannel(
    'com.develop4god.devocional_nuevo/resume_watchdog',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_confirmResumeDrawn());
    });
  }

  Future<void> _confirmResumeDrawn() async {
    try {
      await _resumeWatchdogChannel.invokeMethod('confirmResumeDrawn');
      widget.resultCompleter.complete('confirmed');
    } catch (e) {
      widget.resultCompleter.complete('error_swallowed');
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    'com.develop4god.devocional_nuevo/resume_watchdog',
  );

  group('Resume watchdog confirmation', () {
    testWidgets(
      'invokes confirmResumeDrawn on the correct channel and method name',
      (WidgetTester tester) async {
        String? capturedMethod;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (methodCall) async {
          capturedMethod = methodCall.method;
          return null;
        });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null);
        });

        final resultCompleter = Completer<String>();
        await tester.pumpWidget(
          TestResumeWatchdogWidget(resultCompleter: resultCompleter),
        );
        await tester.pump();

        final result = await resultCompleter.future;
        expect(result, equals('confirmed'));
        expect(capturedMethod, equals('confirmResumeDrawn'));
      },
    );

    testWidgets(
      'swallows a PlatformException from the channel without propagating it',
      (WidgetTester tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (methodCall) async {
          throw PlatformException(
            code: 'test_error',
            message: 'Simulated native channel failure',
          );
        });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null);
        });

        final resultCompleter = Completer<String>();
        await tester.pumpWidget(
          TestResumeWatchdogWidget(resultCompleter: resultCompleter),
        );
        await tester.pump();

        // Must not throw — this is non-critical telemetry and a channel
        // failure (e.g. native side not yet attached) must never surface
        // as an app error.
        final result = await resultCompleter.future;
        expect(result, equals('error_swallowed'));
      },
    );
  });
}
