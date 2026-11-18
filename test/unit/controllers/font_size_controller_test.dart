@Tags(['unit', 'controllers'])
library;

import 'package:devocional_nuevo/controllers/font_size_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FontSizeController', () {
    late FontSizeController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      controller = FontSizeController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('has correct default font size', () {
      expect(controller.fontSize, FontSizeController.defaultFontSize);
      expect(controller.fontSize, 16.0);
    });

    test('font controls are hidden by default', () {
      expect(controller.showControls, isFalse);
    });

    test('toggleControls flips visibility', () {
      expect(controller.showControls, isFalse);

      controller.toggleControls();
      expect(controller.showControls, isTrue);

      controller.toggleControls();
      expect(controller.showControls, isFalse);
    });

    test('hideControls sets controls to hidden', () {
      controller.toggleControls();
      expect(controller.showControls, isTrue);

      controller.hideControls();
      expect(controller.showControls, isFalse);
    });

    test('hideControls does nothing when already hidden', () {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.hideControls();
      expect(notifyCount, 0);
    });

    test('exposes five stops 16, 20, 24, 28, 32', () {
      expect(FontSizeController.fontSizeStops, [16.0, 20.0, 24.0, 28.0, 32.0]);
      expect(FontSizeController.minFontSize, 16.0);
      expect(FontSizeController.maxFontSize, 32.0);
    });

    test('increase moves to the next stop', () async {
      await controller.increase();
      expect(controller.fontSize, 20.0);
      await controller.increase();
      expect(controller.fontSize, 24.0);
    });

    test('decrease moves to the previous stop', () async {
      await controller.setFontSize(28.0);
      await controller.decrease();
      expect(controller.fontSize, 24.0);
    });

    test('increase clamps at the maximum stop', () async {
      await controller.setFontSize(32.0);
      await controller.increase();
      expect(controller.fontSize, 32.0);
    });

    test('decrease clamps at the minimum stop', () async {
      await controller.decrease();
      expect(controller.fontSize, 16.0);
    });

    test('increase from a legacy value goes to the stop above its snap',
        () async {
      SharedPreferences.setMockInitialValues({'devocional_font_size': 24.0});
      await controller.load(); // snaps to 24
      await controller.increase();
      expect(controller.fontSize, 28.0);
    });

    test('setFontSize is a no-op when the snapped size is unchanged', () async {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.setFontSize(17.0); // snaps to 16, already current

      expect(notifyCount, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('devocional_font_size'), isNull);
    });

    test('increase and decrease work after loading a legacy size', () async {
      SharedPreferences.setMockInitialValues({'devocional_font_size': 40.0});
      await controller.load(); // snaps to 32
      await controller.increase();
      expect(controller.fontSize, 32.0);
      await controller.decrease();
      expect(controller.fontSize, 28.0);
    });

    test('snapToStop picks the nearest stop', () {
      expect(FontSizeController.snapToStop(12.0), 16.0);
      expect(FontSizeController.snapToStop(17.0), 16.0);
      expect(FontSizeController.snapToStop(19.0), 20.0);
      expect(FontSizeController.snapToStop(21.0), 20.0);
      expect(FontSizeController.snapToStop(27.0), 28.0);
      expect(FontSizeController.snapToStop(40.0), 32.0);
      expect(FontSizeController.snapToStop(24.0), 24.0);
    });

    test('snapToStop resolves ties to the lower stop', () {
      expect(FontSizeController.snapToStop(18.0), 16.0);
    });

    test('setFontSize snaps, notifies and persists', () async {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.setFontSize(23.0);

      expect(controller.fontSize, 24.0);
      expect(notifyCount, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('devocional_font_size'), 24.0);
    });

    test('reset returns to default and persists', () async {
      await controller.setFontSize(32.0);
      await controller.reset();

      expect(controller.fontSize, FontSizeController.defaultFontSize);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('devocional_font_size'), 16.0);
    });

    test('canIncrease is false at maxFontSize', () async {
      await controller.setFontSize(32.0);
      expect(controller.canIncrease, isFalse);
      expect(controller.canDecrease, isTrue);
    });

    test('canDecrease is false at minFontSize', () {
      expect(controller.canDecrease, isFalse);
      expect(controller.canIncrease, isTrue);
    });

    test('load restores persisted font size', () async {
      // Persist a custom font size
      SharedPreferences.setMockInitialValues({'devocional_font_size': 24.0});

      final controller2 = FontSizeController();
      await controller2.load();

      expect(controller2.fontSize, 24.0);
      controller2.dispose();
    });

    test('load snaps legacy saved sizes to the nearest stop', () async {
      for (final entry in {12.0: 16.0, 17.0: 16.0, 40.0: 32.0}.entries) {
        SharedPreferences.setMockInitialValues({
          'devocional_font_size': entry.key,
        });
        await controller.load();
        expect(controller.fontSize, entry.value, reason: '${entry.key}');
      }
    });

    test('load uses default when no persisted value', () async {
      SharedPreferences.setMockInitialValues({});

      await controller.load();
      expect(controller.fontSize, FontSizeController.defaultFontSize);
    });

    test('increase persists font size', () async {
      await controller.increase();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('devocional_font_size'), controller.fontSize);
    });

    test('decrease persists font size', () async {
      // Start above min so we can decrease
      await controller.setFontSize(28.0);
      await controller.decrease();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('devocional_font_size'), controller.fontSize);
    });

    test('notifies listeners on increase', () async {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.increase();
      expect(notifyCount, 1);
    });

    test('notifies listeners on decrease', () async {
      int notifyCount = 0;
      await controller.setFontSize(24.0); // Make room to decrease
      controller.addListener(() => notifyCount++);

      await controller.decrease();
      expect(notifyCount, 1);
    });

    test('notifies listeners on toggleControls', () {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.toggleControls();
      expect(notifyCount, 1);
    });

    test('notifies listeners on load', () async {
      SharedPreferences.setMockInitialValues({'devocional_font_size': 20.0});

      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.load();
      expect(notifyCount, 1);
    });

    test('constants have valid ranges', () {
      expect(
        FontSizeController.minFontSize,
        lessThan(FontSizeController.maxFontSize),
      );
      expect(
        FontSizeController.defaultFontSize,
        greaterThanOrEqualTo(FontSizeController.minFontSize),
      );
      expect(
        FontSizeController.defaultFontSize,
        lessThanOrEqualTo(FontSizeController.maxFontSize),
      );
    });
  });
}
