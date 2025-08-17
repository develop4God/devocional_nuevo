// lib/services/tts_service.dart - REFACTORED VERSION

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced TTS state with more granular control
enum TtsState { idle, initializing, playing, paused, stopping, error }

/// Custom exception for TTS-related errors
class TtsException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const TtsException(this.message, {this.code, this.originalError});

  @override
  String toString() =>
      'TtsException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Simplified, focused TTS Service without deadlocks
class TtsService {
  static final TtsService _instance = TtsService._internal();

  factory TtsService() => _instance;

  TtsService._internal();

  // Core TTS components
  final FlutterTts _flutterTts = FlutterTts();

  // State management (simplified - no mutex needed)
  TtsState _currentState = TtsState.idle;
  String? _currentDevocionalId;
  List<String> _currentChunks = [];
  int _currentChunkIndex = 0;

  // Event streaming for reactive UI updates
  final _stateController = StreamController<TtsState>.broadcast();
  final _progressController = StreamController<double>.broadcast();

  // Configuration
  bool _isInitialized = false;
  bool _disposed = false;

  // Public streams
  Stream<TtsState> get stateStream => _stateController.stream;

  Stream<double> get progressStream => _progressController.stream;

  // Public getters
  TtsState get currentState => _currentState;

  String? get currentDevocionalId => _currentDevocionalId;

  bool get isPlaying => _currentState == TtsState.playing;

  bool get isPaused => _currentState == TtsState.paused;

  bool get isActive => isPlaying || isPaused;

  /// Check if platform supports TTS
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

  Null get isDisposed => null;

  /// Initialize TTS (no mutex - called once on first use)
  Future<void> _initialize() async {
    if (_isInitialized || _disposed) return;

    debugPrint('🔧 TTS: Initializing service...');
    _updateState(TtsState.initializing);

    try {
      // Platform check
      if (!_isPlatformSupported) {
        throw const TtsException(
            'Text-to-Speech not supported on this platform',
            code: 'PLATFORM_NOT_SUPPORTED');
      }

      // Load preferences
      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString('tts_language') ?? 'es-ES';
      final rate = prefs.getDouble('tts_rate') ?? 0.5;

      // Configure TTS
      await _configureTts(language, rate);

      // Setup event handlers
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

  /// Configure TTS settings
  Future<void> _configureTts(String language, double rate) async {
    try {
      await _flutterTts.setLanguage(language);
    } catch (e) {
      debugPrint('⚠️ TTS: Language $language failed, using en-US');
      await _flutterTts.setLanguage('en-US');
    }

    await _flutterTts.setSpeechRate(rate.clamp(0.1, 3.0));
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  /// Setup TTS event handlers
  void _setupEventHandlers() {
    _flutterTts.setStartHandler(() {
      debugPrint('🎬 TTS: Speech started');
      if (!_disposed) _updateState(TtsState.playing);
    });

    _flutterTts.setCompletionHandler(() {
      debugPrint('🏁 TTS: Speech completed');
      if (!_disposed) _onChunkCompleted();
    });

    _flutterTts.setPauseHandler(() {
      debugPrint('⏸️ TTS: Speech paused');
      if (!_disposed) _updateState(TtsState.paused);
    });

    _flutterTts.setContinueHandler(() {
      debugPrint('▶️ TTS: Speech continued');
      if (!_disposed) _updateState(TtsState.playing);
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint('💥 TTS: Error occurred: $msg');
      if (!_disposed) {
        _updateState(TtsState.error);
        _resetPlayback();
      }
    });
  }

  /// Handle chunk completion and continue to next chunk
  void _onChunkCompleted() {
    _currentChunkIndex++;

    // Update progress
    if (_currentChunks.isNotEmpty) {
      final progress = _currentChunkIndex / _currentChunks.length;
      _progressController.add(progress);
    }

    // Check if there are more chunks
    if (_currentChunkIndex < _currentChunks.length) {
      _speakNextChunk();
    } else {
      // All chunks completed
      debugPrint('✅ TTS: All chunks completed');
      _resetPlayback();
    }
  }

  /// Speak next chunk in the queue
  void _speakNextChunk() async {
    if (_currentChunkIndex < _currentChunks.length) {
      final chunk = _currentChunks[_currentChunkIndex];
      debugPrint(
          '🔊 TTS: Speaking chunk ${_currentChunkIndex + 1}/${_currentChunks.length}');

      try {
        await _flutterTts.speak(chunk);
      } catch (e) {
        debugPrint('❌ TTS: Failed to speak chunk: $e');
        _updateState(TtsState.error);
        _resetPlayback();
      }
    }
  }

  /// Generate text chunks from devotional
  List<String> _generateChunks(Devocional devocional) {
    List<String> chunks = [];

    // Verse
    if (devocional.versiculo.trim().isNotEmpty) {
      chunks.add('Versículo: ${_sanitize(devocional.versiculo)}');
    }

    // Reflection (split into smaller chunks)
    if (devocional.reflexion.trim().isNotEmpty) {
      chunks.add('Reflexión:');
      final reflection = _sanitize(devocional.reflexion);
      final sentences = reflection.split('. ');

      String currentParagraph = '';
      for (final sentence in sentences) {
        if (sentence.trim().isNotEmpty) {
          if (currentParagraph.length + sentence.length < 200) {
            currentParagraph += '${sentence.trim()}. ';
          } else {
            if (currentParagraph.isNotEmpty) {
              chunks.add(currentParagraph.trim());
            }
            currentParagraph = '${sentence.trim()}. ';
          }
        }
      }
      if (currentParagraph.isNotEmpty) {
        chunks.add(currentParagraph.trim());
      }
    }

    // Meditation points
    if (devocional.paraMeditar.isNotEmpty) {
      chunks.add('Para Meditar:');
      for (final item in devocional.paraMeditar) {
        final citation = _sanitize(item.cita);
        final text = _sanitize(item.texto);
        if (citation.isNotEmpty && text.isNotEmpty) {
          chunks.add('$citation: $text');
        }
      }
    }

    // Prayer
    if (devocional.oracion.trim().isNotEmpty) {
      chunks.add('Oración:');
      final prayer = _sanitize(devocional.oracion);
      final sentences = prayer.split('. ');

      String currentChunk = '';
      for (final sentence in sentences) {
        if (sentence.trim().isNotEmpty) {
          if (currentChunk.length + sentence.length < 250) {
            currentChunk += '${sentence.trim()}. ';
          } else {
            if (currentChunk.isNotEmpty) {
              chunks.add(currentChunk.trim());
            }
            currentChunk = '${sentence.trim()}. ';
          }
        }
      }
      if (currentChunk.isNotEmpty) {
        chunks.add(currentChunk.trim());
      }
    }

    return chunks.where((chunk) => chunk.trim().isNotEmpty).toList();
  }

  /// Sanitize text for TTS
  String _sanitize(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'[^\w\s\.,!?;:\-()]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Update state and notify listeners
  void _updateState(TtsState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
      debugPrint('🔄 TTS: State changed to $newState');
    }
  }

  /// Reset playback state
  void _resetPlayback() {
    _currentDevocionalId = null;
    _currentChunks = [];
    _currentChunkIndex = 0;
    _progressController.add(0.0);
    _updateState(TtsState.idle);
  }

  // ========== PUBLIC API ==========

  /// Speak a devotional
  Future<void> speakDevotional(Devocional devocional) async {
    debugPrint('🎤 TTS: Starting devotional ${devocional.id}');

    if (_disposed) {
      throw const TtsException('TTS service disposed',
          code: 'SERVICE_DISPOSED');
    }

    try {
      // Initialize if needed (no deadlock risk)
      if (!_isInitialized) {
        await _initialize();
      }

      // Stop current playback if any
      if (isActive) {
        await stop();
      }

      // Prepare new playback
      _currentDevocionalId = devocional.id;
      _currentChunks = _generateChunks(devocional);
      _currentChunkIndex = 0;
      _progressController.add(0.0);

      if (_currentChunks.isEmpty) {
        throw const TtsException('No content to speak');
      }

      debugPrint('📝 TTS: Generated ${_currentChunks.length} chunks');

      // Start speaking first chunk
      _speakNextChunk();
    } catch (e) {
      debugPrint('❌ TTS: speakDevotional failed: $e');
      _resetPlayback();
      rethrow;
    }
  }

  /// Pause current speech
  Future<void> pause() async {
    if (_currentState == TtsState.playing) {
      _updateState(TtsState.paused);
      await _flutterTts.pause();
    }
  }

  /// Resume paused speech
  Future<void> resume() async {
    if (_currentState == TtsState.paused) {
      // Resume from current chunk
      _speakNextChunk();
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    if (isActive) {
      _updateState(TtsState.stopping);
      await _flutterTts.stop();
      _resetPlayback();
    }
  }

  /// Set TTS language
  Future<void> setLanguage(String language) async {
    if (!_isInitialized) await _initialize();

    await _flutterTts.setLanguage(language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_language', language);
  }

  /// Set speech rate
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) await _initialize();

    final clampedRate = rate.clamp(0.1, 3.0);
    await _flutterTts.setSpeechRate(clampedRate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_rate', clampedRate);
  }

  /// Get available languages
  Future<List<String>> getLanguages() async {
    if (!_isInitialized) await _initialize();

    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages ?? []);
    } catch (e) {
      debugPrint('Error getting languages: $e');
      return [];
    }
  }

  /// Dispose service
  Future<void> dispose() async {
    if (_disposed) return;

    _disposed = true;
    await stop();
    await _stateController.close();
    await _progressController.close();

    debugPrint('🧹 TTS: Service disposed');
  }
}
