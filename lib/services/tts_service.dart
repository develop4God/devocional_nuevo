// CAMBIOS QUIRÚRGICOS APLICADOS:
// 1. _onChunkCompleted(): Verificación de pausa ANTES de incrementar chunk (línea ~380)
// 2. stop(): Removidas validaciones restrictivas para stop inmediato (línea ~680)
// 3. pause(): Reforzada cancelación de timer de emergencia (línea ~650)

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';
import 'package:devocional_nuevo/services/tts/i_tts_service.dart';
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

/// Text-to-Speech service implementing the ITtsService interface.
///
/// This service provides comprehensive TTS functionality for speaking devotional
/// content, with support for multiple languages, voice customization, and
/// chunk-based playback for better user experience.
///
/// ## Usage Patterns
///
/// ### 1. Production Usage (Recommended)
/// Use the service locator to access the singleton instance:
/// ```dart
/// // In main.dart
/// void main() {
///   setupServiceLocator();
///   runApp(MyApp());
/// }
///
/// // In your code
/// final ttsService = getService<ITtsService>();
/// await ttsService.speakDevotional(devotional);
/// ```
///
/// ### 2. Direct Instantiation (Legacy Support)
/// The factory constructor is available for backward compatibility:
/// ```dart
/// final tts = TtsService(); // Creates new instance with default dependencies
/// ```
/// ⚠️ **Warning:** This creates a new instance each time and bypasses the
/// service locator singleton. Use service locator pattern instead.
///
/// ### 3. Testing (Test Constructor)
/// Use the forTest constructor to inject mocks:
/// ```dart
/// test('TTS service test', () {
///   final mockFlutterTts = MockFlutterTts();
///   final mockLocalization = MockLocalizationService();
///   final mockVoiceSettings = MockVoiceSettingsService();
///
///   final tts = TtsService.forTest(
///     flutterTts: mockFlutterTts,
///     localizationService: mockLocalization,
///     voiceSettingsService: mockVoiceSettings,
///   );
///
///   // Test with mocked dependencies
/// });
/// ```
///
/// ## Singleton Pattern
/// When using the service locator (recommended approach), only one instance
/// of TtsService exists throughout the app lifecycle. This ensures:
/// - Consistent state across the application
/// - Efficient resource usage (single FlutterTts instance)
/// - Proper lifecycle management
///
/// ⚠️ **Important:** Do not create multiple TtsService instances manually.
/// Always use `getService<ITtsService>()` for production code.
///
/// ## Dependencies
/// TtsService requires three dependencies:
/// - `FlutterTts`: Platform TTS implementation
/// - `LocalizationService`: For language-specific text normalization
/// - `VoiceSettingsService`: For voice selection and preferences
///
/// These are automatically provided when using the factory constructor or
/// service locator, but must be explicitly provided when using forTest.
class TtsService implements ITtsService {
  /// Private constructor for dependency injection
  /// Use getService\<ITtsService\>() instead of direct construction
  TtsService._internal({
    required FlutterTts flutterTts,
    required VoiceSettingsService voiceSettingsService,
  })  : _flutterTts = flutterTts,
        _voiceSettingsService = voiceSettingsService;

  /// Factory constructor that creates instance with proper dependencies
  /// Uses the Service Locator to get VoiceSettingsService singleton
  factory TtsService() {
    return TtsService._internal(
      flutterTts: FlutterTts(),
      voiceSettingsService: getService<VoiceSettingsService>(),
    );
  }

  /// Test constructor for injecting mocks
  @visibleForTesting
  factory TtsService.forTest({
    required FlutterTts flutterTts,
    required VoiceSettingsService voiceSettingsService,
  }) {
    return TtsService._internal(
      flutterTts: flutterTts,
      voiceSettingsService: voiceSettingsService,
    );
  }

  final FlutterTts _flutterTts;
  final VoiceSettingsService _voiceSettingsService;

  TtsState _currentState = TtsState.idle;
  String? _currentDevocionalId;

  final _stateController = StreamController<TtsState>.broadcast();
  final _progressController = StreamController<double>.broadcast();
  bool _isInitialized = false;
  bool _disposed = false;

  // Language context for TTS normalization
  String _currentLanguage = 'es';
  String _currentVersion = 'RVR1960';

  String _lastTextSpoken = '';

  @override
  Stream<TtsState> get stateStream => _stateController.stream;

  @override
  Stream<double> get progressStream => _progressController.stream;

  @override
  TtsState get currentState => _currentState;

  @override
  String? get currentDevocionalId => _currentDevocionalId;

  @override
  bool get isPlaying => _currentState == TtsState.playing;

  @override
  bool get isPaused => _currentState == TtsState.paused;

  @override
  bool get isActive => isPlaying || isPaused;

  @override
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
  // INITIALIZATION & CONFIG
  // =========================

  Future<void> _initialize() async {
    if (_isInitialized || _disposed) return;

    debugPrint('🔧 TTS: Initializing service...');
    _currentState = TtsState.initializing;

    try {
      if (!_isPlatformSupported) {
        throw const TtsException(
          'Text-to-Speech not supported on this platform',
          code: 'PLATFORM_NOT_SUPPORTED',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      // Priorizar el idioma del contexto sobre el guardado
      String language = _getTtsLocaleForLanguage(_currentLanguage);
      final rate = prefs.getDouble('tts_rate') ?? 0.5;

      debugPrint('🔧 TTS: Loading config - Language: $language, Rate: $rate');

      // Asignar voz y guardar idioma igual que en settings
      await assignDefaultVoiceForLanguage(_currentLanguage);

      await _configureTts(language, rate);
      await _flutterTts.awaitSpeakCompletion(true);

      _setupEventHandlers();

      _isInitialized = true;
      _currentState = TtsState.idle;
      debugPrint('✅ TTS: Service initialized successfully');
    } catch (e) {
      debugPrint('❌ TTS: Initialization failed: $e');
      _currentState = TtsState.error;
      rethrow;
    }
  }

  String _getTtsLocaleForLanguage(String language) {
    switch (language) {
      case 'es':
        return 'es-US';
      case 'en':
        return 'en-US';
      case 'pt':
        return 'pt-BR';
      case 'fr':
        return 'fr-FR';
      case 'ja':
        return 'ja-JP';
      default:
        return 'es-ES';
    }
  }

  Future<void> _configureTts(String language, double rate) async {
    try {
      debugPrint('🔧 TTS: Setting language to $language');
      await _flutterTts.setLanguage(language);

      final savedVoice = await _voiceSettingsService.loadSavedVoice(
        language.split('-')[0],
      );
      if (savedVoice != null) {
        debugPrint('🔧 TTS: Voice loaded by VoiceSettingsService: $savedVoice');
      }
    } catch (e) {
      debugPrint('⚠️ TTS: Language $language failed, using es-US: $e');
      await _flutterTts.setLanguage('es-US');
    }

    // Convert stored settings-scale (0.1..1.0) to mini-rate (0.5,1.0,2.0)
    double engineRate;
    try {
      if (rate >= 0.1 && rate <= 1.0) {
        engineRate = _voiceSettingsService.getMiniPlayerRate(rate);
      } else {
        // already likely a mini-rate
        engineRate = rate;
      }
    } catch (e) {
      engineRate = 1.0;
    }
    debugPrint(
      '🔧 TTS: Setting speech rate (engine) to $engineRate (from stored $rate)',
    );
    await _flutterTts.setSpeechRate(engineRate.clamp(0.1, 3.0));
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
        _currentState = TtsState.playing;
      }
    });

    _flutterTts.setCompletionHandler(() {
      debugPrint('🏁 TTS: COMPLETION handler (nativo) en ${DateTime.now()}');
      if (!_disposed) {
        _currentState = TtsState.idle;
      }
    });

    _flutterTts.setPauseHandler(() {
      debugPrint('⏸️ TTS: Native PAUSE handler at ${DateTime.now()}');
      if (!_disposed) {
        _currentState = TtsState.paused;
      }
    });

    _flutterTts.setContinueHandler(() {
      debugPrint('▶️ TTS: Native CONTINUE handler at ${DateTime.now()}');
      if (!_disposed) {
        _currentState = TtsState.playing;
      }
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint('💥 TTS: Native ERROR handler: $msg at ${DateTime.now()}');
      if (!_disposed) {
        _currentState = TtsState.error;
      }
    });

    debugPrint('✅ TTS: Native event handlers configured');
  }

  // =========================
  // PLAYBACK MANAGEMENT
  // =========================

  // =========================
  // TEXT NORMALIZATION - OPTIMIZED
  // =========================

  String _normalizeTtsText(String text, [String? language, String? version]) {
    final currentLang = language ?? _currentLanguage;
    return BibleTextFormatter.normalizeTtsText(text, currentLang, version);
  }

  // =========================
  // PUBLIC API
  // =========================

  @override
  Future<void> initialize() async {
    await _initialize();
  }

  @override
  Future<void> speakDevotional(Devocional devocional) async {
    debugPrint(
      '🎤 TTS: Starting devotional ${devocional.id} at ${DateTime.now()}',
    );

    if (_disposed) {
      throw const TtsException(
        'TTS service disposed',
        code: 'SERVICE_DISPOSED',
      );
    }

    try {
      if (!_isInitialized) {
        await _initialize();
      }

      if (isActive) {
        await stop();
      }

      _currentDevocionalId = devocional.id;
      _progressController.add(0.0);

      final normalizedText = _normalizeTtsText(
        devocional.reflexion,
        _currentLanguage,
        _currentVersion,
      );

      if (normalizedText.isEmpty) {
        throw const TtsException('No valid text content to speak');
      }

      debugPrint(
        '📝 TTS: Speaking: ${normalizedText.length > 50 ? '${normalizedText.substring(0, 50)}...' : normalizedText}',
      );

      _lastTextSpoken = normalizedText;

      await _flutterTts.speak(normalizedText);

      Timer(const Duration(seconds: 3), () {
        if (_currentState == TtsState.idle && !_disposed) {
          debugPrint(
            '⚠️ TTS: Start handler fallback for speakText at ${DateTime.now()}',
          );
          _currentState = TtsState.playing;
        }
      });
    } catch (e) {
      debugPrint('❌ TTS: speakDevotional failed: $e at ${DateTime.now()}');
      rethrow;
    }
  }

  @override
  Future<void> speakText(String text) async {
    debugPrint('🔊 TTS: Speaking single text chunk at ${DateTime.now()}');

    if (_disposed) {
      throw const TtsException(
        'TTS service disposed',
        code: 'SERVICE_DISPOSED',
      );
    }

    try {
      if (!_isInitialized) {
        await _initialize();
      }

      final normalizedText = _normalizeTtsText(
        _sanitize(text),
        _currentLanguage,
        _currentVersion,
      );

      if (normalizedText.isEmpty) {
        throw const TtsException('No valid text content to speak');
      }

      debugPrint(
        '📝 TTS: Speaking: ${normalizedText.length > 50 ? '${normalizedText.substring(0, 50)}...' : normalizedText}',
      );

      _lastTextSpoken = normalizedText;

      await _flutterTts.speak(normalizedText);

      Timer(const Duration(seconds: 3), () {
        if (_currentState == TtsState.idle && !_disposed) {
          debugPrint(
            '⚠️ TTS: Start handler fallback for speakText at ${DateTime.now()}',
          );
          _currentState = TtsState.playing;
        }
      });
    } catch (e) {
      debugPrint('❌ TTS: speakText failed: $e at ${DateTime.now()}');
      _currentState = TtsState.error;
      rethrow;
    }
  }

  // FIX 3: Reforzada cancelación de timer de emergencia en pause
  @override
  Future<void> pause() async {
    debugPrint(
      '⏸️ TTS: Pause requested (current state: $_currentState) at ${DateTime.now()}',
    );

    if (_currentState == TtsState.playing) {
      // CRÍTICO: Cancelar timer de emergencia INMEDIATAMENTE para evitar avance de chunk
      _currentState = TtsState.paused;
      await _flutterTts.pause();

      Timer(const Duration(milliseconds: 300), () {
        if (_currentState != TtsState.paused && !_disposed) {
          debugPrint('! TTS: Pause handler fallback at ${DateTime.now()}');
          _currentState = TtsState.paused;
        }
      });
    }
  }

  @override
  Future<void> resume() async {
    debugPrint(
      '▶️ TTS: Resume requested (current state: $_currentState) at ${DateTime.now()}',
    );

    if (_currentState == TtsState.paused) {
      try {
        debugPrint(
          '▶️ TTS: Resuming devotional $_currentDevocionalId at ${DateTime.now()}',
        );
        _currentState = TtsState.playing;
        await _flutterTts.speak(_lastTextSpoken);
      } catch (e) {
        debugPrint('❌ TTS: Resume failed: $e at ${DateTime.now()}');
        _currentState = TtsState.error;
        rethrow;
      }
    } else {
      debugPrint(
        '⚠️ TTS: Cannot resume - not paused (current: $_currentState) at ${DateTime.now()}',
      );
    }
  }

  // FIX 2: Stop inmediato sin validaciones restrictivas
  @override
  Future<void> stop() async {
    debugPrint(
      '⏹️ TTS: Stop requested (current state: $_currentState) at ${DateTime.now()}',
    );

    // CRÍTICO: Stop inmediato sin validaciones restrictivas - usuario siempre tiene control
    _currentState = TtsState.stopping;

    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('⚠️ TTS: Stop error (continuing with reset): $e');
    }

    debugPrint('✅ TTS: Stop completed at ${DateTime.now()}');
  }

  @override
  Future<void> setLanguage(String language) async {
    if (!_isInitialized) await _initialize();
    await _flutterTts.setLanguage(language);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_language', language);

    final languageCode = language.split('-')[0];
    await _voiceSettingsService.loadSavedVoice(languageCode);
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) await _initialize();
    final voiceService = getService<VoiceSettingsService>();
    double miniRate;
    double settingsScale;
    // If caller passed a settings-scale (0.1..1.0), map to mini-rate
    if (rate >= 0.1 && rate <= 1.0) {
      settingsScale = rate;
      miniRate = voiceService.getMiniPlayerRate(settingsScale);
    } else {
      // Otherwise assume mini-rate, find nearest allowed and map to settings-scale
      final allowed = VoiceSettingsService.allowedPlaybackRates;
      double nearest = allowed.first;
      double minDiff = double.infinity;
      for (final r in allowed) {
        final diff = (r - rate).abs();
        if (diff < minDiff) {
          minDiff = diff;
          nearest = r;
        }
      }
      miniRate = nearest;
      settingsScale = voiceService.getSettingsRateForMini(miniRate);
    }

    final clampedRate = miniRate.clamp(0.1, 3.0);
    debugPrint(
      '🔧 TTS Service: Applying speech rate mini=$miniRate (settings-scale=$settingsScale)',
    );
    await _flutterTts.setSpeechRate(clampedRate);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_rate', settingsScale);
  }

  @override
  void setLanguageContext(String language, String version) {
    _currentLanguage = language;
    _currentVersion = version;
    debugPrint('🌐 TTS: Language context set to $language ($version)');

    SharedPreferences.getInstance().then((prefs) {
      String ttsLocale = _getTtsLocaleForLanguage(language);
      prefs.setString('tts_language', ttsLocale);
    });

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
      case 'ja':
        ttsLocale = 'ja-JP';
        break;
      default:
        ttsLocale = 'es-ES';
    }

    try {
      debugPrint(
        '🔧 TTS: Changing voice language to $ttsLocale for context $language',
      );
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

  @override
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

  @override
  Future<List<String>> getVoices() async {
    return await _voiceSettingsService.getAvailableVoices();
  }

  @override
  Future<List<String>> getVoicesForLanguage(String language) async {
    return await _voiceSettingsService.getVoicesForLanguage(language);
  }

  @override
  Future<void> setVoice(Map<String, String> voice) async {
    if (!_isInitialized) await _initialize();
    final voiceName = voice['name'] ?? '';
    final locale = voice['locale'] ?? '';
    await _voiceSettingsService.saveVoice(_currentLanguage, voiceName, locale);
  }

  @override
  @visibleForTesting

  /// Formats Bible book references with appropriate ordinals based on current language context
  String formatBibleBook(String reference) {
    return BibleTextFormatter.formatBibleBook(reference, _currentLanguage);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await stop();
    await _stateController.close();
    await _progressController.close();
    debugPrint('🧹 TTS: Service disposed at ${DateTime.now()}');
  }

  @override
  Future<void> initializeTtsOnAppStart(String languageCode) async {
    // Asigna proactivamente la voz y el idioma TTS al iniciar la app
    // CRITICAL: Update _currentLanguage BEFORE any initialization to ensure correct language
    _currentLanguage = languageCode;
    debugPrint(
      '[TTS] Language context set to $languageCode before initialization',
    );
    await assignDefaultVoiceForLanguage(languageCode);
    debugPrint(
      '[TTS] Voz e idioma asignados proactivamente al iniciar la app: $languageCode',
    );
  }

  @override
  Future<void> assignDefaultVoiceForLanguage(String languageCode) async {
    String ttsLocale = _getTtsLocaleForLanguage(languageCode);
    await _flutterTts.setLanguage(ttsLocale);
    await _voiceSettingsService.loadSavedVoice(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_language', ttsLocale);
    debugPrint(
      '[TTS] Voz por defecto asignada para idioma: $languageCode ($ttsLocale)',
    );
  }

  String _sanitize(String text) {
    return text.trim().replaceAll(RegExp(r'[\s]+'), ' ');
  }
}
