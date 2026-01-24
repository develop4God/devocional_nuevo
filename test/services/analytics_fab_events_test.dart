import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'analytics_service_test.mocks.dart';

@GenerateMocks([FirebaseAnalytics])
void main() {
  group('AnalyticsService - FAB and Discovery Events', () {
    late MockFirebaseAnalytics mockAnalytics;
    late AnalyticsService analyticsService;

    setUp(() {
      mockAnalytics = MockFirebaseAnalytics();
      analyticsService = AnalyticsService(analytics: mockAnalytics);
      AnalyticsService.resetErrorCount();
    });

    group('logFabTapped', () {
      test('should log fab_tapped event from devocionales_page', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'fab_tapped',
            parameters: {'source': 'devocionales_page'},
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logFabTapped(source: 'devocionales_page');

        // Assert
        verify(
          mockAnalytics.logEvent(
            name: 'fab_tapped',
            parameters: {'source': 'devocionales_page'},
          ),
        ).called(1);
      });

      test('should log fab_tapped event from prayers_page', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'fab_tapped',
            parameters: {'source': 'prayers_page'},
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logFabTapped(source: 'prayers_page');

        // Assert
        verify(
          mockAnalytics.logEvent(
            name: 'fab_tapped',
            parameters: {'source': 'prayers_page'},
          ),
        ).called(1);
      });
    });

    group('logFabChoiceSelected', () {
      test('should log prayer choice from devocionales_page', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'fab_choice_selected',
            parameters: {
              'source': 'devocionales_page',
              'choice': 'prayer',
            },
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logFabChoiceSelected(
          source: 'devocionales_page',
          choice: 'prayer',
        );

        // Assert
        verify(
          mockAnalytics.logEvent(
            name: 'fab_choice_selected',
            parameters: {
              'source': 'devocionales_page',
              'choice': 'prayer',
            },
          ),
        ).called(1);
      });

      test('should log thanksgiving choice from prayers_page', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'fab_choice_selected',
            parameters: {
              'source': 'prayers_page',
              'choice': 'thanksgiving',
            },
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logFabChoiceSelected(
          source: 'prayers_page',
          choice: 'thanksgiving',
        );

        // Assert
        verify(
          mockAnalytics.logEvent(
            name: 'fab_choice_selected',
            parameters: {
              'source': 'prayers_page',
              'choice': 'thanksgiving',
            },
          ),
        ).called(1);
      });

      test('should log testimony choice', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'fab_choice_selected',
            parameters: {
              'source': 'devocionales_page',
              'choice': 'testimony',
            },
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logFabChoiceSelected(
          source: 'devocionales_page',
          choice: 'testimony',
        );

        // Assert
        verify(
          mockAnalytics.logEvent(
            name: 'fab_choice_selected',
            parameters: {
              'source': 'devocionales_page',
              'choice': 'testimony',
            },
          ),
        ).called(1);
      });
    });

    group('logDiscoveryAction', () {
      test('should log study_opened with study ID', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'discovery_action',
            parameters: {
              'action': 'study_opened',
              'study_id': 'study_123',
            },
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logDiscoveryAction(
          action: 'study_opened',
          studyId: 'study_123',
        );

        // Assert
        verify(
          mockAnalytics.logEvent(
            name: 'discovery_action',
            parameters: {
              'action': 'study_opened',
              'study_id': 'study_123',
            },
          ),
        ).called(1);
      });

      test('should log study_completed with study ID', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'discovery_action',
            parameters: {
              'action': 'study_completed',
              'study_id': 'study_456',
            },
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logDiscoveryAction(
          action: 'study_completed',
          studyId: 'study_456',
        );

        // Assert
        verify(
          mockAnalytics.logEvent(
            name: 'discovery_action',
            parameters: {
              'action': 'study_completed',
              'study_id': 'study_456',
            },
          ),
        ).called(1);
      });

      test('should log study_shared with study ID', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'discovery_action',
            parameters: {
              'action': 'study_shared',
              'study_id': 'study_789',
            },
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logDiscoveryAction(
          action: 'study_shared',
          studyId: 'study_789',
        );

        // Assert
        verify(
          mockAnalytics.logEvent(
            name: 'discovery_action',
            parameters: {
              'action': 'study_shared',
              'study_id': 'study_789',
            },
          ),
        ).called(1);
      });

      test('should log study_downloaded with study ID', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'discovery_action',
            parameters: {
              'action': 'study_downloaded',
              'study_id': 'study_download',
            },
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logDiscoveryAction(
          action: 'study_downloaded',
          studyId: 'study_download',
        );

        // Assert
        verify(
          mockAnalytics.logEvent(
            name: 'discovery_action',
            parameters: {
              'action': 'study_downloaded',
              'study_id': 'study_download',
            },
          ),
        ).called(1);
      });

      test('should log toggle_grid_view without study ID', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'discovery_action',
            parameters: {
              'action': 'toggle_grid_view',
            },
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logDiscoveryAction(
          action: 'toggle_grid_view',
        );

        // Assert
        verify(
          mockAnalytics.logEvent(
            name: 'discovery_action',
            parameters: {
              'action': 'toggle_grid_view',
            },
          ),
        ).called(1);
      });

      test('should log toggle_carousel_view without study ID', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'discovery_action',
            parameters: {
              'action': 'toggle_carousel_view',
            },
          ),
        ).thenAnswer((_) async => {});

        // Act
        await analyticsService.logDiscoveryAction(
          action: 'toggle_carousel_view',
        );

        // Assert
        verify(
          mockAnalytics.logEvent(
            name: 'discovery_action',
            parameters: {
              'action': 'toggle_carousel_view',
            },
          ),
        ).called(1);
      });
    });

    group('Error handling', () {
      test('should handle errors gracefully for logFabTapped', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'fab_tapped',
            parameters: {'source': 'devocionales_page'},
          ),
        ).thenThrow(Exception('Analytics error'));

        // Act
        await analyticsService.logFabTapped(source: 'devocionales_page');

        // Assert - should not throw
        expect(AnalyticsService.analyticsErrorCount, 1);
      });

      test('should handle errors gracefully for logFabChoiceSelected',
          () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'fab_choice_selected',
            parameters: anyNamed('parameters'),
          ),
        ).thenThrow(Exception('Analytics error'));

        // Act
        await analyticsService.logFabChoiceSelected(
          source: 'prayers_page',
          choice: 'prayer',
        );

        // Assert - should not throw
        expect(AnalyticsService.analyticsErrorCount, greaterThan(0));
      });

      test('should handle errors gracefully for logDiscoveryAction', () async {
        // Arrange
        when(
          mockAnalytics.logEvent(
            name: 'discovery_action',
            parameters: anyNamed('parameters'),
          ),
        ).thenThrow(Exception('Analytics error'));

        // Act
        await analyticsService.logDiscoveryAction(
          action: 'study_opened',
          studyId: 'test',
        );

        // Assert - should not throw
        expect(AnalyticsService.analyticsErrorCount, greaterThan(0));
      });
    });
  });
}
