import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
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

      // Load saved voice for current language if available
      final prefs = await SharedPreferences.getInstance();
      final savedVoice = prefs.getString('tts_voice_$_currentLanguage');
      if (savedVoice != null) {
        try {
          // Parse saved voice
          final voiceParts = savedVoice.split(' (');
          final voiceName = voiceParts[0];
          final locale = voiceParts.length > 1
              ? voiceParts[1].replaceAll(')', '')
              : language;

          await _flutterTts.setVoice({
            'name': voiceName,
            'locale': locale,
          });
          debugPrint(
              '🔧 TTS: Loaded saved voice $voiceName for language $_currentLanguage');
        } catch (e) {
          debugPrint('⚠️ TTS: Failed to load saved voice: $e');
        }
      }
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

  // --- Normalización avanzada de referencia bíblica ---
  /// Formatea dinámicamente los libros con ordinal si comienza con 1, 2, 3
  String formatBibleBook(String reference) {
    final exp =
        RegExp(r'^([123])\s+([A-Za-záéíóúÁÉÍÓÚñÑ]+)', caseSensitive: false);
    final match = exp.firstMatch(reference.trim());
    if (match != null) {
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
          ordinal = '';
      }
      return reference.replaceFirst(exp, '$ordinal $book');
    }
    return reference;
  }

  String _normalizeTtsText(String text, [String? language, String? version]) {
    String normalized = text;
    final currentLang = language ?? _currentLanguage;

    // Get Bible version expansions based on language
    final bibleVersions = _getBibleVersionExpansions(currentLang);

    bibleVersions.forEach((versionKey, expansion) {
      if (normalized.contains(versionKey)) {
        normalized = normalized.replaceAll(versionKey, expansion);
      }
    });

    // Format ordinals and Bible books for specific language
    normalized = _formatBibleBookForLanguage(normalized, currentLang);

    // Apply language-specific text normalizations
    normalized = _applyLanguageSpecificNormalizations(normalized, currentLang);

    // Format years (common for all languages but with language-specific number words)
    normalized = _formatYears(normalized, currentLang);

    // Format Bible references (language-specific)
    normalized = _formatBibleReferences(normalized, currentLang);

    // Format times and ratios
    normalized = _formatTimesAndRatios(normalized, currentLang);

    // Apply language-specific abbreviations
    normalized = _applyAbbreviations(normalized, currentLang);

    // Format ordinal numbers
    normalized = _formatOrdinalNumbers(normalized, currentLang);

    // Clean up whitespace
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }

  // Apply language-specific normalizations
  String _applyLanguageSpecificNormalizations(String text, String language) {
    switch (language) {
      case 'en':
        return text
            .replaceAll('versiculo:', 'Verse:')
            .replaceAll('reflexion:', 'Reflection:')
            .replaceAll('capitulo:', 'chapter:')
            .replaceAll('para_meditar:', 'To Meditate:')
            .replaceAll('Oracion:', 'Prayer:')
            .replaceAll('vs.', 'verse')
            .replaceAll('vv.', 'verses')
            .replaceAll('ch.', 'chapter')
            .replaceAll('chs.', 'chapters');
      case 'pt':
        return text
            .replaceAll('vs.', 'versículo')
            .replaceAll('vv.', 'versículos')
            .replaceAll('cap.', 'capítulo')
            .replaceAll('caps.', 'capítulos');
      case 'fr':
        return text
            .replaceAll('vs.', 'verset')
            .replaceAll('vv.', 'versets')
            .replaceAll('ch.', 'chapitre')
            .replaceAll('chs.', 'chapitres');
      default: // Spanish
        return text;
    }
  }

  // Format years with language-specific number words
  String _formatYears(String text, String language) {
    return text.replaceAllMapped(
      RegExp(r'\b(19\d{2}|20\d{2})\b'),
      (match) {
        final year = match.group(1)!;
        final yearInt = int.parse(year);

        switch (language) {
          case 'en':
            return _formatYearEnglish(yearInt);
          case 'pt':
            return _formatYearPortuguese(yearInt);
          case 'fr':
            return _formatYearFrench(yearInt);
          default: // Spanish
            return _formatYearSpanish(yearInt);
        }
      },
    );
  }

  String _formatYearSpanish(int year) {
    if (year >= 1900 && year < 2000) {
      final lastTwo = year - 1900;
      if (lastTwo < 10) {
        return 'mil novecientos cero $lastTwo';
      } else {
        return 'mil novecientos $lastTwo';
      }
    } else if (year >= 2000 && year < 2100) {
      final lastTwo = year - 2000;
      if (lastTwo == 0) {
        return 'dos mil';
      } else if (lastTwo < 10) {
        return 'dos mil $lastTwo';
      } else {
        return 'dos mil $lastTwo';
      }
    }
    return year.toString();
  }

  String _formatYearEnglish(int year) {
    if (year >= 1900 && year < 2000) {
      final lastTwo = year - 1900;
      if (lastTwo < 10) {
        return 'nineteen oh $lastTwo';
      } else {
        return 'nineteen $lastTwo';
      }
    } else if (year >= 2000 && year < 2100) {
      final lastTwo = year - 2000;
      if (lastTwo == 0) {
        return 'two thousand';
      } else if (lastTwo < 10) {
        return 'two thousand $lastTwo';
      } else {
        return 'two thousand $lastTwo';
      }
    }
    return year.toString();
  }

  String _formatYearPortuguese(int year) {
    if (year >= 1900 && year < 2000) {
      final lastTwo = year - 1900;
      if (lastTwo < 10) {
        return 'mil novecentos e $lastTwo';
      } else {
        return 'mil novecentos e $lastTwo';
      }
    } else if (year >= 2000 && year < 2100) {
      final lastTwo = year - 2000;
      if (lastTwo == 0) {
        return 'dois mil';
      } else if (lastTwo < 10) {
        return 'dois mil e $lastTwo';
      } else {
        return 'dois mil e $lastTwo';
      }
    }
    return year.toString();
  }

  String _formatYearFrench(int year) {
    if (year >= 1900 && year < 2000) {
      final lastTwo = year - 1900;
      if (lastTwo < 10) {
        return 'mille neuf cent $lastTwo';
      } else {
        return 'mille neuf cent $lastTwo';
      }
    } else if (year >= 2000 && year < 2100) {
      final lastTwo = year - 2000;
      if (lastTwo == 0) {
        return 'deux mille';
      } else if (lastTwo < 10) {
        return 'deux mille $lastTwo';
      } else {
        return 'deux mille $lastTwo';
      }
    }
    return year.toString();
  }

  // Format Bible references with language-specific words
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
      RegExp(
          r'(\b(?:\d+\s+)?[A-Za-záéíóúÁÉÍÓÚñÑ]+)\s+(\d+):(\d+)(?:-(\d+))?(?::(\d+))?',
          caseSensitive: false),
      (match) {
        final book = match.group(1)!;
        final chapter = match.group(2)!;
        final verseStart = match.group(3)!;
        final verseEnd = match.group(4);
        final secondVerse = match.group(5);

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
        if (secondVerse != null) {
          result += ' $verseWord $secondVerse';
        }

        return result;
      },
    );
  }

  // Format times and ratios with language-specific words
  String _formatTimesAndRatios(String text, String language) {
    // Time formatting
    final timeWords = {
      'es': ['de la mañana', 'de la tarde', 'de la noche', 'en punto', 'y'],
      'en': [
        'in the morning',
        'in the afternoon',
        'at night',
        "o'clock",
        'and'
      ],
      'pt': ['da manhã', 'da tarde', 'da noite', 'em ponto', 'e'],
      'fr': ['du matin', 'de l\'après-midi', 'du soir', 'heures', 'et'],
    };

    final words = timeWords[language] ?? timeWords['es']!;

    text = text.replaceAllMapped(
      RegExp(
          r'\b(\d{1,2}):(\d{2})\s*(am|pm|a\.m\.|p\.m\.|de la mañana|de la tarde|de la noche)\b',
          caseSensitive: false),
      (match) {
        final hour = match.group(1)!;
        final minute = match.group(2)!;
        final period = match.group(3)!;

        String result;
        if (minute == '00') {
          result = '$hour ${words[3]} ${_mapTimePeriod(period, language)}';
        } else {
          result =
              '$hour ${words[4]} $minute ${_mapTimePeriod(period, language)}';
        }

        return result;
      },
    );

    // Ratio formatting (e.g., 3:2 -> "3 to 2")
    final ratioWord = language == 'en'
        ? 'to'
        : language == 'pt'
            ? 'para'
            : language == 'fr'
                ? 'à'
                : 'a';

    text = text.replaceAllMapped(
      RegExp(
          r'\b(\d+):(\d+)\b(?!\s*(am|pm|a\.m\.|p\.m\.|de la|capítulo|versículo|chapter|verse|chapitre|verset))'),
      (match) {
        final first = match.group(1)!;
        final second = match.group(2)!;
        return '$first $ratioWord $second';
      },
    );

    return text;
  }

  String _mapTimePeriod(String period, String language) {
    final periodMap = {
      'es': {
        'am': 'de la mañana',
        'pm': 'de la tarde',
        'a.m.': 'de la mañana',
        'p.m.': 'de la tarde',
      },
      'en': {
        'am': 'AM',
        'pm': 'PM',
        'a.m.': 'AM',
        'p.m.': 'PM',
      },
      'pt': {
        'am': 'da manhã',
        'pm': 'da tarde',
        'a.m.': 'da manhã',
        'p.m.': 'da tarde',
      },
      'fr': {
        'am': 'du matin',
        'pm': 'de l\'après-midi',
        'a.m.': 'du matin',
        'p.m.': 'de l\'après-midi',
      },
    };

    return periodMap[language]?[period.toLowerCase()] ?? period;
  }

  // Apply language-specific abbreviations
  String _applyAbbreviations(String text, String language) {
    Map<String, String> abbreviations;

    switch (language) {
      case 'en':
        abbreviations = {
          'vs.': 'verse',
          'vv.': 'verses',
          'ch.': 'chapter',
          'chs.': 'chapters',
          'cf.': 'compare',
          'etc.': 'etcetera',
          'e.g.': 'for example',
          'i.e.': 'that is',
          'B.C.': 'before Christ',
          'A.D.': 'anno domini',
          'a.m.': 'ante meridiem',
          'p.m.': 'post meridiem',
        };
        break;
      case 'pt':
        abbreviations = {
          'vs.': 'versículo',
          'vv.': 'versículos',
          'cap.': 'capítulo',
          'caps.': 'capítulos',
          'cf.': 'confira',
          'etc.': 'etcétera',
          'p.ex.': 'por exemplo',
          'ou seja': 'isto é',
          'a.C.': 'antes de Cristo',
          'd.C.': 'depois de Cristo',
        };
        break;
      case 'fr':
        abbreviations = {
          'vs.': 'verset',
          'vv.': 'versets',
          'ch.': 'chapitre',
          'chs.': 'chapitres',
          'cf.': 'comparez',
          'etc.': 'et cetera',
          'p.ex.': 'par exemple',
          'c.-à-d.': 'c\'est-à-dire',
          'av. J.-C.': 'avant Jésus-Christ',
          'ap. J.-C.': 'après Jésus-Christ',
        };
        break;
      default: // Spanish
        abbreviations = {
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
    }

    abbreviations.forEach((abbrev, expansion) {
      if (text.contains(abbrev)) {
        text = text.replaceAll(abbrev, expansion);
      }
    });

    return text;
  }

  // Format ordinal numbers with language-specific words
  String _formatOrdinalNumbers(String text, String language) {
    return text.replaceAllMapped(
      RegExp(r'\b(\d+)([º°ª])\b'),
      (match) {
        final number = int.tryParse(match.group(1)!) ?? 0;

        switch (language) {
          case 'en':
            return _getEnglishOrdinal(number);
          case 'pt':
            return _getPortugueseOrdinal(number);
          case 'fr':
            return _getFrenchOrdinal(number);
          default: // Spanish
            return _getSpanishOrdinal(number);
        }
      },
    );
  }

  String _getSpanishOrdinal(int number) {
    switch (number) {
      case 1:
        return 'primero';
      case 2:
        return 'segundo';
      case 3:
        return 'tercero';
      case 4:
        return 'cuarto';
      case 5:
        return 'quinto';
      default:
        return 'número $number';
    }
  }

  String _getEnglishOrdinal(int number) {
    switch (number) {
      case 1:
        return 'first';
      case 2:
        return 'second';
      case 3:
        return 'third';
      case 4:
        return 'fourth';
      case 5:
        return 'fifth';
      default:
        return 'number $number';
    }
  }

  String _getPortugueseOrdinal(int number) {
    switch (number) {
      case 1:
        return 'primeiro';
      case 2:
        return 'segundo';
      case 3:
        return 'terceiro';
      case 4:
        return 'quarto';
      case 5:
        return 'quinto';
      default:
        return 'número $number';
    }
  }

  String _getFrenchOrdinal(int number) {
    switch (number) {
      case 1:
        return 'premier';
      case 2:
        return 'deuxième';
      case 3:
        return 'troisième';
      case 4:
        return 'quatrième';
      case 5:
        return 'cinquième';
      default:
        return 'numéro $number';
    }
  }

  // Get Bible version expansions based on language
  Map<String, String> _getBibleVersionExpansions(String language) {
    switch (language) {
      case 'es':
        return {
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
      case 'en':
        return {
          'KJV': 'King James Version',
          'NIV': 'New International Version',
        };
      case 'pt':
        return {
          'ARC': 'Almeida Revista e Corrigida',
          'NVI': 'Nova Versão Internacional',
        };
      case 'fr':
        return {
          'LSG1910': 'Louis Segond mil nove cento e dez',
          'LSG': 'Louis Segond',
          'TOB': 'Traduction Oecuménique de la Bible',
        };
      default:
        return {
          'RVR1960': 'Reina Valera mil novecientos sesenta',
        };
    }
  }

  // Format Bible books with ordinals for different languages
  String _formatBibleBookForLanguage(String reference, String language) {
    switch (language) {
      case 'es':
        return formatBibleBook(reference);
      case 'en':
        return _formatBibleBookEnglish(reference);
      case 'pt':
        return _formatBibleBookPortuguese(reference);
      case 'fr':
        return _formatBibleBookFrench(reference);
      default:
        return formatBibleBook(reference);
    }
  }

  String _formatBibleBookEnglish(String reference) {
    final exp = RegExp(r'^([123])\s+([A-Za-z]+)', caseSensitive: false);
    final match = exp.firstMatch(reference.trim());
    if (match != null) {
      final number = match.group(1)!;
      final bookName = match.group(2)!;

      final ordinals = {'1': 'First', '2': 'Second', '3': 'Third'};
      final ordinal = ordinals[number] ?? number;

      return reference.replaceFirst(
        RegExp('^$number\\s+$bookName', caseSensitive: false),
        '$ordinal $bookName',
      );
    }
    return reference;
  }

  String _formatBibleBookPortuguese(String reference) {
    final exp = RegExp(r'^([123])\s+([A-Za-z]+)', caseSensitive: false);
    final match = exp.firstMatch(reference.trim());
    if (match != null) {
      final number = match.group(1)!;
      final bookName = match.group(2)!;

      final ordinals = {'1': 'Primeiro', '2': 'Segundo', '3': 'Terceiro'};
      final ordinal = ordinals[number] ?? number;

      return reference.replaceFirst(
        RegExp('^$number\\s+$bookName', caseSensitive: false),
        '$ordinal $bookName',
      );
    }
    return reference;
  }

  String _formatBibleBookFrench(String reference) {
    final exp = RegExp(r'^([123])\s+([A-Za-z]+)', caseSensitive: false);
    final match = exp.firstMatch(reference.trim());
    if (match != null) {
      final number = match.group(1)!;
      final bookName = match.group(2)!;

      final ordinals = {'1': 'Premier', '2': 'Deuxième', '3': 'Troisième'};
      final ordinal = ordinals[number] ?? number;

      return reference.replaceFirst(
        RegExp('^$number\\s+$bookName', caseSensitive: false),
        '$ordinal $bookName',
      );
    }
    return reference;
  }

  List<String> _generateChunks(Devocional devocional,
      [String? targetLanguage]) {
    List<String> chunks = [];
    final currentLang = targetLanguage ?? _currentLanguage;

    // Get language-specific section headers usando el idioma objetivo
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
            final sentences = trimmed.split(RegExp(r'(?<=[.!?])\s+'));
            String chunkParagraph = '';
            for (final sentence in sentences) {
              final normalizedSentence =
                  _normalizeTtsText(sentence, currentLang, _currentVersion);
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
            final sentences = trimmed.split(RegExp(r'(?<=[.!?])\s+'));
            String chunkParagraph = '';
            for (final sentence in sentences) {
              final normalizedSentence =
                  _normalizeTtsText(sentence, currentLang, _currentVersion);
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
          '   $i: ${chunks[i].length > 50 ? '${chunks[i].substring(0, 50)}...' : chunks[i]}');
    }

    return chunks.where((chunk) => chunk.trim().isNotEmpty).toList();
  }

  // Get section headers for different languages using localization service
  Map<String, String> _getSectionHeaders(String language) {
    // Ensure localization service is using the correct language context
    if (_localizationService.currentLocale.languageCode != language) {
      // This is a fallback - ideally the localization service should already be in sync
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

    // FIX: Enviar progreso 0.0 ANTES de cambiar el estado
    _progressController.add(0.0);
    debugPrint('📊 TTS: Progress reset to 0%');

    // FIX: Cambiar estado al final para evitar race conditions
    _updateState(TtsState.idle);
  }

  // ========== PUBLIC API ==========

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

  // Set language context for TTS normalization
  void setLanguageContext(String language, String version) {
    _currentLanguage = language;
    _currentVersion = version;
    debugPrint('🌐 TTS: Language context set to $language ($version)');

    // Sync with localization service if needed
    if (_localizationService.currentLocale.languageCode != language) {
      debugPrint(
          '🔄 TTS: Syncing localization service to language context $language');
      // Note: We don't change the app language here, just log the mismatch
      // The app language should be controlled by the LocalizationProvider
    }

    // Update TTS language settings based on context immediately
    _updateTtsLanguageSettings(language);
  }

  // Update TTS language settings with proper locale mapping
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

      // Force language change with verification
      await _flutterTts.setLanguage(ttsLocale);

      // Load saved voice for current language if available
      final prefs = await SharedPreferences.getInstance();
      final savedVoice = prefs.getString('tts_voice_$language');
      if (savedVoice != null) {
        try {
          // Parse saved voice
          final voiceParts = savedVoice.split(' (');
          final voiceName = voiceParts[0];
          final locale = voiceParts.length > 1
              ? voiceParts[1].replaceAll(')', '')
              : ttsLocale;

          await _flutterTts.setVoice({
            'name': voiceName,
            'locale': locale,
          });
          debugPrint(
              '🔧 TTS: Loaded saved voice $voiceName for language context $language');
        } catch (e) {
          debugPrint(
              '⚠️ TTS: Failed to load saved voice for language context: $e');
        }
      }

      // Save the TTS language preference
      await prefs.setString('tts_language', ttsLocale);

      debugPrint('✅ TTS: Voice language successfully updated to $ttsLocale');
    } catch (e) {
      debugPrint('❌ TTS: Failed to set language $ttsLocale: $e');

      // Fallback to Spanish if other language fails
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
    if (!_isInitialized) await _initialize();
    try {
      final voices = await _flutterTts.getVoices;
      if (voices is List<dynamic>) {
        return voices.map((voice) {
          if (voice is Map) {
            final name = voice['name'] as String? ?? '';
            final locale = voice['locale'] as String? ?? '';
            return '$name ($locale)';
          }
          return voice.toString();
        }).toList();
      }
      return List<String>.from(voices ?? []);
    } catch (e) {
      debugPrint('Error getting voices: $e at ${DateTime.now()}');
      return [];
    }
  }

  Future<List<String>> getVoicesForLanguage(String language) async {
    final allVoices = await getVoices();
    final targetLocale = _getLocaleForLanguage(language);

    return allVoices.where((voice) => voice.contains(targetLocale)).toList();
  }

  String _getLocaleForLanguage(String language) {
    switch (language) {
      case 'es':
        return 'es-ES';
      case 'en':
        return 'en-US';
      case 'pt':
        return 'pt-BR';
      case 'fr':
        return 'fr-FR';
      default:
        return 'es-ES';
    }
  }

  Future<void> setVoice(Map<String, String> voice) async {
    if (!_isInitialized) await _initialize();
    try {
      await _flutterTts.setVoice(voice);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tts_voice_$_currentLanguage', voice['name'] ?? '');
      debugPrint(
          '🔧 TTS: Voice set to ${voice['name']} for language $_currentLanguage');
    } catch (e) {
      debugPrint('⚠️ TTS: Failed to set voice: $e');
    }
  }

  // Test helper method to expose chunk generation for testing
  @visibleForTesting
  List<String> generateChunksForTesting(Devocional devocional) {
    return _generateChunks(devocional);
  }

  // Test helper method to expose section headers for testing
  @visibleForTesting
  Map<String, String> getSectionHeadersForTesting(String language) {
    return _getSectionHeaders(language);
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
