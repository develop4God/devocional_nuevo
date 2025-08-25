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

  // Timer para timeout de operaciones
  Timer? _operationTimeoutTimer;

  // Variable para verificar si el controller está montado
  bool mounted = true;

  // Getters públicos
  TtsState get currentState => _currentState;

  String? get currentDevocionalId => _currentDevocionalId;

  double get progress => _progress;

  bool get isPlaying => _currentState == TtsState.playing;

  bool get isPaused => _currentState == TtsState.paused;

  bool get isLoading =>
      _currentState == TtsState.initializing || _operationInProgress;

  bool get hasError => _currentState == TtsState.error;

  // FIX: Lógica de isActive simplificada y más clara
  bool get isActive =>
      _currentState == TtsState.playing || _currentState == TtsState.paused;

  // Getter for TTS service to allow language context updates
  TtsService get ttsService => _ttsService;

  /// FIX: Verifica si un devocional específico está activo - LÓGICA CORREGIDA
  bool isDevocionalPlaying(String devocionalId) {
    // FIX CRÍTICO: Leer directamente del servicio para evitar cache stale
    final serviceState = _ttsService.currentState;
    final serviceId = _ttsService.currentDevocionalId;

    debugPrint(
        'AudioController: isDevocionalPlaying($devocionalId) - Checking...');
    debugPrint(
        '  Local: currentId=$_currentDevocionalId, state=$_currentState, isActive=$isActive, operationInProgress=$_operationInProgress');
    debugPrint('  Service: currentId=$serviceId, state=$serviceState');

    // CRÍTICO: Si el servicio está en idle, definitivamente NO está reproduciendo
    if (serviceState == TtsState.idle) {
      debugPrint(
          'AudioController: isDevocionalPlaying($devocionalId) = FALSE - SERVICE state is IDLE');
      return false;
    }

    // Si nuestro estado local es idle, también devolver false
    if (_currentState == TtsState.idle) {
      debugPrint(
          'AudioController: isDevocionalPlaying($devocionalId) = FALSE - LOCAL state is IDLE');
      return false;
    }

    // Si hay una operación en progreso para este devocional, considerarlo activo
    if (_operationInProgress &&
        (_currentDevocionalId == devocionalId || serviceId == devocionalId)) {
      debugPrint(
          'AudioController: isDevocionalPlaying($devocionalId) = TRUE - operation in progress');
      return true;
    }

    // Verificar tanto el estado local como el del servicio
    final localMatch = _currentDevocionalId == devocionalId && isActive;
    final serviceMatch = serviceId == devocionalId &&
        (serviceState == TtsState.playing || serviceState == TtsState.paused);

    final result = localMatch || serviceMatch;

    debugPrint(
        'AudioController: isDevocionalPlaying($devocionalId) = $result (localMatch: $localMatch, serviceMatch: $serviceMatch)');
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
        _updateStateFromService(state);
      },
    );

    // Escuchar cambios de progreso
    _progressSubscription = _ttsService.progressStream.listen(
      (progress) {
        // FIX CRÍTICO: Verificar estado del servicio directamente para evitar stale cache
        final serviceState = _ttsService.currentState;

        if (_currentState == TtsState.idle || serviceState == TtsState.idle) {
          debugPrint(
              'AudioController: Ignorando progress update - estado idle (local: $_currentState, service: $serviceState)');
          _progress = 0.0; // aseguramos reset
          return;
        }

        debugPrint(
            'AudioController: Progress updated: ${(progress * 100).toInt()}%');
        _progress = progress;

        // Al llegar al 100%, solo notificar - el state stream manejará el reset
        if (progress >= 1.0) {
          debugPrint(
              'AudioController: 🚨 Progreso 100% - esperando state change a idle');
        }

        notifyListeners();
      },
      onError: (error) {
        debugPrint('AudioController: Progress stream error: $error');
      },
    );

    debugPrint('AudioController: Reactive proxy initialized');

    // FIX: Sincronización periódica como respaldo
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _forceSyncWithService();
    });
  }

  /// FIX CRÍTICO: Actualiza el estado inmediatamente y síncronamente
  void _updateStateFromService(TtsState state, {String? devocionalId}) {
    final oldState = _currentState;

    debugPrint(
        'AudioController: State update START - OLD: $oldState -> NEW: $state');
    debugPrint(
        'AudioController: BEFORE reset - currentId: $_currentDevocionalId, isActive: $isActive, operationInProgress: $_operationInProgress');

    // FIX: ACTUALIZAR ESTADO INMEDIATAMENTE - SIN DELAY
    _currentState = state;

    // FIX: Reset completo cuando llega a idle - INMEDIATO Y FORZADO
    if (state == TtsState.idle) {
      debugPrint('AudioController: IMMEDIATE idle reset');

      // Reset inmediato y síncrono - FORZAR TODAS LAS VARIABLES
      _currentDevocionalId = null;
      _progress = 0.0;
      _operationInProgress = false;
      _operationTimeoutTimer?.cancel();
      _operationTimeoutTimer = null;

      // FIX: Forzar actualización del estado una vez más para asegurar
      _currentState = TtsState.idle;

      // FIX: Verificar que el reset fue efectivo INMEDIATAMENTE
      final verifyActive = (_currentState == TtsState.playing ||
          _currentState == TtsState.paused);
      debugPrint(
          'AudioController: AFTER idle reset - currentId: $_currentDevocionalId, currentState: $_currentState, isActive: $verifyActive, operationInProgress: $_operationInProgress');

      // FIX: Si la verificación falla, forzar reset nuevamente
      if (verifyActive ||
          _currentDevocionalId != null ||
          _operationInProgress) {
        debugPrint('AudioController: 🚨 RESET FAILED - forcing again');
        _currentState = TtsState.idle;
        _currentDevocionalId = null;
        _progress = 0.0;
        _operationInProgress = false;
      }

      // Notificación inmediata
      notifyListeners();

      // FIX: Notificación adicional con microtask para asegurar propagación
      scheduleMicrotask(() {
        if (mounted) {
          debugPrint('AudioController: Microtask notification for idle reset');
          notifyListeners();
        }
      });

      return; // ❌ SALIR INMEDIATAMENTE, no más callbacks
    }

    // Para otros estados, manejar operationInProgress
    if (_shouldResetOperationInProgress(state, oldState)) {
      _resetOperationInProgress();
      return; // ya notifica en _resetOperationInProgress
    } else {
      _operationInProgress = false;
    }

    // Actualizar ID si se proporciona
    if (devocionalId != null) {
      _currentDevocionalId = devocionalId;
    }

    debugPrint(
        'AudioController: State synchronized - currentId: $_currentDevocionalId, '
        'isActive: $isActive, operationInProgress: $_operationInProgress, '
        'currentState: $_currentState');

    notifyListeners();
  }

  /// Determina si se debe resetear _operationInProgress
  bool _shouldResetOperationInProgress(TtsState newState, TtsState oldState) {
    // Resetear cuando llegamos a un estado estable
    if (newState == TtsState.playing ||
        newState == TtsState.paused ||
        newState == TtsState.error) {
      return _operationInProgress;
    }
    return false;
  }

  /// Inicia una operación con timeout
  void _startOperation(String operationName) {
    debugPrint('AudioController: Starting operation: $operationName');
    _operationInProgress = true;

    // Cancelar timer anterior si existe
    _operationTimeoutTimer?.cancel();

    // Timeout de seguridad
    _operationTimeoutTimer = Timer(const Duration(seconds: 5), () {
      if (_operationInProgress) {
        debugPrint(
            'AudioController: Operation timeout reached, resetting state');
        _resetOperationInProgress();
      }
    });

    notifyListeners();
  }

  /// Resetea el estado de operación en progreso
  void _resetOperationInProgress() {
    if (_operationInProgress) {
      debugPrint('AudioController: Resetting operationInProgress');
      _operationInProgress = false;
      _operationTimeoutTimer?.cancel();
      _operationTimeoutTimer = null;
      notifyListeners();
    }
  }

  /// FIX: Sincronización mejorada con detección de idle
  void _forceSyncWithService() {
    if (!mounted) return;

    final serviceState = _ttsService.currentState;
    final serviceId = _ttsService.currentDevocionalId;
    bool needsUpdate = false;

    if (serviceState != _currentState) {
      debugPrint(
          'AudioController: Force syncing state: $_currentState -> $serviceState');

      // FIX: Si el servicio está en idle, hacer reset inmediato
      if (serviceState == TtsState.idle) {
        debugPrint(
            'AudioController: Force sync - service is idle, doing immediate reset');
        _updateStateFromService(serviceState);
        return; // Salir inmediatamente
      }

      final oldState = _currentState;
      _currentState = serviceState;
      needsUpdate = true;

      // Resetear operationInProgress si el servicio ya está estable
      if (_shouldResetOperationInProgress(serviceState, oldState)) {
        _resetOperationInProgress();
        return; // notifyListeners ya fue llamado en _resetOperationInProgress
      }
    }

    if (serviceId != null &&
        serviceId != _currentDevocionalId &&
        serviceState != TtsState.idle) {
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
      debugPrint('🎵 AudioController: playDevotional(${devocional.id}) called');
      debugPrint(
          '🎵 Current state before play: currentId=$_currentDevocionalId, state=$_currentState, isActive=$isActive');

      _startOperation('playDevotional');
      _currentDevocionalId = devocional.id;

      // Delegar completamente al servicio
      await _ttsService.speakDevotional(devocional);
      debugPrint('AudioController: TtsService.speakDevotional() completed');

      // Intentos de sincronización con timeout más corto
      for (int i = 0; i < 5; i++) {
        await Future.delayed(Duration(milliseconds: 50 * (i + 1)));
        final serviceState = _ttsService.currentState;

        debugPrint(
            'AudioController: Sync attempt ${i + 1}: service=$serviceState, local=$_currentState');

        if (serviceState == TtsState.playing) {
          _updateStateFromService(serviceState);
          break;
        }

        if (serviceState != _currentState) {
          _updateStateFromService(serviceState);
          if (serviceState == TtsState.playing ||
              serviceState == TtsState.paused) {
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('AudioController: Error playing devotional: $e');
      _resetOperationInProgress();
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
      _startOperation('pause');

      await _ttsService.pause();

      // Esperar confirmación del estado
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        final serviceState = _ttsService.currentState;

        if (serviceState == TtsState.paused) {
          debugPrint('AudioController: Pause confirmed by service');
          _updateStateFromService(serviceState);
          break;
        }
      }
    } catch (e) {
      debugPrint('AudioController: Pause error: $e');
      _resetOperationInProgress();
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
      _startOperation('resume');

      await _ttsService.resume();

      // Esperar confirmación del estado
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        final serviceState = _ttsService.currentState;

        if (serviceState == TtsState.playing) {
          debugPrint('AudioController: Resume confirmed by service');
          _updateStateFromService(serviceState);
          break;
        }
      }
    } catch (e) {
      debugPrint('AudioController: Resume error: $e');
      _resetOperationInProgress();
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
      _startOperation('stop');

      await _ttsService.stop();

// Pequeno delay para asegurar que el estado idle se propague bien
      await Future.delayed(const Duration(milliseconds: 200));

// Esperar confirmación del estado
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        final serviceState = _ttsService.currentState;

        if (serviceState == TtsState.idle) {
          debugPrint('AudioController: Stop confirmed by service');
          _updateStateFromService(serviceState);
          break;
        }
      }
    } catch (e) {
      debugPrint('AudioController: Stop error: $e');
      _resetOperationInProgress();
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

    if (currentId != null &&
        currentId == devocional.id &&
        _currentState != TtsState.idle) {
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
      // Si hay una reproducción activa y el devocional es diferente, detener primero
      if (currentId != null && currentId != devocional.id && isActive) {
        debugPrint(
            'AudioController: Stopping current devotional before starting new');
        await stop(); // Esperar que se detenga antes de iniciar nuevo
      }
      // Luego iniciar la reproducción del nuevo devocional
      debugPrint(
          'AudioController: Different devotional or idle state - starting new');
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

  // FIX: Metodo público para forzar parada desde el exterior
  Future<void> forceStop() async {
    debugPrint('AudioController: Force stop requested');
    if (isActive) {
      await stop();
    }
  }

  // FIX: Metodo para notificar cambio de contexto desde el widget
  void notifyContextChange(String devocionalId) {
    debugPrint(
        'AudioController: Context change notification for $devocionalId');

    if (_currentDevocionalId != null &&
        _currentDevocionalId != devocionalId &&
        isActive) {
      debugPrint('AudioController: Auto-stopping due to context change');

      // Usar microtask para evitar problemas de concurrencia
      scheduleMicrotask(() async {
        await stop();
      });
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
    _operationTimeoutTimer?.cancel();
    _stateSubscription?.cancel();
    _progressSubscription?.cancel();
    _ttsService.dispose();
    super.dispose();
    debugPrint('AudioController: Reactive proxy disposed');
  }
}
