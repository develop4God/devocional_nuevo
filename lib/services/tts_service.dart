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

/// Optimized TTS Service with single timer and native handler priority
class TtsService {
  static final TtsService _instance = TtsService._internal();

  factory TtsService() => _instance;

  TtsService._internal();

  // Core TTS components
  final FlutterTts _flutterTts = FlutterTts();

  // State management - simplified
  TtsState _currentState = TtsState.idle;
  String? _currentDevocionalId;
  List<String> _currentChunks = [];
  int _currentChunkIndex = 0;

  // SINGLE global emergency timer - not per chunk
  Timer? _emergencyTimer;

  // Atomic protection - covers full chunk lifecycle
  bool _chunkInProgress = false;

  // Track last activity to detect real failures
  DateTime _lastNativeActivity = DateTime.now();

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

  /// Initialize TTS
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

      debugPrint('🔧 TTS: Loading config - Language: $language, Rate: $rate');

      // Configure TTS
      await _configureTts(language, rate);

      // Setup event handlers - after configuration
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
      debugPrint('🔧 TTS: Setting language to $language');
      await _flutterTts.setLanguage(language);
    } catch (e) {
      debugPrint('⚠️ TTS: Language $language failed, using es-ES: $e');
      await _flutterTts.setLanguage('es-ES');
    }

    debugPrint('🔧 TTS: Setting speech rate to $rate');
    await _flutterTts.setSpeechRate(rate.clamp(0.1, 3.0));
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Android specific settings
    if (Platform.isAndroid) {
      await _flutterTts.setQueueMode(0); // Flush queue
    }
  }

  /// Setup TTS event handlers - native handlers are PRIMARY
  void _setupEventHandlers() {
    debugPrint('🔧 TTS: Setting up event handlers...');

    _flutterTts.setStartHandler(() {
      debugPrint('🎬 TTS: Native START handler');
      if (!_disposed) {
        _lastNativeActivity = DateTime.now();
        _cancelEmergencyTimer();
        _updateState(TtsState.playing);
      }
    });

    _flutterTts.setCompletionHandler(() {
      debugPrint('🏁 TTS: Native COMPLETION handler');
      if (!_disposed) {
        _lastNativeActivity = DateTime.now();
        _cancelEmergencyTimer();
        _onChunkCompleted();
      }
    });

    _flutterTts.setPauseHandler(() {
      debugPrint('⏸️ TTS: Native PAUSE handler');
      if (!_disposed) {
        _lastNativeActivity = DateTime.now();
        _cancelEmergencyTimer();
        _updateState(TtsState.paused);
      }
    });

    _flutterTts.setContinueHandler(() {
      debugPrint('▶️ TTS: Native CONTINUE handler');
      if (!_disposed) {
        _lastNativeActivity = DateTime.now();
        _updateState(TtsState.playing);
      }
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint('💥 TTS: Native ERROR handler: $msg');
      if (!_disposed) {
        _lastNativeActivity = DateTime.now();
        _cancelEmergencyTimer();
        _updateState(TtsState.error);
        _resetPlayback();
      }
    });

    debugPrint('✅ TTS: Native event handlers configured');
  }

  /// Handle chunk completion - ATOMIC protection
  void _onChunkCompleted() {
    if (!_chunkInProgress) {
      debugPrint('⚠️ TTS: No chunk in progress, ignoring completion');
      return;
    }

    debugPrint(
        '🏁 TTS: Processing chunk ${_currentChunkIndex + 1}/${_currentChunks.length} completion');

    _currentChunkIndex++;

    // Update progress
    if (_currentChunks.isNotEmpty) {
      final progress = _currentChunkIndex / _currentChunks.length;
      debugPrint('📊 TTS: Progress: ${(progress * 100).toInt()}%');
      _progressController.add(progress);
    }

    // Check if there are more chunks
    if (_currentChunkIndex < _currentChunks.length &&
        _currentState != TtsState.paused &&
        _currentState != TtsState.error &&
        _currentState != TtsState.stopping) {
      debugPrint('➡️ TTS: Moving to next chunk...');
      // Brief pause between chunks for natural flow
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_disposed && _chunkInProgress) {
          _speakNextChunk();
        }
      });
    } else {
      debugPrint('✅ TTS: All chunks completed or playback interrupted');
      _resetPlayback();
    }
  }

  /// Speak next chunk - PRIMARY reliance on native handlers
  void _speakNextChunk() async {
    if (_disposed || !_chunkInProgress) return;

    if (_currentChunkIndex < _currentChunks.length) {
      final chunk = _currentChunks[_currentChunkIndex];
      debugPrint(
          '🔊 TTS: Speaking chunk ${_currentChunkIndex + 1}/${_currentChunks.length}');
      debugPrint(
          '📝 TTS: Content: ${chunk.length > 50 ? '${chunk.substring(0, 50)}...' : chunk}');

      try {
        _cancelEmergencyTimer();

        if (_currentState != TtsState.paused &&
            _currentState != TtsState.error &&
            _currentState != TtsState.stopping) {
          await _flutterTts.speak(chunk);

          // ONLY emergency timer - not competitive fallback
          _startEmergencyTimer(chunk);
        }
      } catch (e) {
        debugPrint('❌ TTS: Failed to speak chunk: $e');
        _updateState(TtsState.error);
        _resetPlayback();
      }
    }
  }

  /// Emergency timer - ONLY for real native handler failures
  void _startEmergencyTimer(String chunk) {
    _cancelEmergencyTimer();

    // Detect if this is likely a native handler failure

    // Conservative emergency timeout - only for real failures
    final wordCount = chunk.trim().split(RegExp(r'\s+')).length;
    final minExpectedTime =
        (wordCount * 200).clamp(1000, 5000); // 200ms per word, 1-5s range
    final emergencyTimeout =
        minExpectedTime + 1000; // +30s buffer for real emergencies

    debugPrint(
        '🚨 TTS: Emergency timer set for ${emergencyTimeout}ms ($wordCount words)');

    _emergencyTimer = Timer(Duration(milliseconds: emergencyTimeout), () {
      final now = DateTime.now();
      final timeSinceActivity = now.difference(_lastNativeActivity).inSeconds;

      debugPrint(
          '🚨 TTS: Emergency timer triggered after ${emergencyTimeout}ms');
      debugPrint(
          '🚨 TTS: Time since last native activity: ${timeSinceActivity}s');

      // Only act if we haven't heard from native handlers in a while
      if (timeSinceActivity > 2 && !_disposed && _chunkInProgress) {
        debugPrint(
            '🚨 TTS: Native handlers appear to have failed - emergency completion');
        _onChunkCompleted();
      } else {
        debugPrint(
            '🚨 TTS: Native handlers still active - ignoring emergency timer');
      }
    });
  }

  /// Cancel emergency timer
  void _cancelEmergencyTimer() {
    if (_emergencyTimer != null) {
      _emergencyTimer!.cancel();
      _emergencyTimer = null;
    }
  }

  /// Normalize text for better TTS pronunciation
  String _normalizeTtsText(String text) {
    String normalized = text;

    // Bible versions
    final bibleVersions = {
      'RVR1960': 'Reina Valera mil novecientos sesenta',
      'RVR60': 'Reina Valera sesenta',
      'RVR1995': 'Reina Valera mil novecientos noventa y cinco',
      'RVR09': 'Reina Valera dos mil nueve',
      'NVI': 'Nueva Versión Internacional',
      'DHH': 'Dios Habla Hoy',
      'TLA': 'Traducción en Lenguaje Actual',
      'NTV': 'Nueva Traducción Viviente',
      'PDT': 'Palabra de Dios para Todos',
      'BLP': 'Biblia La Palabra',
      'CST': 'Castilian',
      'LBLA': 'La Biblia de las Américas',
      'NBLH': 'Nueva Biblia Latinoamericana de Hoy',
      'RVC': 'Reina Valera Contemporánea',
    };

    bibleVersions.forEach((version, expansion) {
      if (normalized.contains(version)) {
        normalized = normalized.replaceAll(version, expansion);
      }
    });

    // Years
    normalized = normalized.replaceAllMapped(
      RegExp(r'\b(19\d{2}|20\d{2})\b'),
      (match) {
        final year = match.group(1)!;
        final yearInt = int.parse(year);
        String result;

        if (yearInt >= 1900 && yearInt < 2000) {
          final lastTwo = yearInt - 1900;
          if (lastTwo < 10) {
            result = 'mil novecientos cero $lastTwo';
          } else {
            result = 'mil novecientos $lastTwo';
          }
        } else if (yearInt >= 2000 && yearInt < 2100) {
          final lastTwo = yearInt - 2000;
          if (lastTwo == 0) {
            result = 'dos mil';
          } else if (lastTwo < 10) {
            result = 'dos mil $lastTwo';
          } else {
            result = 'dos mil $lastTwo';
          }
        } else {
          result = year;
        }

        return result;
      },
    );

    // Numbered biblical books
    normalized = normalized.replaceAllMapped(
      RegExp(r'\b([123])\s+([A-Za-záéíóúÁÉÍÓÚñÑ]+)', caseSensitive: false),
      (match) {
        final number = match.group(1)!;
        final book = match.group(2)!;

        String ordinal;
        switch (number) {
          case '1':
            ordinal = 'Primera de';
            break;
          case '2':
            ordinal = 'Segunda de';
            break;
          case '3':
            ordinal = 'Tercera de';
            break;
          default:
            ordinal = number;
        }

        return '$ordinal $book';
      },
    );

    // Biblical references
    normalized = normalized.replaceAllMapped(
      RegExp(
          r'(\b(?:\d+\s+)?[A-Za-záéíóúÁÉÍÓÚñÑ]+)\s+(\d+):(\d+)(?:-(\d+))?(?::(\d+))?',
          caseSensitive: false),
      (match) {
        final book = match.group(1)!;
        final chapter = match.group(2)!;
        final verseStart = match.group(3)!;
        final verseEnd = match.group(4);
        final secondVerse = match.group(5);

        String result = '$book capítulo $chapter versículo $verseStart';

        if (verseEnd != null) {
          result += ' al $verseEnd';
        }
        if (secondVerse != null) {
          result += ' versículo $secondVerse';
        }

        return result;
      },
    );

    // Time expressions
    normalized = normalized.replaceAllMapped(
      RegExp(
          r'\b(\d{1,2}):(\d{2})\s*(am|pm|a\.m\.|p\.m\.|de la mañana|de la tarde|de la noche)\b',
          caseSensitive: false),
      (match) {
        final hour = match.group(1)!;
        final minute = match.group(2)!;
        final period = match.group(3)!;

        String result;
        if (minute == '00') {
          result = '$hour en punto $period';
        } else {
          result = '$hour y $minute $period';
        }

        return result;
      },
    );

    // Ratios (not biblical or time)
    normalized = normalized.replaceAllMapped(
      RegExp(
          r'\b(\d+):(\d+)\b(?!\s*(am|pm|a\.m\.|p\.m\.|de la|capítulo|versículo))'),
      (match) {
        final first = match.group(1)!;
        final second = match.group(2)!;
        return '$first a $second';
      },
    );

    // Common abbreviations
    final abbreviations = {
      'vs.': 'versículo',
      'vv.': 'versículos',
      'cap.': 'capítulo',
      'caps.': 'capítulos',
      'cf.': 'compárese',
      'etc.': 'etcétera',
      'p.ej.': 'por ejemplo',
      'i.e.': 'es decir',
      'a.C.': 'antes de Cristo',
      'd.C.': 'después de Cristo',
      'a.m.': 'de la mañana',
      'p.m.': 'de la tarde',
    };

    abbreviations.forEach((abbrev, expansion) {
      if (normalized.contains(abbrev)) {
        normalized = normalized.replaceAll(abbrev, expansion);
      }
    });

    // Ordinal numbers
    normalized = normalized.replaceAllMapped(
      RegExp(r'\b(\d+)(º|°|ª|°)\b'),
      (match) {
        final number = int.tryParse(match.group(1)!) ?? 0;
        String result;

        switch (number) {
          case 1:
            result = 'primero';
            break;
          case 2:
            result = 'segundo';
            break;
          case 3:
            result = 'tercero';
            break;
          case 4:
            result = 'cuarto';
            break;
          case 5:
            result = 'quinto';
            break;
          default:
            result = 'número $number';
            break;
        }

        return result;
      },
    );

    // Clean multiple spaces
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }

  /// Generate text chunks from devotional
  List<String> _generateChunks(Devocional devocional) {
    List<String> chunks = [];

    // Verse as single chunk
    if (devocional.versiculo.trim().isNotEmpty) {
      final normalizedVerse = _normalizeTtsText(devocional.versiculo);
      chunks.add('Versículo: ${_sanitize(normalizedVerse)}');
    }

    // Reflection divided by paragraphs
    if (devocional.reflexion.trim().isNotEmpty) {
      chunks.add('Reflexión:');
      final reflection = _normalizeTtsText(_sanitize(devocional.reflexion));
      final paragraphs = reflection.split(RegExp(r'\n+'));

      for (final paragraph in paragraphs) {
        final trimmed = paragraph.trim();
        if (trimmed.isNotEmpty) {
          if (trimmed.length > 300) {
            // Split long paragraphs by sentences
            final sentences = trimmed.split(RegExp(r'(?<=[.!?])\s+'));
            String chunkParagraph = '';
            for (final sentence in sentences) {
              final normalizedSentence = _normalizeTtsText(sentence);
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
            chunks.add(_normalizeTtsText(trimmed));
          }
        }
      }
    }

    // Para Meditar: each item citation + text as independent chunk
    if (devocional.paraMeditar.isNotEmpty) {
      chunks.add('Para Meditar:');
      for (final item in devocional.paraMeditar) {
        final citation = _normalizeTtsText(_sanitize(item.cita));
        final text = _normalizeTtsText(_sanitize(item.texto));
        if (citation.isNotEmpty && text.isNotEmpty) {
          chunks.add('$citation: $text');
        }
      }
    }

    // Prayer divided similar to reflection
    if (devocional.oracion.trim().isNotEmpty) {
      chunks.add('Oración:');
      final prayer = _normalizeTtsText(_sanitize(devocional.oracion));
      final paragraphs = prayer.split(RegExp(r'\n+'));

      for (final paragraph in paragraphs) {
        final trimmed = paragraph.trim();
        if (trimmed.isNotEmpty) {
          if (trimmed.length > 300) {
            final sentences = trimmed.split(RegExp(r'(?<=[.!?])\s+'));
            String chunkParagraph = '';
            for (final sentence in sentences) {
              final normalizedSentence = _normalizeTtsText(sentence);
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
            chunks.add(_normalizeTtsText(trimmed));
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

  /// Sanitize text keeping accents and signs for good pronunciation
  String _sanitize(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'[^\w\s\.,!?;:áéíóúÁÉÍÓÚüÜñÑ\-\(\)]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Update state and notify listeners
  void _updateState(TtsState newState) {
    if (_currentState != newState) {
      final oldState = _currentState;
      _currentState = newState;
      _stateController.add(newState);
      debugPrint('🔄 TTS: State changed from $oldState to $newState');
    }
  }

  /// Reset playback state
  void _resetPlayback() {
    debugPrint('🔄 TTS: Resetting playback state');
    _cancelEmergencyTimer();
    _chunkInProgress = false;
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
      if (!_isInitialized) {
        await _initialize();
      }

      if (isActive) {
        await stop();
      }

      _currentDevocionalId = devocional.id;
      _currentChunks = _generateChunks(devocional);
      _currentChunkIndex = 0;
      _chunkInProgress = true; // ATOMIC START
      _progressController.add(0.0);

      if (_currentChunks.isEmpty) {
        throw const TtsException('No content to speak');
      }

      debugPrint(
          '📝 TTS: Generated ${_currentChunks.length} chunks for ${devocional.id}');

      _speakNextChunk();
    } catch (e) {
      debugPrint('❌ TTS: speakDevotional failed: $e');
      _resetPlayback();
      rethrow;
    }
  }

  /// Speak a single text chunk
  Future<void> speakText(String text) async {
    debugPrint('🔊 TTS: Speaking single text chunk');

    if (_disposed) {
      throw const TtsException('TTS service disposed',
          code: 'SERVICE_DISPOSED');
    }

    try {
      if (!_isInitialized) {
        await _initialize();
      }

      final normalizedText = _normalizeTtsText(_sanitize(text));
      if (normalizedText.isEmpty) {
        throw const TtsException('No valid text content to speak');
      }

      debugPrint(
          '📝 TTS: Speaking: ${normalizedText.length > 50 ? '${normalizedText.substring(0, 50)}...' : normalizedText}');

      await _flutterTts.speak(normalizedText);

      // Minimal fallback for single text - trust native handlers
      Timer(const Duration(seconds: 3), () {
        if (_currentState == TtsState.idle && !_disposed) {
          debugPrint('⚠️ TTS: Start handler fallback for speakText');
          _updateState(TtsState.playing);
        }
      });
    } catch (e) {
      debugPrint('❌ TTS: speakText failed: $e');
      _updateState(TtsState.error);
      rethrow;
    }
  }

  /// Pause current speech
  Future<void> pause() async {
    debugPrint('⏸️ TTS: Pause requested (current state: $_currentState)');
    if (_currentState == TtsState.playing) {
      await _flutterTts.pause();

      // Trust native handler, minimal fallback
      Timer(const Duration(milliseconds: 800), () {
        if (_currentState == TtsState.playing) {
          debugPrint('⚠️ TTS: Pause handler fallback');
          _updateState(TtsState.paused);
        }
      });
    }
  }

  /// Resume paused speech - continue current chunk
  Future<void> resume() async {
    debugPrint('▶️ TTS: Resume requested (current state: $_currentState)');
    if (_currentState == TtsState.paused) {
      // Continue with current chunk
      if (_currentChunkIndex < _currentChunks.length && _chunkInProgress) {
        try {
          debugPrint(
              '▶️ TTS: Resuming current chunk ${_currentChunkIndex + 1}/${_currentChunks.length}');

          _updateState(TtsState.playing);
          // Re-speak the current chunk
          _speakNextChunk();
        } catch (e) {
          debugPrint('❌ TTS: Resume failed: $e');
          _updateState(TtsState.error);
          rethrow;
        }
      } else {
        debugPrint('⚠️ TTS: Cannot resume - no active playback');
        _resetPlayback();
      }
    } else {
      debugPrint(
          '⚠️ TTS: Cannot resume - not paused (current: $_currentState)');
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    debugPrint('⏹️ TTS: Stop requested (current state: $_currentState)');
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
