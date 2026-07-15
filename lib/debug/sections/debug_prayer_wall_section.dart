import 'package:devocional_nuevo/blocs/prayer_wall/prayer_wall_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_wall/prayer_wall_state.dart';
import 'package:devocional_nuevo/pages/prayer_wall_page.dart';
import 'package:devocional_nuevo/repositories/i_prayer_wall_repository.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Debug section to open the Prayer Wall.
///
/// Prayer Wall has no user-facing navigation entry point yet (only reachable
/// via the `devocional://prayer_wall` deep link), so this gives developers a
/// way to exercise the real end-to-end flow (submit, moderation, pray-tap,
/// report) from a debug build without shipping it to users. Every BLoC state
/// transition is printed so a developer can watch the moderation pipeline
/// (or rules rejections) happen against the real backend.
class DebugPrayerWallSection extends StatelessWidget {
  const DebugPrayerWallSection({super.key});

  static void _logState(PrayerWallState state) {
    switch (state) {
      case PrayerWallInitial():
        debugPrint('🙏 [PrayerWall] state: initial');
      case PrayerWallLoading():
        debugPrint('🙏 [PrayerWall] state: loading');
      case PrayerWallLoaded(
          :final sameLanguagePrayers,
          :final otherLanguagePrayers,
          :final myPendingPrayer,
          :final errorMessage,
        ):
        debugPrint(
          '🙏 [PrayerWall] state: loaded — '
          'sameLang=${sameLanguagePrayers.length}, '
          'otherLang=${otherLanguagePrayers.length}, '
          'myPending=${myPendingPrayer?.status}, '
          'error=$errorMessage',
        );
      case PrayerWallError(:final message):
        debugPrint('🙏 [PrayerWall] state: ERROR — $message');
      case PrayerSubmitting():
        debugPrint('🙏 [PrayerWall] state: submitting…');
      case PrayerSubmitted(:final prayerId):
        debugPrint('🙏 [PrayerWall] state: submitted — prayerId=$prayerId');
      case PastoralResponseTriggered():
        debugPrint('🙏 [PrayerWall] state: pastoral response triggered');
    }
  }

  void _openPrayerWall(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => PrayerWallBloc(
            repository: getService<IPrayerWallRepository>(),
          ),
          child: BlocListener<PrayerWallBloc, PrayerWallState>(
            listener: (_, state) => _logState(state),
            child: const PrayerWallPage(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.purple.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.purple.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.volunteer_activism, color: Colors.purple.shade800),
                const SizedBox(width: 8),
                Text(
                  '🙏 Prayer Wall Debug',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.purple.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Not yet wired into user navigation. Opens the real page '
              'against the live backend — submit, pray-tap, and report all '
              'hit Firestore for real.',
              style: TextStyle(fontSize: 11, color: Colors.purple.shade700),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _openPrayerWall(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Prayer Wall'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
