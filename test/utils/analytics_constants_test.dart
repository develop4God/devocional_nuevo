import 'package:devocional_nuevo/utils/analytics_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsConstants', () {
    group('defaultCampaignTag', () {
      test('should have the correct default value', () {
        expect(AnalyticsConstants.defaultCampaignTag, 'custom_1');
      });

      test('should be a non-empty string', () {
        expect(AnalyticsConstants.defaultCampaignTag.isNotEmpty, true);
      });

      test('should not contain spaces', () {
        expect(AnalyticsConstants.defaultCampaignTag.contains(' '), false);
      });

      test('should be lowercase with underscore separator', () {
        final tag = AnalyticsConstants.defaultCampaignTag;
        expect(tag, matches(r'^[a-z0-9_]+$'),
            reason:
                'Campaign tag should only contain lowercase letters, numbers, and underscores');
      });
    });

    group('getCampaignTag', () {
      test('should return empty string when totalDevocionalesRead is null', () {
        final tag = AnalyticsConstants.getCampaignTag();
        expect(tag, '');
      });

      test('should return empty string when totalDevocionalesRead < 7', () {
        final tag = AnalyticsConstants.getCampaignTag(totalDevocionalesRead: 6);
        expect(tag, '');
      });

      test('should return default tag when totalDevocionalesRead >= 7', () {
        final tag = AnalyticsConstants.getCampaignTag(totalDevocionalesRead: 7);
        expect(tag, AnalyticsConstants.defaultCampaignTag);
      });

      test(
          'should return default tag for any devotional ID when totalDevocionalesRead >= 7',
          () {
        final testIds = [
          'dev_001',
          'dev_999',
          'special_devotional',
          'test_id',
          '',
        ];

        for (final id in testIds) {
          final tag = AnalyticsConstants.getCampaignTag(
              devocionalId: id, totalDevocionalesRead: 7);
          expect(tag, AnalyticsConstants.defaultCampaignTag,
              reason:
                  'Should return default tag when totalDevocionalesRead >= 7 for ID: $id');
        }
      });

      test('should return consistent value for same inputs', () {
        const testId = 'dev_123';
        final tag1 = AnalyticsConstants.getCampaignTag(
            devocionalId: testId, totalDevocionalesRead: 7);
        final tag2 = AnalyticsConstants.getCampaignTag(
            devocionalId: testId, totalDevocionalesRead: 7);

        expect(tag1, tag2, reason: 'Same inputs should always return same tag');
      });

      test('should handle milestone threshold correctly', () {
        // Below threshold
        expect(AnalyticsConstants.getCampaignTag(totalDevocionalesRead: 0), '');
        expect(AnalyticsConstants.getCampaignTag(totalDevocionalesRead: 1), '');
        expect(AnalyticsConstants.getCampaignTag(totalDevocionalesRead: 6), '');

        // At threshold
        expect(AnalyticsConstants.getCampaignTag(totalDevocionalesRead: 7),
            AnalyticsConstants.defaultCampaignTag);

        // Above threshold
        expect(AnalyticsConstants.getCampaignTag(totalDevocionalesRead: 8),
            AnalyticsConstants.defaultCampaignTag);
        expect(AnalyticsConstants.getCampaignTag(totalDevocionalesRead: 100),
            AnalyticsConstants.defaultCampaignTag);
      });
    });

    group('Edge Cases', () {
      test('should handle very long devotional IDs', () {
        final longId = 'dev_${'x' * 1000}';
        final tag = AnalyticsConstants.getCampaignTag(
            devocionalId: longId, totalDevocionalesRead: 7);
        expect(tag, AnalyticsConstants.defaultCampaignTag);
      });

      test('should handle special characters in devotional ID', () {
        final specialIds = [
          'dev@123',
          'dev#special',
          'dev-with-dashes',
          'dev.with.dots',
          'dev with spaces',
        ];

        for (final id in specialIds) {
          final tag = AnalyticsConstants.getCampaignTag(
              devocionalId: id, totalDevocionalesRead: 7);
          expect(tag, AnalyticsConstants.defaultCampaignTag,
              reason: 'Should handle special characters in ID: $id');
        }
      });

      test('should handle unicode characters in devotional ID', () {
        final unicodeIds = [
          'dev_español',
          'dev_中文',
          'dev_🙏',
        ];

        for (final id in unicodeIds) {
          final tag = AnalyticsConstants.getCampaignTag(
              devocionalId: id, totalDevocionalesRead: 7);
          expect(tag, AnalyticsConstants.defaultCampaignTag,
              reason: 'Should handle unicode in ID: $id');
        }
      });

      test('should handle negative totalDevocionalesRead', () {
        final tag =
            AnalyticsConstants.getCampaignTag(totalDevocionalesRead: -1);
        expect(tag, '');
      });

      test('should handle zero totalDevocionalesRead', () {
        final tag = AnalyticsConstants.getCampaignTag(totalDevocionalesRead: 0);
        expect(tag, '');
      });
    });

    group('Future Extensibility', () {
      test('getCampaignTag method signature supports future conditional logic',
          () {
        // This test documents the method signature for future extension
        // The method accepts optional devocionalId parameter

        // Can be called without parameters
        expect(() => AnalyticsConstants.getCampaignTag(), returnsNormally);

        // Can be called with null
        expect(() => AnalyticsConstants.getCampaignTag(devocionalId: null),
            returnsNormally);

        // Can be called with any string
        expect(() => AnalyticsConstants.getCampaignTag(devocionalId: 'any_id'),
            returnsNormally);
      });
    });

    group('Integration with Firebase Analytics', () {
      test(
          'campaign tag format is compatible with Firebase Analytics parameter naming',
          () {
        // Firebase Analytics parameter names should:
        // - Be alphanumeric with underscores
        // - Start with a letter
        // - Be no longer than 40 characters

        final tag = AnalyticsConstants.defaultCampaignTag;

        expect(tag.length <= 40, true,
            reason: 'Firebase parameter values should be <= 40 chars');

        expect(tag, matches(r'^[a-zA-Z][a-zA-Z0-9_]*$'),
            reason:
                'Should start with letter and contain only alphanumeric + underscore');
      });
    });
  });
}
