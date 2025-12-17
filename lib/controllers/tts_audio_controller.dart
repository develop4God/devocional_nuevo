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

  // Solo usar los rates permitidos y lógica de VoiceSettingsService
  static const double _defaultMiniRate = 1.0;

  TtsAudioController({required this.flutterTts}) {
    // Cargar el rate guardado usando VoiceSettingsService
    try {
      getService<VoiceSettingsService>()
          .getSavedSpeechRate()
          .then((settingsRate) {
        final miniRate = VoiceSettingsService.settingsToMini[settingsRate] ??
            VoiceSettingsService().getMiniPlayerRate(settingsRate);
        final allowed = VoiceSettingsService.miniPlayerRates;
        final validRate =
            allowed.contains(miniRate) ? miniRate : _defaultMiniRate;
        playbackRate.value = validRate;
        flutterTts.setSpeechRate(
            VoiceSettingsService.miniToSettings[validRate] ?? 0.5);
        debugPrint(
            '🔧 [TTS Controller] Inicializado playbackRate: mini=$validRate (settings=${VoiceSettingsService.miniToSettings[validRate] ?? 0.5})');
        if (!allowed.contains(miniRate)) {
          debugPrint(
              '⚠️ [TTS Controller] miniRate $miniRate no permitido - reset a $validRate');
          getService<VoiceSettingsService>().setSavedSpeechRate(validRate);
        }
      });
    } catch (e) {
      debugPrint('[TTS Controller] No se pudo cargar playbackRate: $e');
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

  void setText(String text, {String languageCode = 'es'}) {
    _fullText = text;
    _currentText = text;
    // Estimar duración solo para UI
    int estimatedSeconds;
    if (languageCode == 'ja') {
      // Japonés: estimar por caracteres (7 chars/segundo típico)
      final chars = _fullText!.replaceAll(RegExp(r'\s+'), '').length;
      const charsPerSecond = 7.0;
      estimatedSeconds = (chars / charsPerSecond).round();
    } else {
      // Otros idiomas: estimar por palabras
      final words = _fullText!.split(RegExp(r"\\s+")).length;
      final double wordsPerSecond = 150.0 / 60.0;
      estimatedSeconds = (words / wordsPerSecond).round();
    }
    _fullDuration = Duration(seconds: estimatedSeconds);
    totalDuration.value = _fullDuration;
    currentPosition.value = Duration.zero;
    _accumulatedPosition = Duration.zero;
  }

  Future<void> play() async {
    debugPrint(
        '[TTS Controller] play() llamado, estado previo: ${state.value.toString()}');
    // Check _fullText (not _currentText) because we need the full text to calculate resume positions
    if (_fullText == null || _fullText!.isEmpty) {
      state.value = TtsPlayerState.error;
      return;
    }

    state.value = TtsPlayerState.loading;
    await Future.delayed(const Duration(milliseconds: 400));

    // Obtener y aplicar la velocidad guardada usando VoiceSettingsService
    final double settingsRate =
        await getService<VoiceSettingsService>().getSavedSpeechRate();
    final double miniRate = VoiceSettingsService.settingsToMini[settingsRate] ??
        VoiceSettingsService().getMiniPlayerRate(settingsRate);
    playbackRate.value = miniRate;
    final double ttsEngineRate =
        VoiceSettingsService.miniToSettings[miniRate] ?? 0.5;
    debugPrint(
        '[TTS Controller] Aplicando velocidad TTS: mini=$miniRate (settings=$ttsEngineRate)');
    await flutterTts.setSpeechRate(ttsEngineRate);

    // CRITICAL FIX: If resuming from pause (accumulated position > 0),
    // calculate which part of text to speak from accumulated position
    if (_accumulatedPosition > Duration.zero &&
        _accumulatedPosition < _fullDuration) {
      debugPrint(
          '[TTS Controller] Resuming from accumulated position: ${_accumulatedPosition.inSeconds}s');

      // Calculate which words to skip based on accumulated position
      // NOTE: This uses a linear approximation (time ∝ words) which may not be
      // perfectly accurate since TTS engines have variable speaking rates for
      // different words. However, it provides a reasonable resume point.
      final fullWords =
          _fullText!.split(RegExp(r"\s+")).where((w) => w.isNotEmpty).toList();
      final fullSeconds =
          _fullDuration.inSeconds > 0 ? _fullDuration.inSeconds : 1;
      final ratio = _accumulatedPosition.inSeconds / fullSeconds;
      final skipWords =
          (fullWords.length * ratio).clamp(0, fullWords.length).round();

      // Build remaining text from skipWords
      final remainingWords = fullWords.skip(skipWords).toList();
      _currentText = remainingWords.join(' ');

      // Update position tracking for resume (will be used by _startProgressTimer)
      currentPosition.value = _accumulatedPosition;

      debugPrint(
          '[TTS Controller] Resuming from word $skipWords/${fullWords.length}, speaking ${remainingWords.length} remaining words');
    } else {
      // Starting fresh from beginning
      debugPrint('[TTS Controller] Starting from beginning');
      _currentText = _fullText;
      _accumulatedPosition = Duration.zero;
      currentPosition.value = Duration.zero;
    }

    // Speak the current text (either full or remaining after resume)
    if (_currentText != null && _currentText!.isNotEmpty) {
      await flutterTts.speak(_currentText!);
    }

    if (state.value == TtsPlayerState.loading) {
      state.value = TtsPlayerState.playing;
    }

    debugPrint('[TTS Controller] estado actual: ${state.value.toString()}');
  }

  Future<void> pause() async {
    debugPrint(
        '[TTS Controller] pause() llamado, estado previo: ${state.value.toString()}');
    await flutterTts.pause();
    state.value = TtsPlayerState.paused;
    _pauseProgressTimer();

    // CRITICAL: Fallback position capture for test environments or edge cases
    // where TTS handlers may not fire properly. In normal operation,
    // _pauseProgressTimer() accumulates position from the timer. This fallback
    // ensures currentPosition is captured if it's ahead of accumulated position
    // (e.g., in test environments or if user manually seeks before pausing).
    if (currentPosition.value > _accumulatedPosition) {
      _accumulatedPosition = currentPosition.value;
      debugPrint(
          '[TTS Controller] Captured current position on pause: ${_accumulatedPosition.inSeconds}s');
    }

    debugPrint('[TTS Controller] estado actual: ${state.value.toString()}');
  }

  Future<void> stop() async {
    debugPrint(
        '[TTS Controller] stop() llamado, estado previo: ${state.value.toString()}');
    await flutterTts.stop();
    state.value = TtsPlayerState.idle;
    _stopProgressTimer();
    currentPosition.value = Duration.zero;
    _accumulatedPosition = Duration.zero;
    debugPrint('[TTS Controller] estado actual: ${state.value.toString()}');
  }

  void complete() {
    debugPrint(
        '[TTS Controller] complete() llamado, estado previo: ${state.value.toString()}');
    _stopProgressTimer();
    state.value = TtsPlayerState.completed;
    currentPosition.value = totalDuration.value;
    debugPrint('[TTS Controller] estado actual: ${state.value.toString()}');
  }

  void error() {
    debugPrint(
        '[TTS Controller] error() llamado, estado previo: ${state.value.toString()}');
    state.value = TtsPlayerState.error;
    _stopProgressTimer();
    debugPrint('[TTS Controller] estado actual: ${state.value.toString()}');
  }

  /// Exponer los rates permitidos desde VoiceSettingsService
  List<double> get supportedRates => VoiceSettingsService.miniPlayerRates;

  // Progress timer helpers
  void _startProgressTimer() {
    _progressTimer?.cancel();
    // CRITICAL FIX: Reset play start time to NOW when starting/resuming timer
    // This ensures we calculate elapsed time correctly from this point forward
    _playStartTime = DateTime.now();
    debugPrint(
        '[TTS Controller] Starting progress timer at ${_playStartTime!.toIso8601String()}, accumulated: ${_accumulatedPosition.inSeconds}s');

    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final now = DateTime.now();
      // Calculate elapsed time from when playback started, plus any accumulated position
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
    // CRITICAL FIX: Accumulate the elapsed time from current session
    // This preserves the playback position for resume
    if (_playStartTime != null) {
      final sessionElapsed = DateTime.now().difference(_playStartTime!);
      _accumulatedPosition += sessionElapsed;
      debugPrint(
          '[TTS Controller] Pausing timer - session elapsed: ${sessionElapsed.inSeconds}s, total accumulated: ${_accumulatedPosition.inSeconds}s');
      _playStartTime = null;
    } else {
      debugPrint(
          '[TTS Controller] Pausing timer - no active session, accumulated remains: ${_accumulatedPosition.inSeconds}s');
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
    // Keep totalDuration as the full duration for UI slider consistency
    totalDuration.value = _fullDuration;
    currentPosition.value = position;
    _accumulatedPosition = position;
    _playStartTime = DateTime.now();

    // If currently playing, restart TTS from the remaining text
    if (state.value == TtsPlayerState.playing) {
      // flutter_tts doesn't have robust seek; stop and speak remaining text
      flutterTts.stop();
      // FIX: apply current speech rate from VoiceSettingsService (settings-scale, not mini)
      final settingsRate =
          VoiceSettingsService.miniToSettings[playbackRate.value] ?? 0.5;
      flutterTts.setSpeechRate(settingsRate);
      if (_currentText != null && _currentText!.isNotEmpty) {
        flutterTts.speak(_currentText!);
      }
      // progress timer will sync from the start handler
    }
  }

  // Cycle playback rate usando solo VoiceSettingsService
  // FIX: NO recalcular duración - mantener siempre a velocidad 1.0x
  Future<void> cyclePlaybackRate() async {
    try {
      final voiceService = getService<VoiceSettingsService>();
      debugPrint('🔁 [TTS Controller] Delegando ciclo a VoiceSettingsService');

      // Guardamos posición actual para mantenerla después del cambio
      final Duration previousPosition = currentPosition.value;

      // cyclePlaybackRate aplicará el rate en el motor y devolverá el siguiente mini rate
      final next = await voiceService.cyclePlaybackRate(
          currentMiniRate: playbackRate.value, ttsOverride: flutterTts);

      debugPrint('🔄 VoiceSettingsService devolvió nextMini=$next');

      // Actualizamos el notifier del mini rate
      final double oldMini = playbackRate.value;
      playbackRate.value = next;

      // Obtener el valor que se aplica al motor (settings-scale)
      final double newSettingsRate = voiceService.getSettingsRateForMini(next);

      // FIX: NO recalcular duración - mantener _fullDuration sin cambios
      // La duración siempre refleja tiempo a velocidad 1.0x

      // Mantener posición actual sin ajustes de ratio
      currentPosition.value = previousPosition;
      _accumulatedPosition = previousPosition;

      debugPrint(
          '🔧 [TTS Controller] Duración FIJA: ${_fullDuration.inSeconds}s (no recalculada), pos=${previousPosition.inSeconds}s');

      // Si está reproduciendo, reiniciar el audio para aplicar nueva velocidad inmediatamente
      if (state.value == TtsPlayerState.playing) {
        debugPrint(
            '[TTS Controller] Reiniciando reproducción para aplicar nueva velocidad: mini=$next (settings=$newSettingsRate)');
        // Detener utterance actual
        await flutterTts.stop();
        // Asegurar que el motor use el nuevo settings-rate (aunque voiceService ya lo aplicó, lo reafirmamos)
        try {
          await flutterTts.setSpeechRate(newSettingsRate);
        } catch (e) {
          debugPrint('⚠️ [TTS Controller] setSpeechRate tras ciclo falló: $e');
        }

        // Hablar el texto restante (flutter_tts no soporta seek interno robusto)
        if (_currentText != null && _currentText!.isNotEmpty) {
          // Re-lanzar la reproducción desde el texto actual
          await flutterTts.speak(_currentText!);
          // Reiniciar temporizador de progreso
          _playStartTime = DateTime.now();
          _startProgressTimer();
        }
      }

      debugPrint(
          '🔄 [TTS Controller] Rate cambiado: $oldMini -> $next (aplicado settings=$newSettingsRate)');
    } catch (e) {
      debugPrint('❌ [TTS Controller] cyclePlaybackRate falló: $e');
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
