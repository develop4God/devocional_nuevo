import 'package:devocional_nuevo/blocs/bible_versions/bible_versions_bloc.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/repositories/i_bible_version_repository.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/bible/bible_version_download_sheet.dart';
import 'package:flutter/material.dart';

/// Drawer for the Bible reader page. Currently offers a single entry point:
/// downloading additional Bible versions from the remote bible_versions
/// repo. Separate from [DevocionalesDrawer] (the devotionals feature's
/// drawer) — this one is scoped to the Bible reader only.
class BibleReaderDrawer extends StatelessWidget {
  final String languageCode;

  /// Called after the download sheet closes, so the caller can refresh its
  /// version list (a newly downloaded version should appear without
  /// requiring an app restart).
  final VoidCallback onVersionsMayHaveChanged;

  const BibleReaderDrawer({
    super.key,
    required this.languageCode,
    required this.onVersionsMayHaveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                      'bible.drawer_title'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
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
                      icon: const Icon(
                        Icons.close_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'bible.close'.tr(),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.download_for_offline_outlined,
                color: colorScheme.primary,
              ),
              title: Text('bible.download_versions'.tr()),
              subtitle: Text('bible.download_versions_subtitle'.tr()),
              onTap: () async {
                Navigator.of(context).pop();
                await BibleVersionDownloadSheet.show(
                  context,
                  languageCode: languageCode,
                  createBloc: () => BibleVersionsBloc(
                    repository: getService<IBibleVersionRepository>(),
                  ),
                );
                onVersionsMayHaveChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
