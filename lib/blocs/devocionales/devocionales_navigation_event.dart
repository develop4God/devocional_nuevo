// lib/blocs/devocionales/devocionales_navigation_event.dart

import 'package:equatable/equatable.dart';

/// Events for devotional navigation functionality
abstract class DevocionalesNavigationEvent extends Equatable {
  const DevocionalesNavigationEvent();

  @override
  List<Object?> get props => [];
}

/// Navigate to the next devotional
class NavigateToNext extends DevocionalesNavigationEvent {
  const NavigateToNext();
}

/// Navigate to the previous devotional
class NavigateToPrevious extends DevocionalesNavigationEvent {
  const NavigateToPrevious();
}

/// Navigate to a specific devotional by index
class NavigateToIndex extends DevocionalesNavigationEvent {
  final int index;

  const NavigateToIndex(this.index);

  @override
  List<Object?> get props => [index];
}

/// Navigate to the first unread devotional
class NavigateToFirstUnread extends DevocionalesNavigationEvent {
  final List<String> readDevocionalIds;

  const NavigateToFirstUnread(this.readDevocionalIds);

  @override
  List<Object?> get props => [readDevocionalIds];
}

/// Initialize navigation with a specific index (e.g., from deep link)
class InitializeNavigation extends DevocionalesNavigationEvent {
  final int initialIndex;
  final int totalDevocionales;

  const InitializeNavigation({
    required this.initialIndex,
    required this.totalDevocionales,
  });

  @override
  List<Object?> get props => [initialIndex, totalDevocionales];
}

/// Update total devotionals count (when list changes)
class UpdateTotalDevocionales extends DevocionalesNavigationEvent {
  final int totalDevocionales;

  const UpdateTotalDevocionales(this.totalDevocionales);

  @override
  List<Object?> get props => [totalDevocionales];
}
