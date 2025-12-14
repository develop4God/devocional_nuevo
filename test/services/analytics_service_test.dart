import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'analytics_service_test.mocks.dart';

@GenerateMocks([FirebaseAnalytics])
void main() {
  group('AnalyticsService', () {
    late MockFirebaseAnalytics mockAnalytics;
    late AnalyticsService analyticsService;

    setUp(() {
      mockAnalytics = MockFirebaseAnalytics();
      analyticsService = AnalyticsService(analytics: mockAnalytics);
    });

    group('logTtsPlay', () {
      test('should log tts_play event', () async {
        // Arrange
        when(mockAnalytics.logEvent(name: 'tts_play', parameters: null))
            .thenAnswer((_) async => {});

        // Act
        await analyticsService.logTtsPlay();

        // Assert
        verify(mockAnalytics.logEvent(name: 'tts_play', parameters: null))
            .called(1);
      });

      test('should not throw on analytics error', () async {
        // Arrange
        when(mockAnalytics.logEvent(name: 'tts_play', parameters: null))
            .thenThrow(Exception('Analytics error'));

        // Act & Assert - should not throw
        await analyticsService.logTtsPlay();
      });
    });

    group('logDevocionalComplete', () {
      test('should log devotional_read_complete event with required parameters',
          () async {
        // Arrange
        const devocionalId = 'dev_123';
        const campaignTag = 'custom_1';
        const source = 'read';

        when(mockAnalytics.logEvent(
          name: 'devotional_read_complete',
          parameters: anyNamed('parameters'),
        )).thenAnswer((_) async => {});

        // Act
        await analyticsService.logDevocionalComplete(
          devocionalId: devocionalId,
          campaignTag: campaignTag,
          source: source,
        );

        // Assert
        final captured = verify(mockAnalytics.logEvent(
          name: 'devotional_read_complete',
          parameters: captureAnyNamed('parameters'),
        )).captured;

        expect(captured.length, 1);
        final params = captured[0] as Map<String, Object>;
        expect(params['campaign_tag'], campaignTag);
        expect(params['devotional_id'], devocionalId);
        expect(params['source'], source);
      });

      test(
          'should log devotional_read_complete event with optional parameters',
          () async {
        // Arrange
        const devocionalId = 'dev_123';
        const campaignTag = 'custom_1';
        const source = 'read';
        const readingTime = 120;
        const scrollPercentage = 0.95;
        const listenedPercentage = 0.8;

        when(mockAnalytics.logEvent(
          name: 'devotional_read_complete',
          parameters: anyNamed('parameters'),
        )).thenAnswer((_) async => {});

        // Act
        await analyticsService.logDevocionalComplete(
          devocionalId: devocionalId,
          campaignTag: campaignTag,
          source: source,
          readingTimeSeconds: readingTime,
          scrollPercentage: scrollPercentage,
          listenedPercentage: listenedPercentage,
        );

        // Assert
        final captured = verify(mockAnalytics.logEvent(
          name: 'devotional_read_complete',
          parameters: captureAnyNamed('parameters'),
        )).captured;

        expect(captured.length, 1);
        final params = captured[0] as Map<String, Object>;
        expect(params['campaign_tag'], campaignTag);
        expect(params['devotional_id'], devocionalId);
        expect(params['source'], source);
        expect(params['reading_time_seconds'], readingTime);
        expect(params['scroll_percentage'], 95); // 0.95 * 100
        expect(params['listened_percentage'], 80); // 0.8 * 100
      });

      test('should not throw on analytics error', () async {
        // Arrange
        when(mockAnalytics.logEvent(
          name: 'devotional_read_complete',
          parameters: anyNamed('parameters'),
        )).thenThrow(Exception('Analytics error'));

        // Act & Assert - should not throw
        await analyticsService.logDevocionalComplete(
          devocionalId: 'dev_123',
          campaignTag: 'custom_1',
        );
      });
    });

    group('logCustomEvent', () {
      test('should log custom event with parameters', () async {
        // Arrange
        const eventName = 'custom_event';
        final parameters = {'key': 'value', 'count': 42};

        when(mockAnalytics.logEvent(
          name: eventName,
          parameters: anyNamed('parameters'),
        )).thenAnswer((_) async => {});

        // Act
        await analyticsService.logCustomEvent(
          eventName: eventName,
          parameters: parameters,
        );

        // Assert
        verify(mockAnalytics.logEvent(
          name: eventName,
          parameters: parameters,
        )).called(1);
      });
    });

    group('setUserProperty', () {
      test('should set user property', () async {
        // Arrange
        const name = 'user_type';
        const value = 'premium';

        when(mockAnalytics.setUserProperty(name: name, value: value))
            .thenAnswer((_) async => {});

        // Act
        await analyticsService.setUserProperty(name: name, value: value);

        // Assert
        verify(mockAnalytics.setUserProperty(name: name, value: value))
            .called(1);
      });
    });

    group('setUserId', () {
      test('should set user ID', () async {
        // Arrange
        const userId = 'user_123';

        when(mockAnalytics.setUserId(id: userId))
            .thenAnswer((_) async => {});

        // Act
        await analyticsService.setUserId(userId);

        // Assert
        verify(mockAnalytics.setUserId(id: userId)).called(1);
      });
    });

    group('resetAnalyticsData', () {
      test('should reset analytics data', () async {
        // Arrange
        when(mockAnalytics.resetAnalyticsData()).thenAnswer((_) async => {});

        // Act
        await analyticsService.resetAnalyticsData();

        // Assert
        verify(mockAnalytics.resetAnalyticsData()).called(1);
      });
    });
  });
}
