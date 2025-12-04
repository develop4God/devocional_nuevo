import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/bible_version/bible_version_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_version/bible_version_event.dart';
import 'package:devocional_nuevo/blocs/bible_version/bible_version_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/providers/bible_selected_version_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/app_gradient_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

/// Modern and intuitive drawer for Bible Reader with version selection and downloads.
/// Similar to DevocionalDrawer's offline download functionality.
class BibleReaderDrawer extends StatelessWidget {
  final List<BibleVersion> availableVersions;
  final BibleVersion? selectedVersion;
  final Function(BibleVersion) onVersionSelected;

  const BibleReaderDrawer({
    super.key,
    required this.availableVersions,
    this.selectedVersion,
    required this.onVersionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bibleProvider = Provider.of<BibleSelectedVersionProvider>(context);

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              height: 56,
              width: double.infinity,
              color: colorScheme.primary,
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      'bible.drawer_title'.tr(),
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
                      icon:
                          const Icon(Icons.close_outlined, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'drawer.close'.tr(),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ListView(
                  children: [
                    const SizedBox(height: 15),
                    // Selected version section
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'bible.current_version'.tr(),
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Current version chip
                    if (selectedVersion != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorScheme.primary.withAlpha(100),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${selectedVersion!.name} (${selectedVersion!.language})',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Available versions
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'bible.available_versions'.tr(),
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...availableVersions.map((version) {
                      final isSelected = version.name == selectedVersion?.name;
                      return _VersionTile(
                        version: version,
                        isSelected: isSelected,
                        onTap: () {
                          Navigator.of(context).pop();
                          onVersionSelected(version);
                        },
                      );
                    }),

                    Divider(
                      height: 32,
                      color: colorScheme.outline.withAlpha(100),
                    ),

                    // Download more versions button
                    _DrawerRow(
                      icon: Icons.download_for_offline_outlined,
                      iconColor: colorScheme.primary,
                      label: Text(
                        'bible.download_versions'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'bible.download_versions_subtitle'.tr(),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                      onTap: () {
                        _showDownloadDialog(context, bibleProvider);
                      },
                    ),

                    const SizedBox(height: 10),

                    // Manage all versions
                    _DrawerRow(
                      icon: Icons.settings_outlined,
                      iconColor: colorScheme.primary,
                      label: Text(
                        'bible.manage_versions'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context)
                            .pushNamed('/bible_versions_manager');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadDialog(
      BuildContext context, BibleSelectedVersionProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (_) => BibleVersionBloc(
          repository: getService<BibleVersionRepository>(),
        )..add(const LoadBibleVersionsEvent()),
        child: _BibleDownloadDialog(
          currentLanguage: provider.selectedLanguage,
        ),
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  final BibleVersion version;
  final bool isSelected;
  final VoidCallback onTap;

  const _VersionTile({
    required this.version,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.menu_book_outlined,
              color: isSelected ? colorScheme.primary : colorScheme.outline,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    version.name,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    version.language,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
            if (version.isDownloaded)
              Icon(
                Icons.offline_pin,
                color: colorScheme.primary.withAlpha(150),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget label;
  final Widget? subtitle;
  final VoidCallback? onTap;

  const _DrawerRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 36,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(icon, color: iconColor, size: 28),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label,
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    subtitle!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for downloading Bible versions, similar to DevocionalDrawer's offline download.
class _BibleDownloadDialog extends StatefulWidget {
  final String currentLanguage;

  const _BibleDownloadDialog({required this.currentLanguage});

  @override
  State<_BibleDownloadDialog> createState() => _BibleDownloadDialogState();
}

class _BibleDownloadDialogState extends State<_BibleDownloadDialog> {
  String? _downloadingVersionId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<BibleVersionBloc, BibleVersionState>(
      listener: (context, state) {
        if (state is BibleVersionLoaded) {
          // Check for download progress updates
          for (final version in state.versions) {
            if (version.state == DownloadState.downloading) {
              _downloadingVersionId = version.metadata.id;
            } else if (version.state == DownloadState.downloaded &&
                version.metadata.id == _downloadingVersionId) {
              // Download completed
              _downloadingVersionId = null;
            }
          }
        }
      },
      builder: (context, state) {
        return AppGradientDialog(
          maxWidth: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.download_for_offline_outlined,
                      color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'bible.download_dialog_title'.tr(),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'bible.download_dialog_content'.tr(),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Version list
              if (state is BibleVersionLoading)
                const Center(child: CircularProgressIndicator())
              else if (state is BibleVersionLoaded)
                _buildVersionList(context, state)
              else if (state is BibleVersionError)
                Text(
                  'bible.download_error'.tr(),
                  style: TextStyle(color: colorScheme.error),
                ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'drawer.close'.tr(),
                      style:
                          TextStyle(color: colorScheme.onPrimary, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVersionList(BuildContext context, BibleVersionLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Filter versions by current language first, then others
    final languageVersions = state.versions
        .where((v) => v.metadata.language == widget.currentLanguage)
        .toList();
    final otherVersions = state.versions
        .where((v) => v.metadata.language != widget.currentLanguage)
        .toList();

    final allVersions = [...languageVersions, ...otherVersions];

    if (allVersions.isEmpty) {
      return Text(
        'bible.no_versions_available'.tr(),
        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: allVersions.length,
        itemBuilder: (context, index) {
          final version = allVersions[index];
          final isDownloading = version.state == DownloadState.downloading;
          final isDownloaded = version.state == DownloadState.downloaded;
          final isQueued = version.state == DownloadState.queued;

          return ListTile(
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            leading: Icon(
              isDownloaded
                  ? Icons.offline_pin
                  : Icons.download_for_offline_outlined,
              color: isDownloaded
                  ? colorScheme.primary
                  : colorScheme.onPrimary.withAlpha(180),
              size: 22,
            ),
            title: Text(
              '${version.metadata.name} (${version.metadata.languageName})',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: isDownloading
                ? LinearProgressIndicator(
                    value: version.progress > 0 ? version.progress : null,
                    backgroundColor: colorScheme.onPrimary.withAlpha(50),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  )
                : Text(
                    _formatSize(version.metadata.sizeBytes),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimary.withAlpha(150),
                    ),
                  ),
            trailing: _buildTrailingAction(
                context, version, isDownloading, isDownloaded, isQueued),
          );
        },
      ),
    );
  }

  Widget _buildTrailingAction(
    BuildContext context,
    BibleVersionWithState version,
    bool isDownloading,
    bool isDownloaded,
    bool isQueued,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final bloc = context.read<BibleVersionBloc>();

    if (isDownloaded) {
      return Icon(Icons.check_circle, color: colorScheme.primary, size: 20);
    }

    if (isDownloading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: version.progress > 0 ? version.progress : null,
          color: colorScheme.primary,
        ),
      );
    }

    if (isQueued) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 4),
          Text(
            '#${version.queuePosition}',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      );
    }

    return IconButton(
      icon: Icon(Icons.download, color: colorScheme.primary),
      onPressed: () {
        bloc.add(DownloadVersionEvent(version.metadata.id));
      },
      tooltip: 'bible_version.download'.tr(),
      iconSize: 22,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
