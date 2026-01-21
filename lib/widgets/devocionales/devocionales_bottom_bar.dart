import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/pages/discovery_list_page.dart';
import 'package:devocional_nuevo/pages/progress_page.dart';
import 'package:devocional_nuevo/pages/settings_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/utils/bubble_constants.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:devocional_nuevo/widgets/tts_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Bottom navigation bar for Devocionales page
/// Contains navigation controls, TTS player, and action buttons
class DevocionalesBottomBar extends StatelessWidget {
  final Devocional currentDevocional;
  final bool isFavorite;
  final bool canNavigateNext;
  final bool canNavigatePrevious;
  final TtsAudioController ttsAudioController;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onShowInvitation;
  final VoidCallback onBible;
  final VoidCallback onPrayers;
  final VoidCallback onShare;
  final ValueChanged<bool> onFavoriteToggled;

  const DevocionalesBottomBar({
    super.key,
    required this.currentDevocional,
    required this.isFavorite,
    required this.canNavigateNext,
    required this.canNavigatePrevious,
    required this.ttsAudioController,
    required this.onPrevious,
    required this.onNext,
    required this.onShowInvitation,
    required this.onBible,
    required this.onShare,
    required this.onPrayers,
    required this.onFavoriteToggled,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color? appBarBackgroundColor =
        Theme.of(context).appBarTheme.backgroundColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNavigationControls(context, colorScheme),
        _buildActionButtons(
          context,
          appBarBackgroundColor,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildNavigationControls(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Consumer<AudioController>(
            builder: (context, audioController, _) {
              final progress = audioController.progress;
              return LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey[300],
                color: colorScheme.primary,
              );
            },
          ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 45,
                  child: OutlinedButton.icon(
                    key: const Key('bottom_nav_previous_button'),
                    onPressed: canNavigatePrevious ? onPrevious : null,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      'devotionals.previous'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      foregroundColor: colorScheme.primary,
                      overlayColor: colorScheme.primary.withAlpha(
                        (0.1 * 255).round(),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Builder(
                    builder: (context) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TtsPlayerWidget(
                            key: const Key('bottom_nav_tts_player'),
                            devocional: currentDevocional,
                            audioController: ttsAudioController,
                            onCompleted: () {
                              final provider = Provider.of<DevocionalProvider>(
                                context,
                                listen: false,
                              );
                              if (provider.showInvitationDialog) {
                                onShowInvitation();
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 45,
                  child: OutlinedButton(
                    key: const Key('bottom_nav_next_button'),
                    onPressed: canNavigateNext ? onNext : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      foregroundColor: colorScheme.primary,
                      overlayColor: colorScheme.primary.withAlpha(
                        (0.1 * 255).round(),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'devotionals.next'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Color? appBarBackgroundColor,
    ColorScheme colorScheme,
  ) {
    final devocionalProvider = Provider.of<DevocionalProvider>(
      context,
      listen: false,
    );

    return SafeArea(
      top: false,
      child: BottomAppBar(
        height: 60,
        color: appBarBackgroundColor,
        padding: EdgeInsets.zero,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Favorites
              IconButton(
                key: const Key('bottom_appbar_favorite_icon'),
                tooltip: isFavorite
                    ? 'devotionals.remove_from_favorites_short'.tr()
                    : 'devotionals.save_as_favorite'.tr(),
                onPressed: () async {
                  getService<AnalyticsService>().logBottomBarAction(
                    action: 'favorite',
                  );
                  final wasAdded = await devocionalProvider
                      .toggleFavorite(currentDevocional.id);
                  onFavoriteToggled(wasAdded);
                },
                icon: Icon(
                  isFavorite ? Icons.star : Icons.favorite_border,
                  color: isFavorite ? Colors.amber : Colors.white,
                  size: 32,
                ),
              ),
              // 2. Share
              IconButton(
                key: const Key('bottom_appbar_share_icon'),
                tooltip: 'devotionals.share_devotional'.tr(),
                onPressed: () {
                  getService<AnalyticsService>().logBottomBarAction(
                    action: 'share',
                  );
                  onShare();
                },
                icon: Icon(
                  Icons.share_outlined,
                  color: colorScheme.onPrimary,
                  size: 30,
                ),
              ),
              // 3. Prayers
              IconButton(
                key: const Key('bottom_appbar_prayers_icon'),
                tooltip: 'tooltips.my_prayers'.tr(),
                onPressed: () async {
                  getService<AnalyticsService>().logBottomBarAction(
                    action: 'prayers',
                  );
                  HapticFeedback.mediumImpact();
                  await BubbleUtils.markAsShown(
                    BubbleUtils.getIconBubbleId(
                      Icons.local_fire_department_outlined,
                      'new',
                    ),
                  );
                  onPrayers();
                },
                icon: const Icon(
                  Icons.local_fire_department_outlined,
                  color: Colors.white,
                  size: 35,
                ),
              ),
              // 4. Bible
              IconButton(
                key: const Key('bottom_appbar_bible_icon'),
                tooltip: 'tooltips.bible'.tr(),
                onPressed: () async {
                  getService<AnalyticsService>().logBottomBarAction(
                    action: 'bible',
                  );
                  await BubbleUtils.markAsShown(
                    BubbleUtils.getIconBubbleId(
                      Icons.auto_stories_outlined,
                      'new',
                    ),
                  );
                  onBible();
                },
                icon: const Icon(
                  Icons.auto_stories_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              // 5. Discovery Studies (new feature)
              if (Constants.enableDiscoveryFeature)
                IconButton(
                  key: const Key('bottom_appbar_discovery_icon'),
                  tooltip: 'discovery.discovery_studies'.tr(),
                  onPressed: () {
                    getService<AnalyticsService>().logBottomBarAction(
                      action: 'discovery',
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DiscoveryListPage(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.school_outlined,
                    color: colorScheme.onPrimary,
                    size: 32,
                  ),
                ),
              // 6. Spiritual Stats/Progress
              IconButton(
                key: const Key('bottom_appbar_progress_icon'),
                tooltip: 'tooltips.progress'.tr(),
                onPressed: () {
                  getService<AnalyticsService>().logBottomBarAction(
                    action: 'progress',
                  );
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const ProgressPage(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 250),
                    ),
                  );
                },
                icon: Icon(
                  Icons.emoji_events_outlined,
                  color: colorScheme.onPrimary,
                  size: 30,
                ),
              ),
              // 7. Settings
              IconButton(
                key: const Key('bottom_appbar_settings_icon'),
                tooltip: 'tooltips.settings'.tr(),
                onPressed: () async {
                  debugPrint('🔥 [BottomBar] Tap: settings');
                  getService<AnalyticsService>().logBottomBarAction(
                    action: 'settings',
                  );
                  await BubbleUtils.markAsShown(
                    BubbleUtils.getIconBubbleId(
                      Icons.settings_suggest_sharp,
                      'new',
                    ),
                  );
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const SettingsPage(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 250),
                    ),
                  );
                },
                icon: Icon(
                  Icons.settings_suggest_sharp,
                  color: colorScheme.onPrimary,
                  size: 35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
