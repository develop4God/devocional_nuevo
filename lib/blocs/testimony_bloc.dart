// lib/blocs/testimony_bloc.dart

import 'dart:convert';
import 'dart:io';

import 'package:devocional_nuevo/models/testimony_model.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'testimony_event.dart';
import 'testimony_state.dart';

class TestimonyBloc extends Bloc<TestimonyEvent, TestimonyState> {
  TestimonyBloc() : super(TestimonyInitial()) {
    on<LoadTestimonies>(_onLoadTestimonies);
    on<AddTestimony>(_onAddTestimony);
    on<EditTestimony>(_onEditTestimony);
    on<DeleteTestimony>(_onDeleteTestimony);
    on<RefreshTestimonies>(_onRefreshTestimonies);
    on<ClearTestimonyError>(_onClearTestimonyError);
  }

  /// Handles loading testimonies from storage
  Future<void> _onLoadTestimonies(
    LoadTestimonies event,
    Emitter<TestimonyState> emit,
  ) async {
    emit(TestimonyLoading());

    try {
      final testimonies = await _loadTestimoniesFromStorage();
      emit(TestimonyLoaded(testimonies: testimonies));
    } catch (e) {
      final errorMessage = getService<LocalizationService>().translate(
        'errors.testimony_loading_error',
      );
      debugPrint('Error loading testimonies: $e');
      emit(TestimonyError(errorMessage));
    }
  }

  /// Handles adding a new testimony
  Future<void> _onAddTestimony(
    AddTestimony event,
    Emitter<TestimonyState> emit,
  ) async {
    if (event.text.trim().isEmpty) {
      final currentState = state;
      if (currentState is TestimonyLoaded) {
        final errorMessage = getService<LocalizationService>().translate(
          'testimony.enter_testimony_text_error',
        );
        emit(
          currentState.copyWith(
            errorMessage: errorMessage,
          ),
        );
      }
      return;
    }

    try {
      final currentState = state;
      List<Testimony> currentTestimonies = [];

      if (currentState is TestimonyLoaded) {
        currentTestimonies = currentState.testimonies;
      }

      final newTestimony = Testimony(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: event.text.trim(),
        createdDate: DateTime.now(),
      );

      final updatedTestimonies = [...currentTestimonies, newTestimony];
      _sortTestimonies(updatedTestimonies);

      await _saveTestimoniesToStorage(updatedTestimonies);
      emit(TestimonyLoaded(testimonies: updatedTestimonies));
    } catch (e) {
      final currentState = state;
      if (currentState is TestimonyLoaded) {
        final errorMessage = getService<LocalizationService>().translate(
          'errors.testimony_add_error',
        );
        emit(
          currentState.copyWith(
            errorMessage: errorMessage,
          ),
        );
      }
      debugPrint('Error adding testimony: $e');
    }
  }

  /// Handles editing an existing testimony
  Future<void> _onEditTestimony(
    EditTestimony event,
    Emitter<TestimonyState> emit,
  ) async {
    if (event.newText.trim().isEmpty) {
      final currentState = state;
      if (currentState is TestimonyLoaded) {
        final errorMessage = getService<LocalizationService>().translate(
          'testimony.enter_testimony_text_error',
        );
        emit(
          currentState.copyWith(
            errorMessage: errorMessage,
          ),
        );
      }
      return;
    }

    try {
      final currentState = state;
      if (currentState is! TestimonyLoaded) return;

      final updatedTestimonies = currentState.testimonies.map((
        testimony,
      ) {
        if (testimony.id == event.testimonyId) {
          return testimony.copyWith(text: event.newText.trim());
        }
        return testimony;
      }).toList();

      await _saveTestimoniesToStorage(updatedTestimonies);
      emit(
        currentState.copyWith(
          testimonies: updatedTestimonies,
          clearError: true,
        ),
      );
    } catch (e) {
      final currentState = state;
      if (currentState is TestimonyLoaded) {
        final errorMessage = getService<LocalizationService>().translate(
          'errors.testimony_edit_error',
        );
        emit(
          currentState.copyWith(
            errorMessage: errorMessage,
          ),
        );
      }
      debugPrint('Error editing testimony: $e');
    }
  }

  /// Handles deleting a testimony
  Future<void> _onDeleteTestimony(
    DeleteTestimony event,
    Emitter<TestimonyState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! TestimonyLoaded) return;

      final updatedTestimonies = currentState.testimonies
          .where((testimony) => testimony.id != event.testimonyId)
          .toList();

      await _saveTestimoniesToStorage(updatedTestimonies);
      emit(currentState.copyWith(testimonies: updatedTestimonies));
    } catch (e) {
      final currentState = state;
      if (currentState is TestimonyLoaded) {
        final errorMessage = getService<LocalizationService>().translate(
          'errors.testimony_delete_error',
        );
        emit(
          currentState.copyWith(
            errorMessage: errorMessage,
          ),
        );
      }
      debugPrint('Error deleting testimony: $e');
    }
  }

  /// Handles refreshing testimonies
  Future<void> _onRefreshTestimonies(
    RefreshTestimonies event,
    Emitter<TestimonyState> emit,
  ) async {
    try {
      final testimonies = await _loadTestimoniesFromStorage();
      final currentState = state;
      if (currentState is TestimonyLoaded) {
        emit(currentState.copyWith(testimonies: testimonies));
      } else {
        emit(TestimonyLoaded(testimonies: testimonies));
      }
    } catch (e) {
      debugPrint('Error refreshing testimonies: $e');
    }
  }

  /// Handles clearing error messages
  void _onClearTestimonyError(
    ClearTestimonyError event,
    Emitter<TestimonyState> emit,
  ) {
    final currentState = state;
    if (currentState is TestimonyLoaded) {
      emit(currentState.copyWith(clearError: true));
    }
  }

  /// Loads testimonies from SharedPreferences
  Future<List<Testimony>> _loadTestimoniesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? testimoniesJson = prefs.getString('testimonies');

      if (testimoniesJson != null && testimoniesJson.isNotEmpty) {
        final List<dynamic> decodedList = json.decode(testimoniesJson);
        final testimonies = decodedList
            .map((item) => Testimony.fromJson(item as Map<String, dynamic>))
            .toList();

        _sortTestimonies(testimonies);
        return testimonies;
      }
      return [];
    } catch (e) {
      debugPrint('Error loading testimonies from storage: $e');
      return [];
    }
  }

  /// Saves testimonies to SharedPreferences and creates backup
  Future<void> _saveTestimoniesToStorage(
    List<Testimony> testimonies,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String testimoniesJson = json.encode(
        testimonies.map((testimony) => testimony.toJson()).toList(),
      );
      await prefs.setString('testimonies', testimoniesJson);

      // Optional backup to file
      await _backupTestimoniesToFile(testimonies);
    } catch (e) {
      debugPrint('Error saving testimonies to storage: $e');
    }
  }

  /// Creates a backup of testimonies to JSON file
  Future<void> _backupTestimoniesToFile(
    List<Testimony> testimonies,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/testimonies.json');

      final String testimoniesJson = json.encode(
        testimonies.map((testimony) => testimony.toJson()).toList(),
      );

      await file.writeAsString(testimoniesJson);
    } catch (e) {
      debugPrint('Error backing up testimonies to file: $e');
      // This is not critical, don't propagate the error
    }
  }

  /// Sorts testimonies by creation date (newest first)
  void _sortTestimonies(List<Testimony> testimonies) {
    testimonies.sort((a, b) => b.createdDate.compareTo(a.createdDate));
  }
}
