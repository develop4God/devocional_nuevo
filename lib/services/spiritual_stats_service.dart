// lib/services/spiritual_stats_service.dart - VERSIÓN CON AUTO-BACKUP
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/spiritual_stats_model.dart';

class SpiritualStatsService {
  static const String _statsKey = 'spiritual_stats';
  static const String _readDatesKey = 'read_dates';
  static const String _lastReadDevocionalKey = 'last_read_devocional';
  static const String _lastReadTimeKey = 'last_read_time';

  // Configuración para JSON backup
  static const String _jsonBackupEnabledKey = 'json_backup_enabled';
  static const String _autoBackupEnabledKey = 'auto_backup_enabled';
  static const String _lastBackupTimeKey = 'last_backup_time';
  static const String _jsonBackupFilename = 'spiritual_stats_backup.json';

  // Configuración de auto-backup
  static const int _autoBackupIntervalHours = 24; // Cada 24 horas
  static const int _maxBackupFiles = 7; // Mantener 7 backups rotativos

  /// Configurar backup automático (habilitado por defecto para mejor UX)
  Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupEnabledKey, enabled);

    if (enabled) {
      // Crear backup inicial
      await _createAutoBackup();
    }

    debugPrint('Auto-backup ${enabled ? "enabled" : "disabled"}');
  }

  /// Verificar si auto-backup está habilitado
  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Por defecto habilitado para mejor experiencia de usuario
    return prefs.getBool(_autoBackupEnabledKey) ?? true;
  }

  /// NUEVO: Habilitar/deshabilitar backup JSON manual
  Future<void> setJsonBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_jsonBackupEnabledKey, enabled);

    if (enabled) {
      await _createJsonBackup();
    }
  }

  /// Verificar si JSON backup manual está habilitado
  Future<bool> isJsonBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_jsonBackupEnabledKey) ?? false;
  }

  /// Get current spiritual statistics
  Future<SpiritualStats> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final String? statsJson = prefs.getString(_statsKey);

    if (statsJson != null) {
      try {
        final Map<String, dynamic> data = json.decode(statsJson);
        return SpiritualStats.fromJson(data);
      } catch (e) {
        debugPrint('Error parsing spiritual stats: $e');

        // Intentar recuperar desde auto-backup primero
        if (await isAutoBackupEnabled()) {
          debugPrint('Intentando recuperar desde auto-backup...');
          final backupStats = await _restoreFromAutoBackup();
          if (backupStats != null) {
            await saveStats(backupStats);
            return backupStats;
          }
        }

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
  Future<void> saveStats(SpiritualStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    final String statsJson = json.encode(stats.toJson());
    await prefs.setString(_statsKey, statsJson);

    // Auto-backup inteligente (solo cuando es necesario)
    if (await isAutoBackupEnabled()) {
      await _checkAndCreateAutoBackup(stats);
    }

    // Backup JSON manual si está habilitado
    if (await isJsonBackupEnabled()) {
      await _createJsonBackup(stats);
    }
  }

  /// NUEVO: Verificar si es necesario crear auto-backup
  Future<void> _checkAndCreateAutoBackup(SpiritualStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBackupTime = prefs.getInt(_lastBackupTimeKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final hoursSinceLastBackup = (currentTime - lastBackupTime) / 3600;

      // Solo crear backup si han pasado las horas configuradas
      if (hoursSinceLastBackup >= _autoBackupIntervalHours) {
        await _createAutoBackup(stats);
        await prefs.setInt(_lastBackupTimeKey, currentTime);
        debugPrint(
            'Auto-backup created (${hoursSinceLastBackup.toStringAsFixed(1)} hours since last)');
      }
    } catch (e) {
      debugPrint('Error in auto-backup check: $e');
    }
  }

  /// NUEVO: Crear auto-backup con rotación
  Future<void> _createAutoBackup([SpiritualStats? stats]) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      stats ??= await getStats();

      // Crear backup con timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'spiritual_stats_auto_$timestamp.json';
      final file = File('${directory.path}/$filename');

      final backupData = {
        'version': '1.0.0',
        'backup_type': 'auto',
        'created_at': DateTime.now().toIso8601String(),
        'stats': stats.toJson(),
        'read_dates': await _getReadDatesAsStrings(),
        'preferences': await _getPreferences(),
      };

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(backupData),
      );

      // Limpiar backups antiguos
      await _cleanupOldBackups();

      debugPrint('Auto-backup created: $filename');
    } catch (e) {
      debugPrint('Error creating auto-backup: $e');
    }
  }

  /// NUEVO: Limpiar backups antiguos (mantener solo los más recientes)
  Future<void> _cleanupOldBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .where((entity) =>
              entity is File && entity.path.contains('spiritual_stats_auto_'))
          .cast<File>()
          .toList();

      if (files.length > _maxBackupFiles) {
        // Ordenar por fecha de modificación (más reciente primero)
        files.sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

        // Eliminar los más antiguos
        for (int i = _maxBackupFiles; i < files.length; i++) {
          await files[i].delete();
          debugPrint('Deleted old backup: ${files[i].path}');
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old backups: $e');
    }
  }

  /// NUEVO: Restaurar desde el auto-backup más reciente
  Future<SpiritualStats?> _restoreFromAutoBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .where((entity) =>
              entity is File && entity.path.contains('spiritual_stats_auto_'))
          .cast<File>()
          .toList();

      if (files.isEmpty) {
        debugPrint('No auto-backup files found');
        return null;
      }

      // Obtener el más reciente
      files
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      final mostRecentFile = files.first;

      final jsonString = await mostRecentFile.readAsString();
      final backupData = json.decode(jsonString);

      debugPrint('Restoring from auto-backup: ${mostRecentFile.path}');

      final stats = SpiritualStats.fromJson(backupData['stats']);

      if (backupData['read_dates'] != null) {
        await _restoreReadDates(List<String>.from(backupData['read_dates']));
      }

      if (backupData['preferences'] != null) {
        await _restorePreferences(
            Map<String, dynamic>.from(backupData['preferences']));
      }

      debugPrint('Successfully restored from auto-backup');
      return stats;
    } catch (e) {
      debugPrint('Error restoring from auto-backup: $e');
      return null;
    }
  }

  /// Record that a devotional was read - con auto-backup inteligente
  Future<SpiritualStats> recordDevocionalRead({
    required String devocionalId,
    int? favoritesCount,
    int readingTimeSeconds = 0,
    double scrollPercentage = 0.0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final stats = await getStats();

    final bool meetsReadingCriteria =
        readingTimeSeconds >= 60 && scrollPercentage >= 0.8;

    debugPrint('Devotional read attempt: $devocionalId');
    debugPrint(
      'Reading time: ${readingTimeSeconds}s, Scroll: ${(scrollPercentage * 100).toStringAsFixed(1)}%',
    );
    debugPrint('Meets criteria: $meetsReadingCriteria');

    if (stats.readDevocionalIds.contains(devocionalId)) {
      debugPrint('Devotional $devocionalId already counted in statistics');
      if (favoritesCount != null) {
        final updatedStats = stats.copyWith(favoritesCount: favoritesCount);
        await saveStats(updatedStats);
        return updatedStats;
      }
      return stats;
    }

    if (!meetsReadingCriteria) {
      debugPrint(
          'Devotional read but not counting for statistics (criteria not met)');
      await prefs.setString(_lastReadDevocionalKey, devocionalId);
      await prefs.setInt(
          _lastReadTimeKey, DateTime.now().millisecondsSinceEpoch ~/ 1000);

      if (favoritesCount != null) {
        final updatedStats = stats.copyWith(favoritesCount: favoritesCount);
        await saveStats(updatedStats);
        return updatedStats;
      }
      return stats;
    }

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
    }

    await prefs.setString(_lastReadDevocionalKey, devocionalId);
    await prefs.setInt(
        _lastReadTimeKey, DateTime.now().millisecondsSinceEpoch ~/ 1000);

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
        'Recorded devotional for statistics: $devocionalId, total: ${updatedStats.totalDevocionalesRead}');
    return updatedStats;
  }

  Future<SpiritualStats> recordDevotionalHeard({
    required String devocionalId,
    required double listenedPercentage, // De 0.0 a 1.0
    int? favoritesCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final stats = await getStats();

    if (listenedPercentage < 0.8) {
      debugPrint('Escucha menor a 80%, no se cuenta: $listenedPercentage');
      return stats;
    }

    if (stats.readDevocionalIds.contains(devocionalId)) {
      debugPrint('Devocional $devocionalId ya registrado como leído');
      if (favoritesCount != null) {
        final updatedStats = stats.copyWith(favoritesCount: favoritesCount);
        await saveStats(updatedStats);
        return updatedStats;
      }
      return stats;
    }

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
    }

    await prefs.setString(_lastReadDevocionalKey, devocionalId);
    await prefs.setInt(
        _lastReadTimeKey, DateTime.now().millisecondsSinceEpoch ~/ 1000);

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

    debugPrint('Devocional contado como escuchado: $devocionalId');
    return updatedStats;
  }

  /// Update favorites count
  Future<SpiritualStats> updateFavoritesCount(int favoritesCount) async {
    final stats = await getStats();
    final updatedStats = stats.copyWith(
      favoritesCount: favoritesCount,
      unlockedAchievements: _updateAchievements(
        stats,
        stats.currentStreak,
        stats.totalDevocionalesRead,
        favoritesCount,
      ),
    );
    await saveStats(updatedStats);
    return updatedStats;
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
          'Restoring from manual JSON backup version: ${backupData['version']}');

      final stats = SpiritualStats.fromJson(backupData['stats']);

      if (backupData['read_dates'] != null) {
        await _restoreReadDates(List<String>.from(backupData['read_dates']));
      }

      if (backupData['preferences'] != null) {
        await _restorePreferences(
            Map<String, dynamic>.from(backupData['preferences']));
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
      final autoBackups = directory
          .listSync()
          .where((entity) =>
              entity is File && entity.path.contains('spiritual_stats_auto_'))
          .cast<File>()
          .length;

      final manualBackupExists =
          await File('${directory.path}/$_jsonBackupFilename').exists();

      final prefs = await SharedPreferences.getInstance();
      final lastAutoBackup = prefs.getInt(_lastBackupTimeKey);

      return {
        'auto_backup_enabled': await isAutoBackupEnabled(),
        'manual_backup_enabled': await isJsonBackupEnabled(),
        'auto_backups_count': autoBackups,
        'manual_backup_exists': manualBackupExists,
        'last_auto_backup': lastAutoBackup != null
            ? DateTime.fromMillisecondsSinceEpoch(lastAutoBackup * 1000)
            : null,
        'next_auto_backup':
            lastAutoBackup != null && await isAutoBackupEnabled()
                ? DateTime.fromMillisecondsSinceEpoch(
                    (lastAutoBackup + _autoBackupIntervalHours * 3600) * 1000)
                : null,
      };
    } catch (e) {
      debugPrint('Error getting backup info: $e');
      return {};
    }
  }

  /// NUEVO: Forzar creación de backup manual
  Future<bool> createManualBackup() async {
    try {
      await _createJsonBackup();
      return true;
    } catch (e) {
      debugPrint('Error creating manual backup: $e');
      return false;
    }
  }

  // ... resto de métodos helper sin cambios ...

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
            _lastReadDevocionalKey, preferences[_lastReadDevocionalKey]);
      }

      if (preferences[_lastReadTimeKey] != null) {
        await prefs.setInt(_lastReadTimeKey, preferences[_lastReadTimeKey]);
      }
    } catch (e) {
      debugPrint('Error restoring preferences: $e');
    }
  }

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
      final readDateOnly =
          DateTime(readDate.year, readDate.month, readDate.day);

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
    final unlockedAchievements =
        List<Achievement>.from(currentStats.unlockedAchievements);

    for (final achievement in allAchievements) {
      final isAlreadyUnlocked =
          unlockedAchievements.any((a) => a.id == achievement.id);

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
        }

        if (shouldUnlock) {
          unlockedAchievements.add(achievement.copyWith(isUnlocked: true));
          debugPrint('Achievement unlocked: ${achievement.title}');
        }
      }
    }

    return unlockedAchievements;
  }

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
          .where((entity) =>
              entity is File && entity.path.contains('spiritual_stats_auto_'))
          .cast<File>();

      for (final file in autoBackups) {
        await file.delete();
      }

      debugPrint('All backups deleted');
    } catch (e) {
      debugPrint('Error deleting backups: $e');
    }
  }

  Future<List<DateTime>> getReadDatesForVisualization() async {
    return await _getReadDates();
  }

  Future<bool> hasDevocionalBeenRead(String devocionalId) async {
    final stats = await getStats();
    return stats.readDevocionalIds.contains(devocionalId);
  }
}
