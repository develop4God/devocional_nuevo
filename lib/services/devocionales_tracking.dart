import 'dart:async';

import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/in_app_review_service.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
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

  // ScrollController del devocional actual

  // Singleton pattern
  static final DevocionalesTracking _instance =
      DevocionalesTracking._internal();

  factory DevocionalesTracking() => _instance;

  DevocionalesTracking._internal();

  /// Inicializa el servicio de tracking con el contexto necesario
  void initialize(BuildContext context) {
    _context = context;
    debugPrint('🔄 DevocionalesTracking initialized');
  }

  /// Inicia el timer de evaluación de criterios
  void startCriteriaCheckTimer() {
    _criteriaCheckTimer?.cancel();
    _criteriaCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkReadingCriteria();
    });
    debugPrint('🔄 Criteria check timer started');
  }

  /// Detiene el timer de evaluación de criterios
  void stopCriteriaCheckTimer() {
    _criteriaCheckTimer?.cancel();
    debugPrint('🔄 Criteria check timer stopped');
  }

  /// Inicia el tracking para un devocional específico
  void startDevocionalTracking(
      String devocionalId, ScrollController scrollController) {
    if (_context == null) {
      debugPrint('❌ DevocionalesTracking not initialized');
      return;
    }

    final devocionalProvider = Provider.of<DevocionalProvider>(
      _context!,
      listen: false,
    );

    devocionalProvider.startDevocionalTracking(
      devocionalId,
      scrollController: scrollController,
    );

    debugPrint('📖 Started tracking for devotional: $devocionalId');
  }

  /// Evalúa criterios de lectura automáticamente
  void _checkReadingCriteria() {
    if (_context == null || !_context!.mounted) return;

    final devocionalProvider = Provider.of<DevocionalProvider>(
      _context!,
      listen: false,
    );

    final devocionales = devocionalProvider.devocionales;
    if (devocionales.isEmpty) return;

    // Obtener el ID del devocional actualmente siendo tracked
    final currentDevocionalId = devocionalProvider.currentTrackedDevocionalId;
    if (currentDevocionalId == null) return;

    final currentDevocional = devocionales.firstWhere(
      (d) => d.id == currentDevocionalId,
      orElse: () => devocionales.first,
    );

    // Si este devocional ya fue auto-completado, no evaluar de nuevo
    if (_autoCompletedDevocionals.contains(currentDevocional.id)) {
      return;
    }

    // Obtener datos de tracking del provider
    final readingTime = devocionalProvider.currentReadingSeconds;
    final scrollPercentage = devocionalProvider.currentScrollPercentage;

    debugPrint('Devotional read attempt: ${currentDevocional.id}');
    debugPrint(
        'Reading time: ${readingTime}s, Scroll: ${(scrollPercentage * 100).toStringAsFixed(1)}%');

    final meetsCriteria = readingTime >= 60 && scrollPercentage >= 0.8;
    debugPrint('Meets criteria: $meetsCriteria');

    if (meetsCriteria) {
      debugPrint('✅ Criteria met automatically - updating stats immediately');
      _updateReadingStats(currentDevocional.id);
    }
  }

  /// Actualiza estadísticas inmediatamente cuando se cumplen los criterios
  void _updateReadingStats(String devocionalId) async {
    if (_context == null || !_context!.mounted) return;

    final devocionalProvider = Provider.of<DevocionalProvider>(
      _context!,
      listen: false,
    );

    // Marcar como auto-completado para evitar evaluaciones repetidas
    _autoCompletedDevocionals.add(devocionalId);

    // Registrar la lectura inmediatamente
    devocionalProvider.recordDevocionalRead(devocionalId);

    // FORZAR ACTUALIZACIÓN INMEDIATA DE LA UI
    devocionalProvider.forceUIUpdate();

    debugPrint('📊 Stats updated automatically for: $devocionalId');
    debugPrint('🔄 UI update forced via provider notification');

    // Check for in-app review opportunity - AUTOMATIC COMPLETION PATH
    try {
      // Add small delay to ensure stats are persisted before checking
      await Future.delayed(const Duration(milliseconds: 100));

      final stats = await SpiritualStatsService().getStats();
      debugPrint(
          '🎯 Auto-completion review check: ${stats.totalDevocionalesRead} devotionals');

      if (_context?.mounted == true) {
        await InAppReviewService.checkAndShow(stats, _context!);
      }
    } catch (e) {
      debugPrint('❌ Error checking in-app review (auto-completion): $e');
      // Fail silently - review errors should not affect devotional recording
    }
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
        '🧹 Auto-completed devotionals cleared except: $keepDevocionalId');
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

    final devocionalProvider = Provider.of<DevocionalProvider>(
      _context!,
      listen: false,
    );

    devocionalProvider.resumeTracking();
    startCriteriaCheckTimer();
    debugPrint('▶️ Tracking resumed');
  }

  /// Registra manualmente la lectura de un devocional
  void recordDevocionalRead(String devocionalId) async {
    if (_context == null) return;

    final devocionalProvider = Provider.of<DevocionalProvider>(
      _context!,
      listen: false,
    );

    // Registrar la lectura inmediatamente
    devocionalProvider.recordDevocionalRead(devocionalId);
    debugPrint('📊 Manual reading recorded for: $devocionalId');

    // Check for in-app review opportunity - MANUAL COMPLETION PATH
    try {
      // Add delay to ensure stats are persisted before checking
      await Future.delayed(const Duration(milliseconds: 100));

      final stats = await SpiritualStatsService().getStats();
      debugPrint(
          '🎯 Manual completion review check: ${stats.totalDevocionalesRead} devotionals');

      if (_context?.mounted == true) {
        await InAppReviewService.checkAndShow(stats, _context!);
      }
    } catch (e) {
      debugPrint('❌ Error checking in-app review (manual completion): $e');
      // Fail silently - review errors should not affect devotional recording
    }
  }

  /// Verifica si un devocional fue auto-completado
  bool isAutoCompleted(String devocionalId) {
    return _autoCompletedDevocionals.contains(devocionalId);
  }

  /// Limpia recursos al destruir el servicio
  void dispose() {
    _criteriaCheckTimer?.cancel();
    _autoCompletedDevocionals.clear();
    _context = null;
    debugPrint('🗑️ DevocionalesTracking disposed');
  }
}
