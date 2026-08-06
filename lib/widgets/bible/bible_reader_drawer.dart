import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/bible_versions/bible_versions_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

/// Left-side navigation drawer for the Bible reader page: lists downloaded
/// versions for the current language (current version highlighted) plus any
/// remote versions still available to download, each with a download icon.
/// Tapping a downloadable version downloads it in place; the caller is
/// responsible for switching to it once the download completes.
class BibleReaderDrawer extends StatelessWidget {
  final List<BibleVersion> availableVersions;
  final BibleVersion? selectedVersion;
  final List<BibleVersion> downloadableVersions;
  final Map<String, VersionDownloadStatus> downloadStatuses;
  final String Function(BibleVersion version) versionLabelBuilder;
  final ValueChanged<BibleVersion> onVersionSelected;
  final ValueChanged<BibleVersion> onDownloadVersion;

  const BibleReaderDrawer({
    super.key,
    required this.availableVersions,
    required this.selectedVersion,
    this.downloadableVersions = const [],
    this.downloadStatuses = const {},
    required this.versionLabelBuilder,
    required this.onVersionSelected,
    required this.onDownloadVersion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              width: double.infinity,
              color: colorScheme.primary,
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      'bible.select_version'.tr(),
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      key: const Key('bible_reader_drawer_close_button'),
                      icon: const Icon(
                        Icons.close_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'drawer.close'.tr(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ...availableVersions.map((version) {
                    final isSelected =
                        version.dbFileName == selectedVersion?.dbFileName;
                    return ListTile(
                      key: Key(
                        'bible_reader_drawer_version_${version.dbFileName}',
                      ),
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      title: Text(
                        versionLabelBuilder(version),
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (!isSelected) onVersionSelected(version);
                      },
                    );
                  }),
                  ...downloadableVersions.map((version) {
                    final status = downloadStatuses[version.dbFileName];
                    return ListTile(
                      key: Key(
                        'bible_reader_drawer_downloadable_${version.dbFileName}',
                      ),
                      title: Text(
                        versionLabelBuilder(version),
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      trailing: _downloadTrailing(colorScheme, status),
                      onTap: status == null || status.errorMessageKey != null
                          ? () {
                              Navigator.of(context).pop();
                              onDownloadVersion(version);
                            }
                          : null,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Same circular bordered icon treatment as the app language settings
  /// page's download trailing widget, for a consistent download affordance.
  Widget _downloadTrailing(
    ColorScheme colorScheme,
    VersionDownloadStatus? status,
  ) {
    if (status != null &&
        status.errorMessageKey == null &&
        !status.isComplete) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: colorScheme.primary.withAlpha(100), width: 2),
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: status.progress,
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
        ),
      );
    }

    final iconData = status?.errorMessageKey != null
        ? Icons.refresh_outlined
        : Icons.file_download_outlined;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.primary.withAlpha(180), width: 2),
      ),
      child: Center(
        child: Icon(iconData, color: colorScheme.primary, size: 20),
      ),
    );
  }
}
