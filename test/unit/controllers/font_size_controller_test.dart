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

    test('increase increases font size by step', () async {
      final initial = controller.fontSize;
      await controller.increase();
      expect(controller.fontSize, initial + FontSizeController.fontSizeStep);
    });

    test('decrease decreases font size by step', () async {
      // First increase to have room to decrease
      await controller.increase();
      final afterIncrease = controller.fontSize;

      await controller.decrease();
      expect(
          controller.fontSize, afterIncrease - FontSizeController.fontSizeStep);
    });

    test('increase does not exceed maxFontSize', () async {
      // Set font to max
      while (controller.fontSize < FontSizeController.maxFontSize) {
        await controller.increase();
      }
      expect(controller.fontSize, FontSizeController.maxFontSize);

      // Try to increase past max
      await controller.increase();
      expect(controller.fontSize, FontSizeController.maxFontSize);
    });

    test('decrease does not go below minFontSize', () async {
      // Set font to min
      while (controller.fontSize > FontSizeController.minFontSize) {
        await controller.decrease();
      }
      expect(controller.fontSize, FontSizeController.minFontSize);

      // Try to decrease past min
      await controller.decrease();
      expect(controller.fontSize, FontSizeController.minFontSize);
    });

    test('canIncrease is false at maxFontSize', () async {
      while (controller.fontSize < FontSizeController.maxFontSize) {
        await controller.increase();
      }
      expect(controller.canIncrease, isFalse);
    });

    test('canDecrease is false at minFontSize', () async {
      while (controller.fontSize > FontSizeController.minFontSize) {
        await controller.decrease();
      }
      expect(controller.canDecrease, isFalse);
    });

    test('load restores persisted font size', () async {
      // Persist a custom font size
      SharedPreferences.setMockInitialValues({
        'devocional_font_size': 22.0,
      });

      final controller2 = FontSizeController();
      await controller2.load();

      expect(controller2.fontSize, 22.0);
      controller2.dispose();
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
      await controller.increase();
      await controller.increase();
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
      await controller.increase(); // Make room to decrease
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
      SharedPreferences.setMockInitialValues({
        'devocional_font_size': 20.0,
      });

      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.load();
      expect(notifyCount, 1);
    });

    test('constants have valid ranges', () {
      expect(FontSizeController.minFontSize,
          lessThan(FontSizeController.maxFontSize));
      expect(FontSizeController.defaultFontSize,
          greaterThanOrEqualTo(FontSizeController.minFontSize));
      expect(FontSizeController.defaultFontSize,
          lessThanOrEqualTo(FontSizeController.maxFontSize));
      expect(FontSizeController.fontSizeStep, greaterThan(0));
    });
  });
}
