// test/helpers/tts_controller_test_helpers.dart

import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';

mixin TtsControllerTestHooks on TtsAudioController {
  /// Stop the internal progress timer (uses protected API on controller)
  void stopTimer() {
    // Use the protected method exposed by production code
    stopProgressTimer();
  }

  /// Start the internal progress timer (uses protected API on controller)
  void startTimer() {
    startProgressTimer();
  }

  /// Complete playback synchronously without delays
  void completePlayback() {
    stopProgressTimer();
    currentPosition.value = totalDuration.value;
    state.value = TtsPlayerState.completed;
    // Reset protected accumulated position
    accumulatedPosition = Duration.zero;
  }

  /// Set both currentPosition and accumulatedPosition for tests
  /// This method generates synthetic text to ensure _fullDuration > position
  /// so that play() takes the resume branch instead of reset branch.
  /// Rate: 150 words/min = 2.5 words/sec
  void setPositionForTest(Duration position) {
    // Generate synthetic text long enough to produce _fullDuration > position
    final wordsNeeded = (position.inSeconds * 2.5 + 20).ceil();
    final syntheticText = List.generate(
      wordsNeeded,
      (i) => 'palabra',
    ).join(' ');
    setText(syntheticText); // sets _fullDuration correctly
    // Now override position — setText resets these, so set after
    currentPosition.value = position;
    accumulatedPosition = position;
    totalDuration.value = Duration(seconds: position.inSeconds + 60);
  }
}
