// lib/blocs/devocionales/devocionales_navigation_state.dart

import 'package:equatable/equatable.dart';

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
  final bool canNavigateNext;
  final bool canNavigatePrevious;

  const NavigationReady({
    required this.currentIndex,
    required this.totalDevocionales,
    required this.canNavigateNext,
    required this.canNavigatePrevious,
  });

  @override
  List<Object?> get props => [
        currentIndex,
        totalDevocionales,
        canNavigateNext,
        canNavigatePrevious,
      ];

  /// Create a copy with updated values
  NavigationReady copyWith({
    int? currentIndex,
    int? totalDevocionales,
    bool? canNavigateNext,
    bool? canNavigatePrevious,
  }) {
    return NavigationReady(
      currentIndex: currentIndex ?? this.currentIndex,
      totalDevocionales: totalDevocionales ?? this.totalDevocionales,
      canNavigateNext: canNavigateNext ?? this.canNavigateNext,
      canNavigatePrevious: canNavigatePrevious ?? this.canNavigatePrevious,
    );
  }

  /// Factory to create NavigationReady with automatic calculation of navigation capabilities
  factory NavigationReady.calculate({
    required int currentIndex,
    required int totalDevocionales,
  }) {
    return NavigationReady(
      currentIndex: currentIndex,
      totalDevocionales: totalDevocionales,
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
