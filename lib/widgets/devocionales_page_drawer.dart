import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:devocional_nuevo/widgets/theme_selector.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/providers/theme_provider.dart';
import 'package:devocional_nuevo/utils/theme_constants.dart';

import 'package:devocional_nuevo/pages/favorites_page.dart';
import 'package:devocional_nuevo/pages/notification_config_page.dart';

class DevocionalesDrawer extends StatelessWidget {
  const DevocionalesDrawer({super.key});

  void _shareApp(BuildContext context) {
    const String message =
        '¡Participa en el pre-lanzamiento del app devocionales Cristianos.\n'
        'Enlace para inscribirte y edificarte con la palabra de Dios.\n'
        'https://forms.gle/HGFNUv9pc8XpG8aa6';
    Share.share(message);
    Navigator.of(context).pop(); // Cerrar drawer tras compartir
  }

  // Helper para alinear iconos y textos uniformemente
  Widget drawerRow({
    required IconData icon,
    required Widget label,
    VoidCallback? onTap,
    Widget? trailing,
    double iconSize = 28,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
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
              alignment: Alignment.center,
              child: Text(
                'Tu Biblia, tu estilo',
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ListView(
                  children: [
                    // --- Sección Versión Bíblica ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        'Versión Bíblica',
                        style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    // --- Icono alineado + dropdown ---
                    drawerRow(
                      icon: CupertinoIcons.book,
                      iconColor: colorScheme.primary,
                      label: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: devocionalProvider.selectedVersion,
                          icon: Icon(
                            CupertinoIcons.chevron_down,
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
                          items: versions.map<DropdownMenuItem<String>>(
                              (String itemValue) {
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
                      icon: CupertinoIcons.square_favorites_alt,
                      iconColor: colorScheme.primary,
                      label: Text(
                        'Favoritos guardados',
                        style: textTheme.bodyMedium?.copyWith(
                            fontSize: 16, color: colorScheme.onSurface),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const FavoritesPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    // --- Switch modo oscuro ---
                    drawerRow(
                      icon: Icons.contrast,
                      iconColor: colorScheme.primary,
                      label: Text(
                        'Luz baja (modo oscuro)',
                        style: textTheme.bodyMedium?.copyWith(
                            fontSize: 16, color: colorScheme.onSurface),
                      ),
                      trailing: Switch(
                        value:
                            themeProvider.currentBrightness == Brightness.dark,
                        onChanged: (bool value) {
                          themeProvider.setBrightness(
                              value ? Brightness.dark : Brightness.light);
                        },
                      ),
                      onTap: () {
                        final newValue =
                            themeProvider.currentBrightness != Brightness.dark;
                        themeProvider.setBrightness(
                            newValue ? Brightness.dark : Brightness.light);
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
                            fontSize: 16, color: colorScheme.onSurface),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const NotificationConfigPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    // --- Compartir app ---
                    drawerRow(
                      icon: Icons.share,
                      iconColor: colorScheme.primary,
                      label: Text(
                        'Compartir esta app',
                        style: textTheme.bodyMedium?.copyWith(
                            fontSize: 16, color: colorScheme.onSurface),
                      ),
                      onTap: () => _shareApp(context),
                    ),
                    const SizedBox(height: 5),
                    // --- Descargar devocionales ---
                    drawerRow(
                      icon: Icons.download_outlined,
                      iconColor: colorScheme.primary,
                      label: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Descargar devocionales',
                            style: textTheme.bodyMedium?.copyWith(
                                fontSize: 16, color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Próximamente',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
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
                                  child: Icon(Icons.palette,
                                      color: colorScheme.primary, size: 28),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Seleciona color de tema',
                                  style: textTheme.bodyMedium?.copyWith(
                                      fontSize: 16,
                                      color: colorScheme.onSurface),
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
