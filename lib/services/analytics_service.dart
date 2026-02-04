import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Analytics Service for Firebase Analytics tracking
///
/// This service provides a centralized way to track user events and behaviors
/// using Firebase Analytics. It is registered via Dependency Injection (not singleton)
/// to enable proper testing and decoupling.
///
/// Usage:
/// ```dart
/// final analytics = getService<AnalyticsService>();
/// await analytics.logTtsPlay();
/// await analytics.logDevocionalComplete(devocionalId: 'dev_123', campaignTag: 'custom_1');
/// ```
class AnalyticsService {
  FirebaseAnalytics? _analytics;

  // Analytics error telemetry
  static int _analyticsErrorCount = 0;

  static int get analyticsErrorCount => _analyticsErrorCount;

  /// Constructor with optional FirebaseAnalytics instance (for testing)
  AnalyticsService({FirebaseAnalytics? analytics}) : _analytics = analytics;

  /// Get the FirebaseAnalytics instance (for navigation observers, etc.)
  FirebaseAnalytics get analytics => _analytics ??= FirebaseAnalytics.instance;

  /// Validates campaign tag format (Firebase requirements: alphanumeric + underscore)
  static bool isValidCampaignTag(String tag) {
    return tag.isNotEmpty && RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(tag);
  }

  /// Logs analytics errors for debugging/telemetry
  static void _logAnalyticsError(String operation, dynamic error) {
    _analyticsErrorCount++;
    debugPrint(
      '❌ Analytics error #$_analyticsErrorCount in $operation: $error',
    );

    if (_analyticsErrorCount > 10) {
      debugPrint(
        '⚠️ HIGH ANALYTICS ERROR RATE: $_analyticsErrorCount failures detected',
      );
    }
  }

  /// Resets error count (for testing purposes)
  @visibleForTesting
  static void resetErrorCount() {
    _analyticsErrorCount = 0;
  }

  /// Log TTS Play button press event
  ///
  /// Event name: `tts_play`
  ///
  /// This tracks when users press the TTS Play button to listen to devotionals.
  /// Helps measure engagement with the audio feature.
  Future<void> logTtsPlay() async {
    try {
      await analytics.logEvent(name: 'tts_play', parameters: null);
      debugPrint('📊 Analytics: tts_play event logged');
    } catch (e) {
      _logAnalyticsError('tts_play', e);
      // Fail silently - analytics errors should not affect app functionality
    }
  }

  /// Log Devotional Read Complete event
  ///
  /// Event name: `devotional_read_complete`
  /// Parameters:
  /// - `campaign_tag`: Custom parameter for audience segmentation (e.g., 'custom_1')
  /// - `devotional_id`: ID of the devotional that was completed
  /// - `source`: How the devotional was consumed ('read' or 'heard')
  /// - `reading_time_seconds`: Time spent reading (optional)
  /// - `scroll_percentage`: How much was scrolled (optional)
  /// - `listened_percentage`: How much audio was played (optional)
  ///
  /// This enables the marketing team to create custom audiences in Firebase
  /// for targeted In-App Messaging campaigns (e.g., donation requests).
  Future<void> logDevocionalComplete({
    required String devocionalId,
    required String campaignTag,
    String source = 'read',
    int? readingTimeSeconds,
    double? scrollPercentage,
    double? listenedPercentage,
  }) async {
    try {
      // Validate campaign tag format
      if (!isValidCampaignTag(campaignTag)) {
        _logAnalyticsError(
          'devotional_read_complete',
          'Invalid campaign tag format: "$campaignTag"',
        );
        return;
      }

      final parameters = <String, Object>{
        'campaign_tag': campaignTag,
        'devotional_id': devocionalId,
        'source': source,
      };

      // Add optional parameters if provided
      if (readingTimeSeconds != null) {
        parameters['reading_time_seconds'] = readingTimeSeconds;
      }
      if (scrollPercentage != null) {
        parameters['scroll_percentage'] = (scrollPercentage * 100).round();
      }
      if (listenedPercentage != null) {
        parameters['listened_percentage'] = (listenedPercentage * 100).round();
      }

      await analytics.logEvent(
        name: 'devotional_read_complete',
        parameters: parameters,
      );
      debugPrint(
        '📊 Analytics: devotional_read_complete event logged for $devocionalId (campaign_tag: $campaignTag, source: $source)',
      );
    } catch (e) {
      _logAnalyticsError('devotional_read_complete', e);
      // Fail silently - analytics errors should not affect app functionality
    }
  }

  /// Log custom event with parameters
  ///
  /// Generic method for logging any custom event
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    try {
      await analytics.logEvent(name: eventName, parameters: parameters);
      debugPrint('📊 Analytics: $eventName event logged');
    } catch (e) {
      _logAnalyticsError(eventName, e);
      // Fail silently
    }
  }

  /// Set user property
  ///
  /// Useful for audience segmentation
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await analytics.setUserProperty(name: name, value: value);
      debugPrint('📊 Analytics: User property set - $name: $value');
    } catch (e) {
      debugPrint('❌ Analytics error setting user property: $e');
      // Fail silently
    }
  }

  /// Set user ID
  Future<void> setUserId(String? userId) async {
    try {
      await analytics.setUserId(id: userId);
      debugPrint('📊 Analytics: User ID set - $userId');
    } catch (e) {
      debugPrint('❌ Analytics error setting user ID: $e');
      // Fail silently
    }
  }

  /// Reset analytics data (for testing or logout)
  Future<void> resetAnalyticsData() async {
    try {
      await analytics.resetAnalyticsData();
      debugPrint('📊 Analytics: Data reset');
    } catch (e) {
      debugPrint('❌ Analytics error resetting data: $e');
      // Fail silently
    }
  }

  /// Log bottom bar action event
  ///
  /// Event name: `bottom_bar_action`
  /// Parameter: `action` (e.g., 'favorite', 'prayers', 'bible', 'share', 'progress', 'settings')
  Future<void> logBottomBarAction({required String action}) async {
    try {
      debugPrint('🔥 [BottomBar] Tap: $action');
      await analytics.logEvent(
        name: 'bottom_bar_action',
        parameters: {'action': action},
      );
      debugPrint('📊 Analytics: bottom_bar_action event logged ($action)');
    } catch (e) {
      _logAnalyticsError('bottom_bar_action', e);
    }
  }

  /// Log app initialization event
  ///
  /// Event name: `app_init`
  /// Parameters: Additional context parameters (e.g., use_navigation_bloc)
  Future<void> logAppInit({Map<String, Object>? parameters}) async {
    try {
      await analytics.logEvent(name: 'app_init', parameters: parameters);
      debugPrint('📊 Analytics: app_init event logged');
    } catch (e) {
      _logAnalyticsError('app_init', e);
    }
  }

  /// Log navigation to next devotional
  ///
  /// Event name: `navigation_next`
  /// Parameters:
  /// - `current_index`: Current devotional index
  /// - `total_devocionales`: Total number of devotionals
  /// - `via_bloc`: Whether navigation used BLoC ('true') or legacy ('false')
  /// - `fallback_reason`: Reason for fallback to legacy (optional)
  Future<void> logNavigationNext({
    required int currentIndex,
    required int totalDevocionales,
    required String viaBloc,
    String? fallbackReason,
  }) async {
    try {
      final parameters = <String, Object>{
        'current_index': currentIndex,
        'total_devocionales': totalDevocionales,
        'via_bloc': viaBloc,
      };

      if (fallbackReason != null) {
        parameters['fallback_reason'] = fallbackReason;
      }

      await analytics.logEvent(
        name: 'navigation_next',
        parameters: parameters,
      );
      debugPrint('📊 Analytics: navigation_next event logged');
    } catch (e) {
      _logAnalyticsError('navigation_next', e);
    }
  }

  /// Log navigation to previous devotional
  ///
  /// Event name: `navigation_previous`
  /// Parameters:
  /// - `current_index`: Current devotional index
  /// - `total_devocionales`: Total number of devotionals
  /// - `via_bloc`: Whether navigation used BLoC ('true') or legacy ('false')
  /// - `fallback_reason`: Reason for fallback to legacy (optional)
  Future<void> logNavigationPrevious({
    required int currentIndex,
    required int totalDevocionales,
    required String viaBloc,
    String? fallbackReason,
  }) async {
    try {
      final parameters = <String, Object>{
        'current_index': currentIndex,
        'total_devocionales': totalDevocionales,
        'via_bloc': viaBloc,
      };

      if (fallbackReason != null) {
        parameters['fallback_reason'] = fallbackReason;
      }

      await analytics.logEvent(
        name: 'navigation_previous',
        parameters: parameters,
      );
      debugPrint('📊 Analytics: navigation_previous event logged');
    } catch (e) {
      _logAnalyticsError('navigation_previous', e);
    }
  }

  /// Log FAB (Floating Action Button) tap event
  ///
  /// Event name: `fab_tapped`
  /// Parameters:
  /// - `source`: Where the FAB was tapped ('devocionales_page' or 'prayers_page')
  Future<void> logFabTapped({required String source}) async {
    try {
      debugPrint('🔥 [FAB] Tapped on: $source');
      await analytics.logEvent(
        name: 'fab_tapped',
        parameters: {'source': source},
      );
      debugPrint('📊 Analytics: fab_tapped event logged ($source)');
    } catch (e) {
      _logAnalyticsError('fab_tapped', e);
    }
  }

  /// Log FAB choice selection event
  ///
  /// Event name: `fab_choice_selected`
  /// Parameters:
  /// - `source`: Where the choice was made ('devocionales_page' or 'prayers_page')
  /// - `choice`: What was selected ('prayer', 'thanksgiving', or 'testimony')
  Future<void> logFabChoiceSelected({
    required String source,
    required String choice,
  }) async {
    try {
      debugPrint('🔥 [FAB] Choice selected: $choice on $source');
      await analytics.logEvent(
        name: 'fab_choice_selected',
        parameters: {
          'source': source,
          'choice': choice,
        },
      );
      debugPrint(
        '📊 Analytics: fab_choice_selected event logged ($choice on $source)',
      );
    } catch (e) {
      _logAnalyticsError('fab_choice_selected', e);
    }
  }

  /// Log Discovery page actions
  ///
  /// Event name: `discovery_action`
  /// Parameters:
  /// - `action`: The action performed (e.g., 'study_opened', 'study_completed', 'study_shared', 'toggle_view')
  /// - `study_id`: ID of the study (optional, for study-specific actions)
  Future<void> logDiscoveryAction({
    required String action,
    String? studyId,
  }) async {
    try {
      debugPrint('🔥 [Discovery] Action: $action');
      final parameters = <String, Object>{'action': action};
      if (studyId != null) {
        parameters['study_id'] = studyId;
      }
      await analytics.logEvent(
        name: 'discovery_action',
        parameters: parameters,
      );
      debugPrint('📊 Analytics: discovery_action event logged ($action)');
    } catch (e) {
      _logAnalyticsError('discovery_action', e);
    }
  }
}
