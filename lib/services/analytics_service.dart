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
  final FirebaseAnalytics _analytics;

  /// Constructor with optional FirebaseAnalytics instance (for testing)
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  /// Get the FirebaseAnalytics instance (for navigation observers, etc.)
  FirebaseAnalytics get analytics => _analytics;

  /// Log TTS Play button press event
  ///
  /// Event name: `tts_play`
  ///
  /// This tracks when users press the TTS Play button to listen to devotionals.
  /// Helps measure engagement with the audio feature.
  Future<void> logTtsPlay() async {
    try {
      await _analytics.logEvent(
        name: 'tts_play',
        parameters: null,
      );
      debugPrint('📊 Analytics: tts_play event logged');
    } catch (e) {
      debugPrint('❌ Analytics error logging tts_play: $e');
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

      await _analytics.logEvent(
        name: 'devotional_read_complete',
        parameters: parameters,
      );
      debugPrint(
          '📊 Analytics: devotional_read_complete event logged for $devocionalId (campaign_tag: $campaignTag, source: $source)');
    } catch (e) {
      debugPrint('❌ Analytics error logging devotional_read_complete: $e');
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
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
      debugPrint('📊 Analytics: $eventName event logged');
    } catch (e) {
      debugPrint('❌ Analytics error logging $eventName: $e');
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
      await _analytics.setUserProperty(name: name, value: value);
      debugPrint('📊 Analytics: User property set - $name: $value');
    } catch (e) {
      debugPrint('❌ Analytics error setting user property: $e');
      // Fail silently
    }
  }

  /// Set user ID
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      debugPrint('📊 Analytics: User ID set - $userId');
    } catch (e) {
      debugPrint('❌ Analytics error setting user ID: $e');
      // Fail silently
    }
  }

  /// Reset analytics data (for testing or logout)
  Future<void> resetAnalyticsData() async {
    try {
      await _analytics.resetAnalyticsData();
      debugPrint('📊 Analytics: Data reset');
    } catch (e) {
      debugPrint('❌ Analytics error resetting data: $e');
      // Fail silently
    }
  }
}
