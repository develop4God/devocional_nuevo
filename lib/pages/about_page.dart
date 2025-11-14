// lib/pages/about_page.dart
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _appVersion = 'about.loading_version'.tr();

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  // Método para obtener la versión de la aplicación
  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
    });
  }

  // Método para lanzar URL externas
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Si la URL no se puede abrir, muestra un SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('about.link_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: themeState.systemUiOverlayStyle,
        child: Scaffold(
          appBar: CustomAppBar(
            titleText: 'about.title'.tr(),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // Ícono de la Aplicación
                ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),

                // Nombre de la Aplicación
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'about.app_name'.tr(),
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),

                // Versión de la Aplicación
                Text(
                  '${'about.version'.tr()} $_appVersion',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Descripción de la Aplicación
                Text(
                  'about.description'.tr(),
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Características Principales
                Text(
                  'about.main_features'.tr(),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontSize: 17,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    _FeatureItem(text: 'about.feature_daily'.tr()),
                    _FeatureItem(text: 'about.feature_multiversion'.tr()),
                    _FeatureItem(text: 'about.feature_favorites'.tr()),
                    _FeatureItem(text: 'about.feature_sharing'.tr()),
                    _FeatureItem(text: 'about.feature_language'.tr()),
                    _FeatureItem(text: 'about.feature_themes'.tr()),
                    _FeatureItem(text: 'about.feature_dark_light'.tr()),
                    _FeatureItem(text: 'about.feature_notifications'.tr()),
                  ],
                ),
                const SizedBox(height: 12),

                // Desarrollado por
                Text(
                  'about.developed_by'.tr(),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Enlace visible del sitio web (ARRIBA del botón)
                InkWell(
                  onTap: () => _launchURL('https://www.develop4God.com/'),
                  child: Text(
                    'https://www.develop4God.com/',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),

                // Botón de Términos y Condiciones / Copyright
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchURL('https://www.develop4god.com/'),
                    icon: Icon(Icons.public, color: colorScheme.onPrimary),
                    label: Text(
                      'about.terms_copyright'.tr(),
                      style: TextStyle(color: colorScheme.onPrimary),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ));
  }
}

// Widget auxiliar para elementos de la lista de características
class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
