// lib/blocs/devocionales/devocionales_navigation_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/repositories/navigation_repository.dart';
import 'package:devocional_nuevo/repositories/navigation_repository_impl.dart';
import 'package:devocional_nuevo/repositories/devocional_repository.dart';
import 'package:devocional_nuevo/repositories/devocional_repository_impl.dart';
import 'devocionales_navigation_event.dart';
import 'devocionales_navigation_state.dart';

/// BLoC for managing devotional navigation state
class DevocionalesNavigationBloc
    extends Bloc<DevocionalesNavigationEvent, DevocionalesNavigationState> {
  final NavigationRepository _navigationRepository;
  final DevocionalRepository _devocionalRepository;

  DevocionalesNavigationBloc({
    NavigationRepository? navigationRepository,
    DevocionalRepository? devocionalRepository,
  })  : _navigationRepository =
            navigationRepository ?? NavigationRepositoryImpl(),
        _devocionalRepository =
            devocionalRepository ?? DevocionalRepositoryImpl(),
        super(const NavigationInitial()) {
    // Register event handlers
    on<InitializeNavigation>(_onInitializeNavigation);
    on<NavigateToNext>(_onNavigateToNext);
    on<NavigateToPrevious>(_onNavigateToPrevious);
    on<NavigateToIndex>(_onNavigateToIndex);
    on<NavigateToFirstUnread>(_onNavigateToFirstUnread);
    on<UpdateDevocionales>(_onUpdateDevocionales);
  }

  /// Initialize navigation with a list of devotionals
  Future<void> _onInitializeNavigation(
    InitializeNavigation event,
    Emitter<DevocionalesNavigationState> emit,
  ) async {
    if (event.devocionales.isEmpty) {
      emit(const NavigationError('No devotionals available'));
      return;
    }

    // Validate and clamp the initial index
    final validIndex = _clampIndex(
      event.initialIndex,
      event.devocionales.length,
    );

    emit(
      NavigationReady.calculate(
        currentIndex: validIndex,
        devocionales: event.devocionales,
      ),
    );

    // Save the index via repository
    await _navigationRepository.saveCurrentIndex(validIndex);
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

    emit(
      NavigationReady.calculate(
        currentIndex: newIndex,
        devocionales: currentState.devocionales,
      ),
    );

    await _navigationRepository.saveCurrentIndex(newIndex);
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

    emit(
      NavigationReady.calculate(
        currentIndex: newIndex,
        devocionales: currentState.devocionales,
      ),
    );

    await _navigationRepository.saveCurrentIndex(newIndex);
  }

  /// Navigate to a specific index
  Future<void> _onNavigateToIndex(
    NavigateToIndex event,
    Emitter<DevocionalesNavigationState> emit,
  ) async {
    if (state is! NavigationReady) return;

    final currentState = state as NavigationReady;

    // Validate the index
    final validIndex = _clampIndex(
      event.index,
      currentState.devocionales.length,
    );

    // Don't emit if we're already at this index
    if (validIndex == currentState.currentIndex) {
      return;
    }

    emit(
      NavigationReady.calculate(
        currentIndex: validIndex,
        devocionales: currentState.devocionales,
      ),
    );

    await _navigationRepository.saveCurrentIndex(validIndex);
  }

  /// Navigate to the first unread devotional
  Future<void> _onNavigateToFirstUnread(
    NavigateToFirstUnread event,
    Emitter<DevocionalesNavigationState> emit,
  ) async {
    if (state is! NavigationReady) return;

    final currentState = state as NavigationReady;

    // Find the first unread devotional using the repository
    final firstUnreadIndex =
        _devocionalRepository.findFirstUnreadDevocionalIndex(
      currentState.devocionales,
      event.readDevocionalIds,
    );

    // Don't emit if we're already at this index
    if (firstUnreadIndex == currentState.currentIndex) {
      return;
    }

    emit(
      NavigationReady.calculate(
        currentIndex: firstUnreadIndex,
        devocionales: currentState.devocionales,
      ),
    );

    await _navigationRepository.saveCurrentIndex(firstUnreadIndex);
  }

  /// Update devotionals list
  Future<void> _onUpdateDevocionales(
    UpdateDevocionales event,
    Emitter<DevocionalesNavigationState> emit,
  ) async {
    if (state is! NavigationReady) return;

    if (event.devocionales.isEmpty) {
      emit(const NavigationError('No devotionals available'));
      return;
    }

    // FIX: When devotionals update (language/version change),
    // we must find the first unread in the NEW list, instead of just keeping the index.
    final firstUnreadIndex =
        _devocionalRepository.findFirstUnreadDevocionalIndex(
      event.devocionales,
      event.readDevocionalIds,
    );

    emit(
      NavigationReady.calculate(
        currentIndex: firstUnreadIndex,
        devocionales: event.devocionales,
      ),
    );

    await _navigationRepository.saveCurrentIndex(firstUnreadIndex);
  }

  /// Clamp index to valid range [0, totalDevocionales - 1]
  int _clampIndex(int index, int totalDevocionales) {
    if (totalDevocionales <= 0) return 0;
    if (index < 0) return 0;
    if (index >= totalDevocionales) return totalDevocionales - 1;
    return index;
  }

  /// Helper method to find first unread devotional index
  /// Delegates to the DevocionalRepository
  int findFirstUnreadDevocionalIndex(
    List<Devocional> devocionales,
    List<String> readDevocionalIds,
  ) {
    return _devocionalRepository.findFirstUnreadDevocionalIndex(
      devocionales,
      readDevocionalIds,
    );
  }
}
