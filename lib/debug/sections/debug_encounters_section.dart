// ignore_for_file: use_build_context_synchronously
import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/debug/debug_flags.dart';
import 'package:devocional_nuevo/repositories/encounter_repository.dart';
import 'package:devocional_nuevo/services/i_encounter_progress_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/utils/constants/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Debug section for Encounters: branch selector, fallback toggle,
/// force reload, reset welcome, and restore completed encounters.
/// Single Responsibility: only handles Encounter-related debug controls.
class DebugEncountersSection extends StatelessWidget {
  final List<String> branches;
  final bool loadingBranches;

  const DebugEncountersSection({
    super.key,
    required this.branches,
    required this.loadingBranches,
  });

  Future<void> _resetEncounterWelcome(BuildContext context) async {
    if (!kDebugMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('encounter_welcome_seen', false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Encounter welcome reset — will show on next visit',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      debugPrint('🔄 Encounter welcome reset: encounter_welcome_seen = false');
    } catch (e) {
      debugPrint('Error resetting encounter welcome: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _completeAllEncounters(BuildContext context) async {
    if (!kDebugMode) return;
    try {
      final state = context.read<EncounterBloc>().state;
      if (state is! EncounterLoaded || state.index.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ No encounters loaded — load index first'),
            ),
          );
        }
        return;
      }
      final allIds = state.index.map((e) => e.id).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        IEncounterProgressService.completedIdsKey,
        allIds,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ All ${allIds.length} encounters marked complete'),
            duration: const Duration(seconds: 2),
          ),
        );
        context.read<EncounterBloc>().add(
              LoadEncounterIndex(forceRefresh: true),
            );
      }
      debugPrint('🔄 All ${allIds.length} encounters marked complete');
    } catch (e) {
      debugPrint('❌ Error completing all encounters: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _restoreEncounters(BuildContext context) async {
    if (!kDebugMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(IEncounterProgressService.completedIdsKey);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All encounters restored to incomplete'),
            duration: Duration(seconds: 2),
          ),
        );
        context.read<EncounterBloc>().add(
              LoadEncounterIndex(forceRefresh: true),
            );
      }
      debugPrint('🔄 All encounters restored to incomplete');
    } catch (e) {
      debugPrint('❌ Error restoring encounters: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Constants.enableEncountersFeature) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.explore_outlined, size: 32, color: Colors.teal),
              const SizedBox(width: 8),
              const Text(
                'Encounters Debug',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Branch selector
          const Text('Branch:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (loadingBranches)
            const CircularProgressIndicator()
          else
            DropdownButton<String>(
              value: branches.contains(DebugFlags.debugEncounterBranch)
                  ? DebugFlags.debugEncounterBranch
                  : branches.first,
              isExpanded: true,
              items: branches
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (newBranch) {
                if (newBranch == null) return;
                DebugFlags.debugEncounterBranch = newBranch;
                context.read<EncounterBloc>().add(LoadEncounterIndex());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Encounters branch → $newBranch')),
                );
              },
            ),
          const SizedBox(height: 16),

          // Fallback toggle
          StatefulBuilder(
            builder: (context, setLocal) => Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Use Cache Fallback',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        Constants.enableEncounterFallback
                            ? '✅ ON — network errors use cached data'
                            : '🚫 OFF — network errors are thrown',
                        style: TextStyle(
                          fontSize: 12,
                          color: Constants.enableEncounterFallback
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: Constants.enableEncounterFallback,
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.teal;
                    }
                    return null;
                  }),
                  onChanged: (val) {
                    setLocal(() => Constants.enableEncounterFallback = val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          val
                              ? '✅ Fallback ENABLED'
                              : '🚫 Fallback DISABLED — real network only',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Force reload
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final repository = getService<EncounterRepository>();
                await repository.clearCache();

                // Fetch the fresh index once, then force-download every
                // study in it (normal app flow only preloads the first
                // encounter's images, not all study content).
                var downloadedCount = 0;
                try {
                  final entries = await repository.fetchIndex(
                    forceRefresh: true,
                  );
                  for (final entry in entries) {
                    final lang = entry.files.keys.isNotEmpty
                        ? entry.files.keys.first
                        : 'es';
                    await repository.fetchStudy(
                      entry.id,
                      lang,
                      filename: entry.files[lang],
                      entry: entry,
                    );
                    downloadedCount++;
                  }
                } catch (e) {
                  debugPrint(
                      '⚠️ Encounter: Force reload of studies failed: $e');
                }

                if (!context.mounted) return;
                context.read<EncounterBloc>().add(
                      LoadEncounterIndex(forceRefresh: false),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '🔄 Encounters: reloaded index + $downloadedCount studies',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.refresh, color: Colors.teal),
              label: const Text(
                'Force Reload Index',
                style: TextStyle(color: Colors.teal),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.teal),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Toggle fallback OFF to test real network fetch.\n'
            'If URL returns 404, fix path in GitHub repo.\n'
            'Toggle back ON to use bundled asset while debugging.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Reset welcome
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _resetEncounterWelcome(context),
              icon: const Icon(Icons.refresh, color: Colors.teal),
              label: const Text(
                'Reset Welcome Screen',
                style: TextStyle(color: Colors.teal),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.teal),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Reset the encounter welcome dialog so it displays again\non the next visit to the Encounters tab.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Complete all encounters
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _completeAllEncounters(context),
              icon: const Icon(Icons.done_all, color: Colors.green),
              label: const Text(
                'Complete All Encounters',
                style: TextStyle(color: Colors.green),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mark all loaded encounters as completed.\n'
            'Useful for testing unlock logic & end states. [DEBUG ONLY]',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Restore encounters
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _restoreEncounters(context),
              icon: const Icon(Icons.restore, color: Colors.amber),
              label: const Text(
                'Restore All Encounters',
                style: TextStyle(color: Colors.amber),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.amber),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Clear all completed encounters progress.\n'
            'All encounters will be marked incomplete &\n'
            'available to replay. [DEBUG ONLY]',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
