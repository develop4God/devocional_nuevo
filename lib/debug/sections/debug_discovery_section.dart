// ignore_for_file: use_build_context_synchronously
import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/debug/debug_flags.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Debug section for Discovery branch selection.
/// Single Responsibility: only handles the Discovery branch dropdown.
class DebugDiscoverySection extends StatelessWidget {
  final List<String> branches;
  final bool loadingBranches;
  final VoidCallback onRefreshBranches;

  const DebugDiscoverySection({
    super.key,
    required this.branches,
    required this.loadingBranches,
    required this.onRefreshBranches,
  });

  @override
  Widget build(BuildContext context) {
    if (!Constants.enableDiscoveryFeature) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.fork_right, size: 48, color: Colors.deepOrange),
          const SizedBox(height: 8),
          const Text(
            'Discovery Branch',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (loadingBranches)
            const CircularProgressIndicator()
          else
            DropdownButton<String>(
              value: branches.contains(DebugFlags.debugBranch)
                  ? DebugFlags.debugBranch
                  : branches.first,
              isExpanded: true,
              items: branches
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (newBranch) {
                if (newBranch == null) return;
                DebugFlags.debugBranch = newBranch;
                context.read<DiscoveryBloc>().add(RefreshDiscoveryStudies());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cambiado a: $newBranch')),
                );
              },
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRefreshBranches,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Branches'),
          ),
        ],
      ),
    );
  }
}

