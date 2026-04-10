import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsPlayerState { idle, loading, playing, paused, completed, error }

class TtsAudioController {
  final ValueNotifier<TtsPlayerState> state = ValueNotifier<TtsPlayerState>(
    TtsPlayerState.idle,
  );
  final FlutterTts flutterTts;
  final VoiceSettingsService _voiceSettingsService;
  String? _currentText;
  String? _fullText;
  String _languageCode = 'es';
  Duration _fullDuration = Duration.zero;
  bool _disposed = false;

  /// Flag to prevent state changes from voice sample playback
  /// Set to true when playing voice samples in VoiceSelector dialog
  bool _isPlayingSample = false;

  /// Flag to prevent modal close during seek operation
  bool _isSeeking = false;

  /// When true, the completion handler is suppressed (intermediate chunk
  /// finished speaking but more chunks remain). Reset to false before the
  /// last chunk so the handler fires normally at the end of playback.
  bool _suppressTtsCompletion = false;

  // Progress notifiers for miniplayer
  final ValueNotifier<Duration> currentPosition = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> totalDuration = ValueNotifier(Duration.zero);
  final ValueNotifier<double> playbackRate = ValueNotifier(1.0);

  Timer? _progressTimer;
  DateTime? _playStartTime;
  @protected
  Duration accumulatedPosition = Duration.zero;

  // Solo usar los rates permitidos y lógica de VoiceSettingsService
  static const double _defaultMiniRate = 1.0;

  /// Check if currently playing a voice sample (not full content)
  bool get isPlayingSample => _isPlayingSample;

  /// Set sample playback mode
  void setPlayingSample(bool value) {
    _isPlayingSample = value;
  }

  /// Safely update state if controller is not disposed
  void _setStateIfNotDisposed(TtsPlayerState newState) {
    if (_disposed) {
      debugPrint(
          '⚠️ [TTS Controller] Attempted to set state after dispose: $newState');
      return;
    }
    try {
      state.value = newState;
    } catch (e) {
      debugPrint('⚠️ [TTS Controller] Error setting state: $e');
    }
  }

  TtsAudioController({
    required this.flutterTts,
    required VoiceSettingsService voiceSettingsService,
  }) : _voiceSettingsService = voiceSettingsService {
    // Cargar el rate guardado usando VoiceSettingsService
    try {
      _voiceSettingsService.getSavedSpeechRate().then((
        settingsRate,
      ) {
        final miniRate = VoiceSettingsService.settingsToMini[settingsRate] ??
            _voiceSettingsService.getMiniPlayerRate(settingsRate);
        final allowed = VoiceSettingsService.miniPlayerRates;
        final validRate =
            allowed.contains(miniRate) ? miniRate : _defaultMiniRate;
        playbackRate.value = validRate;
        flutterTts.setSpeechRate(
          VoiceSettingsService.miniToSettings[validRate] ?? 0.5,
        );
        debugPrint(
          '🔧 [TTS Controller] Inicializado playbackRate: mini=$validRate (settings=${VoiceSettingsService.miniToSettings[validRate] ?? 0.5})',
        );
        if (!allowed.contains(miniRate)) {
          debugPrint(
            '⚠️ [TTS Controller] miniRate $miniRate no permitido - reset a $validRate',
          );
          _voiceSettingsService.setSavedSpeechRate(validRate);
        }
      });
    } catch (e) {
      debugPrint('[TTS Controller] No se pudo cargar playbackRate: $e');
    }
    flutterTts.setStartHandler(() {
      debugPrint(
        '🎬 [TTS Controller] ▶️ START HANDLER LLAMADO - Inicio de reproducción recibido',
      );
      debugPrint(
        '🎬 [TTS Controller] Estado previo: ${state.value}, _isPlayingSample: $_isPlayingSample',
      );

      // CRITICAL: Don't change state when playing voice samples
      // This prevents the mini-player modal from opening during voice selection
      if (_isPlayingSample) {
        debugPrint(
          '🎬 [TTS Controller] ⏭️ Ignorando cambio de estado (es un sample de voz)',
        );
        return;
      }

      debugPrint('🎬 [TTS Controller] Cambiando a PLAYING');
      _setStateIfNotDisposed(TtsPlayerState.playing);
      debugPrint('🎬 [TTS Controller] Iniciando timer de progreso...');
      _startProgressTimer();
      debugPrint('🎬 [TTS Controller] Timer iniciado correctamente');
    });
    flutterTts.setCompletionHandler(() {
      // During multi-chunk speaking, intermediate chunks fire the completion
      // handler when they finish.  Suppress it so we don't stop the timer,
      // set state to completed, or reset accumulatedPosition prematurely.
      if (_suppressTtsCompletion) {
        debugPrint(
          '🔇 [TTS Controller] COMPLETION suppressed (intermediate chunk)',
        );
        return;
      }
      debugPrint(
        '🏁 [TTS Controller] COMPLETION HANDLER - Audio completado, cambiando estado a COMPLETED',
      );
      stopProgressTimer();
      currentPosition.value = totalDuration.value;
      _setStateIfNotDisposed(TtsPlayerState.completed);
      // CRITICAL FIX: Reset accumulated position to allow replay from beginning
      accumulatedPosition = Duration.zero;
      debugPrint(
        '🏁 [TTS Controller] Posición acumulada reseteada a 0 para permitir replay desde el inicio',
      );
    });
    flutterTts.setCancelHandler(() {
      debugPrint('❌ [TTS Controller] CANCEL HANDLER - Audio cancelado');
      // Don't change state to idle if we're in the middle of a seek operation
      if (_isSeeking) {
        debugPrint(
          '⏭️ [TTS Controller] Seek en progreso, manteniendo estado actual',
        );
        return;
      }
      stopProgressTimer();
      _setStateIfNotDisposed(TtsPlayerState.idle);
    });

    // CRITICAL: ErrorHandler must be registered to catch TTS engine failures.
    // Without this, errors (e.g. language not loaded, voice not available) are
    // completely silent and speak() may hang forever without any callback.
    flutterTts.setErrorHandler((dynamic message) {
      debugPrint(
        '❌ [TTS Controller] ERROR HANDLER — message: $message (language: $_languageCode, state: ${state.value})',
      );
      if (!_isPlayingSample) {
        stopProgressTimer();
        _setStateIfNotDisposed(TtsPlayerState.error);
      }
    });
  }

  void setText(String text, {String languageCode = 'es'}) {
    debugPrint(
      '📝 [TTS Controller] setText llamado con ${text.length} caracteres, idioma: $languageCode',
    );
    _fullText = text;
    _currentText = text;
    _languageCode = languageCode; // store for voice application in play()
    // Estimar duración solo para UI
    int estimatedSeconds;
    if (languageCode == 'ja' || languageCode == 'zh') {
      // Japonés y Chino: estimar por caracteres (7 chars/segundo típico)
      final chars = _fullText!.replaceAll(RegExp(r'\s+'), '').length;
      const charsPerSecond = 7.0;
      estimatedSeconds = (chars / charsPerSecond).round();
      debugPrint(
        '📝 [TTS Controller] Idioma $languageCode (caracteres): $chars caracteres -> $estimatedSeconds segundos estimados',
      );
    } else {
      // Otros idiomas: estimar por palabras
      final words = _fullText!.split(RegExp(r"\s+")).length;
      final double wordsPerSecond = 150.0 / 60.0;
      estimatedSeconds = (words / wordsPerSecond).round();
      debugPrint(
        '📝 [TTS Controller] Palabras: $words -> $estimatedSeconds segundos estimados',
      );
    }
    _fullDuration = Duration(seconds: estimatedSeconds);
    totalDuration.value = _fullDuration;
    currentPosition.value = Duration.zero;
    accumulatedPosition = Duration.zero;
    debugPrint(
      '📝 [TTS Controller] Duración total estimada: ${_fullDuration.inSeconds}s',
    );
    debugPrint('📝 [TTS Controller] Posición inicializada a 0:00');
  }

  /// Splits text into chunks of at most [maxLength] characters,
  /// breaking only at word boundaries to avoid mid-word cuts.
  /// Android TTS engine hard-rejects input >= 4096 chars (ERROR_OUTPUT -8).
  List<String> _splitIntoChunks(String text, {int maxLength = 3500}) {
    if (text.length <= maxLength) return [text];
    final chunks = <String>[];
    int start = 0;
    while (start < text.length) {
      int end = (start + maxLength).clamp(0, text.length);
      if (end < text.length) {
        // Walk back to last space to avoid mid-word cut
        final lastSpace = text.lastIndexOf(' ', end);
        if (lastSpace > start) end = lastSpace;
      }
      chunks.add(text.substring(start, end).trim());
      start = end;
      // Skip leading whitespace for next chunk
      while (start < text.length && text[start] == ' ') {
        start++;
      }
    }
    debugPrint(
      '📝 [TTS Controller] Text split into ${chunks.length} chunks (max $maxLength chars each)',
    );
    return chunks;
  }

  Future<void> play() async {
    debugPrint('▶️ [TTS Controller] ========== PLAY() LLAMADO ==========');
    debugPrint('▶️ [TTS Controller] Estado previo: ${state.value.toString()}');
    debugPrint(
      '▶️ [TTS Controller] Posición acumulada: ${accumulatedPosition.inSeconds}s',
    );
    debugPrint(
      '▶️ [TTS Controller] Texto completo: ${_fullText?.length ?? 0} caracteres',
    );

    // Check _fullText (not _currentText) because we need the full text to calculate resume positions
    if (_fullText == null || _fullText!.isEmpty) {
      debugPrint('❌ [TTS Controller] ERROR: No hay texto para reproducir');
      _setStateIfNotDisposed(TtsPlayerState.error);
      return;
    }

    debugPrint('⏳ [TTS Controller] Cambiando estado a LOADING');
    _setStateIfNotDisposed(TtsPlayerState.loading);
    await Future.delayed(const Duration(milliseconds: 400));

    // Obtener y aplicar la velocidad guardada usando VoiceSettingsService
    final double settingsRate =
        await _voiceSettingsService.getSavedSpeechRate();
    final double miniRate = VoiceSettingsService.settingsToMini[settingsRate] ??
        _voiceSettingsService.getMiniPlayerRate(settingsRate);
    playbackRate.value = miniRate;
    final double ttsEngineRate =
        VoiceSettingsService.miniToSettings[miniRate] ?? 0.5;
    debugPrint(
      '🎚️ [TTS Controller] Velocidad aplicada: mini=$miniRate (settings=$ttsEngineRate)',
    );
    await flutterTts.setSpeechRate(ttsEngineRate);

    // CRITICAL FIX: If resuming from pause (accumulated position > 0),
    // calculate which part of text to speak from accumulated position
    if (accumulatedPosition > Duration.zero &&
        accumulatedPosition < _fullDuration) {
      debugPrint(
        '▶️ [TTS Controller] REANUDANDO desde posición: ${accumulatedPosition.inSeconds}s',
      );

      // Calculate which words to skip based on accumulated position
      final fullWords =
          _fullText!.split(RegExp(r"\s+")).where((w) => w.isNotEmpty).toList();
      final fullSeconds =
          _fullDuration.inSeconds > 0 ? _fullDuration.inSeconds : 1;
      final ratio = accumulatedPosition.inSeconds / fullSeconds;
      final skipWords =
          (fullWords.length * ratio).clamp(0, fullWords.length).round();

      // Build remaining text from skipWords
      final remainingWords = fullWords.skip(skipWords).toList();
      _currentText = remainingWords.join(' ');

      // Update position tracking for resume (will be used by _startProgressTimer)
      currentPosition.value = accumulatedPosition;

      debugPrint(
        '▶️ [TTS Controller] Saltando $skipWords/${fullWords.length} palabras, quedan ${remainingWords.length} palabras',
      );
    } else {
      // Starting fresh from beginning
      debugPrint('▶️ [TTS Controller] INICIANDO desde el principio');
      _currentText = _fullText;
      accumulatedPosition = Duration.zero;
      currentPosition.value = Duration.zero;
    }

    // Speak the current text (either full or remaining after resume)
    debugPrint(
      '🎤 [TTS Controller] Llamando flutterTts.speak() con ${_currentText!.length} caracteres',
    );
    if (_currentText != null && _currentText!.isNotEmpty) {
      // CRITICAL FIX: Apply the saved voice to THIS FlutterTts instance before
      // speaking. VoiceSettingsService.loadSavedVoice() only applies the voice
      // to its own internal FlutterTts instance, not to this controller's
      // instance. Without this, Arabic (and other non-default-language) voices
      // are never applied, causing TTS to speak with the wrong voice or silently fail.
      try {
        await _voiceSettingsService.applyVoiceToInstance(
            flutterTts, _languageCode);
      } catch (e) {
        debugPrint(
          '⚠️ [TTS Controller] applyVoiceToInstance failed for $_languageCode: $e',
        );
      }

      // SAFETY NET: wrap speak() in a timeout.
      // On some Android devices/languages (e.g. Arabic), speak() can hang
      // indefinitely if the TTS engine rejects the request without calling
      // any callback. The timeout prevents the UI from freezing in LOADING.
      final chunks = _splitIntoChunks(_currentText!);
      bool speakTimedOut = false;
      bool speakErrored = false;

      // For multi-chunk: tell flutter_tts to block until each utterance
      // actually finishes speaking.  Without this, speak() returns the
      // moment the utterance is *queued* and the next speak() immediately
      // cancels the previous one (the bug the user saw).
      final isMultiChunk = chunks.length > 1;
      if (isMultiChunk) {
        await flutterTts.awaitSpeakCompletion(true);
        _suppressTtsCompletion = true;
        debugPrint(
          '🔗 [TTS Controller] Multi-chunk mode ON — awaitSpeakCompletion(true), completion suppressed',
        );
      }

      for (int i = 0; i < chunks.length; i++) {
        if (_disposed) break;
        // Re-check state — user may have paused/stopped between chunks
        if (state.value != TtsPlayerState.loading &&
            state.value != TtsPlayerState.playing) {
          debugPrint(
            '⏹️ [TTS Controller] Chunk loop interrupted — state: ${state.value}',
          );
          break;
        }

        // Un-suppress completion handler before the last chunk so the
        // normal end-of-playback logic (state→completed, timer stop,
        // accumulatedPosition reset) fires when TTS finishes the final chunk.
        if (isMultiChunk && i == chunks.length - 1) {
          _suppressTtsCompletion = false;
          debugPrint(
            '🔓 [TTS Controller] Last chunk — completion handler re-enabled',
          );
        }

        debugPrint(
          '🎤 [TTS Controller] Iniciando speak() chunk ${i + 1}/${chunks.length} '
          '[lang=$_languageCode, ${chunks[i].length}ch, await=$isMultiChunk]',
        );

        // Timeout: when awaitSpeakCompletion is true the Future blocks for
        // the entire utterance (minutes); use a generous per-chunk timeout.
        // When false (single chunk / fire-and-forget) 10 s is enough.
        final speakTimeout = isMultiChunk
            ? const Duration(seconds: 300)
            : const Duration(seconds: 10);

        try {
          await flutterTts.speak(chunks[i]).timeout(
            speakTimeout,
            onTimeout: () {
              speakTimedOut = true;
              debugPrint(
                '⚠️ [TTS Controller] speak() TIMED OUT after ${speakTimeout.inSeconds}s — '
                'chunk ${i + 1}, language: $_languageCode.',
              );
              return null;
            },
          );
        } catch (e) {
          debugPrint(
              '❌ [TTS Controller] speak() threw exception on chunk ${i + 1}: $e');
          speakErrored = true;
          break;
        }
        debugPrint(
          '🎤 [TTS Controller] Chunk ${i + 1}/${chunks.length} completado — timeout: $speakTimedOut',
        );
        if (speakTimedOut) break;
      }

      // Cleanup: restore fire-and-forget mode so other callers (seek,
      // cyclePlaybackRate) are not affected, and clear the suppression flag.
      if (isMultiChunk) {
        await flutterTts.awaitSpeakCompletion(false);
        debugPrint(
          '🔗 [TTS Controller] Multi-chunk mode OFF — awaitSpeakCompletion(false)',
        );
      }
      _suppressTtsCompletion = false;

      if (speakTimedOut || speakErrored) {
        debugPrint(
          '❌ [TTS Controller] speak() failed — transitioning to ERROR state (timedOut: $speakTimedOut, errored: $speakErrored)',
        );
        _setStateIfNotDisposed(TtsPlayerState.error);
        return;
      }
    }

    if (state.value == TtsPlayerState.loading) {
      debugPrint('▶️ [TTS Controller] Cambiando estado de LOADING a PLAYING');
      state.value = TtsPlayerState.playing;

      // CRITICAL FIX: Iniciar el timer manualmente ya que el START HANDLER
      // no siempre se dispara en todas las plataformas al reanudar
      debugPrint('⏱️ [TTS Controller] Iniciando timer manualmente (fallback)');
      _startProgressTimer();
    }

    debugPrint('▶️ [TTS Controller] Estado final: ${state.value.toString()}');
    debugPrint('▶️ [TTS Controller] ========== FIN PLAY() ==========');
  }

  Future<void> pause() async {
    debugPrint('⏸️ [TTS Controller] ========== PAUSE() LLAMADO ==========');
    debugPrint('⏸️ [TTS Controller] Estado previo: ${state.value.toString()}');
    debugPrint(
      '⏸️ [TTS Controller] Posición actual antes de pausar: ${currentPosition.value.inSeconds}s',
    );

    // Add validation logging for debugging StringIndexOutOfBoundsException
    debugPrint(
      '⏸️ [TTS Controller] _currentText length: ${_currentText?.length ?? 0}',
    );
    debugPrint(
      '⏸️ [TTS Controller] _fullText length: ${_fullText?.length ?? 0}',
    );

    // Workaround: Detect multibyte characters that cause native crashes
    if (_currentText != null && _currentText!.length > 50) {
      final byteLength = utf8.encode(_currentText!).length;
      final ratio = byteLength / _currentText!.length;

      if (ratio > 1.5) {
        debugPrint(
          '⚠️ [TTS Controller] Multibyte ratio: $ratio (${_currentText!.length} chars → $byteLength bytes)',
        );
        debugPrint(
          '⚠️ [TTS Controller] Using stop() with position preservation instead of pause()',
        );

        // CRITICAL FIX: Preserve position before stopping
        // This allows resume to continue from current position
        final positionBeforeStop = currentPosition.value;

        await flutterTts.stop();

        // Set state to paused (not idle) to indicate we can resume
        state.value = TtsPlayerState.paused;
        _pauseProgressTimer();

        // Preserve the position for resume
        if (positionBeforeStop > accumulatedPosition) {
          accumulatedPosition = positionBeforeStop;
        }

        debugPrint(
          '⏸️ [TTS Controller] Position preserved: ${accumulatedPosition.inSeconds}s for multibyte text',
        );
        debugPrint('⏸️ [TTS Controller] ========== FIN PAUSE() ==========');
        return;
      }
    }

    try {
      await flutterTts.pause();
      state.value = TtsPlayerState.paused;
      _pauseProgressTimer();

      // CRITICAL: Fallback position capture for test environments or edge cases
      if (currentPosition.value > accumulatedPosition) {
        accumulatedPosition = currentPosition.value;
        debugPrint(
          '⏸️ [TTS Controller] Capturada posición actual en pause: ${accumulatedPosition.inSeconds}s',
        );
      }

      debugPrint('⏸️ [TTS Controller] Estado final: ${state.value.toString()}');
      debugPrint(
        '⏸️ [TTS Controller] Posición acumulada guardada: ${accumulatedPosition.inSeconds}s',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [TTS Controller] ERROR en pause(): $e');
      debugPrint('❌ [TTS Controller] Stack trace: $stackTrace');
      // Even if pause fails, update state to paused to maintain consistency
      state.value = TtsPlayerState.paused;
      _pauseProgressTimer();
      // Capture position even on error
      if (currentPosition.value > accumulatedPosition) {
        accumulatedPosition = currentPosition.value;
      }
    }

    debugPrint('⏸️ [TTS Controller] ========== FIN PAUSE() ==========');
  }

  Future<void> stop() async {
    debugPrint(
      '[TTS Controller] stop() llamado, estado previo: ${state.value.toString()}',
    );
    await flutterTts.stop();
    state.value = TtsPlayerState.idle;
    stopProgressTimer();
    currentPosition.value = Duration.zero;
    accumulatedPosition = Duration.zero;
    debugPrint('[TTS Controller] estado actual: ${state.value.toString()}');
  }

  void complete() {
    debugPrint(
      '[TTS Controller] complete() llamado, estado previo: ${state.value.toString()}',
    );
    stopProgressTimer();
    state.value = TtsPlayerState.completed;
    currentPosition.value = totalDuration.value;
    accumulatedPosition = Duration.zero;
    debugPrint('[TTS Controller] estado actual: ${state.value.toString()}');
  }

  void error() {
    debugPrint(
      '[TTS Controller] error() llamado, estado previo: ${state.value.toString()}',
    );
    state.value = TtsPlayerState.error;
    stopProgressTimer();
    debugPrint('[TTS Controller] estado actual: ${state.value.toString()}');
  }

  /// Exponer los rates permitidos desde VoiceSettingsService
  List<double> get supportedRates => VoiceSettingsService.miniPlayerRates;

  // Progress timer helpers
  void _startProgressTimer() {
    debugPrint(
      '⏱️ [TTS Controller] ========== INICIANDO TIMER DE PROGRESO ==========',
    );

    // Si el timer ya está corriendo, no reiniciarlo
    if (_progressTimer != null && _progressTimer!.isActive) {
      debugPrint(
        '⏱️ [TTS Controller] ⚠️ Timer ya está activo, saltando reinicio',
      );
      return;
    }

    _progressTimer?.cancel();
    debugPrint('⏱️ [TTS Controller] Timer anterior cancelado (si existía)');

    // CRITICAL FIX: Reset play start time to NOW when starting/resuming timer
    // This ensures we calculate elapsed time correctly from this point forward
    _playStartTime = clock.now();
    debugPrint(
      '⏱️ [TTS Controller] Hora de inicio: ${_playStartTime!.toIso8601String()}',
    );
    debugPrint(
      '⏱️ [TTS Controller] Posición acumulada: ${accumulatedPosition.inSeconds}s',
    );
    debugPrint(
      '⏱️ [TTS Controller] Duración total: ${totalDuration.value.inSeconds}s',
    );

    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final now = clock.now();
      // Calculate elapsed time from when playback started, plus any accumulated position
      final elapsed = now.difference(_playStartTime!) + accumulatedPosition;

      debugPrint(
        '⏱️ [TTS Controller] TICK - Posición: ${elapsed.inSeconds}s / ${totalDuration.value.inSeconds}s',
      );

      if (elapsed >= totalDuration.value) {
        debugPrint('⏱️ [TTS Controller] Llegó al final - deteniendo timer');
        currentPosition.value = totalDuration.value;
        stopProgressTimer();
        // CRITICAL FIX: Set state to completed to trigger "heard" stats
        debugPrint('✅ [TTS Controller] Setting state to COMPLETED');
        state.value = TtsPlayerState.completed;
      } else {
        currentPosition.value = elapsed;
      }
    });

    debugPrint('⏱️ [TTS Controller] Timer creado y corriendo cada 500ms');
    debugPrint('⏱️ [TTS Controller] ========== TIMER INICIADO ==========');
  }

  @protected
  void startProgressTimer() {
    _startProgressTimer();
  }

  void _pauseProgressTimer() {
    _progressTimer?.cancel();
    // CRITICAL FIX: Accumulate the elapsed time from current session
    // This preserves the playback position for resume
    if (_playStartTime != null) {
      final sessionElapsed = clock.now().difference(_playStartTime!);
      accumulatedPosition += sessionElapsed;
      debugPrint(
        '[TTS Controller] Pausing timer - session elapsed: ${sessionElapsed.inSeconds}s, total accumulated: ${accumulatedPosition.inSeconds}s',
      );
      _playStartTime = null;
    } else {
      debugPrint(
        '[TTS Controller] Pausing timer - no active session, accumulated remains: ${accumulatedPosition.inSeconds}s',
      );
    }
  }

  @protected
  void stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
    _playStartTime = null;
  }

  // Seek within estimated duration
  void seek(Duration position) {
    debugPrint(
      '⏩ [TTS Controller] ========== SEEK LLAMADO: ${position.inSeconds}s ==========',
    );
    if (position < Duration.zero) position = Duration.zero;
    // If we have a full duration (from setText), ensure bounds against full duration
    if (_fullDuration == Duration.zero) {
      // nothing to seek
      debugPrint('⏩ [TTS Controller] No hay duración, abortando seek');
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
    accumulatedPosition = position;
    _playStartTime = clock.now();

    // If currently playing, restart TTS from the remaining text
    if (state.value == TtsPlayerState.playing) {
      debugPrint(
          '⏩ [TTS Controller] Estado es PLAYING, reiniciando desde nueva posición');
      // Set seek flag to prevent cancel handler from changing state
      _isSeeking = true;

      // flutter_tts doesn't have robust seek; stop and speak remaining text
      flutterTts.stop();
      // FIX: apply current speech rate from VoiceSettingsService (settings-scale, not mini)
      final settingsRate =
          VoiceSettingsService.miniToSettings[playbackRate.value] ?? 0.5;
      flutterTts.setSpeechRate(settingsRate);
      if (_currentText != null && _currentText!.isNotEmpty) {
        flutterTts.speak(_currentText!);
        debugPrint(
            '⏩ [TTS Controller] Reproducción reiniciada desde nueva posición');
      }
      // progress timer will sync from the start handler

      // Reset seek flag after a short delay to ensure speak() has started
      Future.delayed(const Duration(milliseconds: 100), () {
        _isSeeking = false;
        debugPrint('⏩ [TTS Controller] Flag de seek reseteada');
      });
    } else {
      debugPrint(
          '⏩ [TTS Controller] Estado no es PLAYING, solo actualizando posición');
    }

    debugPrint('⏩ [TTS Controller] ========== FIN SEEK ==========');
  }

  // Cycle playback rate usando solo VoiceSettingsService
  // FIX: NO recalcular duración - mantener siempre a velocidad 1.0x
  Future<void> cyclePlaybackRate() async {
    try {
      final voiceService = _voiceSettingsService;
      debugPrint('🔁 [TTS Controller] Delegando ciclo a VoiceSettingsService');

      // Guardamos posición actual para mantenerla después del cambio
      final Duration previousPosition = currentPosition.value;

      // cyclePlaybackRate aplicará el rate en el motor y devolverá el siguiente mini rate
      final next = await voiceService.cyclePlaybackRate(
        currentMiniRate: playbackRate.value,
        ttsOverride: flutterTts,
      );

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
      accumulatedPosition = previousPosition;

      debugPrint(
        '🔧 [TTS Controller] Duración FIJA: ${_fullDuration.inSeconds}s (no recalculada), pos=${previousPosition.inSeconds}s',
      );

      // Si está reproduciendo, reiniciar el audio para aplicar nueva velocidad inmediatamente
      if (state.value == TtsPlayerState.playing) {
        debugPrint(
          '[TTS Controller] Reiniciando reproducción para aplicar nueva velocidad: mini=$next (settings=$newSettingsRate)',
        );
        // Set flag to prevent cancel handler from changing state during speed change
        _isSeeking = true;

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
          _playStartTime = clock.now();
          _startProgressTimer();
        }

        // Reset flag after operation completes
        _isSeeking = false;
      }

      debugPrint(
        '🔄 [TTS Controller] Rate cambiado: $oldMini -> $next (aplicado settings=$newSettingsRate)',
      );
    } catch (e) {
      debugPrint('❌ [TTS Controller] cyclePlaybackRate falló: $e');
    }
  }

  void dispose() {
    _disposed = true;
    state.dispose();
    currentPosition.dispose();
    totalDuration.dispose();
    playbackRate.dispose();
    stopProgressTimer();
  }
}
