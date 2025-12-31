// lib/blocs/devocionales/devocionales_navigation_state.dart

import 'package:equatable/equatable.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';

/// States for devotional navigation functionality
abstract class DevocionalesNavigationState extends Equatable {
  const DevocionalesNavigationState();

  @override
  List<Object?> get props => [];
}

/// Initial state before navigation is initialized
class NavigationInitial extends DevocionalesNavigationState {
  const NavigationInitial();
}

/// Navigation is ready and at a specific index
class NavigationReady extends DevocionalesNavigationState {
  final int currentIndex;
  final int totalDevocionales;
  final Devocional currentDevocional;
  final List<Devocional> devocionales;
  final bool canNavigateNext;
  final bool canNavigatePrevious;

  const NavigationReady({
    required this.currentIndex,
    required this.totalDevocionales,
    required this.currentDevocional,
    required this.devocionales,
    required this.canNavigateNext,
    required this.canNavigatePrevious,
  });

  @override
  List<Object?> get props => [
        currentIndex,
        totalDevocionales,
        currentDevocional,
        devocionales,
        canNavigateNext,
        canNavigatePrevious,
      ];

  /// Create a copy with updated values
  NavigationReady copyWith({
    int? currentIndex,
    int? totalDevocionales,
    Devocional? currentDevocional,
    List<Devocional>? devocionales,
    bool? canNavigateNext,
    bool? canNavigatePrevious,
  }) {
    return NavigationReady(
      currentIndex: currentIndex ?? this.currentIndex,
      totalDevocionales: totalDevocionales ?? this.totalDevocionales,
      currentDevocional: currentDevocional ?? this.currentDevocional,
      devocionales: devocionales ?? this.devocionales,
      canNavigateNext: canNavigateNext ?? this.canNavigateNext,
      canNavigatePrevious: canNavigatePrevious ?? this.canNavigatePrevious,
    );
  }

  /// Factory to create NavigationReady with automatic calculation of navigation capabilities
  factory NavigationReady.calculate({
    required int currentIndex,
    required List<Devocional> devocionales,
  }) {
    final totalDevocionales = devocionales.length;
    return NavigationReady(
      currentIndex: currentIndex,
      totalDevocionales: totalDevocionales,
      currentDevocional: devocionales[currentIndex],
      devocionales: devocionales,
      canNavigateNext: currentIndex < totalDevocionales - 1,
      canNavigatePrevious: currentIndex > 0,
    );
  }
}

/// Navigation error state
class NavigationError extends DevocionalesNavigationState {
  final String message;

  const NavigationError(this.message);

  @override
  List<Object?> get props => [message];
}
