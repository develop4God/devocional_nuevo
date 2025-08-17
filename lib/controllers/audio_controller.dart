// lib/controllers/audio_controller.dart - NEW FILE

import 'dart:async';

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter/widgets.dart';

/// Dedicated controller for audio functionality
/// Separates audio concerns from the main provider
class AudioController extends ChangeNotifier {
  final TtsService _ttsService = TtsService();

  // Subscriptions for reactive updates
  StreamSubscription<TtsState>? _stateSubscription;
  StreamSubscription<double>? _progressSubscription;

  // Current state (cached from service)
  TtsState _currentState = TtsState.idle;
  String? _currentDevocionalId;
  double _progress = 0.0;

  // Getters
  TtsState get currentState => _currentState;

  String? get currentDevocionalId => _currentDevocionalId;

  double get progress => _progress;

  bool get isPlaying => _currentState == TtsState.playing;

  bool get isPaused => _currentState == TtsState.paused;

  bool get isLoading => _currentState == TtsState.initializing;

  bool get hasError => _currentState == TtsState.error;

  bool get isActive => isPlaying || isPaused;

  /// Check if specific devotional is playing
  bool isDevocionalPlaying(String devocionalId) {
    return _currentDevocionalId == devocionalId && isActive;
  }

  /// Initialize controller and setup subscriptions
  void initialize() {
    debugPrint('🎵 AudioController: Initializing...');

    // Listen to TTS state changes
    _stateSubscription = _ttsService.stateStream.listen(
      (state) {
        debugPrint('🔄 AudioController: State changed to $state');
        _currentState = state;
        _currentDevocionalId = _ttsService.currentDevocionalId;

        // Use post-frame callback to avoid build conflicts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      },
      onError: (error) {
        debugPrint('❌ AudioController: State stream error: $error');
        _currentState = TtsState.error;
        notifyListeners();
      },
    );

    // Listen to progress changes
    _progressSubscription = _ttsService.progressStream.listen(
      (progress) {
        _progress = progress;
        // Don't notify listeners for every progress update to avoid spam
        // UI can subscribe directly to progressStream if needed
      },
      onError: (error) {
        debugPrint('❌ AudioController: Progress stream error: $error');
      },
    );

    debugPrint('✅ AudioController: Initialized with subscriptions');
  }

  // ========== AUDIO OPERATIONS ==========

  /// Play a devotional
  Future<void> playDevotional(Devocional devocional) async {
    try {
      debugPrint('🎵 AudioController: Playing ${devocional.id}');
      await _ttsService.speakDevotional(devocional);
    } on TtsException catch (e) {
      debugPrint('🔥 AudioController: TTS Error: ${e.message}');

      // Handle specific error cases
      switch (e.code) {
        case 'PLATFORM_NOT_SUPPORTED':
          // Platform doesn't support TTS - fail silently
          break;
        case 'SERVICE_DISPOSED':
          // Service was disposed - reinitialize if needed
          break;
        default:
          rethrow; // Let other errors bubble up
      }
    } catch (e) {
      debugPrint('❌ AudioController: Unexpected error: $e');
      rethrow;
    }
  }

  /// Pause current audio
  Future<void> pause() async {
    if (isPlaying) {
      try {
        await _ttsService.pause();
      } catch (e) {
        debugPrint('❌ AudioController: Pause error: $e');
        rethrow;
      }
    }
  }

  /// Resume paused audio
  Future<void> resume() async {
    if (isPaused) {
      try {
        await _ttsService.resume();
      } catch (e) {
        debugPrint('❌ AudioController: Resume error: $e');
        rethrow;
      }
    }
  }

  /// Stop current audio
  Future<void> stop() async {
    if (isActive) {
      try {
        await _ttsService.stop();
      } catch (e) {
        debugPrint('❌ AudioController: Stop error: $e');
        // Don't rethrow stop errors - they should be robust
      }
    }
  }

  /// Toggle play/pause for a devotional
  Future<void> togglePlayPause(Devocional devocional) async {
    if (_currentDevocionalId == devocional.id) {
      // Same devotional - toggle play/pause
      if (isPaused) {
        await resume();
      } else if (isPlaying) {
        await pause();
      } else {
        // Idle or error - start playing
        await playDevotional(devocional);
      }
    } else {
      // Different devotional - start new playback
      await playDevotional(devocional);
    }
  }

  // ========== SETTINGS ==========

  /// Get available TTS languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      return await _ttsService.getLanguages();
    } catch (e) {
      debugPrint('❌ AudioController: Error getting languages: $e');
      return [];
    }
  }

  /// Set TTS language
  Future<void> setLanguage(String language) async {
    try {
      await _ttsService.setLanguage(language);
    } catch (e) {
      debugPrint('❌ AudioController: Error setting language: $e');
      rethrow;
    }
  }

  /// Set TTS speech rate
  Future<void> setSpeechRate(double rate) async {
    try {
      await _ttsService.setSpeechRate(rate);
    } catch (e) {
      debugPrint('❌ AudioController: Error setting speech rate: $e');
      rethrow;
    }
  }

  // ========== LIFECYCLE ==========

  @override
  void dispose() {
    debugPrint('🧹 AudioController: Disposing...');

    // Cancel subscriptions
    _stateSubscription?.cancel();
    _progressSubscription?.cancel();

    // Dispose TTS service
    _ttsService.dispose();

    super.dispose();
    debugPrint('✅ AudioController: Disposed');
  }
}
