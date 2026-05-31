// lib/debug/sections/debug_streak_section.dart
// ignore_for_file: use_build_context_synchronously
import 'package:devocional_nuevo/debug/i_debug_spiritual_stats_service.dart';
import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:flutter/material.dart';

/// Debug section to manually add streak days without waiting 24 hours.
///
/// Single Responsibility: only handles streak manipulation for testing purposes.
/// The [ISpiritualStatsService] is injected via constructor (DI compliant).
class DebugStreakSection extends StatefulWidget {
  final IDebugSpiritualStatsService statsService;

  const DebugStreakSection({super.key, required this.statsService});

  @override
  State<DebugStreakSection> createState() => _DebugStreakSectionState();
}

class _DebugStreakSectionState extends State<DebugStreakSection> {
  SpiritualStats? _stats;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final stats = await widget.statsService.getStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _loading = false;
      });
    }
  }

  Future<void> _addStreakDay() async {
    setState(() => _loading = true);
    try {
      final updatedStats = await widget.statsService.addStreakDay();
      if (mounted) {
        setState(() {
          _stats = updatedStats;
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔥 Streak extended! Now ${updatedStats.currentStreak} day(s)',
            ),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [DEBUG] addStreakDay error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _stats?.currentStreak ?? 0;
    final longest = _stats?.longestStreak ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Text(
                'Streak Debug',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Current stats
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatChip(label: 'Current', value: '$current 🔥'),
                _StatChip(label: 'Longest', value: '$longest ⭐'),
              ],
            ),

          const SizedBox(height: 16),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _addStreakDay,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(_loading ? 'Updating...' : '+ 1 Day Streak'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            'Inserts a synthetic read-date to extend the streak by 1 day.\n'
            'Use this to test streak milestones without waiting 24 h.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade900,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}

/// Small info chip for displaying a stat value.
class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.orange.shade700),
        ),
      ],
    );
  }
}
