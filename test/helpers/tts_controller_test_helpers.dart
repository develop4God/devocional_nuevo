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
}
