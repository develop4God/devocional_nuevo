// lib/providers/prayer_provider.dart

import 'dart:convert';
import 'dart:io';

import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerProvider with ChangeNotifier {
  List<Prayer> _prayers = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters públicos
  List<Prayer> get prayers => _prayers;
  List<Prayer> get activePrayers => _prayers.where((p) => p.isActive).toList();
  List<Prayer> get answeredPrayers =>
      _prayers.where((p) => p.isAnswered).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Estadísticas básicas
  int get totalPrayers => _prayers.length;
  int get activePrayersCount => activePrayers.length;
  int get answeredPrayersCount => answeredPrayers.length;

  /// Constructor: inicializa los datos cuando el provider se crea
  PrayerProvider() {
    _initializeData();
  }

  /// Inicializa los datos cargando las oraciones guardadas
  Future<void> _initializeData() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _loadPrayers();
    } catch (e) {
      _errorMessage =
          LocalizationService.instance.translate('errors.prayer_loading_error');
      debugPrint('Error initializing prayer data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga las oraciones desde SharedPreferences
  Future<void> _loadPrayers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? prayersJson = prefs.getString('prayers');

      if (prayersJson != null && prayersJson.isNotEmpty) {
        final List<dynamic> decodedList = json.decode(prayersJson);
        _prayers = decodedList
            .map((item) => Prayer.fromJson(item as Map<String, dynamic>))
            .toList();

        // Ordenar las oraciones: activas por fecha de creación (más recientes primero),
        // seguidas de las respondidas por fecha de respuesta (más recientes primero)
        _sortPrayers();
      }
    } catch (e) {
      debugPrint('Error loading prayers: $e');
      _prayers = [];
    }
  }

  /// Guarda las oraciones en SharedPreferences
  Future<void> _savePrayers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String prayersJson = json.encode(
        _prayers.map((prayer) => prayer.toJson()).toList(),
      );
      await prefs.setString('prayers', prayersJson);

      // Backup opcional en archivo JSON
      await _backupPrayersToFile();
    } catch (e) {
      debugPrint('Error saving prayers: $e');
    }
  }

  /// Backup opcional: guarda las oraciones en un archivo JSON en DocumentsDirectory
  Future<void> _backupPrayersToFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/prayers.json');

      final String prayersJson = json.encode(
        _prayers.map((prayer) => prayer.toJson()).toList(),
      );

      await file.writeAsString(prayersJson);
    } catch (e) {
      debugPrint('Error backing up prayers to file: $e');
      // No es crítico, no se propaga el error
    }
  }

  /// Ordena las oraciones: activas por fecha de creación (más recientes primero),
  /// seguidas de las respondidas por fecha de respuesta (más recientes primero)
  void _sortPrayers() {
    _prayers.sort((a, b) {
      // Primero las activas
      if (a.isActive && !b.isActive) return -1;
      if (!a.isActive && b.isActive) return 1;

      // Si ambas tienen el mismo estado
      if (a.isActive && b.isActive) {
        // Ordenar activas por fecha de creación (más recientes primero)
        return b.createdDate.compareTo(a.createdDate);
      } else {
        // Ordenar respondidas por fecha de respuesta (más recientes primero)
        final aAnsweredDate = a.answeredDate ?? a.createdDate;
        final bAnsweredDate = b.answeredDate ?? b.createdDate;
        return bAnsweredDate.compareTo(aAnsweredDate);
      }
    });
  }

  /// Añade una nueva oración
  Future<void> addPrayer(String text) async {
    if (text.trim().isEmpty) {
      _errorMessage = 'El texto de la oración no puede estar vacío';
      notifyListeners();
      return;
    }

    try {
      final newPrayer = Prayer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text.trim(),
        createdDate: DateTime.now(),
        status: PrayerStatus.active,
      );

      _prayers.add(newPrayer);
      _sortPrayers();
      await _savePrayers();

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al añadir la oración: $e';
      debugPrint('Error adding prayer: $e');
      notifyListeners();
    }
  }

  /// Marca una oración como respondida
  Future<void> markPrayerAsAnswered(String prayerId) async {
    try {
      final prayerIndex = _prayers.indexWhere((p) => p.id == prayerId);
      if (prayerIndex != -1) {
        _prayers[prayerIndex] = _prayers[prayerIndex].copyWith(
          status: PrayerStatus.answered,
          answeredDate: DateTime.now(),
        );

        _sortPrayers();
        await _savePrayers();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error al marcar la oración como respondida: $e';
      debugPrint('Error marking prayer as answered: $e');
      notifyListeners();
    }
  }

  /// Marca una oración como activa (deshace el estado de respondida)
  Future<void> markPrayerAsActive(String prayerId) async {
    try {
      final prayerIndex = _prayers.indexWhere((p) => p.id == prayerId);
      if (prayerIndex != -1) {
        _prayers[prayerIndex] = _prayers[prayerIndex].copyWith(
          status: PrayerStatus.active,
          clearAnsweredDate: true,
        );

        _sortPrayers();
        await _savePrayers();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error al marcar la oración como activa: $e';
      debugPrint('Error marking prayer as active: $e');
      notifyListeners();
    }
  }

  /// Edita el texto de una oración
  Future<void> editPrayer(String prayerId, String newText) async {
    if (newText.trim().isEmpty) {
      _errorMessage = 'El texto de la oración no puede estar vacío';
      notifyListeners();
      return;
    }

    try {
      final prayerIndex = _prayers.indexWhere((p) => p.id == prayerId);
      if (prayerIndex != -1) {
        _prayers[prayerIndex] = _prayers[prayerIndex].copyWith(
          text: newText.trim(),
        );

        await _savePrayers();
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error al editar la oración: $e';
      debugPrint('Error editing prayer: $e');
      notifyListeners();
    }
  }

  /// Elimina una oración
  Future<void> deletePrayer(String prayerId) async {
    try {
      _prayers.removeWhere((p) => p.id == prayerId);
      await _savePrayers();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al eliminar la oración: $e';
      debugPrint('Error deleting prayer: $e');
      notifyListeners();
    }
  }

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresca los datos (útil para pull-to-refresh)
  Future<void> refresh() async {
    await _loadPrayers();
    notifyListeners();
  }

  /// Obtiene información de estadísticas para mostrar en la UI
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    var oldestActivePrayer = 0;

    if (activePrayers.isNotEmpty) {
      oldestActivePrayer = activePrayers
          .map((p) => now.difference(p.createdDate).inDays)
          .reduce((a, b) => a > b ? a : b);
    }

    return {
      'total': totalPrayers,
      'active': activePrayersCount,
      'answered': answeredPrayersCount,
      'oldestActiveDays': oldestActivePrayer,
    };
  }
}
