import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_event.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/pages/discovery_list_page.dart';
import 'package:devocional_nuevo/pages/favorites_page.dart';
import 'package:devocional_nuevo/pages/notification_config_page.dart';
import 'package:devocional_nuevo/pages/prayers_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/utils/bubble_constants.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:devocional_nuevo/widgets/app_gradient_dialog.dart';
import 'package:devocional_nuevo/widgets/theme_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class DevocionalesDrawer extends StatelessWidget {
  const DevocionalesDrawer({super.key});

  void _shareApp(BuildContext context) {
    final message = 'drawer.share_message'.tr();

    SharePlus.instance.share(ShareParams(text: message));
    Navigator.of(context).pop(); // Cerrar drawer tras compartir
  }

  void _showOfflineManagerDialog(BuildContext context) {
    _showDownloadConfirmationDialog(context);
  }

  void _changeBibleVersion(BuildContext context, String newVersion) async {
    final devocionalProvider =
        Provider.of<DevocionalProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'settings.version_changed'.tr()),
            backgroundColor:
                error != null ? colorScheme.error : colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error switching version: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // Close dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('errors.unknown_error'.tr()),
            backgroundColor: colorScheme.error,
          ),
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
                            Future.delayed(
                              const Duration(milliseconds: 400),
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
                                      ScaffoldMessenger.of(parentContext)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'drawer.download_success'.tr()
                                                : 'drawer.download_error'.tr(),
                                          ),
                                          backgroundColor: success
                                              ? colorScheme.primary
                                              : colorScheme.error,
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    } catch (_) {
                                      // If parent context no longer has a ScaffoldMessenger, ignore.
                                    }
                                  }
                                }
                              },
                            );
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
                                  return versions
                                      .map<Widget>((String itemValue) {
                                    return Row(
                                      children: [
                                        Text(
                                          itemValue,
                                          style: TextStyle(
                                            color: colorScheme.onSurface,
                                            fontSize: 16,
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
                                      itemValue,
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
                        // --- Mis oraciones ---
                        drawerRow(
                          key: const Key('drawer_my_prayers'),
                          icon: Icons.local_fire_department_outlined,
                          iconColor: colorScheme.primary,
                          label: Text(
                            'drawer.my_prayers'.tr(),
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PrayersPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 5),
                        // --- Discovery Studies ---
                        if (Constants.enableDiscoveryFeature)
                          drawerRow(
                            key: const Key('drawer_discovery_studies'),
                            icon: Icons.school_outlined,
                            iconColor: colorScheme.primary,
                            label: Text(
                              'discovery.discovery_studies'.tr(),
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 16,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DiscoveryListPage(),
                                ),
                              );
                            },
                          ),
                        if (Constants.enableDiscoveryFeature)
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
                          icon: Icons.share,
                          iconColor: colorScheme.primary,
                          label: Text(
                            'drawer.share_app'.tr(),
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          onTap: () => _shareApp(context),
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'drawer.offline_access_ready'.tr(),
                                      ),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      duration: const Duration(seconds: 2),
                                    ),
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
                              // Evita overflow limitando el alto del grid visual
                              SizedBox(
                                height: 120,
                                child: ThemeSelectorCircleGrid(
                                  selectedTheme: currentThemeFamily,
                                  brightness: currentBrightness,
                                  onThemeChanged: (theme) {
                                    context.read<ThemeBloc>().add(
                                          ChangeThemeFamily(theme),
                                        );
                                    Navigator.of(context).pop();
                                  },
                                ),
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
}
