// lib/pages/prayer_wall_page.dart

import 'package:devocional_nuevo/blocs/prayer_wall/prayer_wall_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_wall/prayer_wall_event.dart';
import 'package:devocional_nuevo/blocs/prayer_wall/prayer_wall_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/repositories/prayer_wall_repository.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/prayer_wall/pastoral_support_sheet.dart';
import 'package:devocional_nuevo/widgets/prayer_wall/prayer_wall_card.dart';
import 'package:devocional_nuevo/widgets/prayer_wall/submit_prayer_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The Prayer Wall page: a community prayer board where users can post
/// prayer requests and support each other with a 🙏 tap.
///
/// Section 1: Same-language prayers (prominent, full cards).
/// Section 2: Cross-language prayers (compact cards with language flag).
class PrayerWallPage extends StatefulWidget {
  const PrayerWallPage({super.key});

  @override
  State<PrayerWallPage> createState() => _PrayerWallPageState();
}

class _PrayerWallPageState extends State<PrayerWallPage> {
  late final String _userLanguage;
  late final String _authorHash;

  @override
  void initState() {
    super.initState();

    final localization = getService<LocalizationService>();
    _userLanguage = localization.currentLocale.languageCode;

    // Hash the Firebase UID once — never use raw UID
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    _authorHash = PrayerWallRepository.hashUserId(uid);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<PrayerWallBloc>()
          .add(LoadPrayerWall(userLanguage: _userLanguage, authorHash: _authorHash));

      getService<AnalyticsService>().logCustomEvent(
          eventName: 'prayer_wall_viewed',
          parameters: {'language': _userLanguage});
    });
  }

  void _openSubmitModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<PrayerWallBloc>(),
        child: BlocBuilder<PrayerWallBloc, PrayerWallState>(
          builder: (_, state) => SubmitPrayerModal(
            isSubmitting: state is PrayerSubmitting,
            onSubmit: (text, isAnonymous) {
              context.read<PrayerWallBloc>().add(
                    SubmitPrayer(
                      text: text,
                      language: _userLanguage,
                      isAnonymous: isAnonymous,
                      authorHash: _authorHash,
                    ),
                  );
              Navigator.of(sheetContext).pop();
            },
          ),
        ),
      ),
    );
  }

  void _showReportConfirmation(BuildContext context, String prayerId) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('prayer_wall.report'.tr()),
        content: Text('prayer_wall.report_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('app.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context
                  .read<PrayerWallBloc>()
                  .add(ReportPrayer(prayerId: prayerId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('prayer_wall.report_thanks'.tr()),
                  duration: const Duration(seconds: 3),
                ),
              );
              getService<AnalyticsService>()
                .logCustomEvent(
                    eventName: 'prayer_reported',
                    parameters: {'prayerId': prayerId});
            },
            child: Text('prayer_wall.report'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(titleText: 'prayer_wall.title'.tr()),
      body: BlocListener<PrayerWallBloc, PrayerWallState>(
        listener: (context, state) {
          if (state is PrayerSubmitted) {
            getService<AnalyticsService>().logCustomEvent(
              eventName: 'prayer_submitted',
              parameters: {'prayerId': state.prayerId},
            );
          } else if (state is PastoralResponseTriggered) {
            getService<AnalyticsService>()
                .logCustomEvent(eventName: 'pastoral_sheet_shown');
            PastoralSupportSheet.show(context);
          } else if (state is PrayerWallError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: BlocBuilder<PrayerWallBloc, PrayerWallState>(
          builder: (context, state) {
            if (state is PrayerWallLoading || state is PrayerWallInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PrayerWallError) {
              return _ErrorView(message: state.message);
            }
            if (state is PrayerWallLoaded) {
              return _LoadedWall(
                state: state,
                userLanguage: _userLanguage,
                authorHash: _authorHash,
                onPrayTap: (id) {
                  context
                      .read<PrayerWallBloc>()
                      .add(TapPrayerHand(prayerId: id));
                  getService<AnalyticsService>().logCustomEvent(
                      eventName: 'prayer_hand_tapped',
                      parameters: {'prayerId': id});
                },
                onReport: (id) => _showReportConfirmation(context, id),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSubmitModal(context),
        icon: const Text('🙏', style: TextStyle(fontSize: 18)),
        label: Text('prayer_wall.submit'.tr()),
      ),
    );
  }
}

class _LoadedWall extends StatelessWidget {
  final PrayerWallLoaded state;
  final String userLanguage;
  final String authorHash;
  final void Function(String) onPrayTap;
  final void Function(String) onReport;

  const _LoadedWall({
    required this.state,
    required this.userLanguage,
    required this.authorHash,
    required this.onPrayTap,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final hasSameLang = state.sameLanguagePrayers.isNotEmpty;
    final hasOtherLang = state.otherLanguagePrayers.isNotEmpty;
    final hasPending = state.myPendingPrayer != null;
    final hasAny = hasSameLang || hasOtherLang || hasPending;

    if (!hasAny) {
      return _EmptyState(userLanguage: userLanguage);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<PrayerWallBloc>()
            .add(RefreshPrayerWall(userLanguage: userLanguage));
        // Wait for the refresh to complete
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // My pending prayer (shown only to the author)
          if (hasPending) ...[
            _SectionHeader(label: 'prayer_wall.my_pending'.tr()),
            PrayerWallCard(
              key: ValueKey('pending_${state.myPendingPrayer!.id}'),
              prayer: state.myPendingPrayer!,
            ),
          ],

          // Section 1: Same-language prayers
          if (hasSameLang) ...[
            _SectionHeader(
              label: 'prayer_wall.section_mine'.tr(),
            ),
            ...state.sameLanguagePrayers.map(
              (p) => PrayerWallCard(
                key: ValueKey(p.id),
                prayer: p,
                onPrayTap: () => onPrayTap(p.id),
                onReport: () => onReport(p.id),
              ),
            ),
          ],

          // Section 2: Cross-language prayers
          if (hasOtherLang) ...[
            _SectionHeader(
              label: 'prayer_wall.section_others'.tr(),
            ),
            ...state.otherLanguagePrayers.map(
              (p) => PrayerWallCard(
                key: ValueKey(p.id),
                prayer: p,
                showLanguageBadge: true,
                isCompact: true,
                onPrayTap: () => onPrayTap(p.id),
                onReport: () => onReport(p.id),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String userLanguage;
  const _EmptyState({required this.userLanguage});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🙏', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'prayer_wall.empty_title'.tr(),
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'prayer_wall.empty_description'.tr(),
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
