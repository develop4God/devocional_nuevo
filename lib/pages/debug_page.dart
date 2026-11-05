// ignore_for_file: public_member_api_docs

import 'package:devocional_nuevo/debug/github_branch_lister.dart';
import 'package:devocional_nuevo/debug/i_debug_spiritual_stats_service.dart';
import 'package:devocional_nuevo/debug/sections/debug_banners_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_bible_versions_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_bulk_add_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_crashlytics_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_devotionals_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_discovery_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_encounters_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_iap_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_onboarding_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_streak_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_tts_section.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/repositories/i_bible_index_debug_controls.dart';
import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/debug/debug_backup_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Debug page — visible in kDebugMode only.
///
/// Acts as a thin orchestrator: it owns the shared branches state (needed by
/// multiple sections) and composes the individual [Section] widgets.
/// Business logic lives in each section following SRP/SOLID principles.
class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  List<String> _branches = ['main', 'dev'];
  bool _loadingBranches = false;
  // The Bible versions index lives in its own GitHub repo, so its branches
  // are fetched separately from the Devocionales-json ones.
  List<String> _bibleBranches = ['main'];
  String? _bibleBranchWarning;
  static const _activeBranchWindow = Duration(days: 90);
  final _branchLister = GithubBranchLister();

  // Resolved once at composition time — debug page acts as a local
  // composition root (kDebugMode only, never shipped to production).
  late final IDebugSpiritualStatsService _statsService =
      getService<IDebugSpiritualStatsService>();
  late final OnboardingService _onboardingService =
      getService<OnboardingService>();

  @override
  void dispose() {
    _branchLister.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches({bool forceRefresh = false}) async {
    setState(() => _loadingBranches = true);
    final results = await Future.wait([
      _branchLister.fetch(
        GithubBranchLister.devotionalsRepo,
        forceRefresh: forceRefresh,
      ),
      _branchLister.fetch(
        GithubBranchLister.bibleVersionsRepo,
        activeWithin: _activeBranchWindow,
        forceRefresh: forceRefresh,
      ),
    ]);
    if (results[0].warning != null) debugPrint('⚠️ ${results[0].warning}');
    if (!mounted) return;
    setState(() {
      _branches = results[0].branches ?? _branches;
      _bibleBranches = results[1].branches ?? _bibleBranches;
      _bibleBranchWarning = results[1].warning;
      _loadingBranches = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tools'),
        backgroundColor: Colors.red.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Branch selectors ──
            DebugDiscoverySection(
              branches: _branches,
              loadingBranches: _loadingBranches,
              onRefreshBranches: () => _fetchBranches(forceRefresh: true),
            ),
            const SizedBox(height: 32),
            DebugEncountersSection(
              branches: _branches,
              loadingBranches: _loadingBranches,
            ),
            const SizedBox(height: 32),
            DebugDevotionalsSection(
              branches: _branches,
              loadingBranches: _loadingBranches,
            ),
            const SizedBox(height: 32),
            DebugBibleVersionsSection(
              controls: getService<IBibleIndexDebugControls>(),
              branches: _bibleBranches,
              branchWarning: _bibleBranchWarning,
              loadingBranches: _loadingBranches,
            ),
            const SizedBox(height: 32),

            // ── Crashlytics + Backup + Review ──
            const DebugCrashlyticsSection(),
            const SizedBox(height: 32),
            // ── Backup debug tools ──
            if (kDebugMode) const DebugBackupSection(),
            const SizedBox(height: 32),

            // ── Streak debug ──
            DebugStreakSection(statsService: _statsService),
            const SizedBox(height: 32),

            // ── Onboarding debug ──
            DebugOnboardingSection(onboardingService: _onboardingService),
            const SizedBox(height: 32),

            // ── Bulk add test data ──
            const DebugBulkAddSection(),
            const SizedBox(height: 32),

            // ── IAP debug tools ──
            if (kDebugMode) ...[
              const DebugIapSection(),
              const SizedBox(height: 16),
            ],

            // ── TTS debug (fallback toggle + voice explorer) ──
            const DebugTtsSection(),
            const SizedBox(height: 32),

            // ── Banner previews (update + KJV) ──
            DebugBannersSection(
              updateTitle: 'update.ready_title'.tr(),
              updateMessage: 'update.ready_message'.tr(),
              updateCloseTooltip: 'update.close'.tr(),
              updateRestartFailedMessage: 'update.restart_failed'.tr(),
              updateDownloadingTitle: 'update.downloading_title'.tr(),
              updateDownloadingMessage: 'update.downloading_message'.tr(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
