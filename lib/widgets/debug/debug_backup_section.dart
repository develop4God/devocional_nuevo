import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/backup_bloc.dart';
import '../../blocs/backup_event.dart';

class DebugBackupSection extends StatelessWidget {
  const DebugBackupSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Backup', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => context.read<BackupBloc>().add(
                const CheckStartupBackup(forceBypass: true),
              ),
          child: const Text('Force auto-backup (bypass 24h)'),
        ),
      ],
    );
  }
}
