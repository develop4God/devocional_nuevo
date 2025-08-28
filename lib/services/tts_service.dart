import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/tts_text_normalizer_service.dart';
import 'package:devocional_nuevo/services/tts_localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TtsState { idle, initializing, playing, paused, stopping, error }

class TtsException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const TtsException(this.message, {this.code, this.originalError});

  @override
  String toString() =>
      'TtsException: $message${code != null ? ' (Code: $code)' : ''}';
}

class TtsService {
  static final TtsService _instance = TtsService._internal();

  factory TtsService() => _instance;

  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final TtsTextNormalizerService _textNormalizer = TtsTextNormalizerService();
  final TtsLocalizationService _localization = TtsLocalizationService();

  TtsState _currentState = TtsState.idle;
  String? _currentDevocionalId;
  List<String> _currentChunks = [];
  int _currentChunkIndex = 0;

  Timer? _emergencyTimer;
  bool _chunkInProgress = false;
  DateTime _lastNativeActivity = DateTime.now();

  final _stateController = StreamController<TtsState>.broadcast();
  final _progressController = StreamController<double>.broadcast();

  bool _isInitialized = false;
  bool _disposed = false;

  Stream<TtsState> get stateStream => _stateController.stream;

  Stream<double> get progressStream => _progressController.stream;

  TtsState get currentState => _currentState;

  String? get currentDevocionalId => _currentDevocionalId;

  bool get isPlaying => _currentState == TtsState.playing;

  bool get isPaused => _currentState == TtsState.paused;

  bool get isActive => isPlaying || isPaused;

  bool get _isPlatformSupported {
    try {
      return Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isWindows ||
          Platform.isMacOS ||
          Platform.isLinux;
    } catch (e) {
      developer.log('Platform check failed: $e');
      return false;
    }
  }

  // =========================
  // CHUNK NAVIGATION SUPPORT
  // =========================

  int get currentChunkIndex => _currentChunkIndex;

  int get totalChunks => _currentChunks.length;

  /// Returns a callback for jumping to the previous chunk if possible.
  VoidCallback? get previousChunk {
    if (_currentChunkIndex > 0 && _chunkInProgress) {
      return () => _jumpToChunk(_currentChunkIndex - 1);
    }
    return null;
  }

  /// Returns a callback for jumping to the next chunk if possible.
  VoidCallback? get nextChunk {
    if (_currentChunkIndex < _currentChunks.length - 1 && _chunkInProgress) {
      return () => _jumpToChunk(_currentChunkIndex + 1);
    }
    return null;
  }

  /// Returns a callback for jumping to a specific chunk index, if possible.
  Future<void> Function(int index)? get jumpToChunk {
    if (_currentChunks.isNotEmpty && _chunkInProgress) {
      return (int index) async => await _jumpToChunk(index);
    }
    return null;
  }

  /// Internal method to jump to a specific chunk index and play it.
  Future<void> _jumpToChunk(int index) async {
    if (_chunkInProgress &&
        index >= 0 &&
        index < _currentChunks.length &&
        index != _currentChunkIndex) {
      _cancelEmergencyTimer();
      _currentChunkIndex = index;
      _progressController.add(_currentChunkIndex / _currentChunks.length);
      _speakNextChunk();
    }
  }

  // =========================

  Future<void> _initialize() async {
    if (_isInitialized || _disposed) return;

    debugPrint('🔧 TTS: Initializing service...');
    _updateState(TtsState.initializing);

    try {
      if (!_isPlatformSupported) {
        throw const TtsException(
            'Text-to-Speech not supported on this platform',
            code: 'PLATFORM_NOT_SUPPORTED');
      }

      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString('tts_language') ?? 'es-US';
      final rate = prefs.getDouble('tts_rate') ?? 0.5;

      debugPrint('🔧 TTS: Loading config - Language: $language, Rate: $rate');

      await _configureTts(language, rate);

      // Forzar espera de completion en el plugin, mejora la sincronización en algunos dispositivos
      await _flutterTts.awaitSpeakCompletion(true);

      _setupEventHandlers();

      _isInitialized = true;
      _updateState(TtsState.idle);
      debugPrint('✅ TTS: Service initialized successfully');
    } catch (e) {
      debugPrint('❌ TTS: Initialization failed: $e');
      _updateState(TtsState.error);
      rethrow;
    }
  }

  Future<void> _configureTts(String language, double rate) async {
    try {
      debugPrint('🔧 TTS: Setting language to $language');
      await _flutterTts.setLanguage(language);
    } catch (e) {
      debugPrint('⚠️ TTS: Language $language failed, using es-US: $e');
      await _flutterTts.setLanguage('es-US');
    }

    debugPrint('🔧 TTS: Setting speech rate to $rate');
    await _flutterTts.setSpeechRate(rate.clamp(0.1, 3.0));
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Android: Use queuing for chunked playback
    if (Platform.isAndroid) {
      await _flutterTts.setQueueMode(1);
      debugPrint('🌀 TTS: Android setQueueMode(QUEUE)');
    }
  }

  // --- LOGS REFORZADOS EN HANDLERS ---
  void _setupEventHandlers() {
    _flutterTts.setStartHandler(() {
      debugPrint('🎬 TTS: START handler (nativo) en ${DateTime.now()}');
      if (!_disposed) {
        _lastNativeActivity = DateTime.now();
        _cancelEmergencyTimer();
        _updateState(TtsState.playing);
      }
    });

    _flutterTts.setCompletionHandler(() {
      debugPrint('🏁 TTS: COMPLETION handler (nativo) en ${DateTime.now()}');
      if (!_disposed) {
        _lastNativeActivity = DateTime.now();
        _cancelEmergencyTimer();
        _onChunkCompleted();
      }
    });

    _flutterTts.setPauseHandler(() {
      debugPrint('⏸️ TTS: Native PAUSE handler at ${DateTime.now()}');
      if (!_disposed) {
        _lastNativeActivity = DateTime.now();
        _cancelEmergencyTimer();
        _updateState(TtsState.paused);
      }
    });

    _flutterTts.setContinueHandler(() {
      debugPrint('▶️ TTS: Native CONTINUE handler at ${DateTime.now()}');
      if (!_disposed) {
        _lastNativeActivity = DateTime.now();
        _updateState(TtsState.playing);
      }
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint('💥 TTS: Native ERROR handler: $msg at ${DateTime.now()}');
      if (!_disposed) {
        _lastNativeActivity = DateTime.now();
        _cancelEmergencyTimer();
        _updateState(TtsState.error);
        _resetPlayback();
      }
    });

    debugPrint('✅ TTS: Native event handlers configured');
  }

  void _onChunkCompleted() async {
    if (!_chunkInProgress) return;

    // Evitar avanzar si está pausado
    if (_currentState == TtsState.paused) {
      debugPrint(
          '⏸️ TTS: Chunk completado pero estado pausado, no avanzar chunk');
      return;
    }

    final progress = (_currentChunkIndex + 1) / _currentChunks.length;

    if (_currentDevocionalId != null && progress >= 0.8) {
      await SpiritualStatsService().recordDevotionalHeard(
        devocionalId: _currentDevocionalId!,
        listenedPercentage: progress,
      );
      debugPrint(
          '📈 TTS: Devocional registrado en estadísticas por escucha con progreso ${progress * 100}%');
    }

    debugPrint(
        '🏁 TTS: Processing chunk ${_currentChunkIndex + 1}/${_currentChunks.length} completion at ${DateTime.now()}');

    _currentChunkIndex++;

    if (_currentChunks.isNotEmpty) {
      final progress = _currentChunkIndex / _currentChunks.length;
      debugPrint('📊 TTS: Progress: ${(progress * 100).toInt()}%');
      _progressController.add(progress);
    }

    // Forzar avance al siguiente chunk SIEMPRE
    if (_currentChunkIndex < _currentChunks.length) {
      debugPrint('➡️ TTS: Moving to next chunk...');
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_disposed && _chunkInProgress) {
          _speakNextChunk();
        }
      });
    } else {
      debugPrint('✅ TTS: Playback finalizado.');
      _resetPlayback();
    }
  }

  // Emergency timer debe llamar a _onChunkCompleted() SIEMPRE:
  void _startEmergencyTimer(String chunk) {
    _cancelEmergencyTimer();

    final wordCount = chunk.trim().split(RegExp(r'\s+')).length;
    final minTimer = wordCount < 10 ? 2500 : 4000;
    const maxTimer = 6000;
    final estimatedTime = (wordCount * 180).clamp(minTimer, maxTimer);

    debugPrint(
        '🚨 TTS: Emergency timer set for ${estimatedTime}ms ($wordCount words) at ${DateTime.now()}');

    _emergencyTimer = Timer(Duration(milliseconds: estimatedTime), () {
      final now = DateTime.now();
      final timeSinceActivity = now.difference(_lastNativeActivity).inSeconds;

      debugPrint(
          '🚨 TTS: Emergency timer triggered after ${estimatedTime}ms at $now');
      debugPrint(
          '🚨 TTS: Time since last native activity: ${timeSinceActivity}s');

      if (!_disposed && _chunkInProgress && _currentState != TtsState.paused) {
        debugPrint('🚨 TTS: Emergency fallback - avanzando chunk');
        _onChunkCompleted();
      } else {
        debugPrint(
            '🚨 TTS: Emergency fallback - detenido por estado pausado o disposed');
      }
    });
  }

  void _speakNextChunk() async {
    if (_disposed || !_chunkInProgress) return;

    // Espera a que el TTS esté idle o playing antes de hablar el siguiente chunk (evita overlap)
    if (_currentState != TtsState.idle && _currentState != TtsState.playing) {
      // Si está pausado, no continuar el bucle - esperar a resume()
      if (_currentState == TtsState.paused) {
        debugPrint('⏸️ TTS: Playback pausado, no continuar chunks');
        return;
      }

      debugPrint('⏳ TTS: Esperando estado idle/playing para avanzar chunk...');
      Future.delayed(const Duration(milliseconds: 100), _speakNextChunk);
      return;
    }

    if (_currentChunkIndex < _currentChunks.length) {
      // Unión inteligente de encabezados cortos al siguiente chunk para evitar chunks de una palabra
      String chunk = _currentChunks[_currentChunkIndex];
      if (chunk.trim().length < 6 &&
          _currentChunkIndex + 1 < _currentChunks.length) {
        chunk = '$chunk ${_currentChunks[_currentChunkIndex + 1]}';
        debugPrint('🔗 TTS: Chunk fusionado con siguiente por ser muy corto.');
        _currentChunkIndex++;
      }

      debugPrint(
          '🔊 TTS: Speaking chunk ${_currentChunkIndex + 1}/${_currentChunks.length} at ${DateTime.now()}');
      debugPrint(
          '📝 TTS: Content: ${chunk.length > 50 ? '${chunk.substring(0, 50)}...' : chunk}');

      try {
        _cancelEmergencyTimer();

        if (_currentState != TtsState.paused &&
            _currentState != TtsState.error &&
            _currentState != TtsState.stopping) {
          await _flutterTts.speak(chunk);

          if (_currentState != TtsState.playing) {
            _updateState(TtsState.playing);
          }
          _startEmergencyTimer(chunk);
        } else {
          debugPrint(
              '🚫 TTS: No se reproduce chunk porque el estado es $_currentState');
        }
      } catch (e) {
        debugPrint('❌ TTS: Failed to speak chunk: $e');
        _updateState(TtsState.error);
        _resetPlayback();
      }
    } else {
      debugPrint('✅ TTS: Todos los chunks han sido reproducidos.');
      _resetPlayback();
    }
  }

  void _cancelEmergencyTimer() {
    if (_emergencyTimer != null) {
      _emergencyTimer!.cancel();
      _emergencyTimer = null;
      debugPrint('🔄 TTS: Emergency timer cancelled at ${DateTime.now()}');
    }
  }

  /// Get current TTS language
  Future<String> getCurrentLanguage() async {
    return await _localization.getCurrentLanguage();
  }

  // --- Normalización avanzada de referencia bíblica ---
  /// Formatea dinámicamente los libros con ordinal si comienza con 1, 2, 3
  Future<String> formatBibleBook(String reference) async {
    final currentLanguage = await _localization.getCurrentLanguage();
    final languageCode = _localization.getLanguageCode(currentLanguage);
    return _textNormalizer.formatBibleBook(reference, languageCode);
  }

  Future<String> _normalizeTtsText(String text) async {
    return await _textNormalizer.normalizeTtsText(text);
  }

  Future<List<String>> _generateChunks(Devocional devocional) async {
    List<String> chunks = [];

    if (devocional.versiculo.trim().isNotEmpty) {
      final normalizedVerse = await _normalizeTtsText(devocional.versiculo);
      chunks.add('Versículo: ${_sanitize(normalizedVerse)}');
    }

    if (devocional.reflexion.trim().isNotEmpty) {
      chunks.add('Reflexión:');
      final reflection =
          await _normalizeTtsText(_sanitize(devocional.reflexion));
      final paragraphs = reflection.split(RegExp(r'\n+'));

      for (final paragraph in paragraphs) {
        final trimmed = paragraph.trim();
        if (trimmed.isNotEmpty) {
          if (trimmed.length > 300) {
            final sentences = trimmed.split(RegExp(r'(?<=[.!?])\s+'));
            String chunkParagraph = '';
            for (final sentence in sentences) {
              final normalizedSentence = await _normalizeTtsText(sentence);
              if (chunkParagraph.length + normalizedSentence.length < 300) {
                chunkParagraph += '$normalizedSentence ';
              } else {
                chunks.add(chunkParagraph.trim());
                chunkParagraph = '$normalizedSentence ';
              }
            }
            if (chunkParagraph.trim().isNotEmpty) {
              chunks.add(chunkParagraph.trim());
            }
          } else {
            chunks.add(await _normalizeTtsText(trimmed));
          }
        }
      }
    }

    if (devocional.paraMeditar.isNotEmpty) {
      chunks.add('Para Meditar:');
      for (final item in devocional.paraMeditar) {
        final citation = await _normalizeTtsText(_sanitize(item.cita));
        final text = await _normalizeTtsText(_sanitize(item.texto));
        if (citation.isNotEmpty && text.isNotEmpty) {
          chunks.add('$citation: $text');
        }
      }
    }

    if (devocional.oracion.trim().isNotEmpty) {
      chunks.add('Oración:');
      final prayer = await _normalizeTtsText(_sanitize(devocional.oracion));
      final paragraphs = prayer.split(RegExp(r'\n+'));

      for (final paragraph in paragraphs) {
        final trimmed = paragraph.trim();
        if (trimmed.isNotEmpty) {
          if (trimmed.length > 300) {
            final sentences = trimmed.split(RegExp(r'(?<=[.!?])\s+'));
            String chunkParagraph = '';
            for (final sentence in sentences) {
              final normalizedSentence = await _normalizeTtsText(sentence);
              if (chunkParagraph.length + normalizedSentence.length < 300) {
                chunkParagraph += '$normalizedSentence ';
              } else {
                chunks.add(chunkParagraph.trim());
                chunkParagraph = '$normalizedSentence ';
              }
            }
            if (chunkParagraph.trim().isNotEmpty) {
              chunks.add(chunkParagraph.trim());
            }
          } else {
            chunks.add(await _normalizeTtsText(trimmed));
          }
        }
      }
    }

    debugPrint('📝 TTS: Generated ${chunks.length} chunks');
    for (int i = 0; i < chunks.length; i++) {
      debugPrint(
          '   $i: ${chunks[i].length > 50 ? '${chunks[i].substring(0, 50)}...' : chunks[i]}');
    }

    return chunks.where((chunk) => chunk.trim().isNotEmpty).toList();
  }

  String _sanitize(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'[^\w\s.,!?;:áéíóúÁÉÍÓÚüÜñÑ\-()]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  void _updateState(TtsState newState) {
    if (_currentState != newState) {
      final oldState = _currentState;
      _currentState = newState;
      _stateController.add(newState);
      debugPrint(
          '🔄 TTS: State changed from $oldState to $newState at ${DateTime.now()}');
    }
  }

  void _resetPlayback() {
    debugPrint('🔄 TTS: Resetting playback state at ${DateTime.now()}');
    _cancelEmergencyTimer();
    _chunkInProgress = false;
    _currentDevocionalId = null;
    _currentChunks = [];
    _currentChunkIndex = 0;

    // FIX: Enviar progreso 0.0 ANTES de cambiar el estado
    _progressController.add(0.0);
    debugPrint('📊 TTS: Progress reset to 0%');

    // FIX: Cambiar estado al final para evitar race conditions
    _updateState(TtsState.idle);
  }

  // ========== PUBLIC API ==========

  Future<void> speakDevotional(Devocional devocional) async {
    debugPrint(
        '🎤 TTS: Starting devotional ${devocional.id} at ${DateTime.now()}');

    if (_disposed) {
      throw const TtsException('TTS service disposed',
          code: 'SERVICE_DISPOSED');
    }

    try {
      if (!_isInitialized) {
        await _initialize();
      }

      if (isActive) {
        await stop();
      }

      _currentDevocionalId = devocional.id;
      _currentChunks = await _generateChunks(devocional);
      _currentChunkIndex = 0;
      _chunkInProgress = true;
      _progressController.add(0.0);

      if (_currentChunks.isEmpty) {
        throw const TtsException('No content to speak');
      }

      debugPrint(
          '📝 TTS: Generated ${_currentChunks.length} chunks for ${devocional.id} at ${DateTime.now()}');

      _speakNextChunk();
    } catch (e) {
      debugPrint('❌ TTS: speakDevotional failed: $e at ${DateTime.now()}');
      _resetPlayback();
      rethrow;
    }
  }

  Future<void> speakText(String text) async {
    debugPrint('🔊 TTS: Speaking single text chunk at ${DateTime.now()}');

    if (_disposed) {
      throw const TtsException('TTS service disposed',
          code: 'SERVICE_DISPOSED');
    }

    try {
      if (!_isInitialized) {
        await _initialize();
      }

      final normalizedText = await _normalizeTtsText(_sanitize(text));
      if (normalizedText.isEmpty) {
        throw const TtsException('No valid text content to speak');
      }

      debugPrint(
          '📝 TTS: Speaking: ${normalizedText.length > 50 ? '${normalizedText.substring(0, 50)}...' : normalizedText}');

      await _flutterTts.speak(normalizedText);

      Timer(const Duration(seconds: 3), () {
        if (_currentState == TtsState.idle && !_disposed) {
          debugPrint(
              '⚠️ TTS: Start handler fallback for speakText at ${DateTime.now()}');
          _updateState(TtsState.playing);
        }
      });
    } catch (e) {
      debugPrint('❌ TTS: speakText failed: $e at ${DateTime.now()}');
      _updateState(TtsState.error);
      rethrow;
    }
  }

  Future<void> pause() async {
    debugPrint(
        '⏸️ TTS: Pause requested (current state: $_currentState) at ${DateTime.now()}');

    if (_currentState == TtsState.playing) {
      // FIX: CANCELAR EMERGENCY TIMER INMEDIATAMENTE
      _cancelEmergencyTimer();

      // FIX: CAMBIAR ESTADO A PAUSED INMEDIATAMENTE
      _updateState(TtsState.paused);

      // Luego ejecutar la pausa nativa
      await _flutterTts.pause();

      // Reducir el timeout del fallback
      Timer(const Duration(milliseconds: 300), () {
        if (_currentState != TtsState.paused && !_disposed) {
          debugPrint('! TTS: Pause handler fallback at ${DateTime.now()}');
          _updateState(TtsState.paused);
        }
      });
    }
  }

  Future<void> resume() async {
    debugPrint(
        '▶️ TTS: Resume requested (current state: $_currentState) at ${DateTime.now()}');
    if (_currentState == TtsState.paused) {
      if (_currentChunkIndex < _currentChunks.length && _chunkInProgress) {
        try {
          debugPrint(
              '▶️ TTS: Resuming current chunk ${_currentChunkIndex + 1}/${_currentChunks.length} at ${DateTime.now()}');

          _updateState(TtsState.playing);
          _speakNextChunk();
        } catch (e) {
          debugPrint('❌ TTS: Resume failed: $e at ${DateTime.now()}');
          _updateState(TtsState.error);
          rethrow;
        }
      } else {
        debugPrint(
            '⚠️ TTS: Cannot resume - no active playback at ${DateTime.now()}');
        _resetPlayback();
      }
    } else {
      debugPrint(
          '⚠️ TTS: Cannot resume - not paused (current: $_currentState) at ${DateTime.now()}');
    }
  }

  Future<void> stop() async {
    debugPrint(
        '⏹️ TTS: Stop requested (current state: $_currentState) at ${DateTime.now()}');
    if (isActive) {
      _updateState(TtsState.stopping);
      await _flutterTts.stop();
      _resetPlayback();
    }
  }

  Future<void> setLanguage(String language) async {
    if (!_isInitialized) await _initialize();
    await _flutterTts.setLanguage(language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_language', language);
  }

  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) await _initialize();
    final clampedRate = rate.clamp(0.1, 3.0);
    await _flutterTts.setSpeechRate(clampedRate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_rate', clampedRate);
  }

  Future<List<String>> getLanguages() async {
    if (!_isInitialized) await _initialize();
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages ?? []);
    } catch (e) {
      debugPrint('Error getting languages: $e at ${DateTime.now()}');
      return [];
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;

    _disposed = true;
    await stop();
    await _stateController.close();
    await _progressController.close();

    debugPrint('🧹 TTS: Service disposed at ${DateTime.now()}');
  }
}
