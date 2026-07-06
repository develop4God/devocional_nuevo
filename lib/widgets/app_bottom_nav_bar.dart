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

/// Single source of truth for which tabs are enabled and their order.
/// Both [AppNavigationShell] (IndexedStack children) and [AppBottomNavBar]
/// (icon row) must consume the same list, or the highlighted icon and the
/// visible page can desync.
List<AppTab> enabledAppTabs() => [
      AppTab.home,
      AppTab.prayers,
      AppTab.bible,
      if (Constants.enableDiscoveryFeature) AppTab.discovery,
      if (Constants.enableEncountersFeature) AppTab.encounters,
      AppTab.progress,
      AppTab.settings,
      if (getService<RemoteConfigService>().featureSupporter) AppTab.supporter,
    ];

/// Persistent bottom navigation bar shown on every main screen.
/// Every icon switches tabs via [onSelectTab], keeping the bar frozen.
class AppBottomNavBar extends StatelessWidget {
  /// Tab to highlight. Pass null when the bar is shown standalone on a page
  /// that isn't itself a shell tab (e.g. [FavoritesPage]) so no icon is lit.
  final AppTab? currentTab;
  final ValueChanged<AppTab> onSelectTab;

  /// Enabled tabs, in order. Pass the same (frozen) list that drives the
  /// shell's IndexedStack so icons never point at a missing page. Defaults
  /// to [enabledAppTabs] when the bar is used standalone.
  final List<AppTab>? tabs;

  const AppBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
    this.tabs,
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
    final List<AppTab> enabledTabs = tabs ?? enabledAppTabs();

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
              if (enabledTabs.contains(AppTab.discovery))
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
              if (enabledTabs.contains(AppTab.encounters))
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
              _NavIconWithBadge(
                iconKey: const Key('bottom_appbar_settings_icon'),
                tooltip: 'tooltips.settings'.tr(),
                icon: Icons.settings_suggest_sharp,
                color: _iconColor(colorScheme, AppTab.settings),
                bubbleId: BubbleUtils.getIconBubbleId(
                  Icons.settings_suggest_sharp,
                  'new',
                ),
                onSelect: () => _selectTab(AppTab.settings, 'settings'),
              ),
              // 8. Support/Donate (conditional via Remote Config)
              if (enabledTabs.contains(AppTab.supporter))
                _NavIconWithBadge(
                  iconKey: const Key('bottom_appbar_supporter_icon'),
                  tooltip: 'tooltips.support'.tr(),
                  icon: Icons.volunteer_activism,
                  color: _iconColor(colorScheme, AppTab.supporter),
                  bubbleId: BubbleUtils.getIconBubbleId(
                    Icons.volunteer_activism,
                    'new',
                    semanticLabel: 'supporter_bottom_bar',
                  ),
                  onSelect: () => _selectTab(AppTab.supporter, 'supporter'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nav icon with an optional "new feature" bubble badge.
///
/// Stateful so the shouldShowBubble future is created once per element
/// lifetime instead of on every parent rebuild — a fresh future per build
/// would re-read SharedPreferences and blink the badge on each tab switch.
class _NavIconWithBadge extends StatefulWidget {
  final Key iconKey;
  final String tooltip;
  final IconData icon;
  final Color color;
  final String bubbleId;
  final VoidCallback onSelect;

  const _NavIconWithBadge({
    required this.iconKey,
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.bubbleId,
    required this.onSelect,
  });

  @override
  State<_NavIconWithBadge> createState() => _NavIconWithBadgeState();
}

class _NavIconWithBadgeState extends State<_NavIconWithBadge> {
  late final Future<bool> _showBubble =
      BubbleUtils.shouldShowBubble(widget.bubbleId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _showBubble,
      builder: (context, snapshot) {
        final showBubble = snapshot.data ?? false;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              key: widget.iconKey,
              tooltip: widget.tooltip,
              onPressed: () async {
                await BubbleUtils.markAsShown(widget.bubbleId);
                widget.onSelect();
              },
              icon: Icon(widget.icon, color: widget.color, size: 30),
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
    );
  }
}
