// lib/blocs/devocionales/devocionales_navigation_event.dart

import 'package:equatable/equatable.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';

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

/// Initialize navigation with a list of devotionals
class InitializeNavigation extends DevocionalesNavigationEvent {
  final int initialIndex;
  final List<Devocional> devocionales;

  const InitializeNavigation({
    required this.initialIndex,
    required this.devocionales,
  });

  @override
  List<Object?> get props => [initialIndex, devocionales];
}

/// Update devotionals list (when list changes)
class UpdateDevocionales extends DevocionalesNavigationEvent {
  final List<Devocional> devocionales;

  const UpdateDevocionales(this.devocionales);

  @override
  List<Object?> get props => [devocionales];
}
