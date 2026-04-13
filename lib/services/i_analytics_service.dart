// lib/services/i_analytics_service.dart
//
// Abstract interface for [AnalyticsService].
// Depend on this interface (not the concrete class) for
// Dependency Inversion and easy test mocking.

/// Abstract interface defining Firebase Analytics service capabilities.
abstract class IAnalyticsService {
  /// Log TTS Play button press event
  ///
  /// Event name: `tts_play`
  Future<void> logTtsPlay();

  /// Log Devotional Read Complete event
  ///
  /// Event name: `devotional_read_complete`
  Future<void> logDevocionalComplete({
    required String devocionalId,
    required String campaignTag,
    String source = 'read',
    int? readingTimeSeconds,
    double? scrollPercentage,
    double? listenedPercentage,
  });

  /// Log custom event with parameters
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  });

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String value,
  });

  /// Set user ID
  Future<void> setUserId(String? userId);

  /// Reset analytics data
  Future<void> resetAnalyticsData();

  /// Log bottom bar action event
  ///
  /// Event name: `bottom_bar_action`
  Future<void> logBottomBarAction({required String action});

  /// Log app initialization event
  ///
  /// Event name: `app_init`
  Future<void> logAppInit({Map<String, Object>? parameters});

  /// Log navigation to next devotional
  ///
  /// Event name: `navigation_next`
  Future<void> logNavigationNext({
    required int currentIndex,
    required int totalDevocionales,
    required String viaBloc,
    String? fallbackReason,
  });

  /// Log navigation to previous devotional
  ///
  /// Event name: `navigation_previous`
  Future<void> logNavigationPrevious({
    required int currentIndex,
    required int totalDevocionales,
    required String viaBloc,
    String? fallbackReason,
  });

  /// Log FAB (Floating Action Button) tap event
  ///
  /// Event name: `fab_tapped`
  Future<void> logFabTapped({required String source});

  /// Log FAB choice selection event
  ///
  /// Event name: `fab_choice_selected`
  Future<void> logFabChoiceSelected({
    required String source,
    required String choice,
  });

  /// Log Discovery page actions
  ///
  /// Event name: `discovery_action`
  Future<void> logDiscoveryAction({
    required String action,
    String? studyId,
  });

  /// Log Encounter page actions
  ///
  /// Event name: `encounter_action`
  Future<void> logEncounterAction({
    required String action,
    String? encounterId,
    int? cardOrder,
  });

  /// Log Bible Reader page open event
  ///
  /// Event name: `bible_open`
  Future<void> logBibleOpen({
    String? translation,
    String? book,
    int? chapter,
  });

  /// Log TTS Bible Play button press event
  ///
  /// Event name: `tts_bible_play`
  Future<void> logTtsBiblePlay({
    String? translation,
    String? book,
    int? chapter,
  });
}
