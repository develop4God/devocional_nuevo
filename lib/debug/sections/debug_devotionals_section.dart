// ignore_for_file: use_build_context_synchronously
import 'package:devocional_nuevo/debug/debug_flags.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Debug section for Devotionals branch selection.
/// Single Responsibility: only handles the Devotionals branch dropdown.
class DebugDevotionalsSection extends StatelessWidget {
  final List<String> branches;
  final bool loadingBranches;

  const DebugDevotionalsSection({
    super.key,
    required this.branches,
    required this.loadingBranches,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.menu_book, size: 48, color: Colors.blue),
          const SizedBox(height: 8),
          const Text(
            'Devotionals Branch',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (loadingBranches)
            const CircularProgressIndicator()
          else
            DropdownButton<String>(
              value: branches.contains(DebugFlags.debugBranchDevotionals)
                  ? DebugFlags.debugBranchDevotionals
                  : branches.first,
              isExpanded: true,
              items: branches
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (newBranch) async {
                if (newBranch == null) return;
                DebugFlags.debugBranchDevotionals = newBranch;
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refreshing devotionals from new branch...'),
                    duration: Duration(seconds: 2),
                  ),
                );
                try {
                  await context.read<DevocionalProvider>().refreshDevocionals();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Successfully loaded from: $newBranch'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('❌ Error refreshing devotionals: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error loading from $newBranch: $e'),
                        duration: const Duration(seconds: 3),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          const SizedBox(height: 8),
          const Text(
            'Note: Devotionals will refresh automatically when branch is changed',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
