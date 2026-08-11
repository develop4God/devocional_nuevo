@Tags(['unit', 'services'])
library;

import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:devocional_nuevo/services/user_recency_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

/// Fake stats service with a settable devotional read count.
class _FakeStatsServiceWithCount extends FakeSpiritualStatsService {
  _FakeStatsServiceWithCount(this.totalDevocionalesRead);

  final int totalDevocionalesRead;

  @override
  Future<SpiritualStats> getStats() async =>
      SpiritualStats(totalDevocionalesRead: totalDevocionalesRead);
}

/// Fake stats service whose [getStats] always throws, to exercise the
/// error path.
class _ThrowingStatsService extends FakeSpiritualStatsService {
  @override
  Future<SpiritualStats> getStats() async =>
      throw Exception('stats read failed');
}

void main() {
  group('UserRecencyService.isNewUser', () {
    test('returns true for a device with zero devotionals read', () async {
      final service = UserRecencyService(
        statsService: FakeSpiritualStatsService(),
      );

      expect(await service.isNewUser(), isTrue);
    });

    test('returns true for a device just under the engaged threshold (4)',
        () async {
      final service = UserRecencyService(
        statsService: _FakeStatsServiceWithCount(4),
      );

      expect(await service.isNewUser(), isTrue);
    });

    test('returns false for a device at the engaged threshold (5)', () async {
      final service = UserRecencyService(
        statsService: _FakeStatsServiceWithCount(5),
      );

      expect(await service.isNewUser(), isFalse);
    });

    test('returns false for a device well past the engaged threshold',
        () async {
      final service = UserRecencyService(
        statsService: _FakeStatsServiceWithCount(50),
      );

      expect(await service.isNewUser(), isFalse);
    });

    test('propagates an error from the underlying stats read', () async {
      final service = UserRecencyService(
        statsService: _ThrowingStatsService(),
      );

      expect(service.isNewUser(), throwsException);
    });
  });
}
