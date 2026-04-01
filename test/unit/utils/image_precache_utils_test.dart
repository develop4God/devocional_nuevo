import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/utils/image_precache_utils.dart';

void main() {
  group('safePrecacheImage', () {
    testWidgets(
      'completes without throwing when onError fires',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        final context = tester.element(find.byType(SizedBox));

        // A provider that always fails
        final failingProvider = _AlwaysFailImageProvider();

        bool errorCallbackCalled = false;

        await expectLater(
          safePrecacheImage(
            failingProvider,
            context,
            debugTag: 'test',
            onNetworkError: (_, __) => errorCallbackCalled = true,
          ),
          completes, // must NOT throw
        );

        expect(errorCallbackCalled, isTrue);
      },
    );

    testWidgets(
      'onNetworkError is optional — no throw when omitted',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        final context = tester.element(find.byType(SizedBox));

        await expectLater(
          safePrecacheImage(
            _AlwaysFailImageProvider(),
            context,
            debugTag: 'test-no-callback',
          ),
          completes,
        );
      },
    );
  });
}

// Minimal ImageProvider that always fires onError
class _AlwaysFailImageProvider extends ImageProvider<_AlwaysFailImageProvider> {
  @override
  Future<_AlwaysFailImageProvider> obtainKey(ImageConfiguration config) async =>
      this;

  @override
  ImageStreamCompleter loadImage(
      _AlwaysFailImageProvider key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(
      Future.error(
        Exception('Simulated DNS failure: Failed host lookup'),
      ),
    );
  }
}

