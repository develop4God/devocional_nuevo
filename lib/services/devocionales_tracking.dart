import 'dart:async';
import 'dart:developer' as developer;

import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/in_app_review_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:devocional_nuevo/utils/analytics_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Servicio para manejar el tracking automático de devocionales
/// Evalúa criterios de lectura (tiempo + scroll) y registra estadísticas automáticamente
class DevocionalesTracking {
  // Timer para evaluación periódica de criterios
  Timer? _criteriaCheckTimer;

  // Set para rastrear devocionales que ya cumplieron criterios automáticamente
  final Set<String> _autoCompletedDevocionals = {};

  // Context para acceder al provider
  BuildContext? _context;

  // Lazy-initialized analytics service
  AnalyticsService? _analyticsService;

  // Getter with lazy initialization
  AnalyticsService? get _analytics {
    if (_analyticsService == null) {
      try {
        _analyticsService = getService<AnalyticsService>();
      } catch (e) {
        debugPrint('⚠️ Analytics service not available: $e');
        return null;
      }
    }
    return _analyticsService;
  }

  // ScrollController del devocional actual

  // Singleton pattern
  static final DevocionalesTracking _instance =
      DevocionalesTracking._internal();

  factory DevocionalesTracking() => _instance;

  DevocionalesTracking._internal();

  /// Inicializa el servicio de tracking con el contexto necesario
  void initialize(BuildContext context) {
    _context = context;
    debugPrint('[TRACKING] 🔄 DevocionalesTracking inicializando...');

    // Test simple: verificar que los timers funcionen
    Timer(const Duration(seconds: 2), () {
      debugPrint(
          '[TRACKING] ✅ Timer de prueba funcionó - sistema de timers OK');
    });

    debugPrint('[TRACKING] ✅ DevocionalesTracking inicializado correctamente');
  }

  /// Inicia el timer de evaluación de criterios
  void startCriteriaCheckTimer() {
    _criteriaCheckTimer?.cancel();
    debugPrint('[TRACKING] 🔄 Creando timer de evaluación de criterios...');
    _criteriaCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      debugPrint(
          '[TRACKING] ⏲️ Timer tick #${timer.tick} - evaluando criterios...');
      _checkReadingCriteria();
    });
    final isActive = _criteriaCheckTimer?.isActive ?? false;
    debugPrint(
      '[TRACKING] 🔄 Timer de evaluación de criterios CREADO - isActive: $isActive (cada 5s)',
    );
  }

  /// Detiene el timer de evaluación de criterios
  void stopCriteriaCheckTimer() {
    _criteriaCheckTimer?.cancel();
    debugPrint('[TRACKING] 🛑 Timer de evaluación de criterios DETENIDO');
  }

  /// Inicia el tracking para un devocional específico
  void startDevocionalTracking(
    String devocionalId,
    ScrollController scrollController,
  ) {
    debugPrint(
      '[TRACKING] 🚀 startDevocionalTracking() llamado para $devocionalId',
    );

    if (_context == null) {
      debugPrint(
          '[TRACKING] ❌ DevocionalesTracking no inicializado (context null)');
      return;
    }

    final devocionalProvider = Provider.of<DevocionalProvider>(
      _context!,
      listen: false,
    );

    debugPrint(
      '[TRACKING] 📊 Antes de start: trackedId=${devocionalProvider.currentTrackedDevocionalId}, segundos=${devocionalProvider.currentReadingSeconds}',
    );

    devocionalProvider.startDevocionalTracking(
      devocionalId,
      scrollController: scrollController,
    );

    // Start criteria check timer when tracking begins
    startCriteriaCheckTimer();

    debugPrint(
        '[TRACKING] 📖 Tracking iniciado para devocional: $devocionalId');

    debugPrint(
      '[TRACKING] 📊 Después de start: trackedId=${devocionalProvider.currentTrackedDevocionalId}, segundos=${devocionalProvider.currentReadingSeconds}',
    );
  }

  /// Evalúa criterios de lectura automáticamente
  void _checkReadingCriteria() {
    debugPrint('[TRACKING] 🔄 _checkReadingCriteria() ejecutándose...');

    if (_context == null || !_context!.mounted) {
      debugPrint('[TRACKING] ❌ Context null o no mounted');
      return;
    }

    final devocionalProvider = Provider.of<DevocionalProvider>(
      _context!,
      listen: false,
    );

    final devocionales = devocionalProvider.devocionales;
    if (devocionales.isEmpty) {
      debugPrint('[TRACKING] ❌ Lista de devocionales vacía');
      return;
    }

    // Obtener el ID del devocional actualmente siendo tracked
    final currentDevocionalId = devocionalProvider.currentTrackedDevocionalId;
    if (currentDevocionalId == null) {
      debugPrint('[TRACKING] ❌ No hay devocional siendo trackeado');
      return;
    }

    final currentDevocional = devocionales.firstWhere(
      (d) => d.id == currentDevocionalId,
      orElse: () => devocionales.first,
    );

    // Si este devocional ya fue auto-completado, no evaluar de nuevo
    if (_autoCompletedDevocionals.contains(currentDevocional.id)) {
      debugPrint(
        '[TRACKING] ⏭️ Devocional ${currentDevocional.id} ya fue auto-completado, saltando evaluación',
      );
      return;
    }

    // Obtener datos de tracking del provider
    final readingTime = devocionalProvider.currentReadingSeconds;
    final scrollPercentage = devocionalProvider.currentScrollPercentage;

    debugPrint(
      '[TRACKING] 📖 Evaluando devocional: ${currentDevocional.id}',
    );
    debugPrint(
      '[TRACKING] ⏱️ Tiempo de lectura: ${readingTime}s, Scroll: ${(scrollPercentage * 100).toStringAsFixed(1)}%',
    );

    final meetsCriteria = readingTime >= 40 && scrollPercentage >= 0.6;
    debugPrint('[TRACKING] ✔️ ¿Cumple criterios?: $meetsCriteria');
    developer.log(
      '[TRACKING] Intento de lectura: ${currentDevocional.id}, tiempo: ${readingTime}s, scroll: ${(scrollPercentage * 100).toStringAsFixed(1)}%',
      name: 'DevocionalesTracking',
    );
    developer.log(
      '[TRACKING] ¿Cumple criterio?: $meetsCriteria',
      name: 'DevocionalesTracking',
    );

    if (meetsCriteria) {
      debugPrint(
        '[TRACKING] ✅ Criterios cumplidos automáticamente - actualizando stats inmediatamente',
      );
      developer.log(
        '[TRACKING] Criterio cumplido, actualizando stats para: ${currentDevocional.id}',
        name: 'DevocionalesTracking',
      );
      _updateReadingStats(currentDevocional.id);
    } else {
      debugPrint(
        '[TRACKING] ⏳ Criterios aún no cumplidos (necesita: 40s y 60% scroll)',
      );
    }
  }

  /// Registra la interacción (lectura o escucha) de un devocional y verifica milestone para review
  Future<void> recordDevocionalInteraction({
    required String devocionalId,
    int readingTimeSeconds = 0,
    double scrollPercentage = 0.0,
    double listenedPercentage = 0.0,
    int? favoritesCount,
    String source = 'unknown', // 'read' o 'heard'
  }) async {
    if (_context == null) return;
    try {
      // Actualizar stats usando el metodo unificado
      final stats = await SpiritualStatsService().recordDevocionalCompletado(
        devocionalId: devocionalId,
        readingTimeSeconds: readingTimeSeconds,
        scrollPercentage: scrollPercentage,
        listenedPercentage: listenedPercentage,
        favoritesCount: favoritesCount,
        source: source,
      );
      debugPrint(
        '📊 [TRACKING] Stats actualizados para $devocionalId (source: $source)',
      );

      // Firebase Analytics: Log devotional completion with campaign_tag
      final analytics = _analytics;
      final campaignTag = AnalyticsConstants.getCampaignTag(
        devocionalId: devocionalId,
        totalDevocionalesRead: stats.totalDevocionalesRead,
      );
      debugPrint(
        '🟢 [ANALYTICS] Validando milestone: totalDevocionalesRead=${stats.totalDevocionalesRead}, campaignTag="$campaignTag"',
      );
      if (analytics != null) {
        try {
          debugPrint(
            '🚀 [ANALYTICS] Enviando evento devotional_read_complete a Firebase con campaignTag="$campaignTag" para devocionalId="$devocionalId"',
          );
          await analytics.logDevocionalComplete(
            devocionalId: devocionalId,
            campaignTag: campaignTag,
            source: source,
            readingTimeSeconds: readingTimeSeconds,
            scrollPercentage: scrollPercentage,
            listenedPercentage: listenedPercentage,
          );
        } catch (e) {
          debugPrint('❌ Error logging devotional complete analytics: $e');
          // Fail silently - analytics should not block functionality
        }
      }

      // Verificar milestone para review
      if (_context?.mounted == true) {
        await InAppReviewService.checkAndShow(stats, _context!);
      }
    } catch (e) {
      debugPrint('❌ Error en recordDevocionalInteraction: $e');
    }
  }

  /// Actualiza estadísticas inmediatamente cuando se cumplen los criterios
  void _updateReadingStats(String devocionalId) async {
    if (_context == null || !_context!.mounted) return;
    final devocionalProvider = Provider.of<DevocionalProvider>(
      _context!,
      listen: false,
    );
    _autoCompletedDevocionals.add(devocionalId);
    // Usar el metodo unificado para registrar lectura y verificar milestone
    await recordDevocionalInteraction(
      devocionalId: devocionalId,
      readingTimeSeconds: devocionalProvider.currentReadingSeconds,
      scrollPercentage: devocionalProvider.currentScrollPercentage,
      source: 'read',
    );
    devocionalProvider.forceUIUpdate();
    debugPrint('📊 Stats updated automatically for: $devocionalId');
    debugPrint('🔄 UI update forced via provider notification');

    // Check for in-app review opportunity - AUTOMATIC COMPLETION PATH
    try {
      // Add small delay to ensure stats are persisted before checking
      await Future.delayed(const Duration(milliseconds: 100));

      final stats = await SpiritualStatsService().getStats();
      debugPrint(
        '🎯 Auto-completion review check: ${stats.totalDevocionalesRead} devotionals',
      );

      if (_context?.mounted == true) {
        await InAppReviewService.checkAndShow(stats, _context!);
      }
    } catch (e) {
      debugPrint('❌ Error checking in-app review (auto-completion): $e');
      // Fail silently - review errors should not affect devotional recording
    }
  }

  /// Registra manualmente la lectura de un devocional
  void recordDevocionalRead(String devocionalId) async {
    if (_context == null) return;
    final devocionalProvider = Provider.of<DevocionalProvider>(
      _context!,
      listen: false,
    );
    // Usar el metodo unificado para registrar lectura y verificar milestone
    await recordDevocionalInteraction(
      devocionalId: devocionalId,
      readingTimeSeconds: devocionalProvider.currentReadingSeconds,
      scrollPercentage: devocionalProvider.currentScrollPercentage,
      source: 'read',
    );
    debugPrint('📊 Manual reading recorded for: $devocionalId');
  }

  /// Nuevo: Registra manualmente la escucha de un devocional (TTS/audio)
  Future<void> recordDevocionalHeard(
    String devocionalId,
    double listenedPercentage,
  ) async {
    if (_context == null) return;
    // Usar el metodo unificado para registrar escucha y verificar milestone
    await recordDevocionalInteraction(
      devocionalId: devocionalId,
      listenedPercentage: listenedPercentage,
      source: 'heard',
    );
    debugPrint(
      '📊 Manual heard recorded for: $devocionalId ($listenedPercentage)',
    );
  }

  /// Limpia el set de auto-completados para permitir nueva evaluación
  void clearAutoCompleted() {
    _autoCompletedDevocionals.clear();
    debugPrint('🧹 Auto-completed devotionals cleared');
  }

  /// Limpia auto-completados excepto el ID especificado
  void clearAutoCompletedExcept(String? keepDevocionalId) {
    if (keepDevocionalId != null &&
        _autoCompletedDevocionals.contains(keepDevocionalId)) {
      // Solo mantener el devocional actual si ya estaba completado
      final temp = {keepDevocionalId};
      _autoCompletedDevocionals.clear();
      _autoCompletedDevocionals.addAll(temp);
    } else {
      _autoCompletedDevocionals.clear();
    }
    debugPrint(
      '🧹 Auto-completed devotionals cleared except: $keepDevocionalId',
    );
  }

  /// Pausa el tracking (cuando la app va a background)
  void pauseTracking() {
    if (_context == null) return;

    final devocionalProvider = Provider.of<DevocionalProvider>(
      _context!,
      listen: false,
    );

    devocionalProvider.pauseTracking();
    stopCriteriaCheckTimer();
    debugPrint('⏸️ Tracking paused');
  }

  /// Reanuda el tracking (cuando la app vuelve de background)
  void resumeTracking() {
    if (_context == null) return;
    debugPrint('[TRACKING] resumeTracking() llamado');
    final devocionalProvider = Provider.of<DevocionalProvider>(
      _context!,
      listen: false,
    );
    debugPrint(
      '[TRACKING] Antes de resume: trackedId=${devocionalProvider.currentTrackedDevocionalId}, segundos=${devocionalProvider.currentReadingSeconds}',
    );

    // Only resume tracking and start timer if there's actually a devotional being tracked
    if (devocionalProvider.currentTrackedDevocionalId != null) {
      devocionalProvider.resumeTracking();
      startCriteriaCheckTimer();
      debugPrint(
          '▶️ Tracking resumed for: ${devocionalProvider.currentTrackedDevocionalId}');
    } else {
      debugPrint('⏭️ No devotional being tracked - skipping resume');
    }

    debugPrint(
      '[TRACKING] Después de resume: trackedId=${devocionalProvider.currentTrackedDevocionalId}, segundos=${devocionalProvider.currentReadingSeconds}',
    );
  }

  /// Limpia recursos al destruir el servicio
  void dispose() {
    _criteriaCheckTimer?.cancel();
    _autoCompletedDevocionals.clear();
    _context = null;
    _analyticsService = null; // Clear analytics service cache
    debugPrint('🗑️ DevocionalesTracking disposed');
  }
}
