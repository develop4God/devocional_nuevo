// lib/blocs/testimony_state.dart

import 'package:devocional_nuevo/models/testimony_model.dart';

/// Base class for testimony states
abstract class TestimonyState {}

/// Initial state before any testimonies are loaded
class TestimonyInitial extends TestimonyState {}

/// Loading state while testimonies are being fetched
class TestimonyLoading extends TestimonyState {}

/// State when testimonies are successfully loaded
class TestimonyLoaded extends TestimonyState {
  final List<Testimony> testimonies;
  final String? errorMessage;

  TestimonyLoaded({required this.testimonies, this.errorMessage});

  /// Creates a copy with updated fields
  TestimonyLoaded copyWith({
    List<Testimony>? testimonies,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TestimonyLoaded(
      testimonies: testimonies ?? this.testimonies,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Error state when loading testimonies fails
class TestimonyError extends TestimonyState {
  final String message;

  TestimonyError(this.message);
}
