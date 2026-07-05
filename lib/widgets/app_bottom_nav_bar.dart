import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/services/i_analytics_service.dart';
import 'package:devocional_nuevo/services/remote_config_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/utils/constants/bubble_constants.dart';
import 'package:devocional_nuevo/utils/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Main app sections reachable as persistent tabs from [AppBottomNavBar].
enum AppTab {
  home,
  prayers,
  bible,
  discovery,
  encounters,
  progress,
  settings,
  supporter,
}

/// Persistent bottom navigation bar shown on every main screen.
/// Every icon switches tabs via [onSelectTab], keeping the bar frozen.
class AppBottomNavBar extends StatelessWidget {
  final AppTab currentTab;
  final ValueChanged<AppTab> onSelectTab;

  const AppBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
  });

  Color _iconColor(ColorScheme colorScheme, AppTab tab) {
    return currentTab == tab
        ? colorScheme.onPrimary
        : colorScheme.onPrimary.withValues(alpha: 0.6);
  }

  void _selectTab(AppTab tab, String analyticsAction) {
    getService<IAnalyticsService>().logBottomBarAction(
      action: analyticsAction,
    );
    onSelectTab(tab);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color? appBarBackgroundColor = Theme.of(
      context,
    ).appBarTheme.backgroundColor;

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
              // 1. Home (Devocionales)
              IconButton(
                key: const Key('bottom_appbar_home_icon'),
                tooltip: 'common.home'.tr(),
                onPressed: () => _selectTab(AppTab.home, 'home'),
                icon: Icon(
                  currentTab == AppTab.home ? Icons.home : Icons.home_outlined,
                  color: _iconColor(colorScheme, AppTab.home),
                  size: 30,
                ),
              ),
              // 2. Prayers
              IconButton(
                key: const Key('bottom_appbar_prayers_icon'),
                tooltip: 'tooltips.my_prayers'.tr(),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await BubbleUtils.markAsShown(
                    BubbleUtils.getIconBubbleId(
                      Icons.local_fire_department_outlined,
                      'new',
                    ),
                  );
                  _selectTab(AppTab.prayers, 'prayers');
                },
                icon: Icon(
                  Icons.local_fire_department_outlined,
                  color: _iconColor(colorScheme, AppTab.prayers),
                  size: 30,
                ),
              ),
              // 3. Bible
              IconButton(
                key: const Key('bottom_appbar_bible_icon'),
                tooltip: 'tooltips.bible'.tr(),
                onPressed: () => _selectTab(AppTab.bible, 'bible'),
                icon: Icon(
                  Icons.auto_stories_outlined,
                  color: _iconColor(colorScheme, AppTab.bible),
                  size: 30,
                ),
              ),
              // 4. Discovery Studies
              if (Constants.enableDiscoveryFeature)
                IconButton(
                  key: const Key('bottom_appbar_discovery_icon'),
                  tooltip: 'discovery.discovery_studies'.tr(),
                  onPressed: () => _selectTab(AppTab.discovery, 'discovery'),
                  icon: Icon(
                    Icons.school_outlined,
                    color: _iconColor(colorScheme, AppTab.discovery),
                    size: 30,
                  ),
                ),
              // 5. Encounters
              if (Constants.enableEncountersFeature)
                IconButton(
                  key: const Key('bottom_appbar_encounters_icon'),
                  tooltip: 'Encounters',
                  onPressed: () => _selectTab(AppTab.encounters, 'encounters'),
                  icon: Icon(
                    Icons.location_history_outlined,
                    color: _iconColor(colorScheme, AppTab.encounters),
                    size: 30,
                  ),
                ),
              // 6. Spiritual Stats/Progress
              IconButton(
                key: const Key('bottom_appbar_progress_icon'),
                tooltip: 'tooltips.progress'.tr(),
                onPressed: () => _selectTab(AppTab.progress, 'progress'),
                icon: Icon(
                  Icons.emoji_events_outlined,
                  color: _iconColor(colorScheme, AppTab.progress),
                  size: 30,
                ),
              ),
              // 7. Settings
              FutureBuilder<bool>(
                future: BubbleUtils.shouldShowBubble(
                  BubbleUtils.getIconBubbleId(
                    Icons.settings_suggest_sharp,
                    'new',
                  ),
                ),
                builder: (context, snapshot) {
                  final showBubble = snapshot.data ?? false;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        key: const Key('bottom_appbar_settings_icon'),
                        tooltip: 'tooltips.settings'.tr(),
                        onPressed: () async {
                          await BubbleUtils.markAsShown(
                            BubbleUtils.getIconBubbleId(
                              Icons.settings_suggest_sharp,
                              'new',
                            ),
                          );
                          _selectTab(AppTab.settings, 'settings');
                        },
                        icon: Icon(
                          Icons.settings_suggest_sharp,
                          color: _iconColor(colorScheme, AppTab.settings),
                          size: 30,
                        ),
                      ),
                      if (showBubble)
                        Positioned(
                          top: BubbleConstants.iconBadgeTop,
                          right: BubbleConstants.iconBadgeRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: BubbleConstants.newFeatureColor,
                              borderRadius: BorderRadius.circular(
                                BubbleConstants.iconBadgeRadius,
                              ),
                              boxShadow: BubbleConstants.bubbleShadow,
                            ),
                            child: Text(
                              'bubble_constants.new_feature'.tr(),
                              style: BubbleConstants.iconBadgeTextStyle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              // 8. Support/Donate (conditional via Remote Config)
              if (getService<RemoteConfigService>().featureSupporter)
                FutureBuilder<bool>(
                  future: BubbleUtils.shouldShowBubble(
                    BubbleUtils.getIconBubbleId(
                      Icons.volunteer_activism,
                      'new',
                      semanticLabel: 'supporter_bottom_bar',
                    ),
                  ),
                  builder: (context, snapshot) {
                    final showBubble = snapshot.data ?? false;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          key: const Key('bottom_appbar_supporter_icon'),
                          tooltip: 'tooltips.support'.tr(),
                          onPressed: () async {
                            await BubbleUtils.markAsShown(
                              BubbleUtils.getIconBubbleId(
                                Icons.volunteer_activism,
                                'new',
                                semanticLabel: 'supporter_bottom_bar',
                              ),
                            );
                            _selectTab(AppTab.supporter, 'supporter');
                          },
                          icon: Icon(
                            Icons.volunteer_activism,
                            color: _iconColor(colorScheme, AppTab.supporter),
                            size: 30,
                          ),
                        ),
                        if (showBubble)
                          Positioned(
                            top: BubbleConstants.iconBadgeTop,
                            right: BubbleConstants.iconBadgeRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: BubbleConstants.newFeatureColor,
                                borderRadius: BorderRadius.circular(
                                  BubbleConstants.iconBadgeRadius,
                                ),
                                boxShadow: BubbleConstants.bubbleShadow,
                              ),
                              child: Text(
                                'bubble_constants.new_feature'.tr(),
                                style: BubbleConstants.iconBadgeTextStyle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
