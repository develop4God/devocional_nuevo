import 'dart:async';

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter/widgets.dart';

/// AudioController mejorado para soporte de progreso y navegación de chunks
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

  /// Devuelve true si el devocional específico está activo
  bool isDevocionalPlaying(String devocionalId) {
    final result = _currentDevocionalId == devocionalId && isActive;
    debugPrint(
        '🔍 AudioController: isDevocionalPlaying($devocionalId) = $result (currentId: $_currentDevocionalId, isActive: $isActive, currentState: $_currentState)');
    return result;
  }

  /// Chunk actual y total expuestos para la UI
  int? get currentChunkIndex => _ttsService.currentChunkIndex;

  int? get totalChunks => _ttsService.totalChunks;

  /// Métodos para avanzar/retroceder chunk (devuelven null si no implementados)
  VoidCallback? get previousChunk => _ttsService.previousChunk;

  VoidCallback? get nextChunk => _ttsService.nextChunk;

  /// Método para saltar a un chunk específico
  Future<void> Function(int index)? get jumpToChunk => _ttsService.jumpToChunk;

  /// Inicializa el controller y las suscripciones
  void initialize() {
    debugPrint('🎵 AudioController: Initializing...');

    _stateSubscription = _ttsService.stateStream.listen(
      (state) {
        debugPrint('🔄 AudioController: State changed to $state');
        _currentState = state;
        // Solo actualizar currentDevocionalId si el TtsService tiene un valor válido
        if (_ttsService.currentDevocionalId != null) {
          _currentDevocionalId = _ttsService.currentDevocionalId;
        }
        debugPrint(
            '🔍 AudioController: Current ID after state change: $_currentDevocionalId, isActive: $isActive');
        notifyListeners();
      },
    );

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

  /// Play a devotional (delegates to TtsService)
  Future<void> playDevotional(Devocional devocional) async {
    try {
      debugPrint('🎵 AudioController: Playing ${devocional.id}');
      debugPrint(
          '🔍 AudioController: BEFORE - currentState: $_currentState, currentId: $_currentDevocionalId, isActive: $isActive');

      _currentDevocionalId = devocional.id;
      _currentState = TtsState.playing;

      debugPrint(
          '🔍 AudioController: AFTER setting state - currentState: $_currentState, currentId: $_currentDevocionalId, isActive: $isActive');

      notifyListeners();
      debugPrint('📢 AudioController: notifyListeners() called');

      await _ttsService.speakDevotional(devocional);
      debugPrint('✅ AudioController: TtsService.speakDevotional() completed');
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

  /// TTS wrapper methods
  Future<List<String>> getAvailableLanguages() async {
    try {
      return await _ttsService.getLanguages();
    } catch (e) {
      debugPrint('❌ AudioController: Error getting languages: $e');
      return [];
    }
  }

  Future<void> setLanguage(String language) async {
    try {
      await _ttsService.setLanguage(language);
    } catch (e) {
      debugPrint('❌ AudioController: Error setting language: $e');
      rethrow;
    }
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      await _ttsService.setSpeechRate(rate);
    } catch (e) {
      debugPrint('❌ AudioController: Error setting speech rate: $e');
      rethrow;
    }
  }

  /// Debug info
  String getDebugInfo() {
    return '''
AudioController Debug Info:
- State: $_currentState
- Current ID: $_currentDevocionalId
- Progress: ${(_progress * 100).toInt()}%
- Is Playing: $isPlaying
- Is Paused: $isPaused
- Is Active: $isActive
- Chunk: ${currentChunkIndex ?? '-'} / ${totalChunks ?? '-'}
''';
  }

  void printDebugInfo() {
    debugPrint(getDebugInfo());
  }

  @override
  void dispose() {
    debugPrint('🧹 AudioController: Disposing...');
    _stateSubscription?.cancel();
    _progressSubscription?.cancel();
    _ttsService.dispose();
    super.dispose();
    debugPrint('✅ AudioController: Disposed');
  }
}
