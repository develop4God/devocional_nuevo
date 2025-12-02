import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsPlayerState { idle, loading, playing, paused, completed, error }

class TtsAudioController {
  final ValueNotifier<TtsPlayerState> state =
      ValueNotifier<TtsPlayerState>(TtsPlayerState.idle);
  final FlutterTts flutterTts;
  String? _currentText;

  TtsAudioController({required this.flutterTts}) {
    flutterTts.setCompletionHandler(() {
      debugPrint(
          '[TTS Controller] Audio completado, cambiando estado a COMPLETED');
      state.value = TtsPlayerState.completed;
    });
  }

  void setText(String text) {
    _currentText = text;
  }

  Future<void> play() async {
    debugPrint(
        '[TTS Controller] play() llamado, estado previo: \x1B[33m${state.value}\x1B[0m');
    if (_currentText == null || _currentText!.isEmpty) {
      state.value = TtsPlayerState.error;
      return;
    }
    state.value = TtsPlayerState.loading;
    await Future.delayed(
        const Duration(milliseconds: 400)); // Simula carga breve
    // Obtener y aplicar la velocidad guardada antes de reproducir
    final double rate =
        await getService<VoiceSettingsService>().getSavedSpeechRate();
    debugPrint('[TTS Controller] Aplicando velocidad TTS: $rate');
    await flutterTts.setSpeechRate(rate);
    state.value = TtsPlayerState.playing;
    await flutterTts.speak(_currentText!);
    debugPrint('[TTS Controller] estado actual: \x1B[32m${state.value}\x1B[0m');
  }

  Future<void> pause() async {
    debugPrint(
        '[TTS Controller] pause() llamado, estado previo: \x1B[33m${state.value}\x1B[0m');
    await flutterTts.pause();
    state.value = TtsPlayerState.paused;
    debugPrint('[TTS Controller] estado actual: \x1B[32m${state.value}\x1B[0m');
  }

  Future<void> stop() async {
    debugPrint(
        '[TTS Controller] stop() llamado, estado previo: \x1B[33m${state.value}\x1B[0m');
    await flutterTts.stop();
    state.value = TtsPlayerState.idle;
    debugPrint('[TTS Controller] estado actual: \x1B[32m${state.value}\x1B[0m');
  }

  void complete() {
    debugPrint(
        '[TTS Controller] complete() llamado, estado previo: \x1B[33m${state.value}\x1B[0m');
    state.value = TtsPlayerState.completed;
    debugPrint('[TTS Controller] estado actual: \x1B[32m${state.value}\x1B[0m');
  }

  void error() {
    debugPrint(
        '[TTS Controller] error() llamado, estado previo: \x1B[33m${state.value}\x1B[0m');
    state.value = TtsPlayerState.error;
    debugPrint('[TTS Controller] estado actual: \x1B[31m${state.value}\x1B[0m');
  }

  void dispose() {
    state.dispose();
  }
}
