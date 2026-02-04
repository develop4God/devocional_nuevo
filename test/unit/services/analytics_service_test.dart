import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'analytics_service_test.mocks.dart';

@Tags(['unit', 'services'])
@GenerateMocks([FirebaseAnalytics])
void main() {
  group('AnalyticsService', () {
    late MockFirebaseAnalytics mockAnalytics;
    late AnalyticsService analyticsService;

    setUp(() {
      mockAnalytics = MockFirebaseAnalytics();
      analyticsService = AnalyticsService(analytics: mockAnalytics);
      // Reset error count before each test
      AnalyticsService.resetErrorCount();
    });

    group('logTtsPlay', () {
      test('should log tts_play event', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(name: 'tts_play', parameters: null),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logTtsPlay();

        // Assert
        verify(
          mockAnalytics.logEvent(name: 'tts_play', parameters: null),
        ).called(1);
      });

      test('should not throw on analytics error', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(name: 'tts_play', parameters: null),
        ).thenThrow(Exception('Analytics error'));

        // Act & Assert - should not throw
        await analyticsService.logTtsPlay();
      });
    });

    group('logDevocionalComplete', () {
      test(
        'should log devotional_read_complete event with required parameters',
        () async {
          // Arrange
          const devocionalId = 'dev_123';
          const campaignTag = 'custom_1';
          const source = 'read';

          when(
            mockAnalytics.logEvent(
              name: 'devotional_read_complete',
              parameters: anyNamed('parameters'),
            ),
          ).thenAnswer((_) async => {});

          // Act
          await analyticsService.logDevocionalComplete(
            devocionalId: devocionalId,
            campaignTag: campaignTag,
            source: source,
          );

          // Assert
          final captured = verify(
            mockAnalytics.logEvent(
              name: 'devotional_read_complete',
              parameters: captureAnyNamed('parameters'),
            ),
          ).captured;

          expect(captured.length, 1);
          final params = captured[0] as Map<String, Object>;
          expect(params['campaign_tag'], campaignTag);
          expect(params['devotional_id'], devocionalId);
          expect(params['source'], source);
        },
      );

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

          when(
            mockAnalytics.logEvent(
              name: 'devotional_read_complete',
              parameters: anyNamed('parameters'),
            ),
          ).thenAnswer((_) async => {});

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
          final captured = verify(
            mockAnalytics.logEvent(
              name: 'devotional_read_complete',
              parameters: captureAnyNamed('parameters'),
            ),
          ).captured;

          expect(captured.length, 1);
          final params = captured[0] as Map<String, Object>;
          expect(params['campaign_tag'], campaignTag);
          expect(params['devotional_id'], devocionalId);
          expect(params['source'], source);
          expect(params['reading_time_seconds'], readingTime);
          expect(params['scroll_percentage'], 95); // 0.95 * 100
          expect(params['listened_percentage'], 80); // 0.8 * 100
        },
      );

      test('should not throw on analytics error', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).thenThrow(Exception('Analytics error'));

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

        when(
          mockAnalytics.logEvent(
            name: eventName,
            parameters: anyNamed('parameters'),
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logCustomEvent(
          eventName: eventName,
          parameters: parameters,
        );

        // Assert
        verify(
          mockAnalytics.logEvent(name: eventName, parameters: parameters),
        ).called(1);
      });
    });

    group('setUserProperty', () {
      test('should set user property', () async {
        // Arrange
        const name = 'user_type';
        const value = 'premium';

        when(
          mockAnalytics.setUserProperty(name: name, value: value),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.setUserProperty(name: name, value: value);

        // Assert
        verify(
          mockAnalytics.setUserProperty(name: name, value: value),
        ).called(1);
      });
    });

    group('setUserId', () {
      test('should set user ID', () async {
        // Arrange
        const userId = 'user_123';

        when(mockAnalytics.setUserId(id: userId)).thenAnswer((_) async => {});

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

    group('Campaign Tag Validation', () {
      test('isValidCampaignTag should accept valid tags', () {
        final validTags = [
          'custom_1',
          'custom_2',
          'test_tag',
          'TAG123',
          'a',
          'Tag_With_Mixed_Case_123',
        ];

        for (final tag in validTags) {
          expect(
            AnalyticsService.isValidCampaignTag(tag),
            true,
            reason: 'Should accept valid tag: $tag',
          );
        }
      });

      test('isValidCampaignTag should reject invalid tags', () {
        final invalidTags = [
          '',
          'tag with spaces',
          'tag-with-dashes',
          'tag.with.dots',
          'tag@special',
          'tag#hash',
          'tag!exclamation',
          'tag\$dollar',
          'tag%percent',
        ];

        for (final tag in invalidTags) {
          expect(
            AnalyticsService.isValidCampaignTag(tag),
            false,
            reason: 'Should reject invalid tag: $tag',
          );
        }
      });

      test(
        'logDevocionalComplete should reject invalid campaign tags',
        () async {
          // Arrange
          const devocionalId = 'dev_123';
          const invalidTag = 'invalid tag with spaces';

          // Act
          await analyticsService.logDevocionalComplete(
            devocionalId: devocionalId,
            campaignTag: invalidTag,
          );

          // Assert - should NOT call Firebase Analytics due to invalid tag
          verifyNever(
            mockAnalytics.logEvent(
              name: anyNamed('name'),
              parameters: anyNamed('parameters'),
            ),
          );

          // Error count should increment
          expect(AnalyticsService.analyticsErrorCount, 1);
        },
      );

      test('logDevocionalComplete should accept valid campaign tags', () async {
        // Arrange
        const devocionalId = 'dev_123';
        const validTag = 'custom_1';

        when(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logDevocionalComplete(
          devocionalId: devocionalId,
          campaignTag: validTag,
        );

        // Assert - should call Firebase Analytics with valid tag
        verify(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).called(1);

        // Error count should remain 0
        expect(AnalyticsService.analyticsErrorCount, 0);
      });
    });

    group('Error Telemetry', () {
      test('should track analytics errors', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(name: 'tts_play', parameters: null),
        ).thenThrow(Exception('Network error'));

        expect(AnalyticsService.analyticsErrorCount, 0);

        // Act
        await analyticsService.logTtsPlay();

        // Assert
        expect(AnalyticsService.analyticsErrorCount, 1);
      });

      test('should increment error count for multiple failures', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(name: 'tts_play', parameters: null),
        ).thenThrow(Exception('Error'));

        expect(AnalyticsService.analyticsErrorCount, 0);

        // Act - trigger 3 errors
        await analyticsService.logTtsPlay();
        await analyticsService.logTtsPlay();
        await analyticsService.logTtsPlay();

        // Assert
        expect(AnalyticsService.analyticsErrorCount, 3);
      });

      test('should track errors from different operations', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(name: 'tts_play', parameters: null),
        ).thenThrow(Exception('Error 1'));
        when(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).thenThrow(Exception('Error 2'));

        expect(AnalyticsService.analyticsErrorCount, 0);

        // Act
        await analyticsService.logTtsPlay();
        await analyticsService.logDevocionalComplete(
          devocionalId: 'dev_123',
          campaignTag: 'custom_1',
        );

        // Assert
        expect(AnalyticsService.analyticsErrorCount, 2);
      });

      test('resetErrorCount should reset error counter', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(name: 'tts_play', parameters: null),
        ).thenThrow(Exception('Error'));

        await analyticsService.logTtsPlay();
        expect(AnalyticsService.analyticsErrorCount, greaterThan(0));

        // Act
        AnalyticsService.resetErrorCount();

        // Assert
        expect(AnalyticsService.analyticsErrorCount, 0);
      });

      test('should warn when error count exceeds threshold', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(name: 'tts_play', parameters: null),
        ).thenThrow(Exception('Error'));

        // Act - trigger 11 errors to exceed threshold of 10
        for (var i = 0; i < 11; i++) {
          await analyticsService.logTtsPlay();
        }

        // Assert
        expect(AnalyticsService.analyticsErrorCount, 11);
        // The warning message should be logged (checked via console output)
      });
    });

    group('Edge Cases', () {
      test('should handle empty devotional ID', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logDevocionalComplete(
          devocionalId: '',
          campaignTag: 'custom_1',
        );

        // Assert - should still log even with empty ID
        verify(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).called(1);
      });

      test('should handle very long devotional IDs', () async {
        // Arrange
        final longId = 'dev_${'x' * 1000}';
        when(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logDevocionalComplete(
          devocionalId: longId,
          campaignTag: 'custom_1',
        );

        // Assert
        verify(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).called(1);
      });

      test('should handle special characters in devotional ID', () async {
        // Arrange
        const specialId = 'dev@123#special!';
        when(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logDevocionalComplete(
          devocionalId: specialId,
          campaignTag: 'custom_1',
        );

        // Assert
        verify(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).called(1);
      });
    });

    group('logBottomBarAction', () {
      test(
        'should log bottom_bar_action event with action parameter',
        () async {
          // Arrange
          const action = 'favorite';
          when(
            mockAnalytics.logEvent(
              name: 'bottom_bar_action',
              parameters: {'action': action},
            ),
          ).thenAnswer((_) async => {});

          // Act
          await analyticsService.logBottomBarAction(action: action);

          // Assert
          verify(
            mockAnalytics.logEvent(
              name: 'bottom_bar_action',
              parameters: {'action': action},
            ),
          ).called(1);
        },
      );

      test('should not throw on analytics error', () async {
        // Arrange
        const action = 'settings';
        when(
          mockAnalytics.logEvent(
            name: 'bottom_bar_action',
            parameters: {'action': action},
          ),
        ).thenThrow(Exception('Analytics error'));

        // Act & Assert - should not throw
        await analyticsService.logBottomBarAction(action: action);
      });
    });

    group('logAppInit', () {
      test('should log app_init event with parameters', () async {
        // Arrange
        final parameters = {'use_navigation_bloc': 'true'};
        when(
          mockAnalytics.logEvent(name: 'app_init', parameters: parameters),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logAppInit(parameters: parameters);

        // Assert
        verify(
          mockAnalytics.logEvent(name: 'app_init', parameters: parameters),
        ).called(1);
      });

      test('should log app_init event without parameters', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(name: 'app_init', parameters: null),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logAppInit();

        // Assert
        verify(
          mockAnalytics.logEvent(name: 'app_init', parameters: null),
        ).called(1);
      });

      test('should not throw on analytics error', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'app_init',
            parameters: anyNamed('parameters'),
          ),
        ).thenThrow(Exception('Analytics error'));

        // Act & Assert - should not throw
        await analyticsService.logAppInit();
      });
    });

    group('logNavigationNext', () {
      test('should log navigation_next event with all parameters', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'navigation_next',
            parameters: anyNamed('parameters'),
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logNavigationNext(
          currentIndex: 5,
          totalDevocionales: 365,
          viaBloc: 'true',
        );

        // Assert
        final captured = verify(
          mockAnalytics.logEvent(
            name: 'navigation_next',
            parameters: captureAnyNamed('parameters'),
          ),
        ).captured;

        expect(captured.length, 1);
        final params = captured[0] as Map<String, Object>;
        expect(params['current_index'], 5);
        expect(params['total_devocionales'], 365);
        expect(params['via_bloc'], 'true');
        expect(params.containsKey('fallback_reason'), false);
      });

      test('should log navigation_next event with fallback reason', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'navigation_next',
            parameters: anyNamed('parameters'),
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logNavigationNext(
          currentIndex: 10,
          totalDevocionales: 365,
          viaBloc: 'false',
          fallbackReason: 'bloc_error',
        );

        // Assert
        final captured = verify(
          mockAnalytics.logEvent(
            name: 'navigation_next',
            parameters: captureAnyNamed('parameters'),
          ),
        ).captured;

        expect(captured.length, 1);
        final params = captured[0] as Map<String, Object>;
        expect(params['current_index'], 10);
        expect(params['total_devocionales'], 365);
        expect(params['via_bloc'], 'false');
        expect(params['fallback_reason'], 'bloc_error');
      });

      test('should not throw on analytics error', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'navigation_next',
            parameters: anyNamed('parameters'),
          ),
        ).thenThrow(Exception('Analytics error'));

        // Act & Assert - should not throw
        await analyticsService.logNavigationNext(
          currentIndex: 0,
          totalDevocionales: 365,
          viaBloc: 'true',
        );
      });
    });

    group('logNavigationPrevious', () {
      test(
        'should log navigation_previous event with all parameters',
        () async {
          // Arrange
          when(
            mockAnalytics.logEvent(
              name: 'navigation_previous',
              parameters: anyNamed('parameters'),
            ),
          ).thenAnswer((_) async => {});

          // Act
          await analyticsService.logNavigationPrevious(
            currentIndex: 3,
            totalDevocionales: 365,
            viaBloc: 'true',
          );

          // Assert
          final captured = verify(
            mockAnalytics.logEvent(
              name: 'navigation_previous',
              parameters: captureAnyNamed('parameters'),
            ),
          ).captured;

          expect(captured.length, 1);
          final params = captured[0] as Map<String, Object>;
          expect(params['current_index'], 3);
          expect(params['total_devocionales'], 365);
          expect(params['via_bloc'], 'true');
          expect(params.containsKey('fallback_reason'), false);
        },
      );

      test(
        'should log navigation_previous event with fallback reason',
        () async {
          // Arrange
          when(
            mockAnalytics.logEvent(
              name: 'navigation_previous',
              parameters: anyNamed('parameters'),
            ),
          ).thenAnswer((_) async => {});

          // Act
          await analyticsService.logNavigationPrevious(
            currentIndex: 8,
            totalDevocionales: 365,
            viaBloc: 'false',
            fallbackReason: 'bloc_error',
          );

          // Assert
          final captured = verify(
            mockAnalytics.logEvent(
              name: 'navigation_previous',
              parameters: captureAnyNamed('parameters'),
            ),
          ).captured;

          expect(captured.length, 1);
          final params = captured[0] as Map<String, Object>;
          expect(params['current_index'], 8);
          expect(params['total_devocionales'], 365);
          expect(params['via_bloc'], 'false');
          expect(params['fallback_reason'], 'bloc_error');
        },
      );

      test('should not throw on analytics error', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'navigation_previous',
            parameters: anyNamed('parameters'),
          ),
        ).thenThrow(Exception('Analytics error'));

        // Act & Assert - should not throw
        await analyticsService.logNavigationPrevious(
          currentIndex: 0,
          totalDevocionales: 365,
          viaBloc: 'true',
        );
      });
    });
  });
}
