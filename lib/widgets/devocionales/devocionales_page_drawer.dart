import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/pages/favorites_page.dart';
import 'package:devocional_nuevo/pages/notification_config_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/in_app_review_service.dart';
import 'package:devocional_nuevo/utils/constants/bubble_constants.dart';
import 'package:devocional_nuevo/widgets/app_gradient_dialog.dart';
import 'package:devocional_nuevo/widgets/app_snack_bar.dart';
import 'package:devocional_nuevo/widgets/theme_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class DevocionalesDrawer extends StatefulWidget {
  const DevocionalesDrawer({super.key});

  @override
  State<DevocionalesDrawer> createState() => _DevocionalesDrawerState();
}

class _DevocionalesDrawerState extends State<DevocionalesDrawer> {
  List<BibleVersion> _loadedVersions = [];

  @override
  void initState() {
    super.initState();
    _loadVersionsForCurrentLanguage();
  }

  Future<void> _loadVersionsForCurrentLanguage() async {
    final versions = await BibleVersionRegistry.getAllVersions();
    if (mounted) {
      setState(() {
        _loadedVersions = versions;
      });
    }
  }

  void _shareApp(BuildContext context) async {
    final message = 'drawer.share_message'.tr();

    await BubbleUtils.markAsShown('drawer_share_bubble');
    if (!context.mounted) return;

    SharePlus.instance.share(ShareParams(text: message));
    Navigator.of(context).pop(); // Cerrar drawer tras compartir
  }

  void _showOfflineManagerDialog(BuildContext context) {
    _showDownloadConfirmationDialog(context);
  }

  void _changeBibleVersion(BuildContext context, String newVersion) async {
    final devocionalProvider = Provider.of<DevocionalProvider>(
      context,
      listen: false,
    );
    final textTheme = Theme.of(context).textTheme;

    // Show blocking loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: AppGradientDialog(
            maxWidth: 300,
            dismissible: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  'drawer.switching_version'.tr(),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      await devocionalProvider.setSelectedVersion(newVersion);
      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        // Close drawer
        Navigator.of(context).pop();

        final error = devocionalProvider.errorMessage;
        AppSnackBar.show(
          context,
          error ?? 'settings.version_changed'.tr(),
          type: error != null ? AppSnackBarType.feedback : AppSnackBarType.tip,
        );
      }
    } catch (e) {
      debugPrint('Error switching version: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // Close dialog if still open
        AppSnackBar.show(
          context,
          'errors.unknown_error'.tr(),
          type: AppSnackBarType.feedback,
        );
      }
    }
  }

  // NUEVO METODO AJUSTADO:
  void _showDownloadConfirmationDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Capture the parent context (drawer) to use for operations outside the dialog
    final parentContext = context;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        double progress = 0.0;
        bool downloading = false;

        // Use explicit names for the StatefulBuilder builder params to avoid shadowing
        return StatefulBuilder(
          builder: (sbContext, setState) => AppGradientDialog(
            maxWidth: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.download_for_offline_outlined,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        downloading
                            ? 'drawer.download_dialog_downloading'.tr()
                            : 'drawer.download_dialog_title'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'drawer.download_dialog_content'.tr(),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
                if (downloading) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(value: progress, minHeight: 8),
                  const SizedBox(height: 8),
                  Text(
                    "${'drawer.download_dialog_downloading'.tr()} ${(progress * 100).toStringAsFixed(0)}%",
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (!downloading)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        child: Text(
                          'drawer.cancel'.tr(),
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          // Set downloading state on the dialog UI
                          setState(() {
                            downloading = true;
                            progress = 0.0;
                          });

                          // Use parentContext to obtain the provider from the outer tree
                          final devocionalProvider =
                              Provider.of<DevocionalProvider>(
                            parentContext,
                            listen: false,
                          );

                          bool success = await devocionalProvider
                              .downloadDevocionalesWithProgress(
                            onProgress: (p) {
                              // Guard setState: only update dialog UI while it is still the current route
                              final bool dialogIsCurrent =
                                  ModalRoute.of(dialogContext)?.isCurrent ??
                                      false;
                              if (dialogIsCurrent) {
                                try {
                                  setState(() {
                                    progress = p;
                                  });
                                } catch (_) {
                                  // In case setState fails for any reason, swallow to avoid crash.
                                }
                              }
                            },
                          );

                          // After download finishes, close the dialog and optionally the drawer
                          // Check if context is still mounted before using it
                          if (!dialogContext.mounted) return;

                          final bool dialogStillOpen =
                              ModalRoute.of(dialogContext)?.isCurrent ?? false;

                          if (dialogStillOpen) {
                            Future.delayed(const Duration(milliseconds: 400),
                                () {
                              // Check if context is still mounted before using it
                              if (!dialogContext.mounted) return;

                              final bool dialogStillOpenNow =
                                  ModalRoute.of(dialogContext)?.isCurrent ??
                                      false;
                              if (dialogStillOpenNow) {
                                // Close the dialog
                                Navigator.of(dialogContext).pop();

                                // If success, also close the drawer (parent context)
                                if (success) {
                                  if (parentContext.mounted) {
                                    try {
                                      Navigator.of(parentContext).pop();
                                    } catch (_) {
                                      // Ignore: parent may have been removed
                                    }
                                  }
                                }

                                // Show snackbar on the parent scaffold
                                if (parentContext.mounted) {
                                  try {
                                    AppSnackBar.show(
                                      parentContext,
                                      success
                                          ? 'drawer.download_success'.tr()
                                          : 'drawer.download_error'.tr(),
                                      type: success
                                          ? AppSnackBarType.tip
                                          : AppSnackBarType.feedback,
                                    );
                                  } catch (_) {
                                    // If parent context no longer has a ScaffoldMessenger, ignore.
                                  }
                                }
                              }
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        child: Text('drawer.accept'.tr()),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper para alinear iconos y textos uniformemente
  Widget drawerRow({
    required IconData icon,
    required Widget label,
    VoidCallback? onTap,
    Widget? trailing,
    double iconSize = 28,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      vertical: 5,
      horizontal: 0,
    ),
    Color? iconColor,
    Key? key,
  }) {
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 36, // ancho fijo para todos los iconos
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(icon, color: iconColor, size: iconSize),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: label),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devocionalProvider = Provider.of<DevocionalProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Get available versions for current language
    final versions = devocionalProvider.availableVersions;
    final selectedVersion =
        versions.contains(devocionalProvider.selectedVersion)
            ? devocionalProvider.selectedVersion
            : (versions.isNotEmpty ? versions.first : null);

    final drawerBackgroundColor = theme.scaffoldBackgroundColor;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        // Get theme info from state, with fallbacks
        String currentThemeFamily;
        Brightness currentBrightness;
        Color dividerAdaptiveColor;

        if (themeState is ThemeLoaded) {
          currentThemeFamily = themeState.themeFamily;
          currentBrightness = themeState.brightness;
          dividerAdaptiveColor = themeState.dividerAdaptiveColor;
        } else {
          // Fallback values
          final themeBloc = context.read<ThemeBloc>();
          currentThemeFamily = themeBloc.currentThemeFamily;
          currentBrightness = themeBloc.currentBrightness;
          dividerAdaptiveColor = themeBloc.dividerAdaptiveColor;
        }

        return Drawer(
          backgroundColor: drawerBackgroundColor,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado morado compacto
                Container(
                  height: 56,
                  width: double.infinity,
                  color: colorScheme.primary,
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          'drawer.title'.tr(),
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
                          key: const Key('drawer_close_button'),
                          icon: const Icon(
                            Icons.close_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          tooltip: 'drawer.close'.tr(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: ListView(
                      children: [
                        const SizedBox(height: 15),
                        // --- Sección Versión Bíblica ---
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            'drawer.bible_version_section'.tr(),
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // --- Icono alineado + dropdown ---
                        drawerRow(
                          key: const Key('drawer_bible_version_selector'),
                          icon: Icons.auto_stories_outlined,
                          iconColor: colorScheme.primary,
                          label: DropdownButtonHideUnderline(
                            child: AbsorbPointer(
                              absorbing: devocionalProvider.isSwitchingVersion,
                              child: DropdownButton<String>(
                                value: selectedVersion,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: colorScheme.onSurface,
                                ),
                                dropdownColor: colorScheme.surface,
                                isExpanded: true,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    _changeBibleVersion(context, newValue);
                                  }
                                },
                                selectedItemBuilder: (BuildContext context) {
                                  return versions.map<Widget>((
                                    String itemValue,
                                  ) {
                                    return Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _versionLabel(itemValue),
                                            style: TextStyle(
                                              color: colorScheme.onSurface,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList();
                                },
                                items: versions.map<DropdownMenuItem<String>>((
                                  String itemValue,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: itemValue,
                                    child: Text(
                                      _versionLabel(itemValue),
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // --- Favoritos guardados ---
                        drawerRow(
                          key: const Key('drawer_saved_favorites'),
                          icon: Icons.star_border_outlined,
                          iconColor: colorScheme.primary,
                          label: Text(
                            'drawer.saved_favorites'.tr(),
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const FavoritesPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 5),
                        // --- Switch modo oscuro ---
                        drawerRow(
                          key: const Key('drawer_dark_mode_toggle'),
                          icon: currentBrightness == Brightness.dark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          iconColor: colorScheme.primary,
                          label: Text(
                            currentBrightness == Brightness.dark
                                ? 'drawer.light_mode'.tr()
                                : 'drawer.dark_mode'.tr(),
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          trailing: Switch(
                            value: currentBrightness == Brightness.dark,
                            onChanged: (bool value) {
                              context.read<ThemeBloc>().add(
                                    ChangeBrightness(
                                      value
                                          ? Brightness.dark
                                          : Brightness.light,
                                    ),
                                  );
                            },
                          ),
                          onTap: () {
                            final newValue =
                                currentBrightness != Brightness.dark;
                            context.read<ThemeBloc>().add(
                                  ChangeBrightness(
                                    newValue
                                        ? Brightness.dark
                                        : Brightness.light,
                                  ),
                                );
                          },
                        ),
                        const SizedBox(height: 5),
                        // --- Notificaciones ---
                        drawerRow(
                          key: const Key('drawer_notifications_config'),
                          icon: Icons.notifications_active_outlined,
                          iconColor: colorScheme.primary,
                          label: Text(
                            'drawer.notifications_config'.tr(),
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationConfigPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 5),
                        // --- Compartir app ---
                        drawerRow(
                          key: const Key('drawer_share_app'),
                          icon: Icons.share_outlined,
                          iconColor: colorScheme.primary,
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'drawer.share_app'.tr(),
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'bible.share'.tr(),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withAlpha(150),
                                ),
                              ).newBubbleWithId('drawer_share_bubble'),
                            ],
                          ),
                          onTap: () => _shareApp(context),
                        ),
                        const SizedBox(height: 5),
                        // --- Calificar app ---
                        drawerRow(
                          key: const Key('drawer_rate_app'),
                          icon: Icons.thumb_up_alt_outlined,
                          iconColor: colorScheme.primary,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'drawer.rate_app'.tr(),
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ).newBubbleWithId('drawer_rate_bubble'),
                            ],
                          ),
                          onTap: () async {
                            await BubbleUtils.markAsShown('drawer_rate_bubble');
                            if (!context.mounted) return;
                            Navigator.of(context).pop(); // Closes the drawer
                            InAppReviewService.requestInAppReview(context);
                          },
                        ),
                        const SizedBox(height: 5),
                        // --- Descargar devocionales ---
                        FutureBuilder<bool>(
                          future: devocionalProvider.hasTargetYearsLocalData(),
                          builder: (context, snapshot) {
                            final bool hasLocalData = snapshot.data ?? false;
                            return drawerRow(
                              key: const Key('drawer_download_devotionals'),
                              icon: hasLocalData
                                  ? Icons.offline_pin_outlined
                                  : Icons.download_for_offline_outlined,
                              iconColor: colorScheme.primary,
                              label: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'drawer.download_devotionals'.tr(),
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontSize: 16,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  hasLocalData
                                      ? Text(
                                          'drawer.offline_content_ready'.tr(),
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurface
                                                .withAlpha(150),
                                          ),
                                        )
                                      : Text(
                                          'drawer.for_offline_use'.tr(),
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurface
                                                .withAlpha(150),
                                          ),
                                        ).newBubble,
                                ],
                              ),
                              onTap: () {
                                if (!hasLocalData) {
                                  _showOfflineManagerDialog(context);
                                } else {
                                  Navigator.of(
                                    context,
                                  ).pop(); // Cierra el Drawer
                                  AppSnackBar.show(
                                    context,
                                    'drawer.offline_access_ready'.tr(),
                                    type: AppSnackBarType.tip,
                                  );
                                }
                              },
                            );
                          },
                        ),
                        Divider(height: 32, color: dividerAdaptiveColor),
                        // --- Selector visual de temas con icono y título a la par, y el grid debajo ---
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 36,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Icon(
                                        Icons.palette_outlined,
                                        color: colorScheme.primary,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'drawer.select_theme_color'.tr(),
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontSize: 16,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ThemeSelectorCircleGrid(
                                selectedTheme: currentThemeFamily,
                                brightness: currentBrightness,
                                onThemeChanged: (theme) {
                                  context.read<ThemeBloc>().add(
                                        ChangeThemeFamily(theme),
                                      );
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _versionLabel(String versionId) {
    try {
      final version = _loadedVersions.firstWhere(
        (v) => v.dbFileName.startsWith(versionId),
      );

      // Use display name directly from registry
      return _getDisplayName(version.name, version.languageCode);
    } catch (_) {
      return versionId;
    }
  }

  /// Extract display name from version name
  /// - For Latin-script languages (es, en, pt, fr): removes "Display Name (CODE)"
  /// - For native-script languages (ja, zh, hi): returns the name as-is with full abbreviation info
  String _getDisplayName(String name, String languageCode) {
    // For languages with Latin version codes, remove the (CODE) part
    if (languageCode == 'es' ||
        languageCode == 'en' ||
        languageCode == 'pt' ||
        languageCode == 'fr') {
      final regex = RegExp(r'^(.+?)\s*\([A-Z0-9]+\)$');
      final match = regex.firstMatch(name);
      if (match != null) {
        return match.group(1)!.trim();
      }
    }
    // For native-script languages (ja, zh, hi), use name as-is
    return name;
  }
}
