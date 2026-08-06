import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

/// Left-side navigation drawer for the Bible reader page: lists the
/// available versions for the current language (current version
/// highlighted) and offers a "download more versions" action, replacing
/// the previous version-picker [PopupMenuButton].
class BibleReaderDrawer extends StatelessWidget {
  final List<BibleVersion> availableVersions;
  final BibleVersion? selectedVersion;
  final String Function(BibleVersion version) versionLabelBuilder;
  final ValueChanged<BibleVersion> onVersionSelected;
  final VoidCallback onDownloadMoreVersions;

  const BibleReaderDrawer({
    super.key,
    required this.availableVersions,
    required this.selectedVersion,
    required this.versionLabelBuilder,
    required this.onVersionSelected,
    required this.onDownloadMoreVersions,
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
                  const Divider(height: 24),
                  ListTile(
                    key: const Key('bible_reader_drawer_download_more'),
                    leading: Icon(
                      Icons.download_for_offline_outlined,
                      color: colorScheme.primary,
                    ),
                    title: Text(
                      'bible.download_versions'.tr(),
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      onDownloadMoreVersions();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
