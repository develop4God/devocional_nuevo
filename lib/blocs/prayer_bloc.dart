// lib/blocs/prayer_bloc.dart

import 'dart:convert';
import 'dart:io';

import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prayer_event.dart';
import 'prayer_state.dart';

class PrayerBloc extends Bloc<PrayerEvent, PrayerState> {
  PrayerBloc() : super(PrayerInitial()) {
    on<LoadPrayers>(_onLoadPrayers);
    on<AddPrayer>(_onAddPrayer);
    on<EditPrayer>(_onEditPrayer);
    on<DeletePrayer>(_onDeletePrayer);
    on<MarkPrayerAsAnswered>(_onMarkPrayerAsAnswered);
    on<MarkPrayerAsActive>(_onMarkPrayerAsActive);
    on<RefreshPrayers>(_onRefreshPrayers);
    on<ClearPrayerError>(_onClearPrayerError);
  }

  /// Handles loading prayers from storage
  Future<void> _onLoadPrayers(
    LoadPrayers event,
    Emitter<PrayerState> emit,
  ) async {
    emit(PrayerLoading());

    try {
      final prayers = await _loadPrayersFromStorage();
      emit(PrayerLoaded(prayers: prayers));
    } catch (e) {
      final errorMessage = LocalizationService.instance.translate('errors.prayer_loading_error');
      debugPrint('Error loading prayers: $e');
      emit(PrayerError(errorMessage));
    }
  }

  /// Handles adding a new prayer
  Future<void> _onAddPrayer(
    AddPrayer event,
    Emitter<PrayerState> emit,
  ) async {
    if (event.text.trim().isEmpty) {
      final currentState = state;
      if (currentState is PrayerLoaded) {
        emit(currentState.copyWith(errorMessage: 'El texto de la oración no puede estar vacío'));
      }
      return;
    }

    try {
      final currentState = state;
      List<Prayer> currentPrayers = [];
      
      if (currentState is PrayerLoaded) {
        currentPrayers = currentState.prayers;
      }

      final newPrayer = Prayer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: event.text.trim(),
        createdDate: DateTime.now(),
        status: PrayerStatus.active,
      );

      final updatedPrayers = [...currentPrayers, newPrayer];
      _sortPrayers(updatedPrayers);
      
      await _savePrayersToStorage(updatedPrayers);
      emit(PrayerLoaded(prayers: updatedPrayers));
    } catch (e) {
      final currentState = state;
      if (currentState is PrayerLoaded) {
        emit(currentState.copyWith(errorMessage: 'Error al añadir la oración: $e'));
      }
      debugPrint('Error adding prayer: $e');
    }
  }

  /// Handles editing an existing prayer
  Future<void> _onEditPrayer(
    EditPrayer event,
    Emitter<PrayerState> emit,
  ) async {
    if (event.newText.trim().isEmpty) {
      final currentState = state;
      if (currentState is PrayerLoaded) {
        emit(currentState.copyWith(errorMessage: 'El texto de la oración no puede estar vacío'));
      }
      return;
    }

    try {
      final currentState = state;
      if (currentState is! PrayerLoaded) return;

      final updatedPrayers = currentState.prayers.map((prayer) {
        if (prayer.id == event.prayerId) {
          return prayer.copyWith(text: event.newText.trim());
        }
        return prayer;
      }).toList();

      await _savePrayersToStorage(updatedPrayers);
      emit(currentState.copyWith(prayers: updatedPrayers, clearError: true));
    } catch (e) {
      final currentState = state;
      if (currentState is PrayerLoaded) {
        emit(currentState.copyWith(errorMessage: 'Error al editar la oración: $e'));
      }
      debugPrint('Error editing prayer: $e');
    }
  }

  /// Handles deleting a prayer
  Future<void> _onDeletePrayer(
    DeletePrayer event,
    Emitter<PrayerState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! PrayerLoaded) return;

      final updatedPrayers = currentState.prayers
          .where((prayer) => prayer.id != event.prayerId)
          .toList();

      await _savePrayersToStorage(updatedPrayers);
      emit(currentState.copyWith(prayers: updatedPrayers));
    } catch (e) {
      final currentState = state;
      if (currentState is PrayerLoaded) {
        emit(currentState.copyWith(errorMessage: 'Error al eliminar la oración: $e'));
      }
      debugPrint('Error deleting prayer: $e');
    }
  }

  /// Handles marking a prayer as answered
  Future<void> _onMarkPrayerAsAnswered(
    MarkPrayerAsAnswered event,
    Emitter<PrayerState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! PrayerLoaded) return;

      final updatedPrayers = currentState.prayers.map((prayer) {
        if (prayer.id == event.prayerId) {
          return prayer.copyWith(
            status: PrayerStatus.answered,
            answeredDate: DateTime.now(),
          );
        }
        return prayer;
      }).toList();

      _sortPrayers(updatedPrayers);
      await _savePrayersToStorage(updatedPrayers);
      emit(currentState.copyWith(prayers: updatedPrayers));
    } catch (e) {
      final currentState = state;
      if (currentState is PrayerLoaded) {
        emit(currentState.copyWith(errorMessage: 'Error al marcar la oración como respondida: $e'));
      }
      debugPrint('Error marking prayer as answered: $e');
    }
  }

  /// Handles marking a prayer as active
  Future<void> _onMarkPrayerAsActive(
    MarkPrayerAsActive event,
    Emitter<PrayerState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! PrayerLoaded) return;

      final updatedPrayers = currentState.prayers.map((prayer) {
        if (prayer.id == event.prayerId) {
          return prayer.copyWith(
            status: PrayerStatus.active,
            clearAnsweredDate: true,
          );
        }
        return prayer;
      }).toList();

      _sortPrayers(updatedPrayers);
      await _savePrayersToStorage(updatedPrayers);
      emit(currentState.copyWith(prayers: updatedPrayers));
    } catch (e) {
      final currentState = state;
      if (currentState is PrayerLoaded) {
        emit(currentState.copyWith(errorMessage: 'Error al marcar la oración como activa: $e'));
      }
      debugPrint('Error marking prayer as active: $e');
    }
  }

  /// Handles refreshing prayers
  Future<void> _onRefreshPrayers(
    RefreshPrayers event,
    Emitter<PrayerState> emit,
  ) async {
    try {
      final prayers = await _loadPrayersFromStorage();
      final currentState = state;
      if (currentState is PrayerLoaded) {
        emit(currentState.copyWith(prayers: prayers));
      } else {
        emit(PrayerLoaded(prayers: prayers));
      }
    } catch (e) {
      debugPrint('Error refreshing prayers: $e');
    }
  }

  /// Handles clearing error messages
  void _onClearPrayerError(
    ClearPrayerError event,
    Emitter<PrayerState> emit,
  ) {
    final currentState = state;
    if (currentState is PrayerLoaded) {
      emit(currentState.copyWith(clearError: true));
    }
  }

  /// Loads prayers from SharedPreferences
  Future<List<Prayer>> _loadPrayersFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? prayersJson = prefs.getString('prayers');

      if (prayersJson != null && prayersJson.isNotEmpty) {
        final List<dynamic> decodedList = json.decode(prayersJson);
        final prayers = decodedList
            .map((item) => Prayer.fromJson(item as Map<String, dynamic>))
            .toList();

        _sortPrayers(prayers);
        return prayers;
      }
      return [];
    } catch (e) {
      debugPrint('Error loading prayers from storage: $e');
      return [];
    }
  }

  /// Saves prayers to SharedPreferences and creates backup
  Future<void> _savePrayersToStorage(List<Prayer> prayers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String prayersJson = json.encode(
        prayers.map((prayer) => prayer.toJson()).toList(),
      );
      await prefs.setString('prayers', prayersJson);

      // Optional backup to file
      await _backupPrayersToFile(prayers);
    } catch (e) {
      debugPrint('Error saving prayers to storage: $e');
    }
  }

  /// Creates a backup of prayers to JSON file
  Future<void> _backupPrayersToFile(List<Prayer> prayers) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/prayers.json');

      final String prayersJson = json.encode(
        prayers.map((prayer) => prayer.toJson()).toList(),
      );

      await file.writeAsString(prayersJson);
    } catch (e) {
      debugPrint('Error backing up prayers to file: $e');
      // This is not critical, don't propagate the error
    }
  }

  /// Sorts prayers: active first by creation date (newest first), 
  /// then answered by answer date (newest first)
  void _sortPrayers(List<Prayer> prayers) {
    prayers.sort((a, b) {
      // Active prayers first
      if (a.isActive && !b.isActive) return -1;
      if (!a.isActive && b.isActive) return 1;

      // If both have the same status
      if (a.isActive && b.isActive) {
        // Sort active prayers by creation date (newest first)
        return b.createdDate.compareTo(a.createdDate);
      } else {
        // Sort answered prayers by answer date (newest first)
        final aAnsweredDate = a.answeredDate ?? a.createdDate;
        final bAnsweredDate = b.answeredDate ?? b.createdDate;
        return bAnsweredDate.compareTo(aAnsweredDate);
      }
    });
  }
}