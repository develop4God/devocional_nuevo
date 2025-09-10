// CAMBIOS QUIRÚRGICOS APLICADOS:
// 1. _onChunkCompleted(): Verificación de pausa ANTES de incrementar chunk (línea ~380)
// 2. stop(): Removidas validaciones restrictivas para stop inmediato (línea ~680)
// 3. pause(): Reforzada cancelación de timer de emergencia (línea ~650)

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/foundation.dart';
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
  final LocalizationService _localizationService = LocalizationService.instance;
  final VoiceSettingsService _voiceSettingsService = VoiceSettingsService();

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

  // Language context for TTS normalization
  String _currentLanguage = 'es';
  String _currentVersion = 'RVR1960';

  Stream<TtsState> get stateStream => _stateController.stream;

  Stream<double> get progressStream => _progressController.stream;

  TtsState get currentState => _currentState;

  String? get currentDevocionalId => _currentDevocionalId;

  bool get isPlaying => _currentState == TtsState.playing;

  bool get isPaused => _currentState == TtsState.paused;

  bool get isActive => isPlaying || isPaused;

  bool get isDisposed => _disposed;

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

  VoidCallback? get previousChunk {
    if (_currentChunkIndex > 0 && _chunkInProgress) {
      return () => _jumpToChunk(_currentChunkIndex - 1);
    }
    return null;
  }

  VoidCallback? get nextChunk {
    if (_currentChunkIndex < _currentChunks.length - 1 && _chunkInProgress) {
      return () => _jumpToChunk(_currentChunkIndex + 1);
    }
    return null;
  }

  Future<void> Function(int index)? get jumpToChunk {
    if (_currentChunks.isNotEmpty && _chunkInProgress) {
      return (int index) async => await _jumpToChunk(index);
    }
    return null;
  }

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
  // INITIALIZATION & CONFIG
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

      final savedVoice =
          await _voiceSettingsService.loadSavedVoice(_currentLanguage);
      if (savedVoice != null) {
        debugPrint('🔧 TTS: Voice loaded by VoiceSettingsService: $savedVoice');
      }
    } catch (e) {
      debugPrint('⚠️ TTS: Language $language failed, using es-US: $e');
      await _flutterTts.setLanguage('es-US');
    }

    debugPrint('🔧 TTS: Setting speech rate to $rate');
    await _flutterTts.setSpeechRate(rate.clamp(0.1, 3.0));
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    if (Platform.isAndroid) {
      await _flutterTts.setQueueMode(1);
      debugPrint('🌀 TTS: Android setQueueMode(QUEUE)');
    }
  }

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

  // =========================
  // PLAYBACK MANAGEMENT
  // =========================

  // FIX 1: Verificación de pausa ANTES de incrementar chunk
  void _onChunkCompleted() async {
    if (!_chunkInProgress) return;

    // CRÍTICO: Verificar pausa ANTES de incrementar chunk para evitar avance no deseado
    if (_currentState == TtsState.paused) {
      debugPrint(
          '⏸️ TTS: Chunk completado pero estado pausado, manteniendo chunk actual');
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

      // Check for in-app review opportunity - AUDIO COMPLETION PATH
      try {
        // Add delay to ensure stats are persisted before checking
        await Future.delayed(const Duration(milliseconds: 100));

        final stats = await SpiritualStatsService().getStats();
        debugPrint(
            '🎯 Audio completion review check: ${stats.totalDevocionalesRead} devotionals');

        // Note: We cannot show dialog from TTS service without context
        // This will be handled via callback mechanism if needed
        // For now, just log the attempt
        debugPrint(
            '🔔 TTS: Review milestone check completed - context needed for dialog');
      } catch (e) {
        debugPrint('❌ Error checking in-app review (audio completion): $e');
        // Fail silently - review errors should not affect devotional recording
      }
    }

    debugPrint(
        '🏁 TTS: Processing chunk ${_currentChunkIndex + 1}/${_currentChunks.length} completion at ${DateTime.now()}');

    _currentChunkIndex++;

    if (_currentChunks.isNotEmpty) {
      final progress = _currentChunkIndex / _currentChunks.length;
      debugPrint('📊 TTS: Progress: ${(progress * 100).toInt()}%');
      _progressController.add(progress);
    }

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

    if (_currentState != TtsState.idle && _currentState != TtsState.playing) {
      if (_currentState == TtsState.paused) {
        debugPrint('⏸️ TTS: Playback pausado, no continuar chunks');
        return;
      }
      debugPrint('⏳ TTS: Esperando estado idle/playing para avanzar chunk...');
      Future.delayed(const Duration(milliseconds: 100), _speakNextChunk);
      return;
    }

    if (_currentChunkIndex < _currentChunks.length) {
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

  // =========================
  // TEXT NORMALIZATION - OPTIMIZED
  // =========================

  String _normalizeTtsText(String text, [String? language, String? version]) {
    String normalized = text;
    final currentLang = language ?? _currentLanguage;

    // 1. Formatear libros bíblicos PRIMERO (con RegExp corregido)
    normalized = BibleTextFormatter.formatBibleBook(normalized, currentLang);

    // 2. Expandir versiones bíblicas
    final bibleVersions =
        BibleTextFormatter.getBibleVersionExpansions(currentLang);
    bibleVersions.forEach((versionKey, expansion) {
      if (normalized.contains(versionKey)) {
        normalized = normalized.replaceAll(versionKey, expansion);
      }
    });

    // 3. Formatear referencias bíblicas básicas (capítulo:versículo)
    normalized = _formatBibleReferences(normalized, currentLang);

    // Clean up whitespace
    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _formatBibleReferences(String text, String language) {
    final Map<String, String> referenceWords = {
      'es': 'capítulo|versículo',
      'en': 'chapter|verse',
      'pt': 'capítulo|versículo',
      'fr': 'chapitre|verset',
    };

    final words = referenceWords[language] ?? referenceWords['es']!;
    final chapterWord = words.split('|')[0];
    final verseWord = words.split('|')[1];

    return text.replaceAllMapped(
      RegExp(r'(\b(?:\d+\s+)?[A-Za-záéíóúÁÉÍÓÚñÑ]+)\s+(\d+):(\d+)(?:-(\d+))?',
          caseSensitive: false),
      (match) {
        final book = match.group(1)!;
        final chapter = match.group(2)!;
        final verseStart = match.group(3)!;
        final verseEnd = match.group(4);

        String result = '$book $chapterWord $chapter $verseWord $verseStart';
        if (verseEnd != null) {
          final toWord = language == 'en'
              ? 'to'
              : language == 'pt'
                  ? 'ao'
                  : language == 'fr'
                      ? 'au'
                      : 'al';
          result += ' $toWord $verseEnd';
        }
        return result;
      },
    );
  }

  // =========================
  // CHUNK GENERATION
  // =========================

  List<String> _generateChunks(Devocional devocional,
      [String? targetLanguage]) {
    List<String> chunks = [];
    final currentLang = targetLanguage ?? _currentLanguage;
    final sectionHeaders = _getSectionHeaders(currentLang);

    if (devocional.versiculo.trim().isNotEmpty) {
      final normalizedVerse =
          _normalizeTtsText(devocional.versiculo, currentLang, _currentVersion);
      chunks.add('${sectionHeaders['verse']}: ${_sanitize(normalizedVerse)}');
    }

    if (devocional.reflexion.trim().isNotEmpty) {
      chunks.add('${sectionHeaders['reflection']}:');
      final reflection = _normalizeTtsText(
          _sanitize(devocional.reflexion), currentLang, _currentVersion);
      final paragraphs = reflection.split(RegExp(r'\n+'));

      for (final paragraph in paragraphs) {
        final trimmed = paragraph.trim();
        if (trimmed.isNotEmpty) {
          if (trimmed.length > 300) {
            _splitLongParagraph(trimmed, chunks, currentLang);
          } else {
            chunks
                .add(_normalizeTtsText(trimmed, currentLang, _currentVersion));
          }
        }
      }
    }

    if (devocional.paraMeditar.isNotEmpty) {
      chunks.add('${sectionHeaders['meditate']}:');
      for (final item in devocional.paraMeditar) {
        final citation = _normalizeTtsText(
            _sanitize(item.cita), currentLang, _currentVersion);
        final text = _normalizeTtsText(
            _sanitize(item.texto), currentLang, _currentVersion);
        if (citation.isNotEmpty && text.isNotEmpty) {
          chunks.add('$citation: $text');
        }
      }
    }

    if (devocional.oracion.trim().isNotEmpty) {
      chunks.add('${sectionHeaders['prayer']}:');
      final prayer = _normalizeTtsText(
          _sanitize(devocional.oracion), currentLang, _currentVersion);
      final paragraphs = prayer.split(RegExp(r'\n+'));

      for (final paragraph in paragraphs) {
        final trimmed = paragraph.trim();
        if (trimmed.isNotEmpty) {
          if (trimmed.length > 300) {
            _splitLongParagraph(trimmed, chunks, currentLang);
          } else {
            chunks
                .add(_normalizeTtsText(trimmed, currentLang, _currentVersion));
          }
        }
      }
    }

    debugPrint(
        '📝 TTS: Generated ${chunks.length} chunks for language $currentLang');
    for (int i = 0; i < chunks.length; i++) {
      debugPrint(
          '  $i: ${chunks[i].length > 50 ? '${chunks[i].substring(0, 50)}...' : chunks[i]}');
    }

    return chunks.where((chunk) => chunk.trim().isNotEmpty).toList();
  }

  void _splitLongParagraph(
      String paragraph, List<String> chunks, String currentLang) {
    final sentences = paragraph.split(RegExp(r'(?<=[.!?])\s+'));
    String chunkParagraph = '';

    for (final sentence in sentences) {
      final normalizedSentence =
          _normalizeTtsText(sentence, currentLang, _currentVersion);
      if (chunkParagraph.length + normalizedSentence.length < 300) {
        chunkParagraph += '$normalizedSentence ';
      } else {
        if (chunkParagraph.trim().isNotEmpty) {
          chunks.add(chunkParagraph.trim());
        }
        chunkParagraph = '$normalizedSentence ';
      }
    }

    if (chunkParagraph.trim().isNotEmpty) {
      chunks.add(chunkParagraph.trim());
    }
  }

  Map<String, String> _getSectionHeaders(String language) {
    if (_localizationService.currentLocale.languageCode != language) {
      debugPrint(
          '⚠️ TTS: Language mismatch between localization service (${_localizationService.currentLocale.languageCode}) and TTS context ($language)');
    }

    return {
      'verse': _localizationService.translate('devotionals.verse'),
      'reflection': _localizationService.translate('devotionals.reflection'),
      'meditate': _localizationService.translate('devotionals.to_meditate'),
      'prayer': _localizationService.translate('devotionals.prayer'),
    };
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
    _progressController.add(0.0);
    debugPrint('📊 TTS: Progress reset to 0%');
    _updateState(TtsState.idle);
  }

  // =========================
  // PUBLIC API
  // =========================

  Future<void> initialize() async {
    await _initialize();
  }

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
      _currentChunks = _generateChunks(devocional);
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

      final normalizedText =
          _normalizeTtsText(_sanitize(text), _currentLanguage, _currentVersion);

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

  // FIX 3: Reforzada cancelación de timer de emergencia en pause
  Future<void> pause() async {
    debugPrint(
        '⏸️ TTS: Pause requested (current state: $_currentState) at ${DateTime.now()}');

    if (_currentState == TtsState.playing) {
      // CRÍTICO: Cancelar timer de emergencia INMEDIATAMENTE para evitar avance de chunk
      _cancelEmergencyTimer();
      _updateState(TtsState.paused);
      await _flutterTts.pause();

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

  // FIX 2: Stop inmediato sin validaciones restrictivas
  Future<void> stop() async {
    debugPrint(
        '⏹️ TTS: Stop requested (current state: $_currentState) at ${DateTime.now()}');

    // CRÍTICO: Stop inmediato sin validaciones restrictivas - usuario siempre tiene control
    _updateState(TtsState.stopping);

    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('⚠️ TTS: Stop error (continuing with reset): $e');
    }

    _resetPlayback();
    debugPrint('✅ TTS: Stop completed at ${DateTime.now()}');
  }

  Future<void> setLanguage(String language) async {
    if (!_isInitialized) await _initialize();
    await _flutterTts.setLanguage(language);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_language', language);

    final languageCode = language.split('-')[0];
    await _voiceSettingsService.loadSavedVoice(languageCode);
  }

  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) await _initialize();
    final clampedRate = rate.clamp(0.1, 3.0);
    await _flutterTts.setSpeechRate(clampedRate);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_rate', clampedRate);
  }

  void setLanguageContext(String language, String version) {
    _currentLanguage = language;
    _currentVersion = version;
    debugPrint('🌐 TTS: Language context set to $language ($version)');

    if (_localizationService.currentLocale.languageCode != language) {
      debugPrint(
          '🔄 TTS: Syncing localization service to language context $language');
    }

    _updateTtsLanguageSettings(language);
  }

  Future<void> _updateTtsLanguageSettings(String language) async {
    if (!_isInitialized) {
      debugPrint('⚠️ TTS: Cannot update language - service not initialized');
      return;
    }

    String ttsLocale;
    switch (language) {
      case 'es':
        ttsLocale = 'es-ES';
        break;
      case 'en':
        ttsLocale = 'en-US';
        break;
      case 'pt':
        ttsLocale = 'pt-BR';
        break;
      case 'fr':
        ttsLocale = 'fr-FR';
        break;
      default:
        ttsLocale = 'es-ES';
    }

    try {
      debugPrint(
          '🔧 TTS: Changing voice language to $ttsLocale for context $language');
      await _flutterTts.setLanguage(ttsLocale);
      await _voiceSettingsService.loadSavedVoice(language);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tts_language', ttsLocale);
      debugPrint('✅ TTS: Voice language successfully updated to $ttsLocale');
    } catch (e) {
      debugPrint('❌ TTS: Failed to set language $ttsLocale: $e');
      if (ttsLocale != 'es-ES') {
        try {
          await _flutterTts.setLanguage('es-ES');
          debugPrint('🔄 TTS: Fallback to Spanish voice successful');
        } catch (fallbackError) {
          debugPrint('❌ TTS: Even Spanish fallback failed: $fallbackError');
        }
      }
    }
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

  Future<List<String>> getVoices() async {
    return await _voiceSettingsService.getAvailableVoices();
  }

  Future<List<String>> getVoicesForLanguage(String language) async {
    return await _voiceSettingsService.getVoicesForLanguage(language);
  }

  Future<void> setVoice(Map<String, String> voice) async {
    if (!_isInitialized) await _initialize();
    final voiceName = voice['name'] ?? '';
    final locale = voice['locale'] ?? '';
    await _voiceSettingsService.saveVoice(_currentLanguage, voiceName, locale);
  }

  @visibleForTesting
  List<String> generateChunksForTesting(Devocional devocional) {
    return _generateChunks(devocional);
  }

  @visibleForTesting
  Map<String, String> getSectionHeadersForTesting(String language) {
    return _getSectionHeaders(language);
  }

  /// Formats Bible book references with appropriate ordinals based on current language context
  String formatBibleBook(String reference) {
    return BibleTextFormatter.formatBibleBook(reference, _currentLanguage);
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
