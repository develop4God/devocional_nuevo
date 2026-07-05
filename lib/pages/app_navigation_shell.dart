import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/pages/bible_reader_page.dart';
import 'package:devocional_nuevo/pages/devocionales_page.dart';
import 'package:devocional_nuevo/pages/discovery_bible_studies/discovery_list_page.dart';
import 'package:devocional_nuevo/pages/encounters/encounters_list_page.dart';
import 'package:devocional_nuevo/pages/prayers_page.dart';
import 'package:devocional_nuevo/pages/progress_page.dart';
import 'package:devocional_nuevo/pages/settings_page.dart';
import 'package:devocional_nuevo/pages/supporter_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/remote_config_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/utils/constants/constants.dart';
import 'package:devocional_nuevo/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

/// Root shell that keeps [AppBottomNavBar] frozen across all main sections.
///
/// Main sections are tabs in an [IndexedStack] (state preserved, instant
/// switching). Tabs are built lazily on first visit. System back on a
/// non-home tab returns to the home tab; back on home exits the app.
class AppNavigationShell extends StatefulWidget {
  final String? initialDevocionalId;

  const AppNavigationShell({super.key, this.initialDevocionalId});

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  late final List<AppTab> _tabs = [
    AppTab.home,
    AppTab.prayers,
    AppTab.bible,
    if (Constants.enableDiscoveryFeature) AppTab.discovery,
    if (Constants.enableEncountersFeature) AppTab.encounters,
    AppTab.progress,
    AppTab.settings,
    if (getService<RemoteConfigService>().featureSupporter) AppTab.supporter,
  ];

  AppTab _currentTab = AppTab.home;

  // Tabs already visited — unvisited tabs stay as empty placeholders so
  // startup only builds the home tab.
  final Set<AppTab> _builtTabs = {AppTab.home};

  // Tells DevocionalesPage whether its tab is visible, so it can pause
  // reading tracking and stop audio when the user switches away (tab
  // switches don't fire RouteAware callbacks).
  final ValueNotifier<bool> _homeTabActive = ValueNotifier<bool>(true);

  void _selectTab(AppTab tab) {
    if (tab == _currentTab) return;
    setState(() {
      // The bible page owns a FlutterTts engine, and flutter_tts routes
      // platform events to the most recently created instance. Keeping the
      // page alive while hidden starves the other TTS owners (double
      // miniplayer / stuck spinner), so it is disposed on leave and rebuilt
      // per visit — same lifecycle as the previous push navigation.
      if (_currentTab == AppTab.bible) _builtTabs.remove(AppTab.bible);
      _builtTabs.add(tab);
      _currentTab = tab;
    });
    _homeTabActive.value = tab == AppTab.home;
  }

  Widget _buildTab(AppTab tab) {
    if (!_builtTabs.contains(tab)) return const SizedBox.shrink();
    switch (tab) {
      case AppTab.home:
        return DevocionalesPage(
          initialDevocionalId: widget.initialDevocionalId,
          isActive: _homeTabActive,
        );
      case AppTab.prayers:
        return const PrayersPage();
      case AppTab.bible:
        return const _BibleTab();
      case AppTab.discovery:
        return const DiscoveryListPage();
      case AppTab.encounters:
        return const EncountersListPage();
      case AppTab.progress:
        return const ProgressPage();
      case AppTab.settings:
        return const SettingsPage();
      case AppTab.supporter:
        return const SupporterPage();
    }
  }

  @override
  void dispose() {
    _homeTabActive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: PopScope(
        canPop: _currentTab == AppTab.home,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _selectTab(AppTab.home);
        },
        child: Scaffold(
          body: IndexedStack(
            index: _tabs.indexOf(_currentTab),
            children: [for (final tab in _tabs) _buildTab(tab)],
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentTab: _currentTab,
            onSelectTab: _selectTab,
          ),
        ),
      ),
    );
  }
}

/// Bible tab wrapper — resolves the available bible versions for the current
/// app language (with fallbacks) before showing [BibleReaderPage].
class _BibleTab extends StatefulWidget {
  const _BibleTab();

  @override
  State<_BibleTab> createState() => _BibleTabState();
}

class _BibleTabState extends State<_BibleTab> {
  String? _language;
  Future<List<BibleVersion>>? _versionsFuture;

  Future<List<BibleVersion>> _loadVersions(String appLanguage) async {
    List<BibleVersion> versions =
        await BibleVersionRegistry.getVersionsForLanguage(appLanguage);
    if (versions.isEmpty) {
      versions = await BibleVersionRegistry.getVersionsForLanguage('es');
    }
    if (versions.isEmpty) {
      versions = await BibleVersionRegistry.getAllVersions();
    }
    return versions;
  }

  @override
  Widget build(BuildContext context) {
    final String language =
        context.select<DevocionalProvider, String>((p) => p.selectedLanguage);
    if (language != _language) {
      _language = language;
      _versionsFuture = _loadVersions(language);
    }

    return FutureBuilder<List<BibleVersion>>(
      future: _versionsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('[BibleTab] Failed to load versions: ${snapshot.error}');
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return BibleReaderPage(
          key: ValueKey('bible_reader_$_language'),
          versions: snapshot.data ?? const [],
        );
      },
    );
  }
}
