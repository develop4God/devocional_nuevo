import 'package:flutter_tts/flutter_tts.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// Service to handle Text-to-Speech functionality for devotionals
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  String? _currentText;
  Function? _onStateChanged;

  /// Initialize the TTS service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load saved preferences
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('tts_language') ?? 'es-ES';
      final savedRate = prefs.getDouble('tts_rate') ?? 0.5;

      // Set up TTS configuration
      await _flutterTts.setLanguage(savedLanguage);
      await _flutterTts.setSpeechRate(savedRate);
      await _flutterTts.setVolume(1.0); // Full volume
      await _flutterTts.setPitch(1.0); // Normal pitch

      // Set up event handlers
      _flutterTts.setStartHandler(() {
        _isPlaying = true;
        _isPaused = false;
        developer.log('TTS: Started speaking');
        _notifyStateChanged();
      });

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
        _isPaused = false;
        _currentText = null;
        developer.log('TTS: Completed speaking');
        _notifyStateChanged();
      });

      _flutterTts.setPauseHandler(() {
        _isPaused = true;
        developer.log('TTS: Paused');
        _notifyStateChanged();
      });

      _flutterTts.setContinueHandler(() {
        _isPaused = false;
        developer.log('TTS: Continued');
        _notifyStateChanged();
      });

      _flutterTts.setErrorHandler((msg) {
        _isPlaying = false;
        _isPaused = false;
        developer.log('TTS Error: $msg');
        _notifyStateChanged();
      });

      _isInitialized = true;
      developer.log('TTS Service initialized successfully');
    } catch (e) {
      developer.log('Error initializing TTS: $e');
    }
  }

  /// Set a callback to be notified when TTS state changes
  void setStateChangedCallback(Function callback) {
    _onStateChanged = callback;
  }

  /// Notify listeners that the TTS state has changed
  void _notifyStateChanged() {
    if (_onStateChanged != null) {
      _onStateChanged!();
    }
  }

  /// Generate complete text from a devotional
  String _generateDevotionalText(Devocional devocional) {
    String fullText = '';
    
    // Add verse
    fullText += 'Versículo: ${devocional.versiculo}. ';
    
    // Add reflection
    fullText += 'Reflexión: ${devocional.reflexion}. ';
    
    // Add meditation points
    if (devocional.paraMeditar.isNotEmpty) {
      fullText += 'Para Meditar: ';
      for (final item in devocional.paraMeditar) {
        fullText += '${item.cita}: ${item.texto}. ';
      }
    }
    
    // Add prayer
    fullText += 'Oración: ${devocional.oracion}';
    
    return fullText;
  }

  /// Start speaking a devotional
  Future<void> speakDevotional(Devocional devocional) async {
    await initialize();
    
    if (_isPlaying) {
      await stop();
    }

    _currentText = _generateDevotionalText(devocional);
    
    try {
      await _flutterTts.speak(_currentText!);
    } catch (e) {
      developer.log('Error speaking devotional: $e');
    }
  }

  /// Pause the current speech
  Future<void> pause() async {
    if (_isPlaying && !_isPaused) {
      try {
        await _flutterTts.pause();
      } catch (e) {
        developer.log('Error pausing TTS: $e');
      }
    }
  }

  /// Resume the paused speech
  Future<void> resume() async {
    if (_isPaused) {
      try {
        // Flutter TTS doesn't have a native resume, so we continue from where we left off
        // This is a limitation of the current TTS implementation
        await _flutterTts.speak(_currentText ?? '');
      } catch (e) {
        developer.log('Error resuming TTS: $e');
      }
    }
  }

  /// Stop the current speech
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isPlaying = false;
      _isPaused = false;
      _currentText = null;
      _notifyStateChanged();
    } catch (e) {
      developer.log('Error stopping TTS: $e');
    }
  }

  /// Check if TTS is currently playing
  bool get isPlaying => _isPlaying;

  /// Check if TTS is currently paused
  bool get isPaused => _isPaused;

  /// Check if TTS is active (playing or paused)
  bool get isActive => _isPlaying || _isPaused;

  /// Get available languages
  Future<List<String>> getLanguages() async {
    await initialize();
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages ?? []);
    } catch (e) {
      developer.log('Error getting languages: $e');
      return [];
    }
  }

  /// Set the language for TTS
  Future<void> setLanguage(String language) async {
    await initialize();
    try {
      await _flutterTts.setLanguage(language);
      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tts_language', language);
    } catch (e) {
      developer.log('Error setting language: $e');
    }
  }

  /// Set the speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    await initialize();
    try {
      await _flutterTts.setSpeechRate(rate);
      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('tts_rate', rate);
    } catch (e) {
      developer.log('Error setting speech rate: $e');
    }
  }

  /// Dispose of the TTS service
  Future<void> dispose() async {
    await stop();
    // Flutter TTS doesn't require explicit disposal
  }
}