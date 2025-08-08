// lib/blocs/devocionales_state.dart

import 'package:devocional_nuevo/models/devocional_model.dart';

abstract class DevocionalesState {}

class DevocionalesInitial extends DevocionalesState {}

class DevocionalesLoading extends DevocionalesState {}

class DevocionalesLoaded extends DevocionalesState {
  final List<Devocional> devocionales;
  final String selectedVersion;

  DevocionalesLoaded({
    required this.devocionales,
    required this.selectedVersion,
  });
}

class DevocionalesError extends DevocionalesState {
  final String message;

  DevocionalesError(this.message);
}
