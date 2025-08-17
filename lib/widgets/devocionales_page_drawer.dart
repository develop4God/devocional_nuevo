import 'package:devocional_nuevo/pages/favorites_page.dart';
import 'package:devocional_nuevo/pages/notification_config_page.dart';
import 'package:devocional_nuevo/pages/prayers_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/providers/theme_provider.dart';
import 'package:devocional_nuevo/utils/bubble_constants.dart';
import 'package:devocional_nuevo/utils/theme_constants.dart';
import 'package:devocional_nuevo/widgets/theme_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class DevocionalesDrawer extends StatelessWidget {
  const DevocionalesDrawer({super.key});

  void _shareApp(BuildContext context) {
    const String message =
        '¡Participa en el pre-lanzamiento del app devocionales Cristianos.\n'
        'Enlace para inscribirte y edificarte con la palabra de Dios.\n'
        'https://forms.gle/HGFNUv9pc8XpG8aa6';

    SharePlus.instance.share(ShareParams(text: message));
    Navigator.of(context).pop(); // Cerrar drawer tras compartir
  }

  void _showOfflineManagerDialog(BuildContext context) {
    _showDownloadConfirmationDialog(context);
  }

  // NUEVO METODO AJUSTADO:
  void _showDownloadConfirmationDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        double progress = 0.0;
        bool downloading = false;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.download_for_offline_outlined,
                    color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  downloading ? 'Descargando...' : 'Confirmar descarga',
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 16, // O prueba 15, 14, etc.
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Esta descarga se realiza una sola vez. Permite acceder a los devocionales y versículos sin conexión a internet/offline.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                if (downloading) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Descargando... ${(progress * 100).toStringAsFixed(0)}%",
                    style: textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            actions: downloading
                ? []
                : [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          downloading = true;
                          progress = 0.0;
                        });

                        // Tu lógica real de descarga con progreso
                        final devocionalProvider =
                            Provider.of<DevocionalProvider>(context,
                                listen: false);

                        bool success = await devocionalProvider
                            .downloadDevocionalesWithProgress(onProgress: (p) {
                          setState(() {
                            progress = p;
                          });
                        });

                        if (context.mounted) {
                          Future.delayed(const Duration(milliseconds: 400), () {
                            if (context.mounted) {
                              Navigator.of(context)
                                  .pop(); // Cierra el AlertDialog
                              if (success) {
                                Navigator.of(context)
                                    .pop(); // Cierra el Drawer exitoso y fallido,para que se vea el snackbar message
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Devocionales descargados exitosamente'
                                        : 'Error en la descarga. Verifica tu conexión y reintenta.',
                                  ),
                                  backgroundColor: success
                                      ? colorScheme.primary
                                      : colorScheme.error,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: const Text('Aceptar'),
                    ),
                  ],
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
  }) {
    return InkWell(
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final versions = ['RVR1960'];
    appThemeFamilies.keys.toList();

    final drawerBackgroundColor = theme.scaffoldBackgroundColor;

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
                      'Tu Biblia, tu estilo',
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
                      icon: const Icon(Icons.exit_to_app, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      tooltip: 'Cerrar',
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
                    // --- Sección Versión Bíblica ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        'Versión Bíblica',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // --- Icono alineado + dropdown ---
                    drawerRow(
                      icon: Icons.menu_book_outlined,
                      iconColor: colorScheme.primary,
                      label: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: devocionalProvider.selectedVersion,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: colorScheme.onSurface,
                          ),
                          dropdownColor: colorScheme.surface,
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              devocionalProvider.setSelectedVersion(newValue);
                              Navigator.of(context).pop();
                            }
                          },
                          selectedItemBuilder: (BuildContext context) {
                            return versions.map<Widget>((String itemValue) {
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
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // --- Favoritos guardados ---
                    drawerRow(
                      icon: Icons.book_outlined,
                      iconColor: colorScheme.primary,
                      label: Text(
                        'Favoritos guardados',
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
                      icon: Icons.favorite_outline,
                      iconColor: colorScheme.primary,
                      label: Text(
                        'Mis oraciones',
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
                    // --- Switch modo oscuro ---
                    drawerRow(
                      icon: themeProvider.currentBrightness == Brightness.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      iconColor: colorScheme.primary,
                      label: Text(
                        themeProvider.currentBrightness == Brightness.dark
                            ? 'Luz alta (modo claro)'
                            : 'Luz baja (modo oscuro)',
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      trailing: Switch(
                        value:
                            themeProvider.currentBrightness == Brightness.dark,
                        onChanged: (bool value) {
                          themeProvider.setBrightness(
                            value ? Brightness.dark : Brightness.light,
                          );
                        },
                      ),
                      onTap: () {
                        final newValue =
                            themeProvider.currentBrightness != Brightness.dark;
                        themeProvider.setBrightness(
                          newValue ? Brightness.dark : Brightness.light,
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    // --- Notificaciones ---
                    drawerRow(
                      icon: Icons.notifications,
                      iconColor: colorScheme.primary,
                      label: Text(
                        'Configuración de notificaciones',
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
                      icon: Icons.share,
                      iconColor: colorScheme.primary,
                      label: Text(
                        'Comparte app Devocionales Cristianos',
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
                          icon: hasLocalData
                              ? Icons.offline_pin_outlined
                              : Icons.download_for_offline_outlined,
                          iconColor: colorScheme.primary,
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              hasLocalData
                                  ? Text(
                                      'Devocionales descargados',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontSize: 16,
                                        color: colorScheme.onSurface,
                                      ),
                                    )
                                  : Text(
                                      'Descargar devocionales',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontSize: 16,
                                        color: colorScheme.onSurface,
                                      ),
                                    ).newBubble,
                              // <--- Burbuja solo en "Descargar devocionales"
                              const SizedBox(height: 4),
                              Text(
                                hasLocalData
                                    ? 'Disfruta contenido sin internet'
                                    : 'Para uso sin internet',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withAlpha(150),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            if (!hasLocalData) {
                              _showOfflineManagerDialog(context);
                            } else {
                              Navigator.of(context).pop(); // Cierra el Drawer
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Ya puedes acceder a tu contenido sin internet'),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                    Divider(
                      height: 32,
                      color: themeProvider.dividerAdaptiveColor,
                    ),
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
                                    Icons.palette,
                                    color: colorScheme.primary,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Seleciona color de tema',
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
                              selectedTheme: themeProvider.currentThemeFamily,
                              brightness: themeProvider.currentBrightness,
                              onThemeChanged: (theme) {
                                themeProvider.setThemeFamily(theme);
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
  }
}
