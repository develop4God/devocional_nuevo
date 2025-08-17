import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

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

/// Service to handle Text-to-Speech functionality for devotionals
class TtsService {
  static final TtsService _instance = TtsService._internal();

  factory TtsService() => _instance;

  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final Lock _mutex = Lock(); // Thread safety protection
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _disposed = false;
  String? _currentText;
  Function? _onStateChanged;

  // Performance tracking
  DateTime? _lastOperationStart;

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

  /// Initialize the TTS service
  Future<void> initialize() async {
    debugPrint('🔧 TTS: initialize() llamado');

    return await _mutex.synchronized(() async {
      debugPrint('🔒 TTS: initialize() mutex obtenido');

      if (_isInitialized || _disposed) {
        debugPrint('⚠️ TTS: Ya inicializado o disposed, saliendo');
        return;
      }

      _lastOperationStart = DateTime.now();

      try {
        debugPrint('📱 TTS: Verificando plataforma...');
        // Check platform compatibility first
        if (!_isPlatformSupported) {
          debugPrint('❌ TTS: Plataforma no soportada');
          throw const TtsException(
              'Text-to-Speech is not supported on this platform',
              code: 'PLATFORM_NOT_SUPPORTED');
        }
        debugPrint('✅ TTS: Plataforma soportada');

        debugPrint('💾 TTS: Cargando preferencias...');
        // Load saved preferences
        final prefs = await SharedPreferences.getInstance();
        final savedLanguage = prefs.getString('tts_language') ?? 'es-ES';
        final savedRate = prefs.getDouble('tts_rate') ?? 0.5;
        debugPrint(
            '💾 TTS: Preferencias cargadas - idioma: $savedLanguage, rate: $savedRate');

        // Validate preferences
        if (savedRate < 0.1 || savedRate > 3.0) {
          debugPrint('❌ TTS: Rate inválido: $savedRate');
          throw TtsException(
              'Invalid speech rate: $savedRate. Must be between 0.1 and 3.0');
        }

        debugPrint('🗣️ TTS: Configurando flutter_tts...');
        // Set up TTS configuration with error handling
        try {
          debugPrint('🌍 TTS: Estableciendo idioma $savedLanguage...');
          await _flutterTts.setLanguage(savedLanguage);
          debugPrint('✅ TTS: Idioma establecido');
        } catch (e) {
          debugPrint(
              '⚠️ TTS: Fallo al establecer idioma $savedLanguage, usando default: $e');
          await _flutterTts.setLanguage('en-US'); // Fallback language
        }

        debugPrint('⚡ TTS: Estableciendo velocidad...');
        await _flutterTts.setSpeechRate(savedRate);
        debugPrint('🔊 TTS: Estableciendo volumen...');
        await _flutterTts.setVolume(1.0); // Full volume
        debugPrint('🎵 TTS: Estableciendo pitch...');
        await _flutterTts.setPitch(1.0); // Normal pitch

        debugPrint('📡 TTS: Configurando event handlers...');
        // Set up event handlers with error protection
        _flutterTts.setStartHandler(() {
          debugPrint('🎬 TTS: StartHandler disparado');
          if (!_disposed) {
            _isPlaying = true;
            _isPaused = false;
            developer.log('TTS: Started speaking');
            _notifyStateChanged();
          }
        });

        _flutterTts.setCompletionHandler(() {
          debugPrint('🏁 TTS: CompletionHandler disparado');
          if (!_disposed) {
            _isPlaying = false;
            _isPaused = false;
            _currentText = null;
            developer.log('TTS: Completed speaking');
            _notifyStateChanged();
          }
        });

        _flutterTts.setPauseHandler(() {
          debugPrint('⏸️ TTS: PauseHandler disparado');
          if (!_disposed) {
            _isPaused = true;
            developer.log('TTS: Paused');
            _notifyStateChanged();
          }
        });

        _flutterTts.setContinueHandler(() {
          debugPrint('▶️ TTS: ContinueHandler disparado');
          if (!_disposed) {
            _isPaused = false;
            developer.log('TTS: Continued');
            _notifyStateChanged();
          }
        });

        _flutterTts.setErrorHandler((msg) {
          debugPrint('💥 TTS: ErrorHandler disparado: $msg');
          if (!_disposed) {
            _isPlaying = false;
            _isPaused = false;
            developer.log('TTS Error: $msg');
            _notifyStateChanged();
          }
        });

        _isInitialized = true;
        _trackPerformance(
            'initialize', DateTime.now().difference(_lastOperationStart!));
        debugPrint('🎉 TTS: Service initialized successfully');
      } on PlatformException catch (e) {
        debugPrint(
            '💥 TTS: PlatformException durante inicialización: ${e.message}');
        throw TtsException(
            'Platform-specific TTS initialization failed: ${e.message}',
            code: e.code,
            originalError: e);
      } catch (e) {
        debugPrint('💥 TTS: Error general durante inicialización: $e');
        throw TtsException('TTS initialization failed: $e', originalError: e);
      }
    });
  }

  /// Set a callback to be notified when TTS state changes
  void setStateChangedCallback(Function? callback) {
    _onStateChanged = callback;
  }

  /// Notify listeners that the TTS state has changed
  void _notifyStateChanged() {
    if (_onStateChanged != null && !_disposed) {
      try {
        _onStateChanged!();
      } catch (e) {
        developer.log('Error in state change callback: $e');
      }
    }
  }

  /// Track performance of TTS operations
  void _trackPerformance(String operation, Duration duration) {
    final durationMs = duration.inMilliseconds;
    developer.log('TTS Performance: $operation took ${durationMs}ms');

    // Log warning for slow operations
    if (duration > const Duration(seconds: 5)) {
      developer.log(
          'WARNING: Slow TTS operation: $operation took ${duration.inSeconds}s');
    }
  }

  /// Validate text input for TTS
  String? _validateAndSanitizeText(String? text) {
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    final sanitized = text.trim();

    // Check for reasonable length (prevent extremely long texts that could cause issues)
    if (sanitized.length > 50000) {
      throw const TtsException(
          'Text too long for TTS processing. Maximum 50,000 characters allowed.',
          code: 'TEXT_TOO_LONG');
    }

    // Remove or replace problematic characters that might cause TTS issues
    final cleaned = sanitized
        .replaceAll(RegExp(r'[^\w\s\.,!?;:\-()]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace

    return cleaned.isEmpty ? null : cleaned;
  }

  /// Generate devotional text divided into smaller chunks for better TTS performance
  List<String> _generateDevotionalChunks(Devocional devocional) {
    List<String> chunks = [];

    try {
      // Versículo
      final verse = _validateAndSanitizeText(devocional.versiculo);
      if (verse != null) {
        chunks.add('Versículo: $verse');
      }

      // Reflexión dividida en párrafos
      final reflection = _validateAndSanitizeText(devocional.reflexion);
      if (reflection != null) {
        chunks.add('Reflexión:');

        // Dividir reflexión en párrafos por puntos
        final sentences = reflection.split('. ');
        String currentParagraph = '';

        for (String sentence in sentences) {
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

      // Para Meditar
      if (devocional.paraMeditar.isNotEmpty) {
        chunks.add('Para Meditar:');
        for (final item in devocional.paraMeditar) {
          final citation = _validateAndSanitizeText(item.cita);
          final text = _validateAndSanitizeText(item.texto);
          if (citation != null && text != null) {
            chunks.add('$citation: $text');
          }
        }
      }

      // Oración dividida
      final prayer = _validateAndSanitizeText(devocional.oracion);
      if (prayer != null) {
        chunks.add('Oración:');

        // Dividir oración en chunks más pequeños
        final prayerSentences = prayer.split('. ');
        String currentChunk = '';

        for (String sentence in prayerSentences) {
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

      return chunks;
    } catch (e) {
      throw TtsException('Failed to generate devotional chunks: $e',
          originalError: e);
    }
  }

  /// Start speaking a devotional (MODIFIED to use chunks)
  Future<void> speakDevotional(Devocional devocional) async {
    debugPrint('🎤 TTS: speakDevotional iniciado para ${devocional.id}');

    return await _mutex.synchronized(() async {
      debugPrint('🔒 TTS: Mutex obtenido');

      if (_disposed) {
        debugPrint('❌ TTS: Servicio disposed, abortando');
        throw const TtsException('TTS service has been disposed',
            code: 'SERVICE_DISPOSED');
      }

      _lastOperationStart = DateTime.now();

      try {
        debugPrint('🚀 TTS: Iniciando inicialización...');
        await initialize();
        debugPrint('✅ TTS: Inicialización completada');

        if (_isPlaying) {
          debugPrint('🛑 TTS: Deteniendo audio anterior...');
          await _stopInternal();
        }

        debugPrint('📝 TTS: Generando chunks de texto...');
        // NUEVO: Dividir el texto en chunks
        final textChunks = _generateDevotionalChunks(devocional);
        debugPrint('📝 TTS: Generados ${textChunks.length} chunks');

        debugPrint('🔊 TTS: Iniciando reproducción de chunks...');
        // Reproducir chunk por chunk
        for (int i = 0; i < textChunks.length; i++) {
          String chunk = textChunks[i];
          debugPrint(
              '🔊 TTS: Reproduciendo chunk ${i + 1}/${textChunks.length}');

          if (_disposed || (!_isPlaying && !_isPaused)) {
            debugPrint('⏸️ TTS: Interrumpido, saliendo del loop');
            break; // Si se pausó/detuvo, salir
          }

          _currentText = chunk;

          try {
            debugPrint('📢 TTS: Llamando flutter_tts.speak()...');
            await _flutterTts.speak(chunk);
            debugPrint('✅ TTS: flutter_tts.speak() completado');

            // Esperar un poco entre chunks
            await Future.delayed(Duration(milliseconds: 600));
          } on PlatformException catch (e) {
            debugPrint('💥 TTS: PlatformException: ${e.message}');
            throw TtsException('Platform-specific speech error: ${e.message}',
                code: e.code, originalError: e);
          }
        }

        _trackPerformance(
            'speak', DateTime.now().difference(_lastOperationStart!));
        debugPrint('🎉 TTS: speakDevotional completado exitosamente');
      } catch (e) {
        debugPrint('💥 TTS: Error en speakDevotional: $e');
        if (e is TtsException) {
          rethrow;
        }
        throw TtsException('Failed to speak devotional: $e', originalError: e);
      }
    });
  }

  /// Pause the current speech
  Future<void> pause() async {
    return await _mutex.synchronized(() async {
      if (_disposed) {
        throw const TtsException('TTS service has been disposed',
            code: 'SERVICE_DISPOSED');
      }

      if (_isPlaying && !_isPaused) {
        try {
          await _flutterTts.pause();
        } on PlatformException catch (e) {
          throw TtsException('Platform-specific pause error: ${e.message}',
              code: e.code, originalError: e);
        } catch (e) {
          throw TtsException('Failed to pause TTS: $e', originalError: e);
        }
      }
    });
  }

  /// Resume the paused speech
  Future<void> resume() async {
    return await _mutex.synchronized(() async {
      if (_disposed) {
        throw const TtsException('TTS service has been disposed',
            code: 'SERVICE_DISPOSED');
      }

      if (_isPaused && _currentText != null) {
        try {
          // Flutter TTS doesn't have a native resume, so we continue from where we left off
          // This is a limitation of the current TTS implementation
          await _flutterTts.speak(_currentText!);
        } on PlatformException catch (e) {
          throw TtsException('Platform-specific resume error: ${e.message}',
              code: e.code, originalError: e);
        } catch (e) {
          throw TtsException('Failed to resume TTS: $e', originalError: e);
        }
      }
    });
  }

  /// Stop the current speech (internal method without mutex)
  Future<void> _stopInternal() async {
    try {
      await _flutterTts.stop();
      _isPlaying = false;
      _isPaused = false;
      _currentText = null;
      _notifyStateChanged();
    } on PlatformException catch (e) {
      developer.log('Platform-specific stop error: ${e.message}');
      // Don't throw here as stop should be robust
      _isPlaying = false;
      _isPaused = false;
      _currentText = null;
      _notifyStateChanged();
    } catch (e) {
      developer.log('Error stopping TTS: $e');
      // Don't throw here as stop should be robust
      _isPlaying = false;
      _isPaused = false;
      _currentText = null;
      _notifyStateChanged();
    }
  }

  /// Stop the current speech
  Future<void> stop() async {
    return await _mutex.synchronized(() async {
      if (_disposed) return; // Don't throw on stop when disposed
      await _stopInternal();
    });
  }

  /// Check if TTS is currently playing
  bool get isPlaying => !_disposed && _isPlaying;

  /// Check if TTS is currently paused
  bool get isPaused => !_disposed && _isPaused;

  /// Check if TTS is active (playing or paused)
  bool get isActive => !_disposed && (_isPlaying || _isPaused);

  /// Check if service is disposed
  bool get isDisposed => _disposed;

  /// Get available languages
  Future<List<String>> getLanguages() async {
    return await _mutex.synchronized(() async {
      if (_disposed) {
        throw const TtsException('TTS service has been disposed',
            code: 'SERVICE_DISPOSED');
      }

      try {
        await initialize();
        final languages = await _flutterTts.getLanguages;
        return List<String>.from(languages ?? []);
      } on PlatformException catch (e) {
        throw TtsException(
            'Platform-specific error getting languages: ${e.message}',
            code: e.code,
            originalError: e);
      } catch (e) {
        throw TtsException('Failed to get available languages: $e',
            originalError: e);
      }
    });
  }

  /// Set the language for TTS
  Future<void> setLanguage(String language) async {
    return await _mutex.synchronized(() async {
      if (_disposed) {
        throw const TtsException('TTS service has been disposed',
            code: 'SERVICE_DISPOSED');
      }

      final sanitizedLanguage = _validateAndSanitizeText(language);
      if (sanitizedLanguage == null) {
        throw const TtsException('Invalid language parameter',
            code: 'INVALID_LANGUAGE');
      }

      try {
        await initialize();
        await _flutterTts.setLanguage(sanitizedLanguage);
        // Save preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('tts_language', sanitizedLanguage);
      } on PlatformException catch (e) {
        throw TtsException(
            'Platform-specific error setting language: ${e.message}',
            code: e.code,
            originalError: e);
      } catch (e) {
        throw TtsException('Failed to set language: $e', originalError: e);
      }
    });
  }

  /// Set the speech rate (0.1 to 3.0)
  Future<void> setSpeechRate(double rate) async {
    return await _mutex.synchronized(() async {
      if (_disposed) {
        throw const TtsException('TTS service has been disposed',
            code: 'SERVICE_DISPOSED');
      }

      if (rate < 0.1 || rate > 3.0) {
        throw TtsException(
            'Invalid speech rate: $rate. Must be between 0.1 and 3.0');
      }

      try {
        await initialize();
        await _flutterTts.setSpeechRate(rate);
        // Save preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('tts_rate', rate);
      } on PlatformException catch (e) {
        throw TtsException(
            'Platform-specific error setting speech rate: ${e.message}',
            code: e.code,
            originalError: e);
      } catch (e) {
        throw TtsException('Failed to set speech rate: $e', originalError: e);
      }
    });
  }

  /// Dispose of the TTS service and release all resources
  Future<void> dispose() async {
    return await _mutex.synchronized(() async {
      if (_disposed) return;

      try {
        // Stop any ongoing speech
        await _stopInternal();

        // Clear callback to prevent further notifications
        _onStateChanged = null;

        // Mark as disposed
        _disposed = true;
        _isInitialized = false;

        developer.log('TTS Service disposed successfully');
      } catch (e) {
        developer.log('Error during TTS disposal: $e');
        // Still mark as disposed even if cleanup failed
        _disposed = true;
        _isInitialized = false;
      }
    });
  }
}
