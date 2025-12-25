// lib/blocs/devocionales/devocionales_navigation_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'devocionales_navigation_event.dart';
import 'devocionales_navigation_state.dart';

/// BLoC for managing devotional navigation state
class DevocionalesNavigationBloc
    extends Bloc<DevocionalesNavigationEvent, DevocionalesNavigationState> {
  static const String _lastDevocionalIndexKey = 'lastDevocionalIndex';

  DevocionalesNavigationBloc() : super(const NavigationInitial()) {
    // Register event handlers
    on<InitializeNavigation>(_onInitializeNavigation);
    on<NavigateToNext>(_onNavigateToNext);
    on<NavigateToPrevious>(_onNavigateToPrevious);
    on<NavigateToIndex>(_onNavigateToIndex);
    on<NavigateToFirstUnread>(_onNavigateToFirstUnread);
    on<UpdateTotalDevocionales>(_onUpdateTotalDevocionales);
  }

  /// Initialize navigation with a specific index
  Future<void> _onInitializeNavigation(
    InitializeNavigation event,
    Emitter<DevocionalesNavigationState> emit,
  ) async {
    if (event.totalDevocionales <= 0) {
      emit(const NavigationError('No devotionals available'));
      return;
    }

    // Validate and clamp the initial index
    final validIndex = _clampIndex(event.initialIndex, event.totalDevocionales);

    emit(NavigationReady.calculate(
      currentIndex: validIndex,
      totalDevocionales: event.totalDevocionales,
    ));

    // Save the index to SharedPreferences
    await _saveCurrentIndex(validIndex);
  }

  /// Navigate to the next devotional
  Future<void> _onNavigateToNext(
    NavigateToNext event,
    Emitter<DevocionalesNavigationState> emit,
  ) async {
    if (state is! NavigationReady) return;

    final currentState = state as NavigationReady;

    // Check if we can navigate next
    if (!currentState.canNavigateNext) {
      return; // Already at the last devotional
    }

    final newIndex = currentState.currentIndex + 1;

    emit(NavigationReady.calculate(
      currentIndex: newIndex,
      totalDevocionales: currentState.totalDevocionales,
    ));

    await _saveCurrentIndex(newIndex);
  }

  /// Navigate to the previous devotional
  Future<void> _onNavigateToPrevious(
    NavigateToPrevious event,
    Emitter<DevocionalesNavigationState> emit,
  ) async {
    if (state is! NavigationReady) return;

    final currentState = state as NavigationReady;

    // Check if we can navigate previous
    if (!currentState.canNavigatePrevious) {
      return; // Already at the first devotional
    }

    final newIndex = currentState.currentIndex - 1;

    emit(NavigationReady.calculate(
      currentIndex: newIndex,
      totalDevocionales: currentState.totalDevocionales,
    ));

    await _saveCurrentIndex(newIndex);
  }

  /// Navigate to a specific index
  Future<void> _onNavigateToIndex(
    NavigateToIndex event,
    Emitter<DevocionalesNavigationState> emit,
  ) async {
    if (state is! NavigationReady) return;

    final currentState = state as NavigationReady;

    // Validate the index
    final validIndex = _clampIndex(event.index, currentState.totalDevocionales);

    // Don't emit if we're already at this index
    if (validIndex == currentState.currentIndex) {
      return;
    }

    emit(NavigationReady.calculate(
      currentIndex: validIndex,
      totalDevocionales: currentState.totalDevocionales,
    ));

    await _saveCurrentIndex(validIndex);
  }

  /// Navigate to the first unread devotional
  Future<void> _onNavigateToFirstUnread(
    NavigateToFirstUnread event,
    Emitter<DevocionalesNavigationState> emit,
  ) async {
    if (state is! NavigationReady) return;

    final currentState = state as NavigationReady;

    // This method needs access to the devotionals list to find the first unread
    // For now, we'll just emit the current state
    // The actual logic should be handled in the UI or a service layer
    // that has access to both the devotionals and the read IDs

    // This is a placeholder - the actual implementation would require
    // the devotionals list to be passed in the event
    emit(currentState);
  }

  /// Update total devotionals count
  Future<void> _onUpdateTotalDevocionales(
    UpdateTotalDevocionales event,
    Emitter<DevocionalesNavigationState> emit,
  ) async {
    if (state is! NavigationReady) return;

    final currentState = state as NavigationReady;

    if (event.totalDevocionales <= 0) {
      emit(const NavigationError('No devotionals available'));
      return;
    }

    // Ensure current index is still valid with the new total
    final validIndex = _clampIndex(
      currentState.currentIndex,
      event.totalDevocionales,
    );

    emit(NavigationReady.calculate(
      currentIndex: validIndex,
      totalDevocionales: event.totalDevocionales,
    ));

    if (validIndex != currentState.currentIndex) {
      await _saveCurrentIndex(validIndex);
    }
  }

  /// Clamp index to valid range [0, totalDevocionales - 1]
  int _clampIndex(int index, int totalDevocionales) {
    if (totalDevocionales <= 0) return 0;
    if (index < 0) return 0;
    if (index >= totalDevocionales) return totalDevocionales - 1;
    return index;
  }

  /// Save the current index to SharedPreferences
  Future<void> _saveCurrentIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastDevocionalIndexKey, index);
    } catch (e) {
      // Fail silently - navigation should continue to work even if persistence fails
      // In a production app, you might want to log this error
    }
  }

  /// Load the last saved index from SharedPreferences
  static Future<int> loadSavedIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_lastDevocionalIndexKey) ?? 0;
    } catch (e) {
      return 0; // Default to first devotional
    }
  }

  /// Helper method to find first unread devotional index
  /// This is a utility method that can be called from outside the BLoC
  static int findFirstUnreadDevocionalIndex(
    List<Devocional> devocionales,
    List<String> readDevocionalIds,
  ) {
    if (devocionales.isEmpty) return 0;

    // Start from index 0 and find the first unread devotional
    for (int i = 0; i < devocionales.length; i++) {
      if (!readDevocionalIds.contains(devocionales[i].id)) {
        return i;
      }
    }

    // If all devotionals are read, start from the beginning
    return 0;
  }
}
