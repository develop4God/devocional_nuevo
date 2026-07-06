import 'package:flutter/material.dart';

/// Reusable actions bar for Discovery list studies.
///
/// This widget is a thin, stateless wrapper around the real Discovery
/// list actions (download, share, favorites, read, next). It is designed
/// so that the Discovery list page can pass in the correct callbacks and
/// state flags while all layout and visual styling live in one place.
class DiscoveryActionsBar extends StatelessWidget {
  final bool isDownloaded;
  final bool isDownloading;
  final String downloadLabel;
  final String shareLabel;
  final String favoritesLabel;
  final String readLabel;
  final String nextLabel;

  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onOpenFavorites;
  final VoidCallback onRead;
  final VoidCallback onNext;

  const DiscoveryActionsBar({
    super.key,
    required this.isDownloaded,
    required this.isDownloading,
    required this.downloadLabel,
    required this.shareLabel,
    required this.favoritesLabel,
    required this.readLabel,
    required this.nextLabel,
    required this.onDownload,
    required this.onShare,
    required this.onOpenFavorites,
    required this.onRead,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // There are always five buttons: download, share, favorites, read, next.
            const buttonCount = 5;
            // Subtract total padding (8px left + 8px right = 16px per button)
            final maxButtonWidth =
                (constraints.maxWidth - (16 * buttonCount)) / buttonCount;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Download
                _ActionButton(
                  icon: isDownloaded
                      ? Icons.file_download_done_rounded
                      : isDownloading
                          ? Icons.sync_rounded
                          : Icons.file_download_outlined,
                  label: downloadLabel,
                  onTap: onDownload,
                  colorScheme: colorScheme,
                  isDownloading: isDownloading,
                  maxWidth: maxButtonWidth,
                ),
                // Share
                _ActionButton(
                  icon: Icons.share_rounded,
                  label: shareLabel,
                  onTap: onShare,
                  colorScheme: colorScheme,
                  maxWidth: maxButtonWidth,
                ),
                // Favorites
                _ActionButton(
                  icon: Icons.star_rounded,
                  label: favoritesLabel,
                  onTap: onOpenFavorites,
                  colorScheme: colorScheme,
                  maxWidth: maxButtonWidth,
                ),
                // Read
                _ActionButton(
                  icon: Icons.auto_stories_rounded,
                  label: readLabel,
                  onTap: onRead,
                  colorScheme: colorScheme,
                  isPrimary: true,
                  maxWidth: maxButtonWidth,
                ),
                // Next
                _ActionButton(
                  icon: Icons.arrow_forward_rounded,
                  label: nextLabel,
                  onTap: onNext,
                  colorScheme: colorScheme,
                  maxWidth: maxButtonWidth,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isPrimary;
  final bool isDownloading;
  final double? maxWidth;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
    this.isPrimary = false,
    this.isDownloading = false,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBorderedIcon = [
      Icons.share_rounded,
      Icons.star_rounded,
      Icons.auto_stories_rounded,
      Icons.arrow_forward_rounded,
      Icons.file_download_outlined,
      Icons.file_download_done_rounded,
      Icons.sync_rounded,
    ].contains(icon);

    // We allow up to 2 lines for the label so longer texts like the
    // download action can wrap, while keeping a slightly taller fixed
    // height so we don’t overflow.
    return InkWell(
      onTap: isDownloading ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: SizedBox(
          width: maxWidth,
          height: 68,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isBorderedIcon
                  ? Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isPrimary
                              ? colorScheme.primary
                              : colorScheme.primary.withAlpha(180),
                          width: 2,
                        ),
                        color: isPrimary
                            ? colorScheme.primary.withAlpha(26)
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: isDownloading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              )
                            : Icon(icon, color: colorScheme.primary, size: 22),
                      ),
                    )
                  : Icon(
                      icon,
                      color: isPrimary
                          ? colorScheme.onPrimary
                          : colorScheme.primary,
                      size: 26,
                    ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.05,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
