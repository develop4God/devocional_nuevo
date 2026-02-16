import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_bloc.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_event.dart';
import 'package:devocional_nuevo/blocs/devocionales/devocionales_navigation_state.dart';
import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Direction of devotional navigation.
enum DevocionalNavigationDirection { next, previous }

/// Handles devotional navigation logic: audio stop, BLoC dispatch,
/// analytics, haptics, and error reporting.
///
/// Follows Single Responsibility Principle: encapsulates the shared
/// navigation sequence used by both next and previous navigation.
/// Eliminates ~60 lines of duplicated code from `DevocionalesPage`.
class DevocionalNavigationHelper {
  final DevocionalesNavigationBloc Function() getBloc;
  final AudioController? Function() getAudioController;
  final FlutterTts flutterTts;
  final ScrollController scrollController;
  final Duration audioStopDelay;
  final Duration scrollToTopDuration;

  const DevocionalNavigationHelper({
    required this.getBloc,
    required this.getAudioController,
    required this.flutterTts,
    required this.scrollController,
    this.audioStopDelay = const Duration(milliseconds: 100),
    this.scrollToTopDuration = const Duration(milliseconds: 300),
  });

  /// Navigate in the given [direction].
  ///
  /// Returns `true` if navigation was executed, `false` if blocked.
  /// [isMounted] should return `context.mounted` for the calling widget.
  /// [onPostNavigation] is called after successful navigation (e.g., to
  /// show an invitation dialog on "next").
  Future<bool> navigate({
    required DevocionalNavigationDirection direction,
    required bool Function() isMounted,
    VoidCallback? onPostNavigation,
  }) async {
    final bloc = getBloc();

    try {
      // Guard: Don't navigate if BLoC is not ready
      if (bloc.state is! NavigationReady) {
        debugPrint('⚠️ Navigation blocked: BLoC not ready yet');
        return false;
      }

      // Stop audio/TTS before navigation
      await _stopAudioBeforeNavigation(isMounted);
      if (!isMounted()) return false;

      // Get current state for analytics
      final currentState = bloc.state;
      final currentIndex =
          currentState is NavigationReady ? currentState.currentIndex : 0;
      final totalDevocionales =
          currentState is NavigationReady ? currentState.totalDevocionales : 0;

      // Dispatch navigation event
      bloc.add(
        direction == DevocionalNavigationDirection.next
            ? const NavigateToNext()
            : const NavigateToPrevious(),
      );

      // Scroll to top
      _scrollToTop();

      // Trigger haptic feedback
      HapticFeedback.mediumImpact();

      // Log analytics event
      await _logAnalytics(direction, currentIndex, totalDevocionales);

      // Post-navigation callback (e.g., show invitation dialog)
      if (isMounted() && onPostNavigation != null) {
        onPostNavigation();
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ BLoC navigation error: $e');
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: direction == DevocionalNavigationDirection.next
            ? 'NavigationBloc.NavigateToNext failed'
            : 'NavigationBloc.NavigateToPrevious failed',
        information: [
          'Feature: Navigation BLoC',
          'Action: Navigate to ${direction.name} devotional',
        ],
        fatal: false,
      );
      return false;
    }
  }

  Future<void> _stopAudioBeforeNavigation(bool Function() isMounted) async {
    final audioController = getAudioController();
    if (audioController != null && audioController.isActive) {
      debugPrint(
        'DevocionalesPage: Stopping AudioController before navigation',
      );
      await audioController.stop();
      if (!isMounted()) return;
      await Future.delayed(audioStopDelay);
    } else {
      await flutterTts.stop();
    }
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0.0,
          duration: scrollToTopDuration,
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _logAnalytics(
    DevocionalNavigationDirection direction,
    int currentIndex,
    int totalDevocionales,
  ) async {
    final analytics = getService<AnalyticsService>();
    if (direction == DevocionalNavigationDirection.next) {
      await analytics.logNavigationNext(
        currentIndex: currentIndex,
        totalDevocionales: totalDevocionales,
        viaBloc: 'true',
      );
    } else {
      await analytics.logNavigationPrevious(
        currentIndex: currentIndex,
        totalDevocionales: totalDevocionales,
        viaBloc: 'true',
      );
    }
  }
}
