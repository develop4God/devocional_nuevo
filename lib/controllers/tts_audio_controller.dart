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
  String? _fullText;
  Duration _fullDuration = Duration.zero;

  // Progress notifiers for miniplayer
  final ValueNotifier<Duration> currentPosition = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> totalDuration = ValueNotifier(Duration.zero);
  final ValueNotifier<double> playbackRate = ValueNotifier(1.0);

  Timer? _progressTimer;
  DateTime? _playStartTime;
  Duration _accumulatedPosition = Duration.zero;

  // No duplication of allowed rates here; use VoiceSettingsService.allowedPlaybackRates when needed.
  // The controller will delegate cycling and persistence to VoiceSettingsService.
  // Keep a local default for fallback.
  static const double _defaultMiniRate = 1.0;

  TtsAudioController({required this.flutterTts}) {
    // Load saved playback rate early so the UI can show the persisted value
    // and the TTS engine receives the value before speaking.
    try {
      getService<VoiceSettingsService>().getSavedSpeechRate().then((rate) {
        final allowed = VoiceSettingsService.allowedPlaybackRates;
        final validRate = allowed.contains(rate) ? rate : _defaultMiniRate;
        playbackRate.value = validRate;
        flutterTts.setSpeechRate(validRate);
        debugPrint(
            '🔧 [TTS Controller] Initialized saved playback rate: $validRate');
        if (!allowed.contains(rate)) {
          debugPrint(
              '⚠️ [TTS Controller] Saved rate $rate not allowed - reset to $validRate');
          // Persist the normalized value
          getService<VoiceSettingsService>().setSavedSpeechRate(validRate);
        }
      });
    } catch (e) {
      debugPrint('[TTS Controller] Could not load saved playback rate: $e');
    }
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
    _fullText = text;
    _currentText = text;
    // Estimate full duration based on full text and current playbackRate
    final words = _fullText!.split(RegExp(r"\s+")).length;
    // average 150 wpm -> 2.5 words per second
    final double wordsPerSecond = 150.0 / 60.0;
    final estimatedSeconds = (words / wordsPerSecond) / playbackRate.value;
    _fullDuration = Duration(seconds: estimatedSeconds.round());
    // By default totalDuration represents remaining duration (initially full)
    totalDuration.value = _fullDuration;
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

  /// Expose allowed playback rates from VoiceSettingsService to avoid duplication
  List<double> get supportedRates => VoiceSettingsService.allowedPlaybackRates;

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
    // If we have a full duration (from setText), ensure bounds against full duration
    if (_fullDuration == Duration.zero) {
      // nothing to seek
      return;
    }

    if (position > _fullDuration) position = _fullDuration;

    // Calculate proportion and estimate words to skip
    final fullWords = (_fullText ?? '')
        .split(RegExp(r"\s+"))
        .where((w) => w.isNotEmpty)
        .toList();
    final fullSeconds =
        _fullDuration.inSeconds > 0 ? _fullDuration.inSeconds : 1;
    final ratio = position.inSeconds / fullSeconds;
    final skipWords =
        (fullWords.length * ratio).clamp(0, fullWords.length).round();

    // Build remaining text from skipWords
    final remainingWords = fullWords.skip(skipWords).toList();
    final remainingText = remainingWords.join(' ');

    // Update current text and durations
    _currentText = remainingText;
    final remainingWordsCount = remainingWords.length;
    final double wordsPerSecond = 150.0 / 60.0;
    // Keep totalDuration as the full duration for UI slider consistency
    totalDuration.value = _fullDuration;
    currentPosition.value = position;
    _accumulatedPosition = position;
    _playStartTime = DateTime.now();

    // If currently playing, restart TTS from the remaining text
    if (state.value == TtsPlayerState.playing) {
      // flutter_tts doesn't have robust seek; stop and speak remaining text
      flutterTts.stop();
      // apply current speech rate before speaking
      flutterTts.setSpeechRate(playbackRate.value);
      if (_currentText != null && _currentText!.isNotEmpty) {
        flutterTts.speak(_currentText!);
      }
      // progress timer will sync from the start handler
    }
  }

  // Cycle playback rate
  Future<void> cyclePlaybackRate() async {
    try {
      final voiceService = getService<VoiceSettingsService>();
      debugPrint(
          '🔁 [TTS Controller] Delegating cycle to VoiceSettingsService');
      final next = await voiceService.cyclePlaybackRate(
          currentRate: playbackRate.value, ttsOverride: flutterTts);
      debugPrint(
          '🔄 [TTS Controller] Rate changed: ${playbackRate.value} -> $next');
      playbackRate.value = next;
      // ensure engine uses it (service already applied it, but keep in sync)
      try {
        await flutterTts.setSpeechRate(next);
      } catch (_) {}
    } catch (e) {
      debugPrint('❌ [TTS Controller] cyclePlaybackRate failed: $e');
    }
  }

  void dispose() {
    state.dispose();
    currentPosition.dispose();
    totalDuration.dispose();
    playbackRate.dispose();
    _stopProgressTimer();
  }
}
