// ignore_for_file: public_member_api_docs
import 'dart:convert';

import 'package:devocional_nuevo/debug/i_debug_spiritual_stats_service.dart';
import 'package:devocional_nuevo/debug/sections/debug_bulk_add_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_crashlytics_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_devotionals_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_discovery_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_encounters_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_iap_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_prayer_wall_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_streak_section.dart';
import 'package:devocional_nuevo/debug/sections/debug_tts_section.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/debug/debug_backup_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  // Resolved once at composition time — debug page acts as a local
  // composition root (kDebugMode only, never shipped to production).
  late final IDebugSpiritualStatsService _statsService =
      getService<IDebugSpiritualStatsService>();

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    setState(() => _loadingBranches = true);
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/develop4God/Devocionales-json/branches',
        ),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );
      if (response.statusCode == 200) {
        final List branches = jsonDecode(response.body);
        setState(
          () => _branches = branches.map((b) => b['name'] as String).toList(),
        );
      } else if (response.statusCode == 403) {
        debugPrint('⚠️ GitHub rate limit hit, using fallback branches');
      } else {
        debugPrint('⚠️ GitHub API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching branches: $e');
    }
    setState(() => _loadingBranches = false);
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
              onRefreshBranches: _fetchBranches,
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

            // ── Crashlytics + Backup + Review ──
            const DebugCrashlyticsSection(),
            const SizedBox(height: 32),
            // ── Backup debug tools ──
            if (kDebugMode) const DebugBackupSection(),
            const SizedBox(height: 32),

            // ── Streak debug ──
            DebugStreakSection(statsService: _statsService),
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

            // ── Prayer Wall debug (no user-facing nav entry yet) ──
            const DebugPrayerWallSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
