import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/bible_versions/bible_versions_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/utils/constants/bubble_constants.dart';
import 'package:flutter/material.dart';

/// Left-side navigation drawer for the Bible reader page: lists downloaded
/// versions for the current language (current version highlighted) plus any
/// remote versions still available to download, each with a download icon.
/// Tapping a downloadable version starts the download in place, showing
/// progress on that item's icon; the drawer stays open (and cannot be
/// dismissed) until the caller closes it once the download completes.
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

  bool get _isDownloading => downloadStatuses.values.any(
        (status) => status.errorMessageKey == null && !status.isComplete,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return PopScope(
      canPop: !_isDownloading,
      child: Drawer(
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
                        onPressed: _isDownloading
                            ? null
                            : () => Navigator.of(context).pop(),
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
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (version.hasUpdate)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BubbleConstants.updatedFeatureColor,
                                    borderRadius: BorderRadius.circular(
                                      BubbleConstants.widgetBubbleRadius,
                                    ),
                                  ),
                                  child: Text(
                                    'bubble_constants.updated_feature'.tr(),
                                    style:
                                        BubbleConstants.widgetBubbleTextStyle,
                                  ),
                                ),
                              ),
                            Text(
                              versionLabelBuilder(version),
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 16,
                                color: colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        trailing: version.hasUpdate
                            ? IconButton(
                                key: Key(
                                  'bible_reader_drawer_update_${version.dbFileName}',
                                ),
                                icon: Icon(
                                  Icons.system_update_alt_outlined,
                                  color: BubbleConstants.updatedFeatureColor,
                                ),
                                tooltip:
                                    'bubble_constants.updated_feature'.tr(),
                                onPressed: _isDownloading
                                    ? null
                                    : () => onDownloadVersion(version),
                              )
                            : null,
                        onTap: _isDownloading
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                if (!isSelected) onVersionSelected(version);
                              },
                      );
                    }),
                    ...downloadableVersions.map((version) {
                      final status = downloadStatuses[version.dbFileName];
                      final bubbleId =
                          'bible_reader_drawer_remote_${version.dbFileName}';
                      return _DownloadableVersionTile(
                        key: Key(
                          'bible_reader_drawer_downloadable_${version.dbFileName}',
                        ),
                        bubbleId: bubbleId,
                        label: versionLabelBuilder(version),
                        status: status,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        downloadTrailing: _downloadTrailing,
                        onTap: status == null || status.errorMessageKey != null
                            ? () {
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

/// A downloadable-version [ListTile] that owns the "new" chip's visibility
/// as local state, so dismissing it (via [onTap]) hides it immediately
/// instead of waiting for an unrelated rebuild to re-evaluate the bubble.
class _DownloadableVersionTile extends StatefulWidget {
  final String bubbleId;
  final String label;
  final VersionDownloadStatus? status;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final Widget Function(ColorScheme, VersionDownloadStatus?) downloadTrailing;
  final VoidCallback? onTap;

  const _DownloadableVersionTile({
    super.key,
    required this.bubbleId,
    required this.label,
    required this.status,
    required this.colorScheme,
    required this.textTheme,
    required this.downloadTrailing,
    required this.onTap,
  });

  @override
  State<_DownloadableVersionTile> createState() =>
      _DownloadableVersionTileState();
}

class _DownloadableVersionTileState extends State<_DownloadableVersionTile> {
  bool? _showChip;

  @override
  void initState() {
    super.initState();
    BubbleUtils.shouldShowBubble(widget.bubbleId).then((shouldShow) {
      if (mounted) setState(() => _showChip = shouldShow);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showChip == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: BubbleConstants.newFeatureColor,
                  borderRadius: BorderRadius.circular(
                    BubbleConstants.widgetBubbleRadius,
                  ),
                ),
                child: Text(
                  'bubble_constants.new_feature'.tr(),
                  style: BubbleConstants.widgetBubbleTextStyle,
                ),
              ),
            ),
          Text(
            widget.label,
            style: widget.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: widget.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      trailing: widget.downloadTrailing(widget.colorScheme, widget.status),
      onTap: widget.onTap == null
          ? null
          : () {
              BubbleUtils.markAsShown(widget.bubbleId);
              setState(() => _showChip = false);
              widget.onTap!();
            },
    );
  }
}
