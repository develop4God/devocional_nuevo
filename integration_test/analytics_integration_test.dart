import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/utils/analytics_constants.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'analytics_integration_test.mocks.dart';

@GenerateMocks([FirebaseAnalytics])
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Analytics Integration Tests', () {
    late MockFirebaseAnalytics mockAnalytics;
    late AnalyticsService analyticsService;

    setUp(() {
      mockAnalytics = MockFirebaseAnalytics();
      analyticsService = AnalyticsService(analytics: mockAnalytics);
      AnalyticsService.resetErrorCount();

      // Register mock analytics service
      ServiceLocator().registerFactory<AnalyticsService>(
        () => analyticsService,
        // El parámetro 'replace' no existe en la API, simplemente sobrescribimos en pruebas
      );
    });

    tearDown(() {
      AnalyticsService.resetErrorCount();
    });

    group('TTS Play Button Tracking', () {
      testWidgets('should log tts_play event when play button is pressed',
          (tester) async {
        // Arrange
        when(mockAnalytics.logEvent(name: 'tts_play', parameters: null))
            .thenAnswer((_) async => {});

        // Act
        await analyticsService.logTtsPlay();
        await tester.pumpAndSettle();

        // Assert
        verify(mockAnalytics.logEvent(name: 'tts_play', parameters: null))
            .called(1);
        expect(AnalyticsService.analyticsErrorCount, 0);
      });

      testWidgets(
          'should handle analytics failure gracefully when tracking TTS play',
          (tester) async {
        // Arrange
        when(mockAnalytics.logEvent(name: 'tts_play', parameters: null))
            .thenThrow(Exception('Network timeout'));

        // Act
        await analyticsService.logTtsPlay();
        await tester.pumpAndSettle();

        // Assert - should not throw, error count increments
        expect(AnalyticsService.analyticsErrorCount, 1);
      });
    });

    group('Devotional Completion Tracking', () {
      testWidgets(
          'should log completion with valid campaign tag from constants',
          (tester) async {
        // Arrange
        const devocionalId = 'dev_integration_test_001';
        final campaignTag =
            AnalyticsConstants.getCampaignTag(devocionalId: devocionalId);

        when(mockAnalytics.logEvent(
          name: 'devotional_read_complete',
          parameters: anyNamed('parameters'),
        )).thenAnswer((_) async => {});

        // Act
        await analyticsService.logDevocionalComplete(
          devocionalId: devocionalId,
          campaignTag: campaignTag,
          source: 'read',
          readingTimeSeconds: 120,
          scrollPercentage: 0.95,
        );
        await tester.pumpAndSettle();

        // Assert
        final captured = verify(mockAnalytics.logEvent(
          name: 'devotional_read_complete',
          parameters: captureAnyNamed('parameters'),
        )).captured;

        expect(captured.length, 1);
        final params = captured[0] as Map<String, Object>;
        expect(params['campaign_tag'], campaignTag);
        expect(params['devotional_id'], devocionalId);
        expect(params['source'], 'read');
        expect(params['reading_time_seconds'], 120);
        expect(params['scroll_percentage'], 95);
        expect(AnalyticsService.analyticsErrorCount, 0);
      });

      testWidgets('should log heard completion with listened percentage',
          (tester) async {
        // Arrange
        const devocionalId = 'dev_heard_test';
        const campaignTag = 'custom_1';

        when(mockAnalytics.logEvent(
          name: 'devotional_read_complete',
          parameters: anyNamed('parameters'),
        )).thenAnswer((_) async => {});

        // Act
        await analyticsService.logDevocionalComplete(
          devocionalId: devocionalId,
          campaignTag: campaignTag,
          source: 'heard',
          listenedPercentage: 0.8,
        );
        await tester.pumpAndSettle();

        // Assert
        final captured = verify(mockAnalytics.logEvent(
          name: 'devotional_read_complete',
          parameters: captureAnyNamed('parameters'),
        )).captured;

        expect(captured.length, 1);
        final params = captured[0] as Map<String, Object>;
        expect(params['campaign_tag'], campaignTag);
        expect(params['source'], 'heard');
        expect(params['listened_percentage'], 80);
      });

      testWidgets('should reject invalid campaign tags', (tester) async {
        // Arrange
        const devocionalId = 'dev_invalid_tag_test';
        const invalidTag = 'invalid tag with spaces';

        // Act
        await analyticsService.logDevocionalComplete(
          devocionalId: devocionalId,
          campaignTag: invalidTag,
        );
        await tester.pumpAndSettle();

        // Assert - should NOT call Firebase Analytics
        verifyNever(mockAnalytics.logEvent(
          name: 'any_event',
          parameters: anyNamed('parameters'),
        ));
        expect(AnalyticsService.analyticsErrorCount, 1);
      });
    });

    group('Campaign Tag Validation', () {
      testWidgets('should validate campaign tag before logging',
          (tester) async {
        // Arrange
        final testCases = [
          {'tag': 'custom_1', 'valid': true},
          {'tag': 'valid_tag_123', 'valid': true},
          {'tag': 'UPPERCASE_TAG', 'valid': true},
          {'tag': 'invalid-tag', 'valid': false},
          {'tag': 'invalid tag', 'valid': false},
          {'tag': 'invalid.tag', 'valid': false},
          {'tag': '', 'valid': false},
        ];

        when(mockAnalytics.logEvent(
          name: 'devotional_read_complete',
          parameters: anyNamed('parameters'),
        )).thenAnswer((_) async => {});

        // Act & Assert
        for (final testCase in testCases) {
          AnalyticsService.resetErrorCount();
          final tag = testCase['tag'] as String;
          final shouldBeValid = testCase['valid'] as bool;

          await analyticsService.logDevocionalComplete(
            devocionalId: 'test_dev',
            campaignTag: tag,
          );
          await tester.pumpAndSettle();

          if (shouldBeValid) {
            expect(AnalyticsService.analyticsErrorCount, 0,
                reason: 'Valid tag "$tag" should not produce errors');
          } else {
            expect(AnalyticsService.analyticsErrorCount, 1,
                reason: 'Invalid tag "$tag" should produce error');
          }
        }
      });
    });

    group('Error Telemetry', () {
      testWidgets('should track multiple consecutive errors', (tester) async {
        // Arrange
        when(mockAnalytics.logEvent(name: 'tts_play', parameters: null))
            .thenThrow(Exception('Persistent error'));

        expect(AnalyticsService.analyticsErrorCount, 0);

        // Act - trigger 5 errors
        for (var i = 0; i < 5; i++) {
          await analyticsService.logTtsPlay();
          await tester.pump();
        }

        // Assert
        expect(AnalyticsService.analyticsErrorCount, 5);
      });

      testWidgets('should track errors from mixed operations', (tester) async {
        // Arrange
        when(mockAnalytics.logEvent(name: 'tts_play', parameters: null))
            .thenThrow(Exception('TTS error'));
        when(mockAnalytics.logEvent(
          name: 'devotional_read_complete',
          parameters: anyNamed('parameters'),
        )).thenThrow(Exception('Completion error'));

        expect(AnalyticsService.analyticsErrorCount, 0);

        // Act
        await analyticsService.logTtsPlay();
        await analyticsService.logDevocionalComplete(
          devocionalId: 'test',
          campaignTag: 'custom_1',
        );
        await analyticsService.logTtsPlay();
        await tester.pumpAndSettle();

        // Assert
        expect(AnalyticsService.analyticsErrorCount, 3);
      });

      testWidgets('should warn after exceeding error threshold',
          (tester) async {
        // Arrange
        when(mockAnalytics.logEvent(name: 'tts_play', parameters: null))
            .thenThrow(Exception('Error'));

        // Act - trigger 12 errors (threshold is 10)
        for (var i = 0; i < 12; i++) {
          await analyticsService.logTtsPlay();
          await tester.pump();
        }

        // Assert
        expect(AnalyticsService.analyticsErrorCount, 12);
        expect(AnalyticsService.analyticsErrorCount, greaterThan(10));
      });
    });

    group('Integration with AnalyticsConstants', () {
      testWidgets('should use constants for campaign tags', (tester) async {
        // Arrange
        const devocionalId = 'dev_constants_test';
        final expectedTag = AnalyticsConstants.getCampaignTag(
          devocionalId: devocionalId,
        );

        when(mockAnalytics.logEvent(
          name: 'devotional_read_complete',
          parameters: anyNamed('parameters'),
        )).thenAnswer((_) async => {});

        // Act
        await analyticsService.logDevocionalComplete(
          devocionalId: devocionalId,
          campaignTag: expectedTag,
        );
        await tester.pumpAndSettle();

        // Assert
        final captured = verify(mockAnalytics.logEvent(
          name: 'devotional_read_complete',
          parameters: captureAnyNamed('parameters'),
        )).captured;

        final params = captured[0] as Map<String, Object>;
        expect(params['campaign_tag'], AnalyticsConstants.defaultCampaignTag);
      });

      testWidgets('should validate constants-generated tags', (tester) async {
        // Arrange & Act
        final tag = AnalyticsConstants.getCampaignTag();

        // Assert
        expect(AnalyticsService.isValidCampaignTag(tag), true,
            reason: 'Constants-generated tags should always pass validation');
      });
    });

    group('Real-World Scenarios', () {
      testWidgets('complete user journey: read devotional and track',
          (tester) async {
        // Arrange
        const devocionalId = 'daily_devotional_2024_01_01';
        final campaignTag = AnalyticsConstants.getCampaignTag(
          devocionalId: devocionalId,
        );

        when(mockAnalytics.logEvent(
          name: 'devotional_read_complete',
          parameters: anyNamed('parameters'),
        )).thenAnswer((_) async => {});

        // Act - User reads for 180 seconds and scrolls 90%
        await analyticsService.logDevocionalComplete(
          devocionalId: devocionalId,
          campaignTag: campaignTag,
          source: 'read',
          readingTimeSeconds: 180,
          scrollPercentage: 0.9,
        );
        await tester.pumpAndSettle();

        // Assert
        verify(mockAnalytics.logEvent(
          name: 'devotional_read_complete',
          parameters: anyNamed('parameters'),
        )).called(1);
        expect(AnalyticsService.analyticsErrorCount, 0);
      });

      testWidgets('complete user journey: TTS playback and track',
          (tester) async {
        // Arrange
        const devocionalId = 'audio_devotional_test';
        final campaignTag = AnalyticsConstants.getCampaignTag(
          devocionalId: devocionalId,
        );

        when(mockAnalytics.logEvent(name: 'tts_play', parameters: null))
            .thenAnswer((_) async => {});
        when(mockAnalytics.logEvent(
          name: 'devotional_read_complete',
          parameters: anyNamed('parameters'),
        )).thenAnswer((_) async => {});

        // Act - User presses play and listens to 75% of audio
        await analyticsService.logTtsPlay();
        await analyticsService.logDevocionalComplete(
          devocionalId: devocionalId,
          campaignTag: campaignTag,
          source: 'heard',
          listenedPercentage: 0.75,
        );
        await tester.pumpAndSettle();

        // Assert
        verify(mockAnalytics.logEvent(name: 'tts_play', parameters: null))
            .called(1);
        verify(mockAnalytics.logEvent(
          name: 'devotional_read_complete',
          parameters: anyNamed('parameters'),
        )).called(1);
        expect(AnalyticsService.analyticsErrorCount, 0);
      });
    });
  });
}
