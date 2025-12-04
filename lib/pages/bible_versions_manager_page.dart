import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/bible_version/bible_version_bloc.dart';
import '../blocs/bible_version/bible_version_event.dart';
import '../blocs/bible_version/bible_version_state.dart';
import '../services/service_locator.dart';

/// Page for managing Bible version downloads.
///
/// Displays available Bible versions organized by language,
/// allows downloading new versions and deleting existing ones.
class BibleVersionsManagerPage extends StatelessWidget {
  const BibleVersionsManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BibleVersionBloc(
        repository: getService<BibleVersionRepository>(),
      )..add(const LoadBibleVersionsEvent()),
      child: const _BibleVersionsManagerView(),
    );
  }
}

class _BibleVersionsManagerView extends StatelessWidget {
  const _BibleVersionsManagerView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Versions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<BibleVersionBloc>().add(
                    const LoadBibleVersionsEvent(forceRefresh: true),
                  );
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocBuilder<BibleVersionBloc, BibleVersionState>(
        builder: (context, state) {
          if (state is BibleVersionInitial || state is BibleVersionLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is BibleVersionError) {
            return _ErrorView(
              message: state.message,
              onRetry: () {
                context.read<BibleVersionBloc>().add(
                      const LoadBibleVersionsEvent(forceRefresh: true),
                    );
              },
            );
          }

          if (state is BibleVersionLoaded) {
            return _VersionsList(state: state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionsList extends StatelessWidget {
  final BibleVersionLoaded state;

  const _VersionsList({required this.state});

  @override
  Widget build(BuildContext context) {
    // Group versions by language
    final versionsByLanguage = <String, List<BibleVersionWithState>>{};
    for (final version in state.versions) {
      final lang = version.metadata.languageName;
      versionsByLanguage.putIfAbsent(lang, () => []).add(version);
    }

    // Sort languages alphabetically
    final languages = versionsByLanguage.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: languages.length,
      itemBuilder: (context, index) {
        final language = languages[index];
        final versions = versionsByLanguage[language]!;

        return _LanguageSection(
          language: language,
          versions: versions,
        );
      },
    );
  }
}

class _LanguageSection extends StatelessWidget {
  final String language;
  final List<BibleVersionWithState> versions;

  const _LanguageSection({
    required this.language,
    required this.versions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            language,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...versions.map((version) => _VersionTile(version: version)),
        const Divider(),
      ],
    );
  }
}

class _VersionTile extends StatelessWidget {
  final BibleVersionWithState version;

  const _VersionTile({required this.version});

  @override
  Widget build(BuildContext context) {
    final metadata = version.metadata;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      title: Text(metadata.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metadata.description.isNotEmpty)
            Text(
              metadata.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            _formatSize(metadata.uncompressedSizeBytes),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          if (version.state == DownloadState.failed &&
              version.errorMessage != null)
            Text(
              version.errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
            ),
        ],
      ),
      trailing: _buildTrailing(context),
      isThreeLine: true,
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final bloc = context.read<BibleVersionBloc>();
    final colorScheme = Theme.of(context).colorScheme;

    switch (version.state) {
      case DownloadState.notDownloaded:
        return IconButton(
          icon: Icon(Icons.download, color: colorScheme.primary),
          onPressed: () {
            bloc.add(DownloadVersionEvent(version.metadata.id));
          },
          tooltip: 'Download',
        );

      case DownloadState.downloading:
        return SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: version.progress > 0 ? version.progress : null,
                strokeWidth: 2,
              ),
              Text(
                '${(version.progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        );

      case DownloadState.downloaded:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: colorScheme.primary),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              onPressed: () => _showDeleteConfirmation(context),
              tooltip: 'Delete',
            ),
          ],
        );

      case DownloadState.failed:
        return IconButton(
          icon: Icon(Icons.refresh, color: colorScheme.error),
          onPressed: () {
            bloc.add(DownloadVersionEvent(version.metadata.id));
          },
          tooltip: 'Retry',
        );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Bible Version?'),
        content: Text(
          'Are you sure you want to delete ${version.metadata.name}? '
          'You can download it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<BibleVersionBloc>().add(
                    DeleteVersionEvent(version.metadata.id),
                  );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
