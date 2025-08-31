import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';
// ✅ AGREGADO: Import de SpecializedTextNormalizer
import 'package:devocional_nuevo/services/tts/specialized_text_normalizer.dart';
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

      // REFACTORIZADO: Usar VoiceSettingsService para cargar voz guardada
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
  /// Usa el contexto de idioma actual para formatear apropiadamente
  String formatBibleBook(String reference) {
    return BibleTextFormatter.formatBibleBook(reference, _currentLanguage);
  }

  // ✅ METODO PRINCIPAL DE NORMALIZACIÓN - RESTAURADO CON SpecializedTextNormalizer
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

    // ✅ USAR SpecializedTextNormalizer para formatear años
    normalized = SpecializedTextNormalizer.formatYears(normalized, currentLang);

    // ✅ USAR SpecializedTextNormalizer para formatear referencias bíblicas
    normalized = SpecializedTextNormalizer.formatBibleReferences(
        normalized, currentLang);

    // ✅ USAR SpecializedTextNormalizer para formatear tiempos y ratios
    normalized =
        SpecializedTextNormalizer.formatTimesAndRatios(normalized, currentLang);

    // Apply language-specific abbreviations
    normalized = _applyAbbreviations(normalized, currentLang);

    // Format ordinal numbers
    normalized = _formatOrdinalNumbers(normalized, currentLang);

    // Clean up whitespace
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }

  // ✅ MÉTODOS AUXILIARES IMPLEMENTADOS CORRECTAMENTE

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

  String _applyAbbreviations(String text, String language) {
    switch (language) {
      case 'en':
        return text
            .replaceAll(RegExp(r'\bDr\.'), 'Doctor')
            .replaceAll(RegExp(r'\bMr\.'), 'Mister')
            .replaceAll(RegExp(r'\bMrs\.'), 'Missus')
            .replaceAll(RegExp(r'\bMs\.'), 'Miss')
            .replaceAll(RegExp(r'\betc\.'), 'etcetera')
            .replaceAll(RegExp(r'\bi\.e\.'), 'that is')
            .replaceAll(RegExp(r'\be\.g\.'), 'for example');
      case 'pt':
        return text
            .replaceAll(RegExp(r'\bDr\.'), 'Doutor')
            .replaceAll(RegExp(r'\bDra\.'), 'Doutora')
            .replaceAll(RegExp(r'\bSr\.'), 'Senhor')
            .replaceAll(RegExp(r'\bSra\.'), 'Senhora')
            .replaceAll(RegExp(r'\betc\.'), 'etcetera');
      case 'fr':
        return text
            .replaceAll(RegExp(r'\bDr\.'), 'Docteur')
            .replaceAll(RegExp(r'\bM\.'), 'Monsieur')
            .replaceAll(RegExp(r'\bMme\.'), 'Madame')
            .replaceAll(RegExp(r'\bMlle\.'), 'Mademoiselle')
            .replaceAll(RegExp(r'\betc\.'), 'et cetera');
      default: // Spanish
        return text
            .replaceAll(RegExp(r'\bDr\.'), 'Doctor')
            .replaceAll(RegExp(r'\bDra\.'), 'Doctora')
            .replaceAll(RegExp(r'\bSr\.'), 'Señor')
            .replaceAll(RegExp(r'\bSra\.'), 'Señora')
            .replaceAll(RegExp(r'\bSrta\.'), 'Señorita')
            .replaceAll(RegExp(r'\betc\.'), 'etcétera');
    }
  }

  String _formatOrdinalNumbers(String text, String language) {
    switch (language) {
      case 'en':
        return text.replaceAllMapped(
          RegExp(r'\b(\d+)(st|nd|rd|th)\b'),
          (match) {
            final number = match.group(1)!;
            final suffix = match.group(2)!;
            return _numberToWordsEnglish(int.parse(number)) +
                (suffix == 'st'
                    ? ' first'
                    : suffix == 'nd'
                        ? ' second'
                        : suffix == 'rd'
                            ? ' third'
                            : ' th');
          },
        );
      case 'pt':
        return text.replaceAllMapped(
          RegExp(r'\b(\d+)[ºª]\b'),
          (match) {
            final number = int.parse(match.group(1)!);
            return '${_numberToWordsPortuguese(number)}º';
          },
        );
      case 'fr':
        return text.replaceAllMapped(
          RegExp(r'\b(\d+)(er|ème)\b'),
          (match) {
            final number = int.parse(match.group(1)!);
            final suffix = match.group(2)!;
            return _numberToWordsFrench(number) +
                (suffix == 'er' ? ' premier' : ' ième');
          },
        );
      default: // Spanish
        return text.replaceAllMapped(
          RegExp(r'\b(\d+)[ºª]\b'),
          (match) {
            final number = int.parse(match.group(1)!);
            return '${_numberToWordsSpanish(number)}º';
          },
        );
    }
  }

  // Helper methods for number to words conversion
  String _numberToWordsEnglish(int number) {
    const ones = [
      '',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine'
    ];
    const teens = [
      'ten',
      'eleven',
      'twelve',
      'thirteen',
      'fourteen',
      'fifteen',
      'sixteen',
      'seventeen',
      'eighteen',
      'nineteen'
    ];
    const tens = [
      '',
      '',
      'twenty',
      'thirty',
      'forty',
      'fifty',
      'sixty',
      'seventy',
      'eighty',
      'ninety'
    ];

    if (number < 10) return ones[number];
    if (number < 20) return teens[number - 10];
    if (number < 100) {
      return '${tens[number ~/ 10]} ${ones[number % 10]}'.trim();
    }
    return number.toString();
  }

  String _numberToWordsSpanish(int number) {
    const ones = [
      '',
      'uno',
      'dos',
      'tres',
      'cuatro',
      'cinco',
      'seis',
      'siete',
      'ocho',
      'nueve'
    ];
    const teens = [
      'diez',
      'once',
      'doce',
      'trece',
      'catorce',
      'quince',
      'dieciséis',
      'diecisiete',
      'dieciocho',
      'diecinueve'
    ];
    const tens = [
      '',
      '',
      'veinte',
      'treinta',
      'cuarenta',
      'cincuenta',
      'sesenta',
      'setenta',
      'ochenta',
      'noventa'
    ];

    if (number < 10) return ones[number];
    if (number < 20) return teens[number - 10];
    if (number < 100) {
      return '${tens[number ~/ 10]} ${ones[number % 10]}'.trim();
    }
    return number.toString();
  }

  String _numberToWordsPortuguese(int number) {
    const ones = [
      '',
      'um',
      'dois',
      'três',
      'quatro',
      'cinco',
      'seis',
      'sete',
      'oito',
      'nove'
    ];
    const teens = [
      'dez',
      'onze',
      'doze',
      'treze',
      'quatorze',
      'quinze',
      'dezesseis',
      'dezessete',
      'dezoito',
      'dezenove'
    ];
    const tens = [
      '',
      '',
      'vinte',
      'trinta',
      'quarenta',
      'cinquenta',
      'sessenta',
      'setenta',
      'oitenta',
      'noventa'
    ];

    if (number < 10) return ones[number];
    if (number < 20) return teens[number - 10];
    if (number < 100) {
      return '${tens[number ~/ 10]} ${ones[number % 10]}'.trim();
    }
    return number.toString();
  }

  String _numberToWordsFrench(int number) {
    const ones = [
      '',
      'un',
      'deux',
      'trois',
      'quatre',
      'cinq',
      'six',
      'sept',
      'huit',
      'neuf'
    ];
    const teens = [
      'dix',
      'onze',
      'douze',
      'treize',
      'quatorze',
      'quinze',
      'seize',
      'dix-sept',
      'dix-huit',
      'dix-neuf'
    ];
    const tens = [
      '',
      '',
      'vingt',
      'trente',
      'quarante',
      'cinquante',
      'soixante',
      'soixante-dix',
      'quatre-vingts',
      'quatre-vingt-dix'
    ];

    if (number < 10) return ones[number];
    if (number < 20) return teens[number - 10];
    if (number < 100) {
      return '${tens[number ~/ 10]} ${ones[number % 10]}'.trim();
    }
    return number.toString();
  }

  Map<String, String> _getBibleVersionExpansions(String language) {
    switch (language) {
      case 'en':
        return {
          'NIV': 'New International Version',
          'KJV': 'King James Version',
          'ESV': 'English Standard Version',
          'NLT': 'New Living Translation',
          'NASB': 'New American Standard Bible',
        };
      case 'pt':
        return {
          'ARA': 'Almeida Revista e Atualizada',
          'NVI': 'Nova Versão Internacional',
          'ARC': 'Almeida Revista e Corrigida',
        };
      case 'fr':
        return {
          'LSG': 'Louis Segond',
          'NEG': 'Nouvelle Edition de Genève',
          'BFC': 'Bible en Français Courant',
        };
      default: // Spanish
        return {
          'RVR1960': 'Reina Valera mil novecientos sesenta',
          'NVI': 'Nueva Versión Internacional',
          'LBLA': 'La Biblia de las Américas',
          'RVC': 'Reina Valera Contemporánea',
        };
    }
  }

  String _formatBibleBookForLanguage(String text, String language) {
    // Format numbered books (1 Juan, 2 Pedro, etc.)
    return text.replaceAllMapped(
      RegExp(r'\b([123])\s+([A-Za-záéíóúÁÉÍÓÚñÑ]+)\b'),
      (match) {
        final number = match.group(1)!;
        final book = match.group(2)!;

        switch (language) {
          case 'en':
            final ordinal = number == '1'
                ? 'First'
                : number == '2'
                    ? 'Second'
                    : 'Third';
            return '$ordinal $book';
          case 'pt':
            final ordinal = number == '1'
                ? 'Primeiro'
                : number == '2'
                    ? 'Segundo'
                    : 'Terceiro';
            return '$ordinal $book';
          case 'fr':
            final ordinal = number == '1'
                ? 'Premier'
                : number == '2'
                    ? 'Deuxième'
                    : 'Troisième';
            return '$ordinal $book';
          default: // Spanish
            final ordinal = number == '1'
                ? 'Primer'
                : number == '2'
                    ? 'Segundo'
                    : 'Tercer';
            return '$ordinal $book';
        }
      },
    );
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
          ' $i: ${chunks[i].length > 50 ? '${chunks[i].substring(0, 50)}...' : chunks[i]}');
    }

    return chunks.where((chunk) => chunk.trim().isNotEmpty).toList();
  }

  // Get section headers for different languages using localization service
  Map<String, String> _getSectionHeaders(String language) {
    // Ensure localization service is using the correct language context
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

  // REFACTORIZADO: Simplificar usando VoiceSettingsService
  Future<void> setLanguage(String language) async {
    if (!_isInitialized) await _initialize();

    await _flutterTts.setLanguage(language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_language', language);

    // Auto-cargar voz guardada para el nuevo idioma
    final languageCode = language.split('-')[0]; // es-ES -> es
    await _voiceSettingsService.loadSavedVoice(languageCode);
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

      // REFACTORIZADO: Usar VoiceSettingsService para cargar voz
      await _voiceSettingsService.loadSavedVoice(language);

      // Save the TTS language preference
      final prefs = await SharedPreferences.getInstance();
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

  // REFACTORIZADO: Usar VoiceSettingsService para todos los métodos de voz
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

  // DELEGADO: Usar VoiceSettingsService
  Future<List<String>> getVoices() async {
    return await _voiceSettingsService.getAvailableVoices();
  }

  // DELEGADO: Usar VoiceSettingsService
  Future<List<String>> getVoicesForLanguage(String language) async {
    return await _voiceSettingsService.getVoicesForLanguage(language);
  }

  // DELEGADO: Usar VoiceSettingsService
  Future<void> setVoice(Map<String, String> voice) async {
    if (!_isInitialized) await _initialize();

    final voiceName = voice['name'] ?? '';
    final locale = voice['locale'] ?? '';
    await _voiceSettingsService.saveVoice(_currentLanguage, voiceName, locale);
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
