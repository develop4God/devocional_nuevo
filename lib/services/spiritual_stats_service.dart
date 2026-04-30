// lib/services/spiritual_stats_service.dart - VERSIÓN CON AUTO-BACKUP
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/spiritual_stats_model.dart';
import 'i_spiritual_stats_service.dart';

class SpiritualStatsService implements ISpiritualStatsService {
  static const String _statsKey = 'spiritual_stats';
  static const String _readDatesKey = 'read_dates';
  static const String _lastReadDevocionalKey = 'last_read_devocional';
  static const String _lastReadTimeKey = 'last_read_time';

  // Configuración para JSON backup
  static const String _jsonBackupEnabledKey = 'json_backup_enabled';
  static const String _jsonBackupFilename = 'spiritual_stats_backup.json';

  /// NUEVO: Habilitar/deshabilitar backup JSON manual
  @override
  Future<void> setJsonBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_jsonBackupEnabledKey, enabled);

    if (enabled) {
      await _createJsonBackup();
    }
  }

  /// Verificar si JSON backup manual está habilitado
  @override
  Future<bool> isJsonBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_jsonBackupEnabledKey) ?? false;
  }

  /// Registrar visita diaria automática al abrir la app
  Future<void> recordDailyAppVisit() async {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final readDates = await _getReadDates();

    final alreadyVisitedToday = readDates.any(
      (date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day,
    );

    if (!alreadyVisitedToday) {
      readDates.add(todayDateOnly);
      await _saveReadDates(readDates);

      // Actualizar racha automáticamente
      final stats = await getStats();
      final newStreak = _calculateCurrentStreak(readDates);

      final updatedStats = stats.copyWith(
        currentStreak: newStreak,
        longestStreak:
            newStreak > stats.longestStreak ? newStreak : stats.longestStreak,
        lastActivityDate: today,
      );

      await saveStats(updatedStats);
      debugPrint('Nueva visita diaria registrada. Racha: $newStreak');
    }
  }

  /// Get current spiritual statistics
  @override
  Future<SpiritualStats> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final String? statsJson = prefs.getString(_statsKey);

    if (statsJson != null) {
      try {
        final Map<String, dynamic> data = json.decode(statsJson);
        return SpiritualStats.fromJson(data);
      } catch (e) {
        debugPrint('Error parsing spiritual stats: $e');
        // Intentar recuperar desde JSON backup manual
        if (await isJsonBackupEnabled()) {
          debugPrint('Intentando recuperar desde JSON backup manual...');
          final backupStats = await _restoreFromJsonBackup();
          if (backupStats != null) {
            await saveStats(backupStats);
            return backupStats;
          }
        }
      }
    }

    return SpiritualStats();
  }

  /// Save spiritual statistics con auto-backup inteligente
  @override
  Future<void> saveStats(SpiritualStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    final String statsJson = json.encode(stats.toJson());
    await prefs.setString(_statsKey, statsJson);
    // Backup JSON manual si está habilitado
    if (await isJsonBackupEnabled()) {
      await _createJsonBackup(stats);
    }
  }

  /// Record that a devotional was read - SOLO cuenta devocionales, NO afecta racha
  @override
  Future<SpiritualStats> recordDevocionalCompletado({
    required String devocionalId,
    int readingTimeSeconds = 0,
    double scrollPercentage = 0.0,
    double listenedPercentage = 0.0,
    int? favoritesCount,
    String source = 'unknown', // 'read', 'heard', etc.
  }) async {
    debugPrint(
      '🎯 [STATS] Iniciando registro de devocional: $devocionalId, fuente: $source',
    );
    final prefs = await SharedPreferences.getInstance();
    final stats = await getStats();

    if (devocionalId.isEmpty) {
      debugPrint('🎯 [STATS] DevocionalId vacío, no se registra');
      return stats;
    }

    final bool meetsReadingCriteria =
        (readingTimeSeconds >= 40 && scrollPercentage >= 0.6) ||
            (listenedPercentage >= 0.6);

    debugPrint(
      '🎯 [STATS] Criterios: tiempo=$readingTimeSeconds, scroll=$scrollPercentage, escuchado=$listenedPercentage, cumple=$meetsReadingCriteria',
    );

    if (stats.readDevocionalIds.contains(devocionalId)) {
      debugPrint('🎯 [STATS] Devocional ya registrado: $devocionalId');
      if (favoritesCount != null) {
        final updatedStats = stats.copyWith(favoritesCount: favoritesCount);
        await saveStats(updatedStats);
        return updatedStats;
      }
      return stats;
    }

    if (!meetsReadingCriteria) {
      debugPrint(
        '🎯 [STATS] Devocional no cumple criterio, no se suma: $devocionalId',
      );
      await prefs.setString(_lastReadDevocionalKey, devocionalId);
      await prefs.setInt(
        _lastReadTimeKey,
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      if (favoritesCount != null) {
        final updatedStats = stats.copyWith(favoritesCount: favoritesCount);
        await saveStats(updatedStats);
        return updatedStats;
      }
      return stats;
    }

    await prefs.setString(_lastReadDevocionalKey, devocionalId);
    await prefs.setInt(
      _lastReadTimeKey,
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final readDates = await _getReadDates();
    final alreadyReadToday = readDates.any(
      (date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day,
    );
    if (!alreadyReadToday) {
      readDates.add(todayDateOnly);
      await _saveReadDates(readDates);
      debugPrint('🎯 [STATS] Nueva fecha de lectura agregada: $todayDateOnly');
    }
    final newStreak = _calculateCurrentStreak(readDates);

    final newReadDevocionalIds = List<String>.from(stats.readDevocionalIds);
    newReadDevocionalIds.add(devocionalId);

    final updatedStats = stats.copyWith(
      totalDevocionalesRead: stats.totalDevocionalesRead + 1,
      currentStreak: newStreak,
      longestStreak:
          newStreak > stats.longestStreak ? newStreak : stats.longestStreak,
      lastActivityDate: today,
      favoritesCount: favoritesCount ?? stats.favoritesCount,
      readDevocionalIds: newReadDevocionalIds,
      unlockedAchievements: _updateAchievements(
        stats,
        newStreak,
        stats.totalDevocionalesRead + 1,
        favoritesCount ?? stats.favoritesCount,
      ),
    );

    await saveStats(updatedStats);
    debugPrint(
      '🎯 [STATS] Devocional guardado: $devocionalId, total ahora: ${updatedStats.totalDevocionalesRead}',
    );
    return updatedStats;
  }

  @override
  Future<SpiritualStats> recordDevocionalRead({
    required String devocionalId,
    int? favoritesCount,
    int readingTimeSeconds = 0,
    double scrollPercentage = 0.0,
  }) async {
    debugPrint('🎯 [STATS] Registro por lectura: $devocionalId');
    return await recordDevocionalCompletado(
      devocionalId: devocionalId,
      readingTimeSeconds: readingTimeSeconds,
      scrollPercentage: scrollPercentage,
      favoritesCount: favoritesCount,
      source: 'read',
    );
  }

  /// Registra que un devocional fue escuchado (para TTS)
  @override
  Future<SpiritualStats> recordDevocionalHeard({
    required String devocionalId,
    required double listenedPercentage,
    int? favoritesCount,
  }) async {
    return await recordDevocionalCompletado(
      devocionalId: devocionalId,
      listenedPercentage: listenedPercentage,
      favoritesCount: favoritesCount,
      source: 'heard',
    );
  }

  /// Crear backup JSON manual
  Future<void> _createJsonBackup([SpiritualStats? stats]) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_jsonBackupFilename');

      stats ??= await getStats();

      final backupData = {
        'version': '1.0.0',
        'backup_type': 'manual',
        'created_at': DateTime.now().toIso8601String(),
        'stats': stats.toJson(),
        'read_dates': await _getReadDatesAsStrings(),
        'preferences': await _getPreferences(),
      };

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(backupData),
      );

      debugPrint('Manual JSON backup created: ${file.path}');
    } catch (e) {
      debugPrint('Error creating manual JSON backup: $e');
    }
  }

  /// Restaurar desde backup JSON manual
  Future<SpiritualStats?> _restoreFromJsonBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_jsonBackupFilename');

      if (!await file.exists()) {
        debugPrint('Manual JSON backup file does not exist');
        return null;
      }

      final jsonString = await file.readAsString();
      final backupData = json.decode(jsonString);

      debugPrint(
        'Restoring from manual JSON backup version: ${backupData['version']}',
      );

      final stats = SpiritualStats.fromJson(backupData['stats']);

      if (backupData['read_dates'] != null) {
        await _restoreReadDates(List<String>.from(backupData['read_dates']));
      }

      if (backupData['preferences'] != null) {
        await _restorePreferences(
          Map<String, dynamic>.from(backupData['preferences']),
        );
      }

      debugPrint('Successfully restored from manual JSON backup');
      return stats;
    } catch (e) {
      debugPrint('Error restoring from manual JSON backup: $e');
      return null;
    }
  }

  /// NUEVO: Obtener información de backups disponibles
  Future<Map<String, dynamic>> getBackupInfo() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final manualBackupExists = await File(
        '${directory.path}/$_jsonBackupFilename',
      ).exists();

      return {
        'manual_backup_enabled': await isJsonBackupEnabled(),
        'manual_backup_exists': manualBackupExists,
      };
    } catch (e) {
      debugPrint('Error getting backup info: $e');
      return {};
    }
  }

  /// NUEVO: Forzar creación de backup manual
  @override
  Future<bool> createManualBackup() async {
    try {
      await _createJsonBackup();
      return true;
    } catch (e) {
      debugPrint('Error creating manual backup: $e');
      return false;
    }
  }

  /// Actualiza el número de favoritos en las estadísticas espirituales
  @override
  Future<SpiritualStats> updateFavoritesCount(int favoritesCount) async {
    final stats = await getStats();
    final updatedStats = stats.copyWith(favoritesCount: favoritesCount);
    await saveStats(updatedStats);
    debugPrint('✅ [STATS] favoritesCount actualizado: $favoritesCount');
    return updatedStats;
  }

  Future<List<String>> _getReadDatesAsStrings() async {
    final readDates = await _getReadDates();
    return readDates
        .map((date) => date.toIso8601String().split('T').first)
        .toList();
  }

  Future<Map<String, dynamic>> _getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      _lastReadDevocionalKey: prefs.getString(_lastReadDevocionalKey),
      _lastReadTimeKey: prefs.getInt(_lastReadTimeKey),
    };
  }

  Future<void> _restoreReadDates(List<String> dateStrings) async {
    try {
      final dates =
          dateStrings.map((dateString) => DateTime.parse(dateString)).toList();
      await _saveReadDates(dates);
    } catch (e) {
      debugPrint('Error restoring read dates: $e');
    }
  }

  Future<void> _restorePreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (preferences[_lastReadDevocionalKey] != null) {
        await prefs.setString(
          _lastReadDevocionalKey,
          preferences[_lastReadDevocionalKey],
        );
      }

      if (preferences[_lastReadTimeKey] != null) {
        await prefs.setInt(_lastReadTimeKey, preferences[_lastReadTimeKey]);
      }
    } catch (e) {
      debugPrint('Error restoring preferences: $e');
    }
  }

  @override
  Future<String?> exportStatsAsJson() async {
    try {
      final stats = await getStats();
      final exportData = {
        'exported_at': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'stats': stats.toJson(),
        'read_dates': await _getReadDatesAsStrings(),
      };

      return const JsonEncoder.withIndent('  ').convert(exportData);
    } catch (e) {
      debugPrint('Error exporting stats as JSON: $e');
      return null;
    }
  }

  @override
  Future<bool> importStatsFromJson(String jsonString) async {
    try {
      final importData = json.decode(jsonString);

      if (importData['stats'] == null) {
        debugPrint('Invalid JSON format: no stats found');
        return false;
      }

      final stats = SpiritualStats.fromJson(importData['stats']);
      await saveStats(stats);

      if (importData['read_dates'] != null) {
        await _restoreReadDates(List<String>.from(importData['read_dates']));
      }

      debugPrint('Successfully imported stats from JSON');
      return true;
    } catch (e) {
      debugPrint('Error importing stats from JSON: $e');
      return false;
    }
  }

  @override
  Future<String?> getBackupFilePath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_jsonBackupFilename');

      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting backup file path: $e');
      return null;
    }
  }

  Future<List<DateTime>> _getReadDates() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? dateStrings = prefs.getStringList(_readDatesKey);
    if (dateStrings == null) return [];

    return dateStrings
        .map((dateString) {
          try {
            return DateTime.parse(dateString);
          } catch (e) {
            debugPrint('Error parsing read date: $dateString');
            return null;
          }
        })
        .where((date) => date != null)
        .cast<DateTime>()
        .toList();
  }

  Future<void> _saveReadDates(List<DateTime> dates) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> dateStrings =
        dates.map((date) => date.toIso8601String().split('T').first).toList();
    await prefs.setStringList(_readDatesKey, dateStrings);
  }

  int _calculateCurrentStreak(List<DateTime> readDates) {
    if (readDates.isEmpty) return 0;

    readDates.sort((a, b) => b.compareTo(a));
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    int streak = 0;
    DateTime currentDate = todayDateOnly;

    for (final readDate in readDates) {
      final readDateOnly = DateTime(
        readDate.year,
        readDate.month,
        readDate.day,
      );

      if (readDateOnly.isAtSameMomentAs(currentDate)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else if (readDateOnly.isBefore(currentDate)) {
        break;
      }
    }

    return streak;
  }

  List<Achievement> _updateAchievements(
    SpiritualStats currentStats,
    int newStreak,
    int totalRead,
    int favoritesCount,
  ) {
    final allAchievements = PredefinedAchievements.all;
    final unlockedAchievements = List<Achievement>.from(
      currentStats.unlockedAchievements,
    );

    for (final achievement in allAchievements) {
      final isAlreadyUnlocked = unlockedAchievements.any(
        (a) => a.id == achievement.id,
      );

      if (!isAlreadyUnlocked) {
        bool shouldUnlock = false;

        switch (achievement.type) {
          case AchievementType.reading:
            shouldUnlock = totalRead >= achievement.threshold;
            break;
          case AchievementType.streak:
            shouldUnlock = newStreak >= achievement.threshold;
            break;
          case AchievementType.favorites:
            shouldUnlock = favoritesCount >= achievement.threshold;
            break;
          case AchievementType.special:
            // TODO: Handle this case.
            throw UnimplementedError();
        }

        if (shouldUnlock) {
          unlockedAchievements.add(achievement.copyWith(isUnlocked: true));
          debugPrint('Achievement unlocked: ${achievement.title}');
        }
      }
    }

    return unlockedAchievements;
  }

  @override
  Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statsKey);
    await prefs.remove(_readDatesKey);
    await prefs.remove(_lastReadDevocionalKey);
    await prefs.remove(_lastReadTimeKey);

    // Limpiar backups
    try {
      final directory = await getApplicationDocumentsDirectory();

      // Eliminar backup manual
      final manualBackup = File('${directory.path}/$_jsonBackupFilename');
      if (await manualBackup.exists()) {
        await manualBackup.delete();
      }

      // Eliminar auto-backups
      final autoBackups = directory
          .listSync()
          .where(
            (entity) =>
                entity is File && entity.path.contains('spiritual_stats_auto_'),
          )
          .cast<File>();

      for (final file in autoBackups) {
        await file.delete();
      }

      debugPrint('All backups deleted');
    } catch (e) {
      debugPrint('Error deleting backups: $e');
    }
  }

  @override
  Future<List<DateTime>> getReadDatesForVisualization() async {
    return await _getReadDates();
  }

  @override
  Future<bool> hasDevocionalBeenRead(String devocionalId) async {
    final stats = await getStats();
    return stats.readDevocionalIds.contains(devocionalId);
  }

  /// Get all stats as a map for backup purposes
  @override
  Future<Map<String, dynamic>> getAllStats() async {
    try {
      final stats = await getStats();
      final readDates = await _getReadDates();

      return {
        'stats': stats.toJson(),
        'read_dates': readDates.map((date) => date.toIso8601String()).toList(),
        'backup_timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting all stats for backup: $e');
      return {};
    }
  }

  /// Restore stats from backup data
  @override
  Future<void> restoreStats(Map<String, dynamic> backupData) async {
    try {
      if (backupData.containsKey('stats')) {
        final statsData = backupData['stats'] as Map<String, dynamic>;
        final stats = SpiritualStats.fromJson(statsData);

        // Save the restored stats
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_statsKey, json.encode(stats.toJson()));

        debugPrint('Restored spiritual stats from backup');
      }

      if (backupData.containsKey('read_dates')) {
        final readDatesData = backupData['read_dates'] as List<dynamic>;
        final readDates = readDatesData
            .map((dateStr) => DateTime.parse(dateStr as String))
            .toList();

        // Save the restored read dates
        await _saveReadDates(readDates);

        debugPrint('Restored ${readDates.length} read dates from backup');
      }
    } catch (e) {
      debugPrint('Error restoring stats from backup: $e');
      rethrow;
    }
  }
}
