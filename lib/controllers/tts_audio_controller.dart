import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsPlayerState { idle, playing, paused, completed, error }

class TtsAudioController {
  final ValueNotifier<TtsPlayerState> state =
      ValueNotifier<TtsPlayerState>(TtsPlayerState.idle);
  final FlutterTts flutterTts;
  String? _currentText;

  TtsAudioController({required this.flutterTts}) {
    flutterTts.setCompletionHandler(() {
      print('[TTS Controller] Audio completado, cambiando estado a COMPLETED');
      state.value = TtsPlayerState.completed;
    });
  }

  void setText(String text) {
    _currentText = text;
  }

  Future<void> play() async {
    print(
        '[TTS Controller] play() llamado, estado previo: [33m${state.value}[0m');
    if (_currentText == null || _currentText!.isEmpty) {
      state.value = TtsPlayerState.error;
      return;
    }
    state.value = TtsPlayerState.playing;
    await flutterTts.speak(_currentText!);
    print('[TTS Controller] estado actual: [32m${state.value}[0m');
  }

  Future<void> pause() async {
    print(
        '[TTS Controller] pause() llamado, estado previo: [33m${state.value}[0m');
    await flutterTts.pause();
    state.value = TtsPlayerState.paused;
    print('[TTS Controller] estado actual: [32m${state.value}[0m');
  }

  Future<void> stop() async {
    print(
        '[TTS Controller] stop() llamado, estado previo: [33m${state.value}[0m');
    await flutterTts.stop();
    state.value = TtsPlayerState.idle;
    print('[TTS Controller] estado actual: [32m${state.value}[0m');
  }

  void complete() {
    print(
        '[TTS Controller] complete() llamado, estado previo: [33m${state.value}[0m');
    state.value = TtsPlayerState.completed;
    print('[TTS Controller] estado actual: [32m${state.value}[0m');
  }

  void error() {
    print(
        '[TTS Controller] error() llamado, estado previo: [33m${state.value}[0m');
    state.value = TtsPlayerState.error;
    print('[TTS Controller] estado actual: [31m${state.value}[0m');
  }

  void dispose() {
    state.dispose();
  }
}
