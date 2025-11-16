// lib/blocs/thanksgiving_state.dart

import 'package:devocional_nuevo/models/thanksgiving_model.dart';

/// Base class for thanksgiving states
abstract class ThanksgivingState {}

/// Initial state before any thanksgivings are loaded
class ThanksgivingInitial extends ThanksgivingState {}

/// Loading state while thanksgivings are being fetched
class ThanksgivingLoading extends ThanksgivingState {}

/// State when thanksgivings are successfully loaded
class ThanksgivingLoaded extends ThanksgivingState {
  final List<Thanksgiving> thanksgivings;
  final String? errorMessage;

  ThanksgivingLoaded({
    required this.thanksgivings,
    this.errorMessage,
  });

  /// Creates a copy with updated fields
  ThanksgivingLoaded copyWith({
    List<Thanksgiving>? thanksgivings,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ThanksgivingLoaded(
      thanksgivings: thanksgivings ?? this.thanksgivings,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Error state when loading thanksgivings fails
class ThanksgivingError extends ThanksgivingState {
  final String message;

  ThanksgivingError(this.message);
}
