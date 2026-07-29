import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SpiritualStatsService streak calculation', () {
    late SpiritualStatsService statsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await registerTestServices();
      statsService = SpiritualStatsService();
    });

    test('builds and extends streak beyond 30 days correctly', () async {
      // Build 30-day streak via debug helper addStreakDay
      for (int i = 0; i < 30; i++) {
        final s = await statsService.addStreakDay();
        expect(s.currentStreak, equals(i + 1));
      }

      final stats30 = await statsService.getStats();
      expect(stats30.currentStreak, equals(30));

      // Add one more day -> expect 31
      final s31 = await statsService.addStreakDay();
      expect(s31.currentStreak, equals(31));
    });
  });
}
