// lib/blocs/thanksgiving_bloc.dart

import 'dart:convert';
import 'dart:io';

import 'package:devocional_nuevo/models/thanksgiving_model.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'thanksgiving_event.dart';
import 'thanksgiving_state.dart';

class ThanksgivingBloc extends Bloc<ThanksgivingEvent, ThanksgivingState> {
  ThanksgivingBloc() : super(ThanksgivingInitial()) {
    on<LoadThanksgivings>(_onLoadThanksgivings);
    on<AddThanksgiving>(_onAddThanksgiving);
    on<EditThanksgiving>(_onEditThanksgiving);
    on<DeleteThanksgiving>(_onDeleteThanksgiving);
    on<RefreshThanksgivings>(_onRefreshThanksgivings);
    on<ClearThanksgivingError>(_onClearThanksgivingError);
  }

  /// Handles loading thanksgivings from storage
  Future<void> _onLoadThanksgivings(
    LoadThanksgivings event,
    Emitter<ThanksgivingState> emit,
  ) async {
    emit(ThanksgivingLoading());

    try {
      final thanksgivings = await _loadThanksgivingsFromStorage();
      emit(ThanksgivingLoaded(thanksgivings: thanksgivings));
    } catch (e) {
      final errorMessage = getService<LocalizationService>().translate(
        'errors.thanksgiving_loading_error',
      );
      debugPrint('Error loading thanksgivings: $e');
      emit(ThanksgivingError(errorMessage));
    }
  }

  /// Handles adding a new thanksgiving
  Future<void> _onAddThanksgiving(
    AddThanksgiving event,
    Emitter<ThanksgivingState> emit,
  ) async {
    if (event.text.trim().isEmpty) {
      final currentState = state;
      if (currentState is ThanksgivingLoaded) {
        emit(
          currentState.copyWith(
            errorMessage: 'El texto del agradecimiento no puede estar vacío',
          ),
        );
      }
      return;
    }

    try {
      final currentState = state;
      List<Thanksgiving> currentThanksgivings = [];

      if (currentState is ThanksgivingLoaded) {
        currentThanksgivings = currentState.thanksgivings;
      }

      final newThanksgiving = Thanksgiving(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: event.text.trim(),
        createdDate: DateTime.now(),
      );

      final updatedThanksgivings = [...currentThanksgivings, newThanksgiving];
      _sortThanksgivings(updatedThanksgivings);

      await _saveThanksgivingsToStorage(updatedThanksgivings);
      emit(ThanksgivingLoaded(thanksgivings: updatedThanksgivings));
    } catch (e) {
      final currentState = state;
      if (currentState is ThanksgivingLoaded) {
        emit(
          currentState.copyWith(
            errorMessage: 'Error al añadir el agradecimiento: $e',
          ),
        );
      }
      debugPrint('Error adding thanksgiving: $e');
    }
  }

  /// Handles editing an existing thanksgiving
  Future<void> _onEditThanksgiving(
    EditThanksgiving event,
    Emitter<ThanksgivingState> emit,
  ) async {
    if (event.newText.trim().isEmpty) {
      final currentState = state;
      if (currentState is ThanksgivingLoaded) {
        emit(
          currentState.copyWith(
            errorMessage: 'El texto del agradecimiento no puede estar vacío',
          ),
        );
      }
      return;
    }

    try {
      final currentState = state;
      if (currentState is! ThanksgivingLoaded) return;

      final updatedThanksgivings = currentState.thanksgivings.map((
        thanksgiving,
      ) {
        if (thanksgiving.id == event.thanksgivingId) {
          return thanksgiving.copyWith(text: event.newText.trim());
        }
        return thanksgiving;
      }).toList();

      await _saveThanksgivingsToStorage(updatedThanksgivings);
      emit(
        currentState.copyWith(
          thanksgivings: updatedThanksgivings,
          clearError: true,
        ),
      );
    } catch (e) {
      final currentState = state;
      if (currentState is ThanksgivingLoaded) {
        emit(
          currentState.copyWith(
            errorMessage: 'Error al editar el agradecimiento: $e',
          ),
        );
      }
      debugPrint('Error editing thanksgiving: $e');
    }
  }

  /// Handles deleting a thanksgiving
  Future<void> _onDeleteThanksgiving(
    DeleteThanksgiving event,
    Emitter<ThanksgivingState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! ThanksgivingLoaded) return;

      final updatedThanksgivings = currentState.thanksgivings
          .where((thanksgiving) => thanksgiving.id != event.thanksgivingId)
          .toList();

      await _saveThanksgivingsToStorage(updatedThanksgivings);
      emit(currentState.copyWith(thanksgivings: updatedThanksgivings));
    } catch (e) {
      final currentState = state;
      if (currentState is ThanksgivingLoaded) {
        emit(
          currentState.copyWith(
            errorMessage: 'Error al eliminar el agradecimiento: $e',
          ),
        );
      }
      debugPrint('Error deleting thanksgiving: $e');
    }
  }

  /// Handles refreshing thanksgivings
  Future<void> _onRefreshThanksgivings(
    RefreshThanksgivings event,
    Emitter<ThanksgivingState> emit,
  ) async {
    try {
      final thanksgivings = await _loadThanksgivingsFromStorage();
      final currentState = state;
      if (currentState is ThanksgivingLoaded) {
        emit(currentState.copyWith(thanksgivings: thanksgivings));
      } else {
        emit(ThanksgivingLoaded(thanksgivings: thanksgivings));
      }
    } catch (e) {
      debugPrint('Error refreshing thanksgivings: $e');
    }
  }

  /// Handles clearing error messages
  void _onClearThanksgivingError(
    ClearThanksgivingError event,
    Emitter<ThanksgivingState> emit,
  ) {
    final currentState = state;
    if (currentState is ThanksgivingLoaded) {
      emit(currentState.copyWith(clearError: true));
    }
  }

  /// Loads thanksgivings from SharedPreferences
  Future<List<Thanksgiving>> _loadThanksgivingsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? thanksgivingsJson = prefs.getString('thanksgivings');

      if (thanksgivingsJson != null && thanksgivingsJson.isNotEmpty) {
        final List<dynamic> decodedList = json.decode(thanksgivingsJson);
        final thanksgivings = decodedList
            .map((item) => Thanksgiving.fromJson(item as Map<String, dynamic>))
            .toList();

        _sortThanksgivings(thanksgivings);
        return thanksgivings;
      }
      return [];
    } catch (e) {
      debugPrint('Error loading thanksgivings from storage: $e');
      return [];
    }
  }

  /// Saves thanksgivings to SharedPreferences and creates backup
  Future<void> _saveThanksgivingsToStorage(
    List<Thanksgiving> thanksgivings,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String thanksgivingsJson = json.encode(
        thanksgivings.map((thanksgiving) => thanksgiving.toJson()).toList(),
      );
      await prefs.setString('thanksgivings', thanksgivingsJson);

      // Optional backup to file
      await _backupThanksgivingsToFile(thanksgivings);
    } catch (e) {
      debugPrint('Error saving thanksgivings to storage: $e');
    }
  }

  /// Creates a backup of thanksgivings to JSON file
  Future<void> _backupThanksgivingsToFile(
    List<Thanksgiving> thanksgivings,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/thanksgivings.json');

      final String thanksgivingsJson = json.encode(
        thanksgivings.map((thanksgiving) => thanksgiving.toJson()).toList(),
      );

      await file.writeAsString(thanksgivingsJson);
    } catch (e) {
      debugPrint('Error backing up thanksgivings to file: $e');
      // This is not critical, don't propagate the error
    }
  }

  /// Sorts thanksgivings by creation date (newest first)
  void _sortThanksgivings(List<Thanksgiving> thanksgivings) {
    thanksgivings.sort((a, b) => b.createdDate.compareTo(a.createdDate));
  }
}
