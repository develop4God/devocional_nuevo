// lib/pages/favorite_devocional_detail_page.dart

import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/controllers/font_size_controller.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/pages/app_navigation_shell.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/supporter_pet_service.dart';
import 'package:devocional_nuevo/utils/devotional_share_helper.dart';
import 'package:devocional_nuevo/utils/localized_date_formatter.dart';
import 'package:devocional_nuevo/widgets/app_bottom_nav_bar.dart';
import 'package:devocional_nuevo/widgets/app_snack_bar.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocionales_content_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// Read-only view of a single favorited devotional, reached from
/// [FavoritesPage]. Unlike [DevocionalesPage], this has no next/previous
/// paging, drawer, or streak badge — it shows only the devotional the user
/// tapped, so browsing away and back never loses their place in the main
/// reading flow.
class FavoriteDevocionalDetailPage extends StatefulWidget {
  final Devocional devocional;

  const FavoriteDevocionalDetailPage({super.key, required this.devocional});

  @override
  State<FavoriteDevocionalDetailPage> createState() =>
      _FavoriteDevocionalDetailPageState();
}

class _FavoriteDevocionalDetailPageState
    extends State<FavoriteDevocionalDetailPage> {
  late final SupporterPetService _petService =
      getService<SupporterPetService>();

  void _showFavoriteFeedback(bool wasAdded) {
    if (!mounted) return;
    AppSnackBar.show(
      context,
      wasAdded
          ? 'devotionals_page.added_to_favorites'.tr()
          : 'devotionals_page.removed_from_favorites'.tr(),
    );
  }

  Future<void> _share() async {
    final text = DevotionalShareHelper.generarTextoParaCompartir(
      widget.devocional,
    );
    await SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: Scaffold(
        appBar: CustomAppBar(titleText: 'favorites.title'.tr()),
        body: Consumer<DevocionalProvider>(
          builder: (context, devocionalProvider, child) {
            final isFavorite = devocionalProvider.isFavorite(widget.devocional);
            return DevocionalesContentWidget(
              devocional: widget.devocional,
              fontSize: FontSizeController.defaultFontSize,
              currentStreak: 0,
              streakFuture: Future.value(0),
              onStreakBadgeTap: () {},
              showDate: false,
              getLocalizedDateFormat: (context) =>
                  LocalizedDateFormatter.formatForContext(
                context,
                dateTime: widget.devocional.date,
              ),
              isFavorite: isFavorite,
              onFavoriteToggle: () async {
                final wasAdded = await devocionalProvider.toggleFavorite(
                  widget.devocional.id,
                );
                _showFavoriteFeedback(wasAdded);
              },
              onShare: _share,
              petService: _petService,
            );
          },
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentTab: null,
          onSelectTab: (tab) {
            // Pushed over the shell (from FavoritesPage); pop back to it
            // before switching tabs, same convention as FavoritesPage itself.
            Navigator.of(context).popUntil((route) => route.isFirst);
            AppNavigationShell.selectTab(tab);
          },
        ),
      ),
    );
  }
}
