// lib/controllers/audio_controller.dart - SIMPLIFICADO PARA USAR TtsService DIRECTAMENTE

import 'dart:async';

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter/widgets.dart';

/// Simplified audio controller that delegates chunk management to TtsService
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
        notifyListeners();
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
        debugPrint(
            '📊 AudioController: Progress: ${(progress * 100).toInt()}%');
        _progress = progress;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ AudioController: Progress stream error: $error');
      },
    );

    debugPrint('✅ AudioController: Initialized with subscriptions');
  }

  // ========== SIMPLIFIED AUDIO OPERATIONS ==========

  /// Play a devotional (delegates to TtsService)
  Future<void> playDevotional(Devocional devocional) async {
    try {
      debugPrint('🎵 AudioController: Playing ${devocional.id}');
      await _ttsService.speakDevotional(devocional);
    } catch (e) {
      debugPrint('❌ AudioController: Error playing devotional: $e');
      rethrow;
    }
  }

  /// Pause current audio
  Future<void> pause() async {
    if (isPlaying) {
      try {
        debugPrint('⏸️ AudioController: Pausing...');
        await _ttsService.pause();
      } catch (e) {
        debugPrint('❌ AudioController: Pause error: $e');
        rethrow;
      }
    } else {
      debugPrint(
          '⚠️ AudioController: Cannot pause - not playing (state: $_currentState)');
    }
  }

  /// Resume paused audio
  Future<void> resume() async {
    if (isPaused) {
      try {
        debugPrint('▶️ AudioController: Resuming...');
        await _ttsService.resume();
      } catch (e) {
        debugPrint('❌ AudioController: Resume error: $e');
        rethrow;
      }
    } else {
      debugPrint(
          '⚠️ AudioController: Cannot resume - not paused (state: $_currentState)');
    }
  }

  /// Stop current audio
  Future<void> stop() async {
    if (isActive) {
      try {
        debugPrint('⏹️ AudioController: Stopping...');
        await _ttsService.stop();
      } catch (e) {
        debugPrint('❌ AudioController: Stop error: $e');
      }
    }
  }

  /// Toggle play/pause for a devotional
  Future<void> togglePlayPause(Devocional devocional) async {
    debugPrint(
        '🔄 AudioController: Toggle for ${devocional.id} (current: $_currentDevocionalId, state: $_currentState)');

    if (_currentDevocionalId == devocional.id) {
      // Same devotional - toggle play/pause
      if (isPaused) {
        debugPrint('▶️ AudioController: Same devotional - resuming');
        await resume();
      } else if (isPlaying) {
        debugPrint('⏸️ AudioController: Same devotional - pausing');
        await pause();
      } else {
        // Idle or error - start playing
        debugPrint(
            '🎵 AudioController: Same devotional - starting (was idle/error)');
        await playDevotional(devocional);
      }
    } else {
      // Different devotional - start new playback
      debugPrint('🎵 AudioController: Different devotional - starting new');
      await playDevotional(devocional);
    }

    debugPrint('Devotional read attempt: ${devocional.id}');
  }

  // ========== TTS SERVICE WRAPPER METHODS ==========

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

  // ========== DEBUG METHODS ==========

  /// Get current state info for debugging
  String getDebugInfo() {
    return '''
AudioController Debug Info:
- State: $_currentState
- Current ID: $_currentDevocionalId
- Progress: ${(_progress * 100).toInt()}%
- Is Playing: $isPlaying
- Is Paused: $isPaused
- Is Active: $isActive
''';
  }

  /// Print debug info
  void printDebugInfo() {
    debugPrint(getDebugInfo());
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
