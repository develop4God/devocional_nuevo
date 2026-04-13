import 'package:devocional_nuevo/controllers/post_splash_animation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostSplashAnimationController', () {
    late PostSplashAnimationController controller;

    setUp(() {
      PostSplashAnimationController.reset();
      controller = PostSplashAnimationController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('isVisible defaults to false', () {
      expect(controller.isVisible, isFalse);
    });

    test('selectedAsset returns fallback when not initialized', () {
      expect(controller.selectedAsset,
          PostSplashAnimationController.fallbackAsset);
    });

    test('initialize shows animation', () {
      bool dismissCalled = false;
      controller.initialize(onDismiss: () => dismissCalled = true);

      expect(controller.isVisible, isTrue);
      expect(controller.selectedAsset, isNotEmpty);
      expect(dismissCalled, isFalse); // Not dismissed yet
    });

    test('selectedAsset is from the lottieAssets list after initialize', () {
      controller.initialize(onDismiss: () {});

      expect(
        PostSplashAnimationController.lottieAssets,
        contains(controller.selectedAsset),
      );
    });

    test('only shows once per session (static flag)', () {
      final controller1 = PostSplashAnimationController();
      controller1.initialize(onDismiss: () {});
      expect(controller1.isVisible, isTrue);

      final controller2 = PostSplashAnimationController();
      controller2.initialize(onDismiss: () {});
      expect(controller2.isVisible, isFalse); // Should NOT show again

      controller1.dispose();
      controller2.dispose();
    });

    test('lottieAssets contains expected animation files', () {
      expect(PostSplashAnimationController.lottieAssets.length, 6);
      expect(PostSplashAnimationController.lottieAssets,
          contains('assets/lottie/happy_bird.json'));
    });

    test('animationWidth has reasonable value', () {
      expect(PostSplashAnimationController.animationWidth, 200.0);
    });

    test('animationDuration is 7 seconds', () {
      expect(PostSplashAnimationController.animationDuration,
          const Duration(seconds: 7));
    });

    test('reset() allows showing animation again', () {
      final c1 = PostSplashAnimationController();
      c1.initialize(onDismiss: () {});
      expect(c1.isVisible, isTrue);

      PostSplashAnimationController.reset();

      final c2 = PostSplashAnimationController();
      c2.initialize(onDismiss: () {});
      expect(c2.isVisible, isTrue); // Can show again after reset

      c1.dispose();
      c2.dispose();
    });

    test('no crash when disposed before animation timer fires', () async {
      bool dismissCalled = false;
      controller.initialize(onDismiss: () => dismissCalled = true);
      expect(controller.isVisible, isTrue);

      // Dispose immediately — before the 7-second timer fires
      controller.dispose();

      // Pump a short delay — the real timer won't fire in tests, but
      // this verifies the guard path doesn't throw
      await Future<void>.delayed(Duration.zero);

      expect(dismissCalled, isFalse); // onDismiss must NOT be called
    });
  });
}
