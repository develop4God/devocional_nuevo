@Tags(['unit', 'services'])
library;

// test/unit/services/analytics_service_user_workflow_test.dart
//
// Migrated from integration_test/analytics_integration_test.dart
// Uses the existing analytics_service_test.mocks.dart (same @GenerateMocks).
// Switched from IntegrationTestWidgetsFlutterBinding to TestWidgetsFlutterBinding
// so these run in the standard `flutter test` suite without a device.

import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/utils/analytics_constants.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'analytics_service_test.mocks.dart';

// Re-use the mocks generated for analytics_service_test.dart.
// Running build_runner is NOT needed – the MockFirebaseAnalytics class
// is already generated in analytics_service_test.mocks.dart.
@GenerateMocks([FirebaseAnalytics])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Analytics Service - User Workflow Tests', () {
    late MockFirebaseAnalytics mockAnalytics;
    late AnalyticsService analyticsService;

    setUp(() {
      mockAnalytics = MockFirebaseAnalytics();
      analyticsService = AnalyticsService(analytics: mockAnalytics);
      AnalyticsService.reset();

      ServiceLocator().registerFactory<AnalyticsService>(
        () => analyticsService,
      );
    });

    tearDown(() {
      AnalyticsService.reset();
    });

    group('TTS Play Button Tracking', () {
      test('should log tts_play event when play button is pressed', () async {
        when(
          mockAnalytics.logEvent(name: 'tts_play', parameters: null),
        ).thenAnswer((_) async => {});

        await analyticsService.logTtsPlay();

        verify(
          mockAnalytics.logEvent(name: 'tts_play', parameters: null),
        ).called(1);
        expect(AnalyticsService.analyticsErrorCount, 0);
      });

      test(
        'should handle analytics failure gracefully when tracking TTS play',
        () async {
          when(
            mockAnalytics.logEvent(name: 'tts_play', parameters: null),
          ).thenThrow(Exception('Network timeout'));

          await analyticsService.logTtsPlay();

          expect(AnalyticsService.analyticsErrorCount, 1);
        },
      );
    });

    group('Devotional Completion Tracking', () {
      test(
        'should log completion with valid campaign tag from constants',
        () async {
          const devocionalId = 'dev_integration_test_001';
          final campaignTag = AnalyticsConstants.getCampaignTag(
            devocionalId: devocionalId,
            totalDevocionalesRead: 7,
          );

          when(
            mockAnalytics.logEvent(
              name: 'devotional_read_complete',
              parameters: anyNamed('parameters'),
            ),
          ).thenAnswer((_) async => {});

          await analyticsService.logDevocionalComplete(
            devocionalId: devocionalId,
            campaignTag: campaignTag,
            source: 'read',
            readingTimeSeconds: 120,
            scrollPercentage: 0.95,
          );

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
          expect(params['source'], 'read');
          expect(params['reading_time_seconds'], 120);
          expect(params['scroll_percentage'], 95);
          expect(AnalyticsService.analyticsErrorCount, 0);
        },
      );

      test('should log heard completion with listened percentage', () async {
        const devocionalId = 'dev_heard_test';
        const campaignTag = 'custom_1';

        when(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).thenAnswer((_) async => {});

        await analyticsService.logDevocionalComplete(
          devocionalId: devocionalId,
          campaignTag: campaignTag,
          source: 'heard',
          listenedPercentage: 0.8,
        );

        final captured = verify(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: captureAnyNamed('parameters'),
          ),
        ).captured;

        expect(captured.length, 1);
        final params = captured[0] as Map<String, Object>;
        expect(params['campaign_tag'], campaignTag);
        expect(params['source'], 'heard');
        expect(params['listened_percentage'], 80);
      });

      test('should reject invalid campaign tags', () async {
        const devocionalId = 'dev_invalid_tag_test';
        const invalidTag = 'invalid tag with spaces';

        await analyticsService.logDevocionalComplete(
          devocionalId: devocionalId,
          campaignTag: invalidTag,
        );

        verifyNever(
          mockAnalytics.logEvent(
            name: 'any_event',
            parameters: anyNamed('parameters'),
          ),
        );
        expect(AnalyticsService.analyticsErrorCount, 1);
      });
    });

    group('Campaign Tag Validation', () {
      test('should validate campaign tag before logging', () async {
        final testCases = [
          {'tag': 'custom_1', 'valid': true},
          {'tag': 'valid_tag_123', 'valid': true},
          {'tag': 'UPPERCASE_TAG', 'valid': true},
          {'tag': 'invalid-tag', 'valid': false},
          {'tag': 'invalid tag', 'valid': false},
          {'tag': 'invalid.tag', 'valid': false},
          {'tag': '', 'valid': false},
        ];

        when(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).thenAnswer((_) async => {});

        for (final testCase in testCases) {
          AnalyticsService.reset();
          final tag = testCase['tag'] as String;
          final shouldBeValid = testCase['valid'] as bool;

          await analyticsService.logDevocionalComplete(
            devocionalId: 'test_dev',
            campaignTag: tag,
          );

          if (shouldBeValid) {
            expect(
              AnalyticsService.analyticsErrorCount,
              0,
              reason: 'Valid tag "$tag" should not produce errors',
            );
          } else {
            expect(
              AnalyticsService.analyticsErrorCount,
              1,
              reason: 'Invalid tag "$tag" should produce error',
            );
          }
        }
      });
    });

    group('Error Telemetry', () {
      test('should track multiple consecutive errors', () async {
        when(
          mockAnalytics.logEvent(name: 'tts_play', parameters: null),
        ).thenThrow(Exception('Persistent error'));

        expect(AnalyticsService.analyticsErrorCount, 0);

        for (var i = 0; i < 5; i++) {
          await analyticsService.logTtsPlay();
        }

        expect(AnalyticsService.analyticsErrorCount, 5);
      });

      test('should track errors from mixed operations', () async {
        when(
          mockAnalytics.logEvent(name: 'tts_play', parameters: null),
        ).thenThrow(Exception('TTS error'));
        when(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).thenThrow(Exception('Completion error'));

        expect(AnalyticsService.analyticsErrorCount, 0);

        await analyticsService.logTtsPlay();
        await analyticsService.logDevocionalComplete(
          devocionalId: 'test',
          campaignTag: 'custom_1',
        );
        await analyticsService.logTtsPlay();

        expect(AnalyticsService.analyticsErrorCount, 3);
      });

      test('should warn after exceeding error threshold', () async {
        when(
          mockAnalytics.logEvent(name: 'tts_play', parameters: null),
        ).thenThrow(Exception('Error'));

        for (var i = 0; i < 12; i++) {
          await analyticsService.logTtsPlay();
        }

        expect(AnalyticsService.analyticsErrorCount, 12);
        expect(AnalyticsService.analyticsErrorCount, greaterThan(10));
      });
    });

    group('Integration with AnalyticsConstants', () {
      test('should use constants for campaign tags', () async {
        const devocionalId = 'dev_constants_test';
        final expectedTag = AnalyticsConstants.getCampaignTag(
          devocionalId: devocionalId,
          totalDevocionalesRead: 7,
        );

        when(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).thenAnswer((_) async => {});

        await analyticsService.logDevocionalComplete(
          devocionalId: devocionalId,
          campaignTag: expectedTag,
        );

        final captured = verify(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: captureAnyNamed('parameters'),
          ),
        ).captured;

        final params = captured[0] as Map<String, Object>;
        expect(params['campaign_tag'], AnalyticsConstants.defaultCampaignTag);
      });

      test('should validate constants-generated tags', () async {
        final tag = AnalyticsConstants.getCampaignTag(totalDevocionalesRead: 7);

        expect(
          AnalyticsService.isValidCampaignTag(tag),
          true,
          reason: 'Constants-generated tags should always pass validation',
        );
      });
    });

    group('Real-World Scenarios', () {
      test('complete user journey: read devotional and track', () async {
        const devocionalId = 'daily_devotional_2024_01_01';
        final campaignTag = AnalyticsConstants.getCampaignTag(
          devocionalId: devocionalId,
          totalDevocionalesRead: 7,
        );

        when(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).thenAnswer((_) async => {});

        await analyticsService.logDevocionalComplete(
          devocionalId: devocionalId,
          campaignTag: campaignTag,
          source: 'read',
          readingTimeSeconds: 180,
          scrollPercentage: 0.9,
        );

        verify(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).called(1);
        expect(AnalyticsService.analyticsErrorCount, 0);
      });

      test('complete user journey: TTS playback and track', () async {
        const devocionalId = 'audio_devotional_test';
        final campaignTag = AnalyticsConstants.getCampaignTag(
          devocionalId: devocionalId,
          totalDevocionalesRead: 7,
        );

        when(
          mockAnalytics.logEvent(name: 'tts_play', parameters: null),
        ).thenAnswer((_) async => {});
        when(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).thenAnswer((_) async => {});

        await analyticsService.logTtsPlay();
        await analyticsService.logDevocionalComplete(
          devocionalId: devocionalId,
          campaignTag: campaignTag,
          source: 'heard',
          listenedPercentage: 0.75,
        );

        verify(
          mockAnalytics.logEvent(name: 'tts_play', parameters: null),
        ).called(1);
        verify(
          mockAnalytics.logEvent(
            name: 'devotional_read_complete',
            parameters: anyNamed('parameters'),
          ),
        ).called(1);
        expect(AnalyticsService.analyticsErrorCount, 0);
      });
    });
  });
}
