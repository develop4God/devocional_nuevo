@Tags(['unit', 'controllers'])
library;

import 'package:devocional_nuevo/controllers/tts_word_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TtsWordTracker tracker;

  setUp(() => tracker = TtsWordTracker());
  tearDown(() => tracker.dispose());

  test('starts unknown (-1)', () {
    expect(tracker.spokenCharOffset.value, -1);
  });

  test('fresh segment publishes the raw offset', () {
    tracker.beginSegment(0);
    tracker.onProgress(42);
    expect(tracker.spokenCharOffset.value, 42);
  });

  test('resumed segment adds the base offset to make it global', () {
    tracker.beginSegment(1000); // resumed partway through the full text
    tracker.onProgress(25);
    expect(tracker.spokenCharOffset.value, 1025);
  });

  test('reset returns to unknown and clears the base', () {
    tracker.beginSegment(500);
    tracker.onProgress(10);
    tracker.reset();
    expect(tracker.spokenCharOffset.value, -1);

    // After reset, a new fresh segment must not carry the old base.
    tracker.beginSegment(0);
    tracker.onProgress(7);
    expect(tracker.spokenCharOffset.value, 7);
  });

  test('negative inputs are floored to 0', () {
    tracker.beginSegment(-5);
    tracker.onProgress(-3);
    expect(tracker.spokenCharOffset.value, 0);
  });
}
