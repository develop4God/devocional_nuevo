import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/pages/bible_reader_page.dart';
import 'package:devocional_nuevo/pages/progress_page.dart';
import 'package:devocional_nuevo/pages/settings_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
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
    this.appBarForegroundColor,
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
