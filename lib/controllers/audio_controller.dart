import 'dart:async';

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter/widgets.dart';

/// AudioController refactorizado como proxy reactivo puro
/// Eliminado estado local duplicado - solo retransmite estados del TtsService
class AudioController extends ChangeNotifier {
  final TtsService _ttsService = TtsService();

  // Subscriptions para actualizaciones reactivas
  StreamSubscription<TtsState>? _stateSubscription;
  StreamSubscription<double>? _progressSubscription;

  // Estados cacheados del servicio (solo lectura, no modificables localmente)
  TtsState _currentState = TtsState.idle;
  String? _currentDevocionalId;
  double _progress = 0.0;

  // Estado de operación en curso (para UX de loading)
  bool _operationInProgress = false;

  // Getters públicos
  TtsState get currentState => _currentState;

  String? get currentDevocionalId => _currentDevocionalId;

  double get progress => _progress;

  bool get isPlaying => _currentState == TtsState.playing;

  bool get isPaused => _currentState == TtsState.paused;

  bool get isLoading =>
      _currentState == TtsState.initializing || _operationInProgress;

  bool get hasError => _currentState == TtsState.error;

  // FIX: Mejorar la lógica de isActive para considerar operaciones en progreso
  bool get isActive =>
      isPlaying ||
      isPaused ||
      (_operationInProgress && _currentDevocionalId != null);

  /// Verifica si un devocional específico está activo
  bool isDevocionalPlaying(String devocionalId) {
    // FIX: Mejorar la lógica para detectar cuando un devocional está realmente activo
    final currentId = _currentDevocionalId;
    final result = currentId != null &&
        currentId == devocionalId &&
        (isActive || _operationInProgress);
    debugPrint(
        'AudioController: isDevocionalPlaying($devocionalId) = $result (currentId: $currentId, isActive: $isActive, operationInProgress: $_operationInProgress, currentState: $_currentState)');
    return result;
  }

  /// Propiedades de navegación de chunks (delegadas al servicio)
  int? get currentChunkIndex => _ttsService.currentChunkIndex;

  int? get totalChunks => _ttsService.totalChunks;

  VoidCallback? get previousChunk => _ttsService.previousChunk;

  VoidCallback? get nextChunk => _ttsService.nextChunk;

  Future<void> Function(int index)? get jumpToChunk => _ttsService.jumpToChunk;

  /// Inicialización del controller
  void initialize() {
    debugPrint('AudioController: Initializing reactive proxy...');

    // Escuchar cambios de estado del servicio
    _stateSubscription = _ttsService.stateStream.listen(
      (state) {
        debugPrint('AudioController: Service state changed to $state');
        final oldState = _currentState;
        _currentState = state;

        // Sincronizar ID del devocional desde el servicio SOLO si está disponible
        final serviceId = _ttsService.currentDevocionalId;
        if (serviceId != null) {
          _currentDevocionalId = serviceId;
        }

        // FIX: Resetear operationInProgress cuando el estado se estabiliza
        if (state == TtsState.playing ||
            state == TtsState.paused ||
            state == TtsState.error) {
          if (_operationInProgress) {
            debugPrint(
                'AudioController: Resetting operationInProgress - state stabilized at $state');
            _operationInProgress = false;
          }
        } else if (state == TtsState.idle &&
            oldState != TtsState.idle &&
            !_operationInProgress) {
          _operationInProgress = false;
        }

        debugPrint(
            'AudioController: State synchronized - currentId: $_currentDevocionalId, isActive: $isActive, operationInProgress: $_operationInProgress');
        notifyListeners();
      },
    );

    // Escuchar cambios de progreso
    _progressSubscription = _ttsService.progressStream.listen(
      (progress) {
        debugPrint(
            'AudioController: Progress updated: ${(progress * 100).toInt()}%');
        _progress = progress;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('AudioController: Progress stream error: $error');
      },
    );

    debugPrint('AudioController: Reactive proxy initialized');

    // FIX: Agregar sincronización periódica como respaldo con menor frecuencia
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _forceSyncWithService();
    });
  }

  // Variable para verificar si el controller está montado
  bool mounted = true;

  /// Sincroniza forzadamente el estado con el servicio TTS
  void _forceSyncWithService() {
    if (!mounted) return;

    final serviceState = _ttsService.currentState;
    final serviceId = _ttsService.currentDevocionalId;

    bool needsUpdate = false;

    if (serviceState != _currentState) {
      debugPrint(
          'AudioController: Force syncing state: $_currentState -> $serviceState');
      _currentState = serviceState;
      needsUpdate = true;

      // Resetear operationInProgress si el servicio ya está estable
      if (serviceState == TtsState.playing || serviceState == TtsState.paused) {
        if (_operationInProgress) {
          debugPrint(
              'AudioController: Resetting operationInProgress due to stable state');
          _operationInProgress = false;
        }
      }
    }

    if (serviceId != null && serviceId != _currentDevocionalId) {
      debugPrint(
          'AudioController: Force syncing devotional ID: $_currentDevocionalId -> $serviceId');
      _currentDevocionalId = serviceId;
      needsUpdate = true;
    }

    if (needsUpdate) {
      debugPrint(
          'AudioController: Force update triggered - currentState: $_currentState, operationInProgress: $_operationInProgress');
      notifyListeners();
    }
  }

  /// Reproducir devocional - Operación asíncrona pura
  Future<void> playDevotional(Devocional devocional) async {
    try {
      debugPrint('AudioController: Starting playback for ${devocional.id}');

      // Activar indicador de operación en progreso para UX
      _operationInProgress = true;
      // CRÍTICO: Asignar el ID inmediatamente para evitar desincronización
      _currentDevocionalId = devocional.id;
      notifyListeners();

      // Delegar completamente al servicio - NO asignar estado local
      await _ttsService.speakDevotional(devocional);

      debugPrint('AudioController: TtsService.speakDevotional() completed');

      // FIX: Múltiples intentos de sincronización para asegurar que funcione
      for (int i = 0; i < 3; i++) {
        await Future.delayed(Duration(milliseconds: 100 * (i + 1)));
        final serviceState = _ttsService.currentState;
        debugPrint(
            'AudioController: Sync attempt ${i + 1}: service=$serviceState, local=$_currentState');

        if (serviceState != _currentState) {
          debugPrint(
              'AudioController: Forcing state sync from service: $_currentState -> $serviceState');
          _currentState = serviceState;
          if (serviceState == TtsState.playing ||
              serviceState == TtsState.paused) {
            _operationInProgress = false;
          }
          notifyListeners();
          break; // Salir si conseguimos sincronizar
        }

        if (serviceState == TtsState.playing) {
          break; // Si ya está playing, no necesitamos más intentos
        }
      }
    } catch (e) {
      debugPrint('AudioController: Error playing devotional: $e');
      _operationInProgress = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Pausar reproducción
  Future<void> pause() async {
    if (!isPlaying) {
      debugPrint(
          'AudioController: Cannot pause - not playing (state: $_currentState)');
      return;
    }

    try {
      debugPrint('AudioController: Requesting pause...');
      _operationInProgress = true;
      notifyListeners();

      await _ttsService.pause();
    } catch (e) {
      debugPrint('AudioController: Pause error: $e');
      _operationInProgress = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Reanudar reproducción
  Future<void> resume() async {
    if (!isPaused) {
      debugPrint(
          'AudioController: Cannot resume - not paused (state: $_currentState)');
      return;
    }

    try {
      debugPrint('AudioController: Requesting resume...');
      _operationInProgress = true;
      notifyListeners();

      await _ttsService.resume();
    } catch (e) {
      debugPrint('AudioController: Resume error: $e');
      _operationInProgress = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Detener reproducción
  Future<void> stop() async {
    if (!isActive) {
      debugPrint('AudioController: Nothing to stop (state: $_currentState)');
      return;
    }

    try {
      debugPrint('AudioController: Requesting stop...');
      _operationInProgress = true;
      notifyListeners();

      await _ttsService.stop();
    } catch (e) {
      debugPrint('AudioController: Stop error: $e');
      _operationInProgress = false;
      notifyListeners();
    }
  }

  /// Toggle play/pause para un devocional
  Future<void> togglePlayPause(Devocional devocional) async {
    final currentId = _currentDevocionalId;
    debugPrint(
        'AudioController: Toggle for ${devocional.id} (current: $currentId, state: $_currentState)');

    // Prevenir operaciones concurrentes
    if (_operationInProgress) {
      debugPrint(
          'AudioController: Operation already in progress, ignoring toggle');
      return;
    }

    if (currentId != null && currentId == devocional.id) {
      // Mismo devocional - alternar play/pause
      if (isPaused) {
        debugPrint('AudioController: Same devotional - resuming');
        await resume();
      } else if (isPlaying) {
        debugPrint('AudioController: Same devotional - pausing');
        await pause();
      } else {
        // Estado idle o error - reiniciar
        debugPrint(
            'AudioController: Same devotional - restarting (was idle/error)');
        await playDevotional(devocional);
      }
    } else {
      // Devocional diferente - iniciar nueva reproducción
      debugPrint('AudioController: Different devotional - starting new');
      await playDevotional(devocional);
    }

    debugPrint('Devotional read attempt: ${devocional.id}');
  }

  /// Métodos de configuración TTS (delegados al servicio)
  Future<List<String>> getAvailableLanguages() async {
    try {
      return await _ttsService.getLanguages();
    } catch (e) {
      debugPrint('AudioController: Error getting languages: $e');
      return [];
    }
  }

  Future<void> setLanguage(String language) async {
    try {
      await _ttsService.setLanguage(language);
    } catch (e) {
      debugPrint('AudioController: Error setting language: $e');
      rethrow;
    }
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      await _ttsService.setSpeechRate(rate);
    } catch (e) {
      debugPrint('AudioController: Error setting speech rate: $e');
      rethrow;
    }
  }

  /// Información de debug
  String getDebugInfo() {
    final currentId = _currentDevocionalId;
    final chunkIndex = currentChunkIndex;
    final totalChunksCount = totalChunks;
    final serviceActive = _ttsService.isActive;

    return '''
AudioController Debug Info (Reactive Proxy):
- Service State: $_currentState
- Current ID: $currentId
- Operation In Progress: $_operationInProgress
- Progress: ${(_progress * 100).toInt()}%
- Is Playing: $isPlaying
- Is Paused: $isPaused
- Is Loading: $isLoading
- Is Active: $isActive
- Chunk: ${chunkIndex ?? '-'} / ${totalChunksCount ?? '-'}
- Service Active: $serviceActive
''';
  }

  void printDebugInfo() {
    debugPrint(getDebugInfo());
  }

  @override
  void dispose() {
    debugPrint('AudioController: Disposing reactive proxy...');
    mounted = false;
    _stateSubscription?.cancel();
    _progressSubscription?.cancel();
    _ttsService.dispose();
    super.dispose();
    debugPrint('AudioController: Reactive proxy disposed');
  }
}
