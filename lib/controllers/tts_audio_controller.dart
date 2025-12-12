import 'dart:async';

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

  // Progress notifiers for miniplayer
  final ValueNotifier<Duration> currentPosition = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> totalDuration = ValueNotifier(Duration.zero);
  final ValueNotifier<double> playbackRate = ValueNotifier(1.0);
  final List<double> supportedRates = [0.5, 1.0, 1.25, 1.5, 2.0];

  Timer? _progressTimer;
  DateTime? _playStartTime;
  Duration _accumulatedPosition = Duration.zero;

  TtsAudioController({required this.flutterTts}) {
    flutterTts.setStartHandler(() {
      debugPrint(
          '[TTS Controller] Inicio de reproducción recibido, cambiando estado a PLAYING');
      state.value = TtsPlayerState.playing;
      _startProgressTimer();
    });
    flutterTts.setCompletionHandler(() {
      debugPrint(
          '[TTS Controller] Audio completado, cambiando estado a COMPLETED');
      _stopProgressTimer();
      currentPosition.value = totalDuration.value;
      state.value = TtsPlayerState.completed;
    });
    flutterTts.setCancelHandler(() {
      debugPrint('[TTS Controller] Audio cancelado');
      _stopProgressTimer();
      state.value = TtsPlayerState.idle;
    });
  }

  void setText(String text) {
    _currentText = text;
    // Estimate duration based on word count and playbackRate
    final words = _currentText!.split(RegExp(r"\s+")).length;
    // average 150 wpm -> 2.5 words per second
    final double wordsPerSecond = 150.0 / 60.0;
    final estimatedSeconds = (words / wordsPerSecond) / playbackRate.value;
    totalDuration.value = Duration(seconds: estimatedSeconds.round());
    currentPosition.value = Duration.zero;
    _accumulatedPosition = Duration.zero;
  }

  Future<void> play() async {
    debugPrint(
        '[TTS Controller] play() llamado, estado previo: \x1B[33m${state.value}\x1B[0m');
    if (_currentText == null || _currentText!.isEmpty) {
      state.value = TtsPlayerState.error;
      return;
    }
    state.value = TtsPlayerState.loading;
    await Future.delayed(const Duration(milliseconds: 400));
    // Obtener y aplicar la velocidad guardada antes de reproducir
    final double rate =
        await getService<VoiceSettingsService>().getSavedSpeechRate();
    playbackRate.value = rate;
    debugPrint('[TTS Controller] Aplicando velocidad TTS: $rate');
    await flutterTts.setSpeechRate(rate);
    await flutterTts.speak(_currentText!);
    if (state.value == TtsPlayerState.loading) {
      state.value = TtsPlayerState.playing;
    }
    debugPrint('[TTS Controller] estado actual: \x1B[32m${state.value}\x1B[0m');
  }

  Future<void> pause() async {
    debugPrint(
        '[TTS Controller] pause() llamado, estado previo: \x1B[33m${state.value}\x1B[0m');
    await flutterTts.pause();
    state.value = TtsPlayerState.paused;
    _pauseProgressTimer();
    debugPrint('[TTS Controller] estado actual: \x1B[32m${state.value}\x1B[0m');
  }

  Future<void> stop() async {
    debugPrint(
        '[TTS Controller] stop() llamado, estado previo: \x1B[33m${state.value}\x1B[0m');
    await flutterTts.stop();
    state.value = TtsPlayerState.idle;
    _stopProgressTimer();
    currentPosition.value = Duration.zero;
    _accumulatedPosition = Duration.zero;
    debugPrint('[TTS Controller] estado actual: \x1B[32m${state.value}\x1B[0m');
  }

  void complete() {
    debugPrint(
        '[TTS Controller] complete() llamado, estado previo: \x1B[33m${state.value}\x1B[0m');
    _stopProgressTimer();
    state.value = TtsPlayerState.completed;
    currentPosition.value = totalDuration.value;
    debugPrint('[TTS Controller] estado actual: \x1B[32m${state.value}\x1B[0m');
  }

  void error() {
    debugPrint(
        '[TTS Controller] error() llamado, estado previo: \x1B[33m${state.value}\x1B[0m');
    state.value = TtsPlayerState.error;
    _stopProgressTimer();
    debugPrint('[TTS Controller] estado actual: \x1B[31m${state.value}\x1B[0m');
  }

  // Progress timer helpers
  void _startProgressTimer() {
    _progressTimer?.cancel();
    _playStartTime = DateTime.now();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final now = DateTime.now();
      final elapsed = now.difference(_playStartTime!) + _accumulatedPosition;
      if (elapsed >= totalDuration.value) {
        currentPosition.value = totalDuration.value;
        _stopProgressTimer();
        // Let completion handler manage state
      } else {
        currentPosition.value = elapsed;
      }
    });
  }

  void _pauseProgressTimer() {
    _progressTimer?.cancel();
    if (_playStartTime != null) {
      _accumulatedPosition += DateTime.now().difference(_playStartTime!);
      _playStartTime = null;
    }
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
    _playStartTime = null;
  }

  // Seek within estimated duration
  void seek(Duration position) {
    if (position < Duration.zero) position = Duration.zero;
    if (position > totalDuration.value) position = totalDuration.value;
    currentPosition.value = position;
    _accumulatedPosition = position;
    _playStartTime = DateTime.now();
    // Note: flutter_tts may not support native seek; this is a best-effort sync for UI
  }

  // Cycle playback rate
  void cyclePlaybackRate() {
    final idx = supportedRates.indexOf(playbackRate.value);
    final nextIdx = (idx + 1) % supportedRates.length;
    playbackRate.value = supportedRates[nextIdx];
    flutterTts.setSpeechRate(playbackRate.value);
  }

  void dispose() {
    state.dispose();
    currentPosition.dispose();
    totalDuration.dispose();
    playbackRate.dispose();
    _stopProgressTimer();
  }
}
