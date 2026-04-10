import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:devocional_nuevo/services/tts/utils/tts_chunk_processor.dart';
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
  late final TtsChunkProcessor _processor;
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

  /// True while play() is flushing the Android TTS queue with stop() just
  /// before the first speak() call.  Guards cancelHandler so the deferred
  /// Android stop event (left over from a previous flutterTts.pause(), which
  /// calls stop() internally on Android) does NOT cancel the new utterance or
  /// reset state to idle during the flush window.
  bool _isPreparingToSpeak = false;

  /// When true, the completion handler is suppressed (intermediate chunk
  /// finished speaking but more chunks remain). Reset to false before the
  /// last chunk so the handler fires normally at the end of playback.
  bool _suppressTtsCompletion = false;

  /// Guard against concurrent play() invocations caused by rapid button presses
  /// or stress-test scenarios. A second call while one is already running is
  /// silently dropped instead of corrupting the TTS engine state.
  bool _playInProgress = false;

  /// Set to true by startHandler whenever the TTS engine actually begins
  /// producing audio. Reset to false just before each speak() call so the
  /// silent-utterance watchdog can detect a zombie engine state.
  bool _startHandlerFired = false;

  /// Watchdog that fires ~1.2 s after speak() if startHandler never fired,
  /// indicating a "silent utterance" (engine accepted the request but produced
  /// no audio — common on MIUI after audio-session revocation or after many
  /// rapid play/pause cycles). Triggers an automatic stop→settle→retry.
  Timer? _silentUtteranceWatchdog;

  /// How many watchdog retries have been attempted for the current utterance.
  /// Reset at the start of every play() call.  Caps automatic retries so a
  /// permanently-broken engine cannot loop forever.
  int _silentRetryCount = 0;

  /// Maximum number of automatic watchdog retries per utterance before the
  /// controller gives up and transitions to the ERROR state.
  static const int _maxSilentRetries = 2;

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

  /// Safely update a [ValueNotifier] if controller is not disposed.
  /// Prevents "ValueNotifier used after dispose" crashes from async callbacks
  /// (e.g. timer ticks or post-await continuations that race with dispose()).
  void _setNotifierIfNotDisposed<T>(ValueNotifier<T> notifier, T value) {
    if (_disposed) return;
    try {
      notifier.value = value;
    } catch (e) {
      debugPrint(
          '⚠️ [TTS Controller] Error setting notifier after dispose: $e');
    }
  }

  TtsAudioController({
    required this.flutterTts,
    required VoiceSettingsService voiceSettingsService,
    TtsChunkProcessor? chunkProcessor,
  })  : _voiceSettingsService = voiceSettingsService,
        _processor = chunkProcessor ?? TtsChunkProcessor() {
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
          '🔧 [TTS Controller] Initialized playbackRate: mini=$validRate (settings=${VoiceSettingsService.miniToSettings[validRate] ?? 0.5})',
        );
        if (!allowed.contains(miniRate)) {
          debugPrint(
            '⚠️ [TTS Controller] miniRate $miniRate not allowed - reset to $validRate',
          );
          _voiceSettingsService.setSavedSpeechRate(validRate);
        }
      });
    } catch (e) {
      debugPrint('[TTS Controller] Failed to load playbackRate: $e');
    }
    flutterTts.setStartHandler(() {
      debugPrint(
        '🎬 [TTS Controller] ▶️ START HANDLER FIRED - Playback started',
      );
      debugPrint(
        '🎬 [TTS Controller] Previous state: ${state.value}, _isPlayingSample: $_isPlayingSample',
      );

      // Audio is actually playing — cancel the silent-utterance watchdog.
      _startHandlerFired = true;
      _silentUtteranceWatchdog?.cancel();
      _silentUtteranceWatchdog = null;

      // CRITICAL: Don't change state when playing voice samples
      // This prevents the mini-player modal from opening during voice selection
      if (_isPlayingSample) {
        debugPrint(
          '🎬 [TTS Controller] ⏭️ Ignoring state change (voice sample)',
        );
        return;
      }

      debugPrint('🎬 [TTS Controller] Changing to PLAYING');
      _setStateIfNotDisposed(TtsPlayerState.playing);
      debugPrint('🎬 [TTS Controller] Starting progress timer...');
      _startProgressTimer();
      debugPrint('🎬 [TTS Controller] Timer started successfully');
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
      _silentUtteranceWatchdog?.cancel();
      _silentUtteranceWatchdog = null;
      debugPrint(
        '🏁 [TTS Controller] COMPLETION HANDLER - Audio completed, changing state to COMPLETED',
      );
      stopProgressTimer();
      currentPosition.value = totalDuration.value;
      _setStateIfNotDisposed(TtsPlayerState.completed);
      // CRITICAL FIX: Reset accumulated position to allow replay from beginning
      accumulatedPosition = Duration.zero;
      _silentRetryCount = 0;
      debugPrint(
        '🏁 [TTS Controller] Accumulated position reset to 0 to allow replay from start',
      );
    });
    flutterTts.setCancelHandler(() {
      debugPrint('❌ [TTS Controller] CANCEL HANDLER - Audio cancelled');
      _silentUtteranceWatchdog?.cancel();
      _silentUtteranceWatchdog = null;
      // Don't change state to idle if we're in the middle of a seek operation
      // or if play() is currently flushing a stale Android stop event.
      if (_isSeeking || _isPreparingToSpeak) {
        debugPrint(
          '⏭️ [TTS Controller] Cancel ignored — seek:$_isSeeking preparing:$_isPreparingToSpeak',
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

  Future<void> play() async {
    // ── Concurrency guard ─────────────────────────────────────────────────────
    // Under rapid button presses or stress-test scenarios multiple play() calls
    // can arrive before the first one finishes.  A concurrent call would race
    // against the ongoing engine operations (stop/speak/awaitCompletion) and
    // corrupt state.  Drop the second call instead.
    if (_playInProgress) {
      debugPrint(
        '⏭️ [TTS Controller] play() ya en progreso — ignorando llamada concurrente',
      );
      return;
    }
    _playInProgress = true;

    try {
      await _playInternal();
    } finally {
      _playInProgress = false;
    }
  }

  Future<void> _playInternal() async {
    debugPrint('▶️ [TTS Controller] ========== PLAY() LLAMADO ==========');
    debugPrint('▶️ [TTS Controller] Estado previo: ${state.value.toString()}');
    debugPrint(
      '▶️ [TTS Controller] Posición acumulada: ${accumulatedPosition.inSeconds}s',
    );
    debugPrint(
      '▶️ [TTS Controller] Texto completo: ${_fullText?.length ?? 0} caracteres',
    );

    // Reset per-utterance watchdog retry counter.
    _silentRetryCount = 0;

    // Check _fullText (not _currentText) because we need the full text to calculate resume positions
    if (_fullText == null || _fullText!.isEmpty) {
      debugPrint('❌ [TTS Controller] ERROR: No hay texto para reproducir');
      _setStateIfNotDisposed(TtsPlayerState.error);
      return;
    }

    // ── FIX: Unconditionally reset awaitSpeakCompletion to false ─────────────
    // Under stress a previous multi-chunk play() may have set this to true.
    // If a concurrent or interrupted play() never reached the finally block
    // that resets it, the next single-chunk speak() will block on a pending
    // cancel and return "immediately" without producing any audio (silent bug).
    await flutterTts.awaitSpeakCompletion(false);
    _suppressTtsCompletion = false;
    debugPrint(
      '🔄 [TTS Controller] awaitSpeakCompletion reset to false (stress guard)',
    );

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
      // ── FIX: Pre-speak engine flush FIRST, then apply voice ─────────────────
      //
      // Original order was: applyVoice → stop() → speak()
      // On MIUI and some Android devices, stop() resets the TTS engine's
      // language/voice configuration back to defaults, so the voice applied
      // before stop() is lost and speak() runs with no voice → silent audio.
      //
      // Correct order: stop() → [settle] → applyVoice → speak()
      // This guarantees the voice is set on a clean engine state.
      //
      // Additionally, on Android flutterTts.pause() calls tts.stop() internally.
      // That stop fires a deferred cancel event that arrives asynchronously —
      // sometimes AFTER play() has set state→LOADING.  Calling stop() here,
      // under the _isPreparingToSpeak guard, explicitly drains that stale event
      // BEFORE we queue the new utterance.
      _isPreparingToSpeak = true;
      try {
        await flutterTts.stop();
        // Settle delay: gives the Android TTS engine (especially MIUI) time to
        // fully drain any pending deferred callbacks before we apply voice
        // settings and start a new utterance.
        await Future.delayed(const Duration(milliseconds: 80));
      } finally {
        _isPreparingToSpeak = false;
      }
      if (_disposed) return;
      // Re-verify state hasn't been changed by something outside our control
      // (e.g. a very-delayed external event that slipped through the guard).
      if (state.value != TtsPlayerState.loading) {
        debugPrint(
          '⚠️ [TTS Controller] State changed during pre-speak flush: ${state.value} — aborting play()',
        );
        return;
      }
      debugPrint(
        '🧹 [TTS Controller] Pre-speak engine flush complete — engine clean',
      );

      // Apply the saved voice AFTER the flush so stop() cannot clear it.
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
      final chunks = _processor.splitIntoChunks(_currentText!);
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

      try {
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
          // the entire utterance duration.  Compute a rate-aware timeout so
          // slow speeds (0.5×) and large chapters (Psalm 119) never time out
          // while the TTS is still actively speaking.
          // When false (single chunk, fire-and-forget) speak() resolves as soon
          // as the utterance is queued, so a short queue-check timeout suffices.
          final speakTimeout = isMultiChunk
              ? _processor.chunkTimeout(
                  chunks[i].length,
                  settingsRate: ttsEngineRate,
                )
              : const Duration(seconds: TtsChunkProcessor.kQueueTimeoutSec);

          // ── Silent-utterance watchdog (single-chunk / fire-and-forget only) ──
          // In fire-and-forget mode speak() returns as soon as the utterance is
          // *queued*, not when it starts playing.  If startHandler never fires
          // within 1.2 s it means the engine silently dropped the utterance
          // (e.g. MIUI revoked audio focus, or a stale cancel arrived after the
          // flush window).  The watchdog auto-retries with a fresh flush.
          if (!isMultiChunk) {
            _startHandlerFired = false;
            _scheduleUtteranceWatchdog();
          }

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

          // FIX: Freeze the timer between chunks so inter-chunk dead-zones
          // (TTS engine silent while the next utterance is queued) do NOT
          // count as elapsed playback time.  _pauseProgressTimer() snapshots
          // the session elapsed into accumulatedPosition and nulls
          // _playStartTime; setStartHandler for chunk i+1 will call
          // _startProgressTimer() which restarts the timer from the correct
          // accumulated base — eliminating the cumulative drift that causes
          // the slider to finish before the audio on long multi-chunk texts.
          if (isMultiChunk && i < chunks.length - 1) {
            _pauseProgressTimer();
            debugPrint(
              '⏸️ [TTS Controller] Inter-chunk timer frozen — '
              'accumulated=${accumulatedPosition.inSeconds}s '
              '(chunk ${i + 1}/${chunks.length} done)',
            );
          }
        }
      } finally {
        // Cleanup: restore fire-and-forget mode so other callers (seek,
        // cyclePlaybackRate) are not affected, and clear the suppression flag.
        // Guaranteed even if speak() throws synchronously.
        if (isMultiChunk) {
          await flutterTts.awaitSpeakCompletion(false);
          debugPrint(
            '🔗 [TTS Controller] Multi-chunk mode OFF — awaitSpeakCompletion(false)',
          );
        }
        _suppressTtsCompletion = false;
      }

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
      _setStateIfNotDisposed(TtsPlayerState.playing);

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
    _silentUtteranceWatchdog?.cancel();
    _silentUtteranceWatchdog = null;

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

        // SAFEGUARD: controller may have been disposed during the await.
        if (_disposed) return;

        // Set state to paused (not idle) to indicate we can resume
        _setStateIfNotDisposed(TtsPlayerState.paused);
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
      // SAFEGUARD: controller may have been disposed during the await.
      if (_disposed) return;
      _setStateIfNotDisposed(TtsPlayerState.paused);
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
      if (_disposed) return;
      _setStateIfNotDisposed(TtsPlayerState.paused);
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
    _silentUtteranceWatchdog?.cancel();
    _silentUtteranceWatchdog = null;
    _silentRetryCount = 0;
    await flutterTts.stop();
    // SAFEGUARD: dispose() may have been called while we were awaiting
    // flutterTts.stop() (e.g. widget tree disposed during async gap).
    // Writing to a disposed ValueNotifier throws a Fatal Exception — bail out.
    if (_disposed) {
      debugPrint(
          '[TTS Controller] stop() — controller disposed, skipping state update');
      return;
    }
    _setStateIfNotDisposed(TtsPlayerState.idle);
    stopProgressTimer();
    _setNotifierIfNotDisposed(currentPosition, Duration.zero);
    accumulatedPosition = Duration.zero;
    debugPrint('[TTS Controller] estado actual: ${state.value.toString()}');
  }

  void complete() {
    debugPrint(
      '[TTS Controller] complete() llamado, estado previo: ${state.value.toString()}',
    );
    stopProgressTimer();
    _setStateIfNotDisposed(TtsPlayerState.completed);
    _setNotifierIfNotDisposed(currentPosition, totalDuration.value);
    accumulatedPosition = Duration.zero;
    debugPrint('[TTS Controller] estado actual: ${state.value.toString()}');
  }

  void error() {
    debugPrint(
      '[TTS Controller] error() llamado, estado previo: ${state.value.toString()}',
    );
    _setStateIfNotDisposed(TtsPlayerState.error);
    stopProgressTimer();
    debugPrint('[TTS Controller] estado actual: ${state.value.toString()}');
  }

  /// Exponer los rates permitidos desde VoiceSettingsService
  List<double> get supportedRates => VoiceSettingsService.miniPlayerRates;

  // ── Silent-utterance watchdog ────────────────────────────────────────────────

  /// Schedules [_handleSilentUtterance] to fire 1.2 s after speak() is called
  /// in fire-and-forget (single-chunk) mode.  If startHandler fires first,
  /// the watchdog is cancelled immediately.
  void _scheduleUtteranceWatchdog() {
    _silentUtteranceWatchdog?.cancel();
    _silentUtteranceWatchdog = Timer(const Duration(milliseconds: 1200), () {
      _handleSilentUtterance();
    });
    debugPrint('🐕 [TTS Controller] Silent-utterance watchdog armado (1.2s)');
  }

  /// Called by the watchdog when startHandler has not fired 1.2 s after
  /// speak().  Performs a hard stop → settle → re-apply-rate+voice → retry-speak
  /// cycle to recover from MIUI/Android audio-session corruption.
  ///
  /// Retries up to [_maxSilentRetries] times.  After that it transitions to
  /// ERROR so the UI can surface a recoverable failure instead of looping.
  Future<void> _handleSilentUtterance() async {
    _silentUtteranceWatchdog = null;
    if (_startHandlerFired ||
        state.value != TtsPlayerState.playing ||
        _disposed) {
      return;
    }

    _silentRetryCount++;

    if (_silentRetryCount > _maxSilentRetries) {
      debugPrint(
        '🔇 [TTS Controller] ❌ Max retries ($_maxSilentRetries) alcanzado — transitioning to ERROR',
      );
      stopProgressTimer();
      _setStateIfNotDisposed(TtsPlayerState.error);
      return;
    }

    debugPrint(
      '🔇 [TTS Controller] ⚠️ UTTERANCE SILENCIOSA (intento $_silentRetryCount/$_maxSilentRetries) — startHandler no disparó en 1.2s',
    );
    debugPrint(
      '🔇 [TTS Controller] Reintentando con flush + re-apply rate+voice...',
    );

    // Hard-flush under the guard so the cancelHandler is suppressed.
    // 250 ms settle gives MIUI time to drain stale callbacks and
    // re-acquire audio focus before we queue a new utterance.
    _isPreparingToSpeak = true;
    try {
      await flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 250));
    } finally {
      _isPreparingToSpeak = false;
    }

    if (_disposed || state.value != TtsPlayerState.playing) return;

    // Re-apply speech rate — stop() can reset it on some devices.
    final settingsRate =
        VoiceSettingsService.miniToSettings[playbackRate.value] ?? 0.5;
    try {
      await flutterTts.setSpeechRate(settingsRate);
      debugPrint(
          '🔇 [TTS Controller] Retry setSpeechRate($settingsRate) aplicado');
    } catch (e) {
      debugPrint('⚠️ [TTS Controller] setSpeechRate en retry falló: $e');
    }

    if (_disposed || state.value != TtsPlayerState.playing) return;

    // Re-apply voice settings after the flush.
    try {
      await _voiceSettingsService.applyVoiceToInstance(
          flutterTts, _languageCode);
    } catch (e) {
      debugPrint('⚠️ [TTS Controller] applyVoiceToInstance en retry: $e');
    }

    if (_disposed || state.value != TtsPlayerState.playing) return;

    final text = _currentText;
    if (text != null && text.isNotEmpty) {
      // Re-arm the watchdog BEFORE speak() so that if this retry utterance
      // is also silent, the next watchdog cycle will catch it.
      _startHandlerFired = false;
      _scheduleUtteranceWatchdog();

      debugPrint(
        '🔇 [TTS Controller] Retry speak() intento $_silentRetryCount — ${text.length} caracteres',
      );
      await flutterTts.speak(text);
      debugPrint(
          '🔇 [TTS Controller] Retry speak() completado (intento $_silentRetryCount)');
    }
  }

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
      // SAFEGUARD: bail out immediately if the controller was disposed between
      // when this tick was queued and when it actually runs.  Without this
      // guard, writing to a disposed ValueNotifier throws a Fatal Exception.
      if (_disposed) {
        _progressTimer?.cancel();
        return;
      }

      final now = clock.now();
      // Calculate elapsed time from when playback started, plus any accumulated position
      final elapsed = now.difference(_playStartTime!) + accumulatedPosition;

      debugPrint(
        '⏱️ [TTS Controller] TICK - Posición: ${elapsed.inSeconds}s / ${totalDuration.value.inSeconds}s',
      );

      if (elapsed >= totalDuration.value) {
        debugPrint('⏱️ [TTS Controller] Llegó al final - deteniendo timer');
        _setNotifierIfNotDisposed(currentPosition, totalDuration.value);
        stopProgressTimer();
        // CRITICAL FIX: Set state to completed to trigger "heard" stats
        debugPrint('✅ [TTS Controller] Setting state to COMPLETED');
        _setStateIfNotDisposed(TtsPlayerState.completed);
      } else {
        _setNotifierIfNotDisposed(currentPosition, elapsed);
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
    _silentUtteranceWatchdog?.cancel();
    _silentUtteranceWatchdog = null;
    state.dispose();
    currentPosition.dispose();
    totalDuration.dispose();
    playbackRate.dispose();
    stopProgressTimer();
  }
}
