import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/pages/bible_reader_page.dart';
import 'package:devocional_nuevo/pages/progress_page.dart';
import 'package:devocional_nuevo/pages/settings_page.dart';
import 'package:devocional_nuevo/pages/supporter_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/remote_config_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/utils/page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DiscoveryBottomNavBar extends StatelessWidget {
  final VoidCallback? onPrayers;
  final VoidCallback? onBible;
  final VoidCallback? onProgress;
  final VoidCallback? onSettings;
  final Widget? ttsPlayerWidget;
  final Color? appBarForegroundColor;
  final Color? appBarBackgroundColor;

  const DiscoveryBottomNavBar({
    super.key,
    this.onPrayers,
    this.onBible,
    this.onProgress,
    this.onSettings,
    this.ttsPlayerWidget,
    this.appBarForegroundColor = Colors.white,
    this.appBarBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: const BoxDecoration(color: Colors.transparent),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Center(
                  child:
                      ttsPlayerWidget ?? const SizedBox(width: 56, height: 56),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: BottomAppBar(
            height: 60,
            color: appBarBackgroundColor,
            padding: EdgeInsets.zero,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    key: const Key('bottom_appbar_prayers_icon'),
                    tooltip: 'Mis oraciones',
                    onPressed: onPrayers,
                    icon: const Icon(Icons.local_fire_department_outlined,
                        color: Colors.white, size: 35),
                  ),
                  IconButton(
                    key: const Key('bottom_appbar_bible_icon'),
                    tooltip: 'Biblia',
                    onPressed: () async {
                      final devocionalProvider =
                          Provider.of<DevocionalProvider>(context,
                              listen: false);
                      final appLanguage = devocionalProvider.selectedLanguage;
                      List<BibleVersion> versions =
                          await BibleVersionRegistry.getVersionsForLanguage(
                              appLanguage);
                      if (versions.isEmpty) {
                        versions =
                            await BibleVersionRegistry.getVersionsForLanguage(
                                'es');
                      }
                      if (versions.isEmpty) {
                        versions = await BibleVersionRegistry.getAllVersions();
                      }
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        PageTransitions.fadeSlide(
                          BibleReaderPage(
                            versions: versions,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_stories_outlined,
                        color: Colors.white, size: 32),
                  ),
                  IconButton(
                    key: const Key('bottom_appbar_progress_icon'),
                    tooltip: 'Progreso',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProgressPage()),
                      );
                    },
                    icon: Icon(Icons.emoji_events_outlined,
                        color: appBarForegroundColor, size: 30),
                  ),
                  IconButton(
                    key: const Key('bottom_appbar_settings_icon'),
                    tooltip: 'Ajustes',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsPage()),
                      );
                    },
                    icon: Icon(Icons.app_settings_alt_outlined,
                        color: appBarForegroundColor, size: 30),
                  ),
                  // Support/Donate (Conditional - Remote Config)
                  if (getService<RemoteConfigService>().featureSupporter)
                    IconButton(
                      key: const Key('bottom_appbar_supporter_icon'),
                      tooltip: 'Apoyo',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SupporterPage()),
                        );
                      },
                      icon: Icon(Icons.volunteer_activism,
                          color: appBarForegroundColor, size: 32),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
                            : Icon(
                                icon,
                                color: colorScheme.primary,
                                size: 22,
                              ),
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
