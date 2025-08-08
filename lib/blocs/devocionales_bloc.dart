// lib/blocs/devocionales_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'devocionales_event.dart';
import 'devocionales_state.dart';

class DevocionalesBloc extends Bloc<DevocionalesEvent, DevocionalesState> {
  final List<Devocional> _allDevocionales = [];
  String _selectedVersion = 'RVR1960';

  DevocionalesBloc() : super(DevocionalesInitial()) {
    on<LoadDevocionales>(_onLoadDevocionales);
    on<ChangeVersion>(_onChangeVersion);
    on<ToggleFavorite>(_onToggleFavorite);
  }

  Future<void> _onLoadDevocionales(
    LoadDevocionales event,
    Emitter<DevocionalesState> emit,
  ) async {
    emit(DevocionalesLoading());

    try {
      // This would normally fetch data from API or local storage
      // For now, emit a simple success state
      final filteredDevocionales =
          _allDevocionales.where((d) => d.version == _selectedVersion).toList();

      emit(DevocionalesLoaded(
        devocionales: filteredDevocionales,
        selectedVersion: _selectedVersion,
      ));
    } catch (error) {
      emit(DevocionalesError('Error loading devocionales: $error'));
    }
  }

  void _onChangeVersion(
    ChangeVersion event,
    Emitter<DevocionalesState> emit,
  ) {
    _selectedVersion = event.version;

    final filteredDevocionales =
        _allDevocionales.where((d) => d.version == _selectedVersion).toList();

    emit(DevocionalesLoaded(
      devocionales: filteredDevocionales,
      selectedVersion: _selectedVersion,
    ));
  }

  void _onToggleFavorite(
    ToggleFavorite event,
    Emitter<DevocionalesState> emit,
  ) {
    // Handle favorite toggle logic here
    // For now, just re-emit the current state
    if (state is DevocionalesLoaded) {
      final currentState = state as DevocionalesLoaded;
      emit(DevocionalesLoaded(
        devocionales: currentState.devocionales,
        selectedVersion: currentState.selectedVersion,
      ));
    }
  }
}
