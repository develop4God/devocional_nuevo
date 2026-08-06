import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/bible_versions/bible_versions_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_versions/bible_versions_event.dart';
import 'package:devocional_nuevo/blocs/bible_versions/bible_versions_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bottom sheet listing remote Bible versions available for download for
/// [languageCode]. Opened from the Bible reader's version-picker popup
/// menu, via its "Download Bible versions" entry.
class BibleVersionDownloadSheet extends StatelessWidget {
  final String languageCode;

  const BibleVersionDownloadSheet({super.key, required this.languageCode});

  /// Shows the sheet inside a [BlocProvider] scoped to this call, and
  /// dispatches the initial load.
  static Future<void> show(
    BuildContext context, {
    required String languageCode,
    required BibleVersionsBloc Function() createBloc,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => BlocProvider<BibleVersionsBloc>(
        create: (_) => createBloc()
          ..add(LoadAvailableVersions(languageCode: languageCode)),
        child: BibleVersionDownloadSheet(languageCode: languageCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.75,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'bible.download_versions'.tr(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'bible.download_versions_subtitle'.tr(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_outlined),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'bible.close'.tr(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<BibleVersionsBloc, BibleVersionsState>(
                builder: (context, state) {
                  if (state is BibleVersionsLoading ||
                      state is BibleVersionsInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is BibleVersionsError) {
                    return Center(
                      child: Text(
                        state.messageKey.tr(),
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final loaded = state as BibleVersionsLoaded;
                  if (loaded.remoteVersions.isEmpty) {
                    return Center(
                      child: Text(
                        'bible.no_versions_available'.tr(),
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: loaded.remoteVersions.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final version = loaded.remoteVersions[index];
                      final status =
                          loaded.downloadStatuses[version.dbFileName];
                      return _VersionRow(version: version, status: status);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  final BibleVersion version;
  final VersionDownloadStatus? status;

  const _VersionRow({required this.version, required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      title: Text(version.name),
      trailing: _trailing(context, colorScheme),
    );
  }

  Widget _trailing(BuildContext context, ColorScheme colorScheme) {
    if (status == null) {
      return IconButton(
        icon: const Icon(Icons.download_outlined),
        onPressed: () => context.read<BibleVersionsBloc>().add(
              DownloadBibleVersion(version),
            ),
      );
    }

    if (status!.errorMessageKey != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              status!.errorMessageKey!.tr(),
              style: TextStyle(color: colorScheme.error, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => context.read<BibleVersionsBloc>().add(
                  DownloadBibleVersion(version),
                ),
          ),
        ],
      );
    }

    if (status!.isComplete) {
      return Icon(Icons.check_circle_outline, color: colorScheme.primary);
    }

    if (status!.progress == null) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        value: status!.progress,
      ),
    );
  }
}
