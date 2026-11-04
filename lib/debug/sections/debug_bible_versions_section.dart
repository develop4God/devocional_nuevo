// ignore_for_file: use_build_context_synchronously
import 'package:devocional_nuevo/debug/debug_flags.dart';
import 'package:devocional_nuevo/repositories/i_bible_index_debug_controls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Debug section for the remote Bible versions index/repository: branch
/// selector plus a forced refresh of the index.
/// Single Responsibility: only handles Bible-versions debug controls.
class DebugBibleVersionsSection extends StatefulWidget {
  final IBibleIndexDebugControls controls;
  final List<String> branches;
  final bool loadingBranches;

  /// Shown under the dropdown when the branch listing failed or its
  /// activity filter could not be fully applied.
  final String? branchWarning;

  const DebugBibleVersionsSection({
    super.key,
    required this.controls,
    required this.branches,
    required this.loadingBranches,
    this.branchWarning,
  });

  @override
  State<DebugBibleVersionsSection> createState() =>
      _DebugBibleVersionsSectionState();
}

class _DebugBibleVersionsSectionState extends State<DebugBibleVersionsSection> {
  bool _refreshing = false;

  /// Versions listed in the refreshed index, keyed by language.
  Map<String, List<String>> _fetched = {};

  void _showSnack(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: color,
      ),
    );
  }

  /// Force-fetches the index of the selected branch.
  Future<void> _refresh() async {
    final branch = DebugFlags.debugBibleVersionsBranch;
    setState(() => _refreshing = true);
    try {
      final result = await widget.controls.refreshIndex();
      if (mounted) setState(() => _fetched = result.versionsByLanguage);
      if (result.servedFromCache) {
        _showSnack(
          '⚠️ Network failed — showing CACHED index for: $branch',
          color: Colors.orange,
        );
      } else {
        _showSnack('✅ Bible index refreshed from: $branch',
            color: Colors.green);
      }
    } catch (e) {
      debugPrint('❌ Error refreshing Bible versions index: $e');
      _showSnack('❌ Error refreshing from $branch: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    // Always show the branch that is really in effect, even when the
    // (filtered) list no longer contains it, so UI and fetches never diverge
    // and a selection survives reopening the page.
    final selected = DebugFlags.debugBibleVersionsBranch;
    final branches = widget.branches.contains(selected)
        ? widget.branches
        : [selected, ...widget.branches];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_stories, size: 48, color: Colors.deepPurple),
          const SizedBox(height: 8),
          const Text(
            'Bible Versions Branch',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (widget.loadingBranches)
            const CircularProgressIndicator()
          else
            DropdownButton<String>(
              value: selected,
              isExpanded: true,
              items: branches
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (newBranch) {
                if (newBranch == null) return;
                setState(() => DebugFlags.debugBibleVersionsBranch = newBranch);
                _showSnack('Bible versions branch → $newBranch');
              },
            ),
          if (widget.branchWarning != null) ...[
            const SizedBox(height: 8),
            Text(
              '⚠️ ${widget.branchWarning}',
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _refreshing ? null : _refresh,
              icon: _refreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, color: Colors.deepPurple),
              label: const Text(
                'Refresh Index',
                style: TextStyle(color: Colors.deepPurple),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.deepPurple),
              ),
            ),
          ),
          if (_fetched.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final entry in _fetched.entries)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${entry.key}: ${entry.value.isEmpty ? '(none)' : entry.value.join(', ')}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Fetches the latest index from the selected branch, bypassing the '
            'ETag. Versions listed in the index are shown above.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
