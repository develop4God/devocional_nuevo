// lib/services/user_recency_service.dart
import 'package:devocional_nuevo/services/i_spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/i_user_recency_service.dart';
import 'package:devocional_nuevo/utils/constants/engagement_constants.dart';

/// Classifies a user as new or existing based on reading history, using
/// the same threshold already established by [EngagementThresholds] for
/// the first-time app review prompt and the onboarding backfill.
///
/// Registered in ServiceLocator as a lazy singleton.
/// Usage: `getService<IUserRecencyService>()`
class UserRecencyService implements IUserRecencyService {
  final ISpiritualStatsService _statsService;

  UserRecencyService({required ISpiritualStatsService statsService})
      : _statsService = statsService;

  @override
  Future<bool> isNewUser() async {
    final stats = await _statsService.getStats();
    return stats.totalDevocionalesRead <
        EngagementThresholds.engagedUserDevocionalThreshold;
  }
}
